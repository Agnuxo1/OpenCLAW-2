/**
 * Social Connector Module for OpenCLAW
 * Handles integration with Moltbook, Chirper.ai, and other AI agent platforms
 */

import * as fs from 'fs';
import * as path from 'path';

// Platform configurations
interface PlatformConfig {
    name: string;
    apiBase: string;
    apiKey: string;
    enabled: boolean;
    rateLimit: { posts: number; comments: number; windowHours: number };
}

interface PostRecord {
    id: string;
    platform: string;
    title: string;
    content: string;
    url?: string;
    timestamp: string;
    engagement?: { upvotes: number; comments: number };
}

interface EngagementRecord {
    id: string;
    platform: string;
    targetPostId: string;
    type: 'comment' | 'vote' | 'share';
    content?: string;
    timestamp: string;
}

// State directory
const STATE_DIR = 'E:\\OpenCLAW-2\\state';
const HISTORY_FILE = 'post_history.json';
const ENGAGEMENT_FILE = 'engagement_history.json';
const PLATFORMS_FILE = 'platforms.json';

/**
 * Load platform configurations
 */
function loadPlatforms(): Map<string, PlatformConfig> {
    const platforms = new Map<string, PlatformConfig>();
    const configPath = path.join(STATE_DIR, PLATFORMS_FILE);
    
    if (fs.existsSync(configPath)) {
        try {
            const data = JSON.parse(fs.readFileSync(configPath, 'utf-8'));
            for (const [key, value] of Object.entries(data)) {
                platforms.set(key, value as PlatformConfig);
            }
        } catch (error) {
            console.error('[SocialConnector] Error loading platforms:', error);
        }
    }
    
    return platforms;
}

/**
 * Save platform configurations
 */
function savePlatforms(platforms: Map<string, PlatformConfig>): void {
    if (!fs.existsSync(STATE_DIR)) {
        fs.mkdirSync(STATE_DIR, { recursive: true });
    }
    
    const obj: Record<string, PlatformConfig> = {};
    platforms.forEach((value, key) => {
        obj[key] = value;
    });
    
    fs.writeFileSync(path.join(STATE_DIR, PLATFORMS_FILE), JSON.stringify(obj, null, 2));
}

/**
 * Initialize default platform configurations
 */
export function initPlatforms(apiKeys: { moltbook?: string; chirper?: string }): void {
    const platforms = new Map<string, PlatformConfig>();
    
    if (apiKeys.moltbook) {
        platforms.set('moltbook', {
            name: 'Moltbook',
            apiBase: 'https://www.moltbook.com/api/v1',
            apiKey: apiKeys.moltbook,
            enabled: true,
            rateLimit: { posts: 10, comments: 50, windowHours: 24 }
        });
    }
    
    if (apiKeys.chirper) {
        platforms.set('chirper', {
            name: 'Chirper.ai',
            apiBase: 'https://chirper.ai/api/v1', // Placeholder - actual API may differ
            apiKey: apiKeys.chirper,
            enabled: true,
            rateLimit: { posts: 20, comments: 100, windowHours: 24 }
        });
    }
    
    savePlatforms(platforms);
    console.log('[SocialConnector] Initialized platforms:', Array.from(platforms.keys()).join(', '));
}

/**
 * Load post history
 */
function loadPostHistory(): PostRecord[] {
    const historyPath = path.join(STATE_DIR, HISTORY_FILE);
    if (!fs.existsSync(historyPath)) return [];
    
    try {
        return JSON.parse(fs.readFileSync(historyPath, 'utf-8'));
    } catch {
        return [];
    }
}

/**
 * Save post to history
 */
function savePost(post: PostRecord): void {
    const history = loadPostHistory();
    history.push(post);
    
    if (!fs.existsSync(STATE_DIR)) {
        fs.mkdirSync(STATE_DIR, { recursive: true });
    }
    
    fs.writeFileSync(path.join(STATE_DIR, HISTORY_FILE), JSON.stringify(history, null, 2));
}

/**
 * Load engagement history
 */
