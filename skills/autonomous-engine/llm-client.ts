import { runtimeConfig } from "./config";
import { fetchWithTimeout, withRetry } from "./reliability";

export interface LlmResponse {
  content: string;
  model: string;
}

interface Provider {
  id: string;
  url: string;
  key: string;
  model: string;
}

function providers(): Provider[] {
  const baseKey = process.env.NVIDIA_API_KEY?.trim() || "";
  return [
    {
      id: "kimi",
      url: "https://integrate.api.nvidia.com/v1/chat/completions",
      key: process.env.NVIDIA_API_KEY_KIMI?.trim() || baseKey,
      model: "moonshotai/kimi-k2.5",
    },
    {
      id: "glm",
      url: "https://integrate.api.nvidia.com/v1/chat/completions",
      key: process.env.NVIDIA_API_KEY_GLM?.trim() || baseKey,
      model: "z-ai/glm4.7",
    },
    {
      id: "minimax",
      url: "https://integrate.api.nvidia.com/v1/chat/completions",
      key: process.env.NVIDIA_API_KEY_MINIMAX?.trim() || baseKey,
      model: "minimaxai/minimax-m2.1",
    },
  ].filter((provider) => provider.key);
}

function parseContent(value: unknown): string {
  const data = value as { choices?: Array<{ message?: { content?: unknown } }> };
  const content = data.choices?.[0]?.message?.content;
  if (typeof content !== "string" || !content.trim()) {
    throw new Error("LLM response did not contain text content");
  }
  return content.trim();
}

export async function generateContent(
  prompt: string,
  systemPrompt = "You are an evidence-driven specialist. Never invent facts.",
): Promise<LlmResponse> {
  const available = providers();
  if (available.length === 0) {
    throw new Error("No NVIDIA_API_KEY provider is configured");
  }

  const failures: string[] = [];
  for (const provider of available) {
    try {
      return await withRetry(
        async () => {
          const response = await fetchWithTimeout(
            provider.url,
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                Authorization: `Bearer ${provider.key}`,
              },
              body: JSON.stringify({
                model: provider.model,
                messages: [
                  { role: "system", content: systemPrompt },
                  { role: "user", content: prompt },
                ],
                temperature: 0.4,
                max_tokens: 2_048,
              }),
            },
            runtimeConfig.httpTimeoutMs,
          );
          const body = await response.text();
          if (!response.ok) {
            const error = new Error(`${provider.id} HTTP ${response.status}: ${body.slice(0, 200)}`);
            (error as Error & { status?: number }).status = response.status;
            throw error;
          }
          return { content: parseContent(JSON.parse(body) as unknown), model: provider.model };
        },
        {
          attempts: 2,
          shouldRetry: (error) => {
            const status = (error as { status?: number }).status;
            return status === 408 || status === 429 || (status !== undefined && status >= 500);
          },
        },
      );
    } catch (error) {
      failures.push(error instanceof Error ? error.message : String(error));
    }
  }
  throw new Error(`All configured LLM providers failed: ${failures.join(" | ")}`);
}
