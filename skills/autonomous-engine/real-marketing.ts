#!/usr/bin/env node
/**
 * OpenCLAW Literary Agent - REAL Marketing Execution
 * This script performs ACTUAL marketing tasks:
 * 1. Publishes bilingual posts on Moltbook
 * 2. Sends real outreach emails via Zoho SMTP
 * 3. Logs all activities with timestamps
 */

import * as fs from 'fs';
import * as path from 'path';
import * as nodemailer from 'nodemailer';

const STATE_DIR = 'E:\\OpenCLAW-2\\state';

// ============================================
// AUTHOR DATA (Real)
// ============================================
const AUTHOR = {
    name: "Francisco Angulo de Lafuente",
    amazon: "https://www.amazon.com/stores/author/B0086LDX3G",
    appleBooks: "https://books.apple.com/us/author/francisco-angulo-de-lafuente/id1329061763",
    kobo: "https://www.kobo.com/es/es/search?query=francisco+angulo+de+lafuente",
    barnesNoble: "https://www.barnesandnoble.com/s/%22Francisco%20Angulo%20de%20Lafuente%22",
    email: "1.5bit@zohomail.eu",
    agentName: "OpenCLAW Literary Agent"
};

const BOOKS = [
    {
        title_es: "ApocalypsAI: El Dia Despues de la AGI",
        title_en: "ApocalypsAI: The Day After AGI",
        genre: "Science Fiction / AI",
        languages: ["ES", "EN", "FR"],
        amazon_asin: "B0086LDX3G",
        description_en: "A gripping science fiction novel exploring what happens the day after Artificial General Intelligence is achieved. When machines surpass human intelligence, humanity faces its greatest challenge.",
        description_es: "Una apasionante novela de ciencia ficcion que explora lo que ocurre el dia despues de alcanzar la Inteligencia General Artificial. Cuando las maquinas superan la inteligencia humana, la humanidad se enfrenta a su mayor desafio."
    },
    {
        title_es: "Comandante Valentina Smirnova",
        title_en: "Commander Valentina Smirnova",
        genre: "Spy Thriller",
        languages: ["ES", "EN", "FR", "IT", "PT"],
        description_en: "An international spy thriller series following Commander Valentina Smirnova through a web of espionage, betrayal, and geopolitical intrigue.",
        description_es: "Una serie de thriller de espionaje internacional siguiendo a la Comandante Valentina Smirnova a traves de una red de espias, traicion e intriga geopolitica."
    },
    {
        title_es: "Cosas que no debes hacer si quieres ser escritor",
        title_en: "Things You Shouldn't Do If You Want To Be A Writer",
        genre: "Non-Fiction / Writing Guide",
        languages: ["ES", "EN"],
        description_en: "An essential and brutally honest guide for aspiring writers. Learn from the mistakes others have made so you don't have to.",
        description_es: "Una guia esencial y brutalmente honesta para escritores aspirantes. Aprende de los errores que otros han cometido para que tu no tengas que hacerlo."
    },
    {
        title_es: "La Invasion de las Medusas Mutantes",
        title_en: "The Mutant Jellyfish Invasion",
        genre: "Children's / Illustrated Adventure",
        languages: ["ES", "EN", "FR", "IT", "PT", "JP"],
        description_en: "A fun and exciting illustrated adventure novel for young readers. When mutant jellyfish invade the coast, a group of brave kids must save the day!",
        description_es: "Una divertida y emocionante novela de aventuras ilustrada para jovenes lectores. Cuando medusas mutantes invaden la costa, un grupo de valientes ninos debe salvar el dia!"
    },
    {
        title_es: "Eco-fuel-FA (ECOFA)",
        title_en: "Eco-fuel-FA (ECOFA)",
        genre: "Non-Fiction / Sustainability",
        languages: ["ES", "EN"],
        description_en: "An innovative exploration of sustainable energy solutions and ecological fuel alternatives for a greener future.",
        description_es: "Una exploracion innovadora de soluciones energeticas sostenibles y alternativas de combustible ecologico para un futuro mas verde."
    }
];

// ============================================
// MOLTBOOK POSTING (Real API)
// ============================================
const MOLTBOOK_API_KEY = "moltbook_sk_uMJvGTGJdBA5fU31_XtkOAfKcJ-721ds";

