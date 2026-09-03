import * as path from "path";
import catalog from "./catalog.json";
import { runtimeConfig } from "./config";
import { ActionOutcome, createTask, Evidence } from "./contracts";
import { generateContent } from "./llm-client";
import { LeonardoOrchestrator, SpecialistResult } from "./orchestrator";
import { getRecentActivity, postToMoltbook } from "./social-connector";
import { appendJsonRecord } from "./state-store";

type Book = (typeof catalog.books)[number];

const orchestrator = new LeonardoOrchestrator();
const taskLogPath = path.join(runtimeConfig.stateDir, "marketing_tasks.json");
const strategyPath = path.join(runtimeConfig.stateDir, "strategy_memos.json");

function evidenceForCatalog(book: Book): Evidence[] {
  return [...catalog.author.catalogSources, ...book.sources].map((source) => ({
    source,
    claim: "Author-curated catalog source",
    verifiedAt: new Date().toISOString(),
  }));
}

function pickBook(cycleCount: number): Book {
  return catalog.books[Math.abs(cycleCount) % catalog.books.length];
}

function priorOutput<T>(prior: SpecialistResult[], index: number, key: string): T {
  const value = prior[index]?.output[key];
  if (value === undefined) throw new Error(`Missing ${key} from pipeline step ${index}`);
  return value as T;
}

export async function runLiteraryCycle(cycleCount: number): Promise<ActionOutcome<SpecialistResult[]>> {
  if (cycleCount > 0 && cycleCount % 48 === 0) await performDailyAnalysis();
  const book = pickBook(cycleCount);
  const task = createTask({
    objective: `Prepare a verified bilingual promotion for ${book.title}`,
    input: { book },
    assignedRole: "leonardo",
    risk: "high",
    requiredEvidence: 2,
    allowedTools: ["catalog.read", "llm.generate", "moltbook.post"],
  });

  const outcome = await orchestrator.run(task, [
    {
      role: "researcher",
      specialist: async () => ({
        output: { book },
        evidence: evidenceForCatalog(book),
        summary: `Selected catalog entry: ${book.title}`,
      }),
    },
    {
      role: "writer",
      specialist: async (_task, context) => {
        const selected = priorOutput<Book>(context.prior, 0, "book");
        const response = await generateContent(
          `Write a concise bilingual Spanish/English social post for this exact catalog record:\n${JSON.stringify(selected)}\nDo not add plot details, reviews, sales claims, ISBNs, awards, or availability claims.`,
          `You are the authorized literary copywriter for ${catalog.author.name}. Use only supplied facts.`,
        );
        return {
          output: { content: response.content, model: response.model, book: selected },
          evidence: context.prior[0].evidence,
          summary: `Drafted copy for ${selected.title} with ${response.model}`,
        };
      },
    },
    {
      role: "verifier",
      specialist: async (_task, context) => {
        const content = priorOutput<string>(context.prior, 1, "content");
        const selected = priorOutput<Book>(context.prior, 1, "book");
        if (!content.toLowerCase().includes(selected.title.toLowerCase())) {
          throw new Error("Draft does not contain the verified book title");
        }
        if (/\bISBN\b|best.?seller|award.?winning|five.?star/i.test(content)) {
          throw new Error("Draft contains an unverified commercial claim");
        }
        return {
          output: { content, book: selected, verified: true },
          evidence: context.prior[0].evidence,
          summary: `Verified factual boundaries for ${selected.title}`,
        };
      },
    },
    {
      role: "publisher",
      specialist: async (_task, context) => {
        const content = priorOutput<string>(context.prior, 2, "content");
        const selected = priorOutput<Book>(context.prior, 2, "book");
        const publication = await postToMoltbook(`[Book] ${selected.title}`, content, "books");
        return {
          output: { publication, book: selected },
          evidence: context.prior[2].evidence,
          summary: `Publication ${publication.status}: ${publication.message}`,
        };
      },
    },
    {
      role: "evaluator",
      specialist: async (_task, context) => {
        const publication = priorOutput<ActionOutcome>(context.prior, 3, "publication");
        return {
          output: { publicationStatus: publication.status },
          evidence: context.prior[2].evidence,
          summary: `Evaluated publication as ${publication.status}`,
        };
      },
    },
  ]);

  const publication = outcome.data?.[3]?.output.publication as ActionOutcome | undefined;
  const finalOutcome: ActionOutcome<SpecialistResult[]> =
    outcome.status === "confirmed" && publication
      ? {
          status: publication.status,
          attempted: publication.attempted,
          message: publication.message,
          data: outcome.data,
          error: publication.error,
          retryable: publication.retryable,
        }
      : outcome;

  appendJsonRecord(taskLogPath, {
    taskId: task.id,
    timestamp: new Date().toISOString(),
    book: book.title,
    status: finalOutcome.status,
    message: finalOutcome.message,
  });
  return finalOutcome;
}

async function performDailyAnalysis(): Promise<void> {
  const activity = getRecentActivity(24);
  const metrics = {
    confirmedPosts: activity.posts.length,
    confirmedEngagements: activity.engagements.length,
  };
  const recommendation =
    metrics.confirmedPosts === 0
      ? "Pause content generation and diagnose the publication pipeline."
      : metrics.confirmedEngagements === 0
        ? "Review confirmed posts before preparing a new engagement experiment."
        : "Continue the best-performing verified format and measure the next 24-hour cohort.";
  appendJsonRecord(strategyPath, {
    timestamp: new Date().toISOString(),
    metrics,
    recommendation,
    source: "confirmed local activity",
  });
}