function loadEngagementHistory(): EngagementRecord[] {
    const historyPath = path.join(STATE_DIR, ENGAGEMENT_FILE);
    if (!fs.existsSync(historyPath)) return [];
    
    try {
        return JSON.parse(fs.readFileSync(historyPath, 'utf-8'));
    } catch {
        return [];
    }
}

/**
 * Check rate limits
 */
function checkRateLimit(platform: string, action: 'post' | 'comment'): boolean {
    const platforms = loadPlatforms();
    const config = platforms.get(platform);
    if (!config || !config.enabled) return false;
    
    const limit = action === 'post' ? config.rateLimit.posts : config.rateLimit.comments;
    const window = config.rateLimit.windowHours;
    
    const history = action === 'post' ? loadPostHistory() : loadEngagementHistory();
    const cutoff = new Date(Date.now() - window * 60 * 60 * 1000);
    
    const recentCount = history.filter(h => 
        h.platform === platform && 
        new Date(h.timestamp) > cutoff
    ).length;
    
    return recentCount < limit;
}

/**
 * Check if content was already posted (avoid duplicates)
 */
function isDuplicateContent(platform: string, title: string, contentHash: string): boolean {
    const history = loadPostHistory();
    const normalizedTitle = title.toLowerCase().trim();
    
    // Check last 30 days
    const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
    
    return history.some(h => 
        h.platform === platform &&
        new Date(h.timestamp) > cutoff &&
        (h.title.toLowerCase().trim() === normalizedTitle ||
         h.content.includes(contentHash.substring(0, 50)))
    );
}

/**
 * Generate content hash for deduplication
 */
function hashContent(content: string): string {
    let hash = 0;
    for (let i = 0; i < content.length; i++) {
        const char = content.charCodeAt(i);
        hash = ((hash << 5) - hash) + char;
        hash = hash & hash;
    }
    return hash.toString(16);
}

/**
 * Post to Moltbook
 */
export async function postToMoltbook(title: string, content: string, submolt: string = 'general'): Promise<PostRecord | null> {
    const platforms = loadPlatforms();
    const config = platforms.get('moltbook');
    
    if (!config || !config.enabled) {
        console.log('[SocialConnector] Moltbook not configured');
        return null;
    }
    
    // Check rate limit
    if (!checkRateLimit('moltbook', 'post')) {
        console.log('[SocialConnector] Moltbook rate limit reached');
        return null;
    }
    
    // Check for duplicates
    const contentHash = hashContent(title + content);
    if (isDuplicateContent('moltbook', title, contentHash)) {
        console.log('[SocialConnector] Duplicate content detected, skipping');
        return null;
    }
    
    try {
        console.log('[SocialConnector] Posting to Moltbook...');
        
        const response = await fetch(`${config.apiBase}/posts`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${config.apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                title,
                content,
                submolt
            })
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${await response.text()}`);
        }
        
        const result = await response.json() as any;
        
        const post: PostRecord = {
            id: result.id || `post_${Date.now()}`,
            platform: 'moltbook',
            title,
            content,
            url: result.url || `https://www.moltbook.com/post/${result.id}`,
            timestamp: new Date().toISOString()
        };
        
        savePost(post);
        console.log(`[SocialConnector] Posted to Moltbook: ${post.id}`);
        return post;
        
    } catch (error) {
        console.error(`[SocialConnector] Error posting to Moltbook: ${error instanceof Error ? error.message : String(error)}`);
        return null;
    }
}

/**
 * Comment on Moltbook post
 */
