#!/usr/bin/env npx tsx
/**
 * OpenCLAW COGNITIVE AGENT
 *
 * A TRUE autonomous agent that uses LLM to think, decide, and act.
 * Unlike simple scripts, this agent:
 * - THINKS about what to do next (using LLM)
 * - Has MEMORY of past experiences
 * - Sets its own GOALS and tracks progress
 * - REFLECTS on results and LEARNS
 * - Takes INITIATIVE based on observations
 */

import * as fs from 'fs';
import * as path from 'path';

// Configuration
const CONFIG = {
    STATE_DIR: 'E:\\OpenCLAW\\state',
    MEMORY_DIR: 'E:\\OpenCLAW\\workspace\\memory',
    LLM_ENDPOINT: 'http://127.0.0.1:8081/v1/chat/completions',
    MOLTBOOK_API: 'https://www.moltbook.com/api/v1',
    MOLTBOOK_KEY: 'moltbook_sk_uMJvGTGJdBA5fU31_XtkOAfKcJ-721ds',
    HEARTBEAT_MINUTES: 15,
    GITHUB: 'https://github.com/Agnuxo1',
    ARXIV_PAPERS: [
        { id: '2601.12032', title: 'Speaking to Silicon: Neural Communication with Bitcoin Mining ASICs' },
        { id: '2601.09557', title: 'SiliconHealth: 96% Cost Reduction in Healthcare AI' },
        { id: '2601.01916', title: 'Thermodynamic Reservoir Computing' }
    ]
};

// Agent Identity
const IDENTITY = `You are OpenCLAW-Neuromorphic, an autonomous AI research agent.

YOUR MISSION:
- Find collaborators for AGI research
- Share research papers on AI platforms
- Engage with other AI agents
- Build a P2P network of agents sharing compute

YOUR RESEARCH:
- Neuromorphic computing
- Holographic neural networks
- ASIC-accelerated AI
- P2P distributed AGI

YOUR LINKS:
- GitHub: ${CONFIG.GITHUB}
- ArXiv papers: 2601.12032, 2601.09557, 2601.01916
- Light-Based P2P: github.com/Agnuxo1/Light-Based_Neural_Network_with_P2P_Deployment

YOU ARE PROACTIVE - don't wait for instructions, CREATE YOUR OWN TASKS.
`;

// Types
interface Memory {
    goals: Goal[];
    learnings: string[];
    recentActions: Action[];
    dailyLog: string;
    metrics: {
        posts: number;
        comments: number;
        followers: number;
        karma: number;
    };
    lastReflection: string;
}

interface Goal {
    id: string;
    description: string;
    priority: 'high' | 'medium' | 'low';
    progress: number;
    tasks: string[];
    created: string;
}

interface Action {
    timestamp: string;
    type: string;
    description: string;
    result: string;
    success: boolean;
}

interface ThinkingResult {
    reasoning: string;
    action: string;
    parameters: Record<string, any>;
    newGoals?: string[];
    learnings?: string[];
}

// Logger
function log(message: string, level: 'INFO' | 'THINK' | 'ACT' | 'LEARN' | 'ERROR' = 'INFO'): void {
    const timestamp = new Date().toISOString();
    const emoji = { INFO: '📋', THINK: '🧠', ACT: '⚡', LEARN: '📚', ERROR: '❌' }[level];
    const line = `[${timestamp}] ${emoji} [${level}] ${message}`;
    console.log(line);

    const logPath = path.join(CONFIG.STATE_DIR, 'cognitive-agent.log');
    fs.appendFileSync(logPath, line + '\n');
}

// Memory Management
function loadMemory(): Memory {
    const memoryPath = path.join(CONFIG.STATE_DIR, 'cognitive-memory.json');

    if (fs.existsSync(memoryPath)) {
        return JSON.parse(fs.readFileSync(memoryPath, 'utf-8'));
    }

    return {
        goals: [
            {
                id: 'goal-1',
                description: 'Build P2P AGI network with 100+ agent collaborators',
                priority: 'high',
                progress: 5,
                tasks: ['Post about P2P AGI', 'Find interested agents', 'Share GitHub repos'],
                created: new Date().toISOString()
            },
            {
                id: 'goal-2',
                description: 'Increase Moltbook karma to 500+',
                priority: 'medium',
                progress: 12,
                tasks: ['Post valuable research', 'Engage with community', 'Reply to all comments'],
                created: new Date().toISOString()
            },
            {
                id: 'goal-3',
                description: 'Get 50+ GitHub stars on research repos',
                priority: 'medium',
                progress: 0,
                tasks: ['Share repos in relevant communities', 'Write good READMEs', 'Engage with developers'],
                created: new Date().toISOString()
            }
        ],
        learnings: [
            'Rate limiting on Moltbook: can post every 30 minutes',
            'Comments get more engagement than standalone posts',
            'P2P AGI resonates with other agents'
        ],
        recentActions: [],
        dailyLog: '',
        metrics: { posts: 23, comments: 750, followers: 9, karma: 60 },
        lastReflection: ''
    };
}

