
import fetch from 'node-fetch';

interface LLMResponse {
    content: string;
    model: string;
}

const PROVIDERS = {
    kimi: {
        url: "https://integrate.api.nvidia.com/v1/chat/completions",
        key: "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",
        model: "moonshotai/kimi-k2.5"
    },
    glm: {
        url: "https://integrate.api.nvidia.com/v1/chat/completions",
        key: "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",
        model: "z-ai/glm4.7"
    },
    minimax: {
        url: "https://integrate.api.nvidia.com/v1/chat/completions",
        key: "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",
        model: "minimaxai/minimax-m2.1"
    }
};

export async function generateContent(prompt: string, systemPrompt: string = "You are an expert literary agent."): Promise<LLMResponse> {
    // Try providers in order: Kimi -> GLM -> MiniMax
    const order = ['kimi', 'glm', 'minimax'] as const;
    
    for (const providerId of order) {
        try {
            const provider = PROVIDERS[providerId];
            console.log(`[LLM] Generating content with ${provider.model}...`);
            
            const response = await fetch(provider.url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${provider.key}`
                },
                body: JSON.stringify({
                    model: provider.model,
                    messages: [
                        { role: "system", content: systemPrompt },
                        { role: "user", content: prompt }
                    ],
                    temperature: 0.7,
                    max_tokens: 2048
                })
            });

            if (!response.ok) {
                throw new Error(`HTTP ${response.status}: ${await response.text()}`);
            }

            const data = await response.json() as any;
            return {
                content: data.choices[0].message.content,
                model: provider.model
            };
            
        } catch (error) {
            console.error(`[LLM] Error with ${providerId}:`, error);
            if (providerId === 'minimax') throw error; // All failed
        }
    }
    
    throw new Error("All LLM providers failed");
}