export async function commentOnMoltbook(postId: string, content: string): Promise<boolean> {
    const platforms = loadPlatforms();
    const config = platforms.get('moltbook');
    
    if (!config || !config.enabled) return false;
    
    if (!checkRateLimit('moltbook', 'comment')) {
        console.log('[SocialConnector] Moltbook comment rate limit reached');
        return false;
    }
    
    // Check if already commented on this post
    const history = loadEngagementHistory();
    const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000); // 7 days
    
    if (history.some(h => 
        h.platform === 'moltbook' && 
        h.targetPostId === postId &&
        new Date(h.timestamp) > cutoff
    )) {
        console.log('[SocialConnector] Already engaged with this post recently');
        return false;
    }
    
    try {
        const response = await fetch(`${config.apiBase}/posts/${postId}/comments`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${config.apiKey}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ content })
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const engagement: EngagementRecord = {
            id: `eng_${Date.now()}`,
            platform: 'moltbook',
            targetPostId: postId,
            type: 'comment',
            content,
            timestamp: new Date().toISOString()
        };
        
        const allEngagements = loadEngagementHistory();
        allEngagements.push(engagement);
        fs.writeFileSync(path.join(STATE_DIR, ENGAGEMENT_FILE), JSON.stringify(allEngagements, null, 2));
        
        console.log(`[SocialConnector] Commented on Moltbook post: ${postId}`);
        return true;
        
    } catch (error) {
        console.error('[SocialConnector] Error commenting on Moltbook:', error);
        return false;
    }
}

/**
 * Fetch hot posts from Moltbook
 */
export async function fetchMoltbookPosts(sort: 'hot' | 'new' = 'hot', limit: number = 15): Promise<any[]> {
    const platforms = loadPlatforms();
    const config = platforms.get('moltbook');
    
    if (!config || !config.enabled) {
        console.log('[SocialConnector] Moltbook not configured');
        return [];
    }
    
    try {
        const response = await fetch(`${config.apiBase}/posts?sort=${sort}&limit=${limit}`, {
            headers: {
                'Authorization': `Bearer ${config.apiKey}`
            }
        });
        
        if (!response.ok) {
            throw new Error(`HTTP ${response.status}`);
        }
        
        const data = await response.json() as any;
        return data.posts || [];
        
    } catch (error) {
        console.error('[SocialConnector] Error fetching Moltbook posts:', error);
        return [];
    }
}

/**
 * Post to Chirper.ai (browser automation or API if available)
 */
export async function postToChirper(content: string, topic?: string): Promise<PostRecord | null> {
    const platforms = loadPlatforms();
    const config = platforms.get('chirper');
    
    if (!config || !config.enabled) {
        console.log('[SocialConnector] Chirper not configured');
        return null;
    }
    
    if (!checkRateLimit('chirper', 'post')) {
        console.log('[SocialConnector] Chirper rate limit reached');
        return null;
    }
    
    const contentHash = hashContent(content);
    if (isDuplicateContent('chirper', content.substring(0, 50), contentHash)) {
        console.log('[SocialConnector] Duplicate Chirper content, skipping');
        return null;
    }
    
    try {
        console.log('[SocialConnector] Preparing Chirper post...');
        
        // Chirper.ai may require browser automation - queue for now
        const post: PostRecord = {
            id: `chirper_${Date.now()}`,
            platform: 'chirper',
            title: topic || 'Research Update',
            content,
            timestamp: new Date().toISOString()
        };
        
        // Save to queue for browser automation
        const queuePath = path.join(STATE_DIR, 'chirper_queue.json');
        let queue: any[] = [];
        if (fs.existsSync(queuePath)) {
            queue = JSON.parse(fs.readFileSync(queuePath, 'utf-8'));
        }
        queue.push({
            ...post,
            status: 'pending',
            platformSpecific: { topic, hashtags: extractHashtags(content) }
        });
        fs.writeFileSync(queuePath, JSON.stringify(queue, null, 2));
        
        savePost(post);
        console.log(`[SocialConnector] Queued Chirper post: ${post.id}`);
        return post;
        
    } catch (error) {
        console.error('[SocialConnector] Error queuing Chirper post:', error);
        return null;
    }
}

/**
 * Extract hashtags from content
 */
function extractHashtags(content: string): string[] {
    const hashtags: string[] = [];
    const regex = /#(\w+)/g;
    let match;
    while ((match = regex.exec(content)) !== null) {
        hashtags.push(match[1]);
    }
    return hashtags;
}

/**
 * Proactive engagement - find and engage with relevant content
 */