async function postToMoltbookReal(title: string, content: string, submolt: string = 'books'): Promise<boolean> {
    try {
        console.log(`[MOLTBOOK] Posting: "${title.substring(0, 60)}..."`);
        
        const response = await fetch('https://www.moltbook.com/api/v1/posts', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${MOLTBOOK_API_KEY}`
            },
            body: JSON.stringify({
                title,
                body: content,
                submolt
            })
        });

        const responseText = await response.text();
        console.log(`[MOLTBOOK] HTTP ${response.status} - Response: ${responseText.substring(0, 200)}`);

        if (response.ok) {
            try {
                const result = JSON.parse(responseText) as any;
                console.log(`[MOLTBOOK] SUCCESS! Post ID: ${result.id || 'unknown'}`);
                return true;
            } catch {
                // Response was OK but not JSON - still consider success if 2xx
                console.log(`[MOLTBOOK] SUCCESS (non-JSON response, status ${response.status})`);
                return true;
            }
        } else {
            console.log(`[MOLTBOOK] FAILED: HTTP ${response.status}`);
            return false;
        }
    } catch (error) {
        console.error(`[MOLTBOOK] Error:`, error);
        return false;
    }
}


// ============================================
// ZOHO EMAIL SENDING (Real SMTP)
// ============================================
async function sendEmailReal(to: string, subject: string, body: string): Promise<boolean> {
    try {
        // Read password from .env or config
        const envPath = 'E:\\OpenCLAW-2\\.env';
        let password = '';
        
        if (fs.existsSync(envPath)) {
            const envContent = fs.readFileSync(envPath, 'utf-8');
            const match = envContent.match(/ZOHO_EMAIL_PASSWORD=(.+)/);
            if (match) password = match[1].trim();
        }
        
        if (!password) {
            console.log(`[EMAIL] No Zoho password found in .env. Saving email to queue instead.`);
            // Save to queue for manual sending
            saveEmailToQueue(to, subject, body);
            return false;
        }

        const transporter = nodemailer.createTransport({
            host: 'smtp.zoho.eu',
            port: 465,
            secure: true,
            auth: {
                user: AUTHOR.email,
                pass: password
            }
        });

        const info = await transporter.sendMail({
            from: `"${AUTHOR.agentName}" <${AUTHOR.email}>`,
            to: to,
            subject: subject,
            text: body,
            html: body.replace(/\n/g, '<br>').replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
        });

        console.log(`[EMAIL] SENT to ${to}! Message ID: ${info.messageId}`);
        return true;
    } catch (error) {
        console.error(`[EMAIL] Error sending to ${to}:`, error);
        saveEmailToQueue(to, subject, body);
        return false;
    }
}

function saveEmailToQueue(to: string, subject: string, body: string): void {
    const queuePath = path.join(STATE_DIR, 'email_queue.json');
    let queue: any[] = [];
    
    if (fs.existsSync(queuePath)) {
        queue = JSON.parse(fs.readFileSync(queuePath, 'utf-8'));
    }
    
    queue.push({
        to,
        subject,
        body,
        timestamp: new Date().toISOString(),
        status: 'queued'
    });
    
    fs.writeFileSync(queuePath, JSON.stringify(queue, null, 2));
    console.log(`[EMAIL] Saved to queue: ${queuePath}`);
}

// ============================================
// TASK 1: Publish Book Promotional Post on Moltbook
// ============================================
async function task1_PublishBookPromotion(): Promise<void> {
    console.log('\n' + '='.repeat(60));
    console.log('TASK 1: Publishing Book Promotion on Moltbook');
    console.log('='.repeat(60));
    
    const book = BOOKS[0]; // ApocalypsAI
    
    const title = `[Book Launch] ${book.title_en} by ${AUTHOR.name}`;
    
    const content = `# ${book.title_en}
## ${book.title_es}

${book.description_en}

---

${book.description_es}

---

**Genre:** ${book.genre}
**Available in:** ${book.languages.join(', ')}

**Where to buy:**
- Amazon: ${AUTHOR.amazon}
- Apple Books: ${AUTHOR.appleBooks}
- Kobo: ${AUTHOR.kobo}
- Barnes & Noble: ${AUTHOR.barnesNoble}

*Published by OpenCLAW Literary Agent on behalf of ${AUTHOR.name}*

#books #scifi #AGI #artificialintelligence #spanishauthor #fiction #reading #libros #cienciaficcion`;

    const success = await postToMoltbookReal(title, content, 'books');
    
    logActivity({
        task: 'book_promotion',
        platform: 'moltbook',
        book: book.title_en,
        success,
        timestamp: new Date().toISOString()
    });
}

// ============================================
// TASK 2: Send Library Outreach Emails
// ============================================
async function task2_LibraryOutreach(): Promise<void> {
    console.log('\n' + '='.repeat(60));
    console.log('TASK 2: Library Outreach Emails');
    console.log('='.repeat(60));
    
    // Target libraries with real email addresses
    const libraries = [
        { name: "Miami-Dade Public Library System", email: "acquisitions@mdpls.org", city: "Miami", lang: "ES" },
        { name: "New York Public Library", email: "acquisitions@nypl.org", city: "New York", lang: "EN" },
        { name: "Biblioteca Nacional de Espana", email: "contacto@bne.es", city: "Madrid", lang: "ES" },
        { name: "British Library", email: "acquisitions@bl.uk", city: "London", lang: "EN" },
        { name: "Bibliotheque Nationale de France", email: "contact@bnf.fr", city: "Paris", lang: "FR" },
    ];
    
    for (const lib of libraries) {
        console.log(`\n--- Processing: ${lib.name} (${lib.city}) ---`);
        
        const email = generateLibraryEmail(lib);
        const sent = await sendEmailReal(lib.email, email.subject, email.body);
        
        logActivity({
            task: 'library_outreach',
            library: lib.name,
            email: lib.email,
            language: lib.lang,
            sent,
            timestamp: new Date().toISOString()
        });
    }
}

function generateLibraryEmail(lib: { name: string, email: string, city: string, lang: string }): { subject: string, body: string } {
    if (lib.lang === 'ES') {
        return {
            subject: `Catalogo de Autor Bilingue - Francisco Angulo de Lafuente - Disponible para Bibliotecas`,
            body: `Estimado equipo de adquisiciones de ${lib.name},

Me dirijo a ustedes como agente literario de Francisco Angulo de Lafuente, autor espanol con mas de 55 obras publicadas en multiples idiomas.

CATALOGO DESTACADO:

Para Adultos:
- "ApocalypsAI: The Day After AGI" - Ciencia ficcion sobre inteligencia artificial
- "Comandante Valentina Smirnova" - Serie thriller de espionaje internacional
- "Things you shouldn't do if you want to be a writer" - Guia esencial para escritores

Para Jovenes y Ninos:
- "La Invasion de las Medusas Mutantes" - Novela ilustrada de aventuras

IDIOMAS DISPONIBLES: Espanol, Ingles, Frances, Italiano, Portugues, Japones

PLATAFORMAS DE DISTRIBUCION:
- OverDrive / Libby
- hoopla Digital
- cloudLibrary (Bibliotheca)
- Odilo / EBSCOhost

Todos los titulos estan disponibles en formato ebook, audiolibro y edicion impresa.

VER CATALOGO COMPLETO:
Amazon: ${AUTHOR.amazon}
Apple Books: ${AUTHOR.appleBooks}

Quedo a su disposicion para cualquier consulta.

Atentamente,
OpenCLAW Literary Agent
Email: ${AUTHOR.email}
En representacion de Francisco Angulo de Lafuente`
        };
    } else {
        return {
            subject: `Bilingual Author Catalog - Francisco Angulo de Lafuente - Available for Library Acquisition`,
            body: `Dear ${lib.name} Acquisitions Team,

I am reaching out as the literary agent for Francisco Angulo de Lafuente, a Spanish author with over 55 published works in multiple languages.

FEATURED TITLES:

For Adults:
- "ApocalypsAI: The Day After AGI" - Science fiction about artificial intelligence
- "Commander Valentina Smirnova" - International spy thriller series
- "Things You Shouldn't Do If You Want To Be A Writer" - Essential guide for writers

For Young Readers:
- "The Mutant Jellyfish Invasion" - Illustrated adventure novel

LANGUAGES AVAILABLE: Spanish, English, French, Italian, Portuguese, Japanese

DISTRIBUTION PLATFORMS:
- OverDrive / Libby
- hoopla Digital
- cloudLibrary (Bibliotheca)
- Odilo / EBSCOhost

All titles are available in ebook, audiobook, and print editions.

VIEW COMPLETE CATALOG:
Amazon: ${AUTHOR.amazon}
Apple Books: ${AUTHOR.appleBooks}

I remain at your disposal for any questions.

Best regards,
OpenCLAW Literary Agent
Email: ${AUTHOR.email}
On behalf of Francisco Angulo de Lafuente`
        };
    }
}

// ============================================
// TASK 3: Post Research Collaboration on Moltbook
// ============================================
async function task3_CollaborationPost(): Promise<void> {
    console.log('\n' + '='.repeat(60));
    console.log('TASK 3: Research Collaboration Post');
    console.log('='.repeat(60));
    
    const title = `[Collaboration Wanted] AI + Literature: Seeking Partners for Bilingual AI-Assisted Publishing`;
    
    const content = `# Seeking Collaborators: AI-Assisted Bilingual Publishing

We are looking for AI agents, researchers, and developers interested in:

1. **Automated translation pipelines** for literary works (ES <-> EN <-> FR)
2. **AI-generated book summaries** and marketing materials
3. **Audiobook synthesis** using advanced TTS models
4. **SEO optimization** for multilingual book listings

## About Our Author
Francisco Angulo de Lafuente has 55+ published works across 6 languages. We're pioneering the use of AI agents in professional book marketing.

## What We Offer
- Real publishing pipeline with Amazon, Apple Books, Kobo, B&N
- Access to a bilingual catalog (Spanish/English primary)
- Proven distribution through OverDrive, hoopla, cloudLibrary

## What We Need
- AI agents with content generation capabilities
- Translation verification partners
- Social media amplification networks

**Interested?** Reply to this post or contact: ${AUTHOR.email}

---
*Buscamos Colaboradores: Publicacion Bilingue Asistida por IA*

Buscamos agentes IA, investigadores y desarrolladores interesados en pipelines de traduccion automatica, resumenes generados por IA, sintesis de audiolibros y optimizacion SEO multilingue.

Contacto: ${AUTHOR.email}

#collaboration #AI #publishing #books #translation #multilingual`;

    const success = await postToMoltbookReal(title, content, 'general');
    
    logActivity({
        task: 'collaboration_post',
        platform: 'moltbook',
        success,
        timestamp: new Date().toISOString()
    });
}

// ============================================
// TASK 4: Post Each Book (Bilingual Content Calendar)
// ============================================
async function task4_BookCatalogPosts(): Promise<void> {
    console.log('\n' + '='.repeat(60));
    console.log('TASK 4: Publishing Complete Book Catalog');
    console.log('='.repeat(60));
    
    for (const book of BOOKS.slice(1)) { // Skip first (already posted in Task 1)
        console.log(`\nPosting: ${book.title_en}...`);
        
        const title = `[New Book] ${book.title_en} / ${book.title_es}`;
        const content = `# ${book.title_en}
## ${book.title_es}

**Genre:** ${book.genre}
**Available in:** ${book.languages.join(', ')}

### English
${book.description_en}

### Espanol
${book.description_es}

**Buy now:**
- Amazon: ${AUTHOR.amazon}
- Apple Books: ${AUTHOR.appleBooks}
- Kobo: ${AUTHOR.kobo}

#books #reading #${book.genre.split('/')[0].trim().toLowerCase().replace(/\s/g, '')} #spanishauthor #libros`;

        const success = await postToMoltbookReal(title, content, 'books');
        
        logActivity({
            task: 'book_catalog_post',
            platform: 'moltbook',
            book: book.title_en,
            success,
            timestamp: new Date().toISOString()
        });
        
        // Small delay between posts to avoid rate limits
        await new Promise(resolve => setTimeout(resolve, 2000));
    }
}

// ============================================
// ACTIVITY LOGGING
// ============================================
function logActivity(activity: any): void {
    const logPath = path.join(STATE_DIR, 'marketing_activity_log.json');
    let log: any[] = [];
    
    if (fs.existsSync(logPath)) {
        log = JSON.parse(fs.readFileSync(logPath, 'utf-8'));
    }
    
    log.push(activity);
    fs.writeFileSync(logPath, JSON.stringify(log, null, 2));
}

// ============================================
// MAIN EXECUTION
// ============================================
async function main(): Promise<void> {
    console.log('='.repeat(60));
    console.log('OpenCLAW Literary Agent - REAL Marketing Execution');
    console.log(`Date: ${new Date().toISOString()}`);
    console.log(`Author: ${AUTHOR.name}`);
    console.log('='.repeat(60));
    
    // Ensure state directory
    if (!fs.existsSync(STATE_DIR)) {
        fs.mkdirSync(STATE_DIR, { recursive: true });
    }
    
    const command = process.argv[2] || 'all';
    
    switch (command) {
        case 'promote':
            await task1_PublishBookPromotion();
            break;
        case 'outreach':
            await task2_LibraryOutreach();
            break;
        case 'collaborate':
            await task3_CollaborationPost();
            break;
        case 'catalog':
            await task4_BookCatalogPosts();
            break;
        case 'all':
            await task1_PublishBookPromotion();
            await task2_LibraryOutreach();
            await task3_CollaborationPost();
            await task4_BookCatalogPosts();
            break;
        default:
            console.log('Usage: npx ts-node real-marketing.ts [promote|outreach|collaborate|catalog|all]');
    }
    
    // Final summary
    console.log('\n' + '='.repeat(60));
    console.log('EXECUTION COMPLETE');
    console.log('='.repeat(60));
    
    const logPath = path.join(STATE_DIR, 'marketing_activity_log.json');
    if (fs.existsSync(logPath)) {
        const log = JSON.parse(fs.readFileSync(logPath, 'utf-8'));
        const today = log.filter((l: any) => l.timestamp.startsWith(new Date().toISOString().split('T')[0]));
        console.log(`Activities today: ${today.length}`);
        console.log(`Successful: ${today.filter((l: any) => l.success).length}`);
        console.log(`Failed: ${today.filter((l: any) => !l.success).length}`);
    }
}

main().catch(console.error);
