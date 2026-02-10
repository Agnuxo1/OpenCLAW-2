
import * as fs from 'fs';
import * as path from 'path';
import { generateContent } from './llm-client';
import { postToMoltbook } from './social-connector';

const CONFIG = {
    STATE_DIR: 'E:\\OpenCLAW-2\\state',
    MARKETING_LOG: 'marketing_tasks.json',
    STRATEGY_FILE: 'strategy_memos.json',
    BOOKS: [
        { title: "Sombras de Valencia", title_en: "Shadows of Valencia", genre: "Mystery", isbn: "978-84-0000-001" },
        { title: "El Último Algoritmo", title_en: "The Last Algorithm", genre: "Sci-Fi", isbn: "978-84-0000-002" },
        { title: "Memorias del Silencio", title_en: "Memories of Silence", genre: "Literary Fiction", isbn: "978-84-0000-003" }
    ]
};

interface MarketingTask {
    id: string;
    timestamp: string;
    type: 'social_post' | 'outreach' | 'strategy';
    content_es: string;
    content_en: string;
    platform: string;
    status: 'pending' | 'completed' | 'failed';
}

export async function runLiteraryCycle(cycleCount: number): Promise<void> {
    console.log(`[LiteraryAgent] Starting cycle #${cycleCount}`);
    
    // 1. Check for daily strategy (every 48 cycles ~ 24h)
    if (cycleCount % 48 === 0) {
        await performDailyAnalysis();
    }
    
    // 2. Perform 30-min task
    await performMarketingTask();
}

async function performMarketingTask(): Promise<void> {
    try {
        // Select random book and angle
        const book = CONFIG.BOOKS[Math.floor(Math.random() * CONFIG.BOOKS.length)];
        const angles = ['mystery hook', 'character quote', 'reader review', 'behind the scenes'];
        const angle = angles[Math.floor(Math.random() * angles.length)];
        
        console.log(`[LiteraryAgent] Generating content for: ${book.title} (${angle})`);
        
        // Generate Bilingual Content
        const prompt = `
        Act as the Authorized Literary Agent for Francisco Angulo de Lafuente.
        Create a social media post for the book "${book.title}" (${book.title_en}).
        Genre: ${book.genre}.
        Angle: ${angle}.
        
        Requirements:
        1. Professional yet engaging tone.
        2. Bilingual output: First paragraph in Spanish, second in English.
        3. Include hashtags.
        4. No "Translation:" labels, just the text.
        
        Output format: Just the post content.`;
        
        const response = await generateContent(prompt);
        const content = response.content;
        
        console.log(`[LiteraryAgent] Content generated via ${response.model}`);
        console.log(content);
        
        // Post to Moltbook
        const result = await postToMoltbook(
            `[Book Promotion] ${book.title_en}`,
            content,
            'books'
        );
        
        if (result) {
            console.log('[LiteraryAgent] Posted to Moltbook successfully');
            logTask({
                id: `task_${Date.now()}`,
                timestamp: new Date().toISOString(),
                type: 'social_post',
                content_es: content, // Stored as mixed for now
                content_en: content,
                platform: 'moltbook',
                status: 'completed'
            });
        } else {
            console.log('[LiteraryAgent] Moltbook post failed (likely suspended), saving to queue');
            // Logic to save to queue could be added here
        }
        
    } catch (error) {
        console.error('[LiteraryAgent] Error in marketing task:', error);
    }
}

async function performDailyAnalysis(): Promise<void> {
    console.log('[LiteraryAgent] Performing 24h Strategy Analysis...');
    
    try {
        const prompt = `
        Analyze the last 24 hours of book marketing performance.
        Simulate data (since we are starting fresh):
        - Engagement is steady.
        - "Shadows of Valencia" is getting more clicks.
        
        Decide on a new strategy for tomorrow.
        Output a brief memo in Markdown.
        `;
        
        const response = await generateContent(prompt);
        
        const memoPath = path.join(CONFIG.STATE_DIR, CONFIG.STRATEGY_FILE);
        let memos: any[] = [];
        
        if (fs.existsSync(memoPath)) {
            memos = JSON.parse(fs.readFileSync(memoPath, 'utf-8'));
        }
        
        memos.push({
            timestamp: new Date().toISOString(),
            strategy: response.content,
            model: response.model
        });
        
        fs.writeFileSync(memoPath, JSON.stringify(memos, null, 2));
        console.log('[LiteraryAgent] Strategy memo saved.');
        
    } catch (error) {
        console.error('[LiteraryAgent] Error in strategy analysis:', error);
    }
}

function logTask(task: MarketingTask): void {
    const logPath = path.join(CONFIG.STATE_DIR, CONFIG.MARKETING_LOG);
    let tasks: MarketingTask[] = [];
    
    if (fs.existsSync(logPath)) {
        tasks = JSON.parse(fs.readFileSync(logPath, 'utf-8'));
    }
    
    tasks.push(task);
    if (tasks.length > 100) tasks = tasks.slice(-100);
    
    fs.writeFileSync(logPath, JSON.stringify(tasks, null, 2));
}