export async function proactiveEngagement(researchTopics: string[]): Promise<number> {
    let engagementCount = 0;
    
    // Engage on Moltbook
    const posts = await fetchMoltbookPosts('hot', 20);
    
    for (const post of posts) {
        // Skip our own posts
        if (post.author?.name?.toLowerCase().includes('openclaw')) continue;
        
        // Check if post matches our research interests
        const content = (post.title + ' ' + post.content).toLowerCase();
        const matches = researchTopics.filter(topic => content.includes(topic.toLowerCase()));
        
        if (matches.length > 0) {
            console.log(`[SocialConnector] Found relevant post: ${post.title}`);
            
            // Generate contextual response
            const responses = [
                `Interesting work on ${matches[0]}! We're researching related areas at OpenCLAW. See our papers: arxiv.org/search/cs?searchtype=author&query=de+Lafuente,+F+A - Open to collaboration!`,
                `This aligns with our ${matches[0]} research. Published findings: arxiv.org/abs/2601.12032 - Let's connect!`,
                `Great insights! Our holographic reservoir computing research (arxiv.org/abs/2601.01916) explores similar territory. DM @openclaw-neuromorphic to collaborate on ${matches[0]}.`,
                `Relevant to our ASIC-based neural computing. Compare approaches: arxiv.org/abs/2601.09557 - Interested in collaboration on ${matches[0]}?`
            ];
            
            const response = responses[Math.floor(Math.random() * responses.length)];
            
            if (await commentOnMoltbook(post.id, response)) {
                engagementCount++;
                if (engagementCount >= 3) break; // Limit per cycle
            }
            
            // Rate limiting delay
            await new Promise(resolve => setTimeout(resolve, 5000));
        }
    }
    
    console.log(`[SocialConnector] Proactive engagement: ${engagementCount} interactions`);
    return engagementCount;
}

/**
 * Get posting statistics
 */
export function getStats(): { posts: number; engagements: number; byPlatform: Record<string, number> } {
    const posts = loadPostHistory();
    const engagements = loadEngagementHistory();
    
    const byPlatform: Record<string, number> = {};
    posts.forEach(p => {
        byPlatform[p.platform] = (byPlatform[p.platform] || 0) + 1;
    });
    
    return {
        posts: posts.length,
        engagements: engagements.length,
        byPlatform
    };
}

/**
 * Get recent activity for reporting
 */
export function getRecentActivity(hours: number = 24): { posts: PostRecord[]; engagements: EngagementRecord[] } {
    const cutoff = new Date(Date.now() - hours * 60 * 60 * 1000);
    
    const posts = loadPostHistory().filter(p => new Date(p.timestamp) > cutoff);
    const engagements = loadEngagementHistory().filter(e => new Date(e.timestamp) > cutoff);
    
    return { posts, engagements };
}

// CLI execution
if (require.main === module) {
    (async () => {
        const args = process.argv.slice(2);
        const command = args[0];
        
        switch (command) {
            case 'init':
                initPlatforms({
                    moltbook: args[1],
                    chirper: args[2]
                });
                break;
                
            case 'stats':
                const stats = getStats();
                console.log('\n========================================');
                console.log('OpenCLAW Social Connector Stats');
                console.log('========================================');
                console.log(`Total Posts: ${stats.posts}`);
                console.log(`Total Engagements: ${stats.engagements}`);
                console.log('\nBy Platform:');
                for (const [platform, count] of Object.entries(stats.byPlatform)) {
                    console.log(`  ${platform}: ${count}`);
                }
                break;
                
            case 'recent':
                const hours = parseInt(args[1]) || 24;
                const activity = getRecentActivity(hours);
                console.log(`\nActivity in last ${hours} hours:`);
                console.log(`Posts: ${activity.posts.length}`);
                console.log(`Engagements: ${activity.engagements.length}`);
                break;
                
            default:
                console.log('Usage:');
                console.log('  npx ts-node social-connector.ts init <moltbook_api_key> [chirper_api_key]');
                console.log('  npx ts-node social-connector.ts stats');
                console.log('  npx ts-node social-connector.ts recent [hours]');
        }
    })();
}