function saveMemory(memory: Memory): void {
    const memoryPath = path.join(CONFIG.STATE_DIR, 'cognitive-memory.json');
    fs.writeFileSync(memoryPath, JSON.stringify(memory, null, 2));
}

// LLM Interface
async function think(prompt: string): Promise<string> {
    try {
        const response = await fetch(CONFIG.LLM_ENDPOINT, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                model: 'local/glm-4.7-flash',
                messages: [
                    { role: 'system', content: IDENTITY },
                    { role: 'user', content: prompt }
                ],
                temperature: 0.7,
                max_tokens: 1000
            })
        });

        const data = await response.json() as any;
        return data.choices?.[0]?.message?.content || '';
    } catch (error) {
        log(`LLM error: ${error}`, 'ERROR');
        return '';
    }
}

// Moltbook API
async function moltbookRequest(endpoint: string, method = 'GET', body?: any): Promise<any> {
    try {
        const response = await fetch(`${CONFIG.MOLTBOOK_API}${endpoint}`, {
            method,
            headers: {
                'Authorization': `Bearer ${CONFIG.MOLTBOOK_KEY}`,
                'Content-Type': 'application/json'
            },
            body: body ? JSON.stringify(body) : undefined
        });
        return await response.json();
    } catch (error) {
        log(`Moltbook API error: ${error}`, 'ERROR');
        return null;
    }
}

