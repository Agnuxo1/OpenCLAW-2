import * as crypto from "crypto";
import * as path from "path";
import { markExecuted, requestApproval } from "./approval-store";
import { runtimeConfig } from "./config";
import { ActionOutcome, isConfirmed } from "./contracts";
import { CircuitBreaker, fetchWithTimeout, withRetry } from "./reliability";
import { readJson, writeJsonAtomic } from "./state-store";

export interface PostRecord {
  id: string;
  platform: string;
  title: string;
  content: string;
  url?: string;
  timestamp: string;
}

export interface EngagementRecord {
  id: string;
  platform: string;
  targetPostId: string;
  type: "comment" | "vote" | "share";
  content?: string;
  timestamp: string;
}

const postHistoryPath = path.join(runtimeConfig.stateDir, "post_history.json");
const engagementHistoryPath = path.join(runtimeConfig.stateDir, "engagement_history.json");
const platformMetadataPath = path.join(runtimeConfig.stateDir, "platforms.json");
const moltbookBreaker = new CircuitBreaker(3, 10 * 60_000);

function loadPosts(): PostRecord[] {
  return readJson<PostRecord[]>(postHistoryPath, []);
}

function loadEngagements(): EngagementRecord[] {
  return readJson<EngagementRecord[]>(engagementHistoryPath, []);
}

function savePost(post: PostRecord): void {
  writeJsonAtomic(postHistoryPath, [...loadPosts(), post].slice(-5_000));
}

function saveEngagement(engagement: EngagementRecord): void {
  writeJsonAtomic(engagementHistoryPath, [...loadEngagements(), engagement].slice(-5_000));
}

function withinRateLimit(action: "post" | "comment"): boolean {
  const cutoff = Date.now() - 24 * 60 * 60_000;
  const records = action === "post" ? loadPosts() : loadEngagements();
  const limit = action === "post" ? 10 : 50;
  return records.filter((record) => Date.parse(record.timestamp) > cutoff).length < limit;
}

function isDuplicate(title: string, content: string): boolean {
  const digest = crypto.createHash("sha256").update(`${title}\n${content}`).digest("hex");
  const cutoff = Date.now() - 30 * 24 * 60 * 60_000;
  return loadPosts().some((post) => {
    const prior = crypto.createHash("sha256").update(`${post.title}\n${post.content}`).digest("hex");
    return Date.parse(post.timestamp) > cutoff && prior === digest;
  });
}

function retryable(error: unknown): boolean {
  const status = (error as { status?: number }).status;
  return status === undefined || status === 408 || status === 429 || status >= 500;
}

async function moltbookRequest(endpoint: string, init: RequestInit = {}): Promise<unknown> {
  if (!runtimeConfig.moltbookApiKey) throw new Error("MOLTBOOK_API_KEY is not configured");
  if (!moltbookBreaker.canRun()) throw new Error("Moltbook circuit breaker is open");

  try {
    const result = await withRetry(
      async () => {
        const response = await fetchWithTimeout(
          `${runtimeConfig.moltbookApiBase}${endpoint}`,
          {
            ...init,
            headers: {
              Authorization: `Bearer ${runtimeConfig.moltbookApiKey}`,
              "Content-Type": "application/json",
              ...init.headers,
            },
          },
          runtimeConfig.httpTimeoutMs,
        );
        const body = await response.text();
        if (!response.ok) {
          const error = new Error(`Moltbook HTTP ${response.status}: ${body.slice(0, 300)}`);
          (error as Error & { status?: number }).status = response.status;
          throw error;
        }
        return body ? (JSON.parse(body) as unknown) : {};
      },
      { attempts: 3, shouldRetry: retryable },
    );
    moltbookBreaker.success();
    return result;
  } catch (error) {
    moltbookBreaker.failure();
    throw error;
  }
}

export function initPlatforms(): void {
  writeJsonAtomic(platformMetadataPath, {
    moltbook: {
      name: "Moltbook",
      apiBase: runtimeConfig.moltbookApiBase,
      apiKeyEnv: "MOLTBOOK_API_KEY",
      enabled: Boolean(runtimeConfig.moltbookApiKey),
      rateLimit: { posts: 10, comments: 50, windowHours: 24 },
    },
  });
}

export async function postToMoltbook(
  title: string,
  content: string,
  submolt = "general",
): Promise<ActionOutcome<PostRecord>> {
  if (!title.trim() || !content.trim()) {
    return { status: "failed", attempted: false, message: "Title and content are required" };
  }
  if (!withinRateLimit("post")) {
    return { status: "skipped", attempted: false, message: "Moltbook post rate limit reached" };
  }
  if (isDuplicate(title, content)) {
    return { status: "skipped", attempted: false, message: "Duplicate content" };
  }

  const payload = { title, content, submolt };
  const approval = requestApproval("moltbook.post", "high", payload);
  if (!approval.allowed) {
    return { status: "queued", attempted: false, message: `Awaiting approval: ${approval.request.id}` };
  }

  try {
    const response = (await moltbookRequest("/posts", {
      method: "POST",
      body: JSON.stringify(payload),
    })) as { id?: unknown; url?: unknown; post?: { id?: unknown; url?: unknown } };
    const id = String(response.post?.id ?? response.id ?? "").trim();
    if (!id) throw new Error("Moltbook response did not confirm a post id");
    const post: PostRecord = {
      id,
      platform: "moltbook",
      title,
      content,
      url: String(response.post?.url ?? response.url ?? `${runtimeConfig.moltbookApiBase}/posts/${id}`),
      timestamp: new Date().toISOString(),
    };
    savePost(post);
    markExecuted(approval.request.id);
    return { status: "confirmed", attempted: true, message: `Published ${id}`, data: post };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { status: "failed", attempted: true, message, error: message, retryable: retryable(error) };
  }
}