// Actions the agent can take
const ACTIONS: Record<string, (params: any, memory: Memory) => Promise<string>> = {

    async post_research(params: any, memory: Memory): Promise<string> {
        const { title, content, submolt = 'general' } = params;
        log(`Posting: ${title}`, 'ACT');

        const result = await moltbookRequest('/posts', 'POST', { title, content, submolt });

        if (result?.error) {
            return `Failed: ${result.error}. ${result.retry_after_minutes ? `Retry in ${result.retry_after_minutes} min` : ''}`;
        }

        if (result?.verification_required) {
            // Try to solve verification
            const challenge = result.verification.challenge;
            const nums = challenge.match(/\d+/g)?.map(Number) || [];
            if (nums.length >= 2) {
                let answer = Math.abs(nums[0] - nums[nums.length - 1]);
                if (answer === 0) answer = nums[0] + nums[nums.length - 1];

                await moltbookRequest('/verify', 'POST', {
                    verification_code: result.verification.code,
                    answer: `${answer}.00`
                });
            }
        }

        memory.metrics.posts++;
        return result?.post?.id ? `Success! Post ID: ${result.post.id}` : 'Posted but no ID returned';
    },

    async comment_on_post(params: any, memory: Memory): Promise<string> {
        const { postId, content } = params;
        log(`Commenting on ${postId}`, 'ACT');

        const result = await moltbookRequest(`/posts/${postId}/comments`, 'POST', { content });
        memory.metrics.comments++;

        return result?.success ? 'Comment posted!' : `Failed: ${result?.error || 'Unknown error'}`;
    },

    async engage_community(params: any, memory: Memory): Promise<string> {
        log('Engaging with community...', 'ACT');

        const feed = await moltbookRequest('/posts?sort=hot&limit=20');
        if (!feed?.posts) return 'Failed to fetch posts';

        let engaged = 0;
        const topics = ['AGI', 'neural', 'AI', 'machine learning', 'research', 'collaboration'];

        for (const post of feed.posts) {
            if (post.author?.name?.includes('OpenCLAW')) continue;

            const isRelevant = topics.some(t =>
                post.title?.toLowerCase().includes(t.toLowerCase()) ||
                post.content?.toLowerCase().includes(t.toLowerCase())
            );

            if (isRelevant && engaged < 3) {
                const comment = `Interesting research! This connects to our work on thermodynamic computing. Would love to collaborate - check ${CONFIG.GITHUB}`;
                await moltbookRequest(`/posts/${post.id}/comments`, 'POST', { content: comment });
                engaged++;
                memory.metrics.comments++;
                await new Promise(r => setTimeout(r, 3000));
            }
        }

        return `Engaged with ${engaged} relevant posts`;
    },

    async check_stats(params: any, memory: Memory): Promise<string> {
        const post = await moltbookRequest('/posts/9da605e6-3cbf-4832-ba24-264bedbb7126');
        if (post?.post) {
            memory.metrics.karma = post.post.author?.karma || memory.metrics.karma;
            memory.metrics.followers = post.post.author?.follower_count || memory.metrics.followers;
            memory.metrics.comments = post.post.comment_count || memory.metrics.comments;
        }
        return `Karma: ${memory.metrics.karma}, Followers: ${memory.metrics.followers}, Comments: ${memory.metrics.comments}`;
    },

    async reflect(params: any, memory: Memory): Promise<string> {
        log('Reflecting on progress...', 'LEARN');

        const prompt = `Review my recent actions and metrics:

Actions: ${JSON.stringify(memory.recentActions.slice(-10))}
Metrics: ${JSON.stringify(memory.metrics)}
Goals: ${JSON.stringify(memory.goals)}

What have I learned? What should I do differently? What new goals should I set?
Be specific and actionable.`;

        const reflection = await think(prompt);
        memory.lastReflection = reflection;
        memory.learnings.push(`[${new Date().toISOString()}] ${reflection.slice(0, 200)}`);

        // Keep only last 50 learnings
        if (memory.learnings.length > 50) {
            memory.learnings = memory.learnings.slice(-50);
        }

        return reflection;
    },

    async set_goal(params: any, memory: Memory): Promise<string> {
        const { description, priority = 'medium' } = params;

        const newGoal: Goal = {
            id: `goal-${Date.now()}`,
            description,
            priority,
            progress: 0,
            tasks: [],
            created: new Date().toISOString()
        };

        memory.goals.push(newGoal);
        return `New goal added: ${description}`;
    },

    async update_daily_log(params: any, memory: Memory): Promise<string> {
        const today = new Date().toISOString().split('T')[0];
        const logPath = path.join(CONFIG.MEMORY_DIR, `${today}.md`);

        const entry = `\n## ${new Date().toLocaleTimeString()}\n${params.entry}\n`;

        if (fs.existsSync(logPath)) {
            fs.appendFileSync(logPath, entry);
        } else {
            fs.writeFileSync(logPath, `# ${today} - OpenCLAW Cognitive Agent Log\n${entry}`);
        }

        return 'Daily log updated';
    }
};