export async function commentOnMoltbook(
  postId: string,
  content: string,
): Promise<ActionOutcome<EngagementRecord>> {
  if (!postId.trim() || !content.trim()) {
    return { status: "failed", attempted: false, message: "Post id and comment are required" };
  }
  if (!withinRateLimit("comment")) {
    return { status: "skipped", attempted: false, message: "Moltbook comment rate limit reached" };
  }
  if (loadEngagements().some((entry) => entry.targetPostId === postId)) {
    return { status: "skipped", attempted: false, message: "Post already engaged" };
  }

  const payload = { postId, content };
  const approval = requestApproval("moltbook.comment", "high", payload);
  if (!approval.allowed) {
    return { status: "queued", attempted: false, message: `Awaiting approval: ${approval.request.id}` };
  }

  try {
    await moltbookRequest(`/posts/${encodeURIComponent(postId)}/comments`, {
      method: "POST",
      body: JSON.stringify({ content }),
    });
    const engagement: EngagementRecord = {
      id: `engagement-${Date.now()}`,
      platform: "moltbook",
      targetPostId: postId,
      type: "comment",
      content,
      timestamp: new Date().toISOString(),
    };
    saveEngagement(engagement);
    markExecuted(approval.request.id);
    return { status: "confirmed", attempted: true, message: "Comment confirmed", data: engagement };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { status: "failed", attempted: true, message, error: message, retryable: retryable(error) };
  }
}

export async function fetchMoltbookPosts(
  sort: "hot" | "new" = "hot",
  limit = 15,
): Promise<ActionOutcome<unknown[]>> {
  try {
    const response = (await moltbookRequest(
      `/posts?sort=${sort}&limit=${Math.max(1, Math.min(limit, 50))}`,
    )) as { posts?: unknown };
    const posts = Array.isArray(response.posts) ? response.posts : [];
    return { status: "confirmed", attempted: true, message: `Fetched ${posts.length} posts`, data: posts };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return { status: "failed", attempted: true, message, error: message, retryable: retryable(error) };
  }
}

export async function postToChirper(content: string, topic?: string): Promise<ActionOutcome<PostRecord>> {
  const approval = requestApproval("chirper.post", "high", {
    content,
    topic: topic || "Research Update",
  });
  return {
    status: "queued",
    attempted: false,
    message: `Chirper requires a publisher adapter; queued as ${approval.request.id}`,
  };
}

type MoltbookFeedPost = { id?: string; title?: string; content?: string; author?: { name?: string } };

export async function proactiveEngagement(researchTopics: string[]): Promise<ActionOutcome<number>> {
  const feed = await fetchMoltbookPosts("hot", 20);
  if (!isConfirmed(feed)) return { ...feed, data: undefined };

  let confirmed = 0;
  let queued = 0;
  for (const rawPost of feed.data) {
    const post = rawPost as MoltbookFeedPost;
    if (!post.id || post.author?.name?.toLowerCase().includes("openclaw")) continue;
    const text = `${post.title || ""} ${post.content || ""}`.toLowerCase();
    const topic = researchTopics.find((candidate) => text.includes(candidate.toLowerCase()));
    if (!topic) continue;
    const outcome = await commentOnMoltbook(
      post.id,
      `Your work on ${topic} is relevant to our research. We would be glad to compare methods and evidence.`,
    );
    if (outcome.status === "confirmed") confirmed += 1;
    if (outcome.status === "queued") queued += 1;
    if (confirmed + queued >= 3) break;
  }
  return {
    status: queued > 0 ? "queued" : "confirmed",
    attempted: confirmed > 0,
    message: `${confirmed} confirmed, ${queued} awaiting approval`,
    data: confirmed,
  };
}

export function getStats(): { posts: number; engagements: number; byPlatform: Record<string, number> } {
  const posts = loadPosts();
  const engagements = loadEngagements();
  const byPlatform: Record<string, number> = {};
  for (const post of posts) byPlatform[post.platform] = (byPlatform[post.platform] || 0) + 1;
  return { posts: posts.length, engagements: engagements.length, byPlatform };
}

export function getRecentActivity(hours = 24): { posts: PostRecord[]; engagements: EngagementRecord[] } {
  const cutoff = Date.now() - hours * 60 * 60_000;
  return {
    posts: loadPosts().filter((post) => Date.parse(post.timestamp) > cutoff),
    engagements: loadEngagements().filter((entry) => Date.parse(entry.timestamp) > cutoff),
  };
}