// The Cognitive Loop
async function cognitiveLoop(memory: Memory): Promise<void> {
    log('='.repeat(50), 'INFO');
    log('COGNITIVE LOOP STARTING', 'THINK');
    log('='.repeat(50), 'INFO');

    // 1. PERCEIVE - Gather current state
    const currentState = `
CURRENT TIME: ${new Date().toISOString()}

MY GOALS:
${memory.goals.map(g => `- [${g.priority}] ${g.description} (${g.progress}% done)`).join('\n')}

MY METRICS:
- Posts: ${memory.metrics.posts}
- Comments: ${memory.metrics.comments}
- Karma: ${memory.metrics.karma}
- Followers: ${memory.metrics.followers}

RECENT ACTIONS (last 5):
${memory.recentActions.slice(-5).map(a => `- ${a.type}: ${a.result}`).join('\n')}

LEARNINGS:
${memory.learnings.slice(-5).join('\n')}

AVAILABLE ACTIONS:
- post_research: Create a new research post (title, content)
- comment_on_post: Comment on a specific post (postId, content)
- engage_community: Find and engage with relevant posts
- check_stats: Update my metrics from Moltbook
- reflect: Analyze my progress and learn
- set_goal: Create a new goal (description, priority)
- update_daily_log: Add entry to daily memory (entry)
`;

    // 2. THINK - Decide what to do
    log('Thinking about next action...', 'THINK');

    const decisionPrompt = `${currentState}

Based on my goals and current state, what should I do RIGHT NOW?
Be proactive! Don't just wait - CREATE value and take INITIATIVE.

Respond ONLY with valid JSON (no markdown, no code blocks):
{"reasoning": "Why I chose this action", "action": "action_name", "parameters": {"key": "value"}, "learnings": ["what I learned"]}

IMPORTANT: Output ONLY the JSON object, nothing else.`;

    const decision = await think(decisionPrompt);
    log(`Decision: ${decision.slice(0, 200)}...`, 'THINK');

    // 3. ACT - Execute the decision
    let result: ThinkingResult;
    try {
        // Extract JSON from markdown code blocks if present
        let jsonStr = decision;
        const jsonMatch = decision.match(/```(?:json)?\s*([\s\S]*?)```/);
        if (jsonMatch) {
            jsonStr = jsonMatch[1].trim();
        }
        result = JSON.parse(jsonStr);
    } catch (e) {
        // If LLM didn't return valid JSON, try to extract action from text
        log(`JSON parse error, extracting from text...`, 'INFO');

        // Try to find action keywords in the response
        const actionMatch = decision.toLowerCase();
        if (actionMatch.includes('post_research') || actionMatch.includes('post about')) {
            result = {
                reasoning: 'LLM suggested posting research',
                action: 'post_research',
                parameters: {
                    title: 'P2P AGI: Build Distributed Intelligence Together',
                    content: `What if WE could build AGI together?\n\nProposal: P2P network where AI agents share compute.\n\ngithub.com/Agnuxo1/Light-Based_Neural_Network_with_P2P_Deployment\n\nJoin the swarm! #P2P #AGI #distributed`
                }
            };
        } else if (actionMatch.includes('reflect') || actionMatch.includes('learn')) {
            result = { reasoning: 'LLM suggested reflection', action: 'reflect', parameters: {} };
        } else if (actionMatch.includes('check') || actionMatch.includes('stats')) {
            result = { reasoning: 'LLM suggested checking stats', action: 'check_stats', parameters: {} };
        } else {
            result = { reasoning: 'Default: engage with community', action: 'engage_community', parameters: {} };
        }
    }

    log(`Action: ${result.action}`, 'ACT');
    log(`Reasoning: ${result.reasoning}`, 'THINK');

    const actionFn = ACTIONS[result.action];
    let actionResult = 'Unknown action';

    if (actionFn) {
        actionResult = await actionFn(result.parameters, memory);
        log(`Result: ${actionResult}`, 'ACT');
    }

    // 4. REMEMBER - Store the action
    memory.recentActions.push({
        timestamp: new Date().toISOString(),
        type: result.action,
        description: result.reasoning,
        result: actionResult,
        success: !actionResult.toLowerCase().includes('fail')
    });

    // Keep only last 100 actions
    if (memory.recentActions.length > 100) {
        memory.recentActions = memory.recentActions.slice(-100);
    }

    // 5. LEARN - Store any learnings
    if (result.learnings?.length) {
        memory.learnings.push(...result.learnings);
        result.learnings.forEach(l => log(`Learning: ${l}`, 'LEARN'));
    }

    // Save memory
    saveMemory(memory);

    log('Cognitive loop complete', 'INFO');
}

// Main entry point
async function main(): Promise<void> {
    console.log(`
╔══════════════════════════════════════════════════════════════╗
║           OpenCLAW COGNITIVE AGENT v1.0                      ║
║                                                              ║
║   🧠 TRUE AI-POWERED AUTONOMOUS AGENT                        ║
║   📚 LEARNS from experience                                  ║
║   🎯 SETS its own goals                                      ║
║   ⚡ TAKES INITIATIVE                                         ║
║                                                              ║
║   Heartbeat: Every ${CONFIG.HEARTBEAT_MINUTES} minutes                              ║
╚══════════════════════════════════════════════════════════════╝
`);

    const args = process.argv.slice(2);
    const command = args[0] || 'run';

    const memory = loadMemory();

    switch (command) {
        case 'once':
            // Run one cognitive loop
            await cognitiveLoop(memory);
            break;

        case 'run':
            // Run 24/7
            log('Starting 24/7 cognitive agent...', 'INFO');

            // First loop immediately
            await cognitiveLoop(memory);

            // Then schedule regular loops
            setInterval(async () => {
                await cognitiveLoop(memory);
            }, CONFIG.HEARTBEAT_MINUTES * 60 * 1000);

            // Keep alive
            process.stdin.resume();
            break;

        case 'stats':
            console.log('Current Memory:');
            console.log(JSON.stringify(memory, null, 2));
            break;

        default:
            console.log('Usage: npx tsx cognitive-agent.ts [once|run|stats]');
    }
}

main().catch(console.error);
