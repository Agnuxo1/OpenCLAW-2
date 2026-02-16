#!/bin/bash
# =============================================================================
# OpenCLAW — Unified Secrets Deployment
# =============================================================================
# Copies the complete 29-key LLM pool from Literary v1 to ALL agents.
# Uses GitHub CLI (gh) for secure secret management.
#
# PREREQUISITE: gh auth login
# USAGE: ./unify_secrets.sh
# =============================================================================

GITHUB_USER="Agnuxo1"

# Target repos (all 5 active agents)
TARGET_REPOS=(
    "OpenCLAW-Autonomous-Multi-Agent-Scientific-Research-Platform"
    "OpenCLAW-2-Autonomous-Multi-Agent-Scientific-Research-Platform"
    "OpenCLAW-2-Autonomous-Multi-Agent-literary"
    "OpenCLAW-2-Autonomous-Multi-Agent-literary2"
    "OpenCLAW-update-Literary-Agent-24-7-auto"
)

# Source repo (Literary v1 — most complete)
SOURCE_REPO="OpenCLAW-2-Autonomous-Multi-Agent-literary"

echo "╔══════════════════════════════════════════╗"
echo "║  OpenCLAW Secret Unification Tool        ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "This script will copy secrets from Literary v1 to all agents."
echo "Source: ${GITHUB_USER}/${SOURCE_REPO}"
echo ""

# Check gh is installed and authenticated
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) not found. Install: https://cli.github.com/"
    exit 1
fi

if ! gh auth status &> /dev/null; then
    echo "❌ Not logged in. Run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI authenticated"
echo ""

# =============================================================================
# STEP 1: Define all secrets to propagate
# =============================================================================
# FORMAT: SECRET_NAME=VALUE
# You need to fill in your actual key values below.
# The script will set them in ALL target repos.

cat << 'EOF'
⚠️  INSTRUCTIONS:
Edit this script and fill in your actual API keys in the section below.
Each key will be set as a GitHub Secret in ALL 5 active repos.

Alternatively, export them as environment variables before running:
  export GROQ_KEY_1="gsk_xxxx"
  export GROQ_KEY_2="gsk_xxxx"
  ... etc
  ./unify_secrets.sh
EOF

echo ""
echo "Starting secret deployment..."
echo ""

# =============================================================================
# LLM KEYS — Set these from env vars or edit directly
# =============================================================================

# Helper function to set a secret across all repos
set_secret_all() {
    local name="$1"
    local value="$2"
    
    if [ -z "$value" ]; then
        echo "  ⏭️  $name: skipped (empty)"
        return
    fi
    
    for repo in "${TARGET_REPOS[@]}"; do
        echo -n "  Setting $name in $repo... "
        echo "$value" | gh secret set "$name" -R "${GITHUB_USER}/${repo}" --body - 2>/dev/null \
            && echo "✅" \
            || echo "❌"
    done
}

# === GROQ (5 keys, CSV) ===
echo "🔑 Groq API Keys..."
GROQ_CSV="${GROQ_KEY_1:-},${GROQ_KEY_2:-},${GROQ_KEY_3:-},${GROQ_KEY_4:-},${GROQ_KEY_5:-}"
GROQ_CSV=$(echo "$GROQ_CSV" | sed 's/^,*//;s/,*$//;s/,,*/,/g')
[ -n "$GROQ_CSV" ] && set_secret_all "GROQ_API_KEYS" "$GROQ_CSV"

# Also set numbered for agents that need that format
for i in 1 2 3 4 5; do
    varname="GROQ_KEY_${i}"
    [ -n "${!varname}" ] && set_secret_all "GROQ_API_KEY_${i}" "${!varname}"
done

# === NVIDIA (3 keys, CSV) ===
echo "🔑 NVIDIA API Keys..."
NVIDIA_CSV="${NVIDIA_KEY_1:-},${NVIDIA_KEY_2:-},${NVIDIA_KEY_3:-}"
NVIDIA_CSV=$(echo "$NVIDIA_CSV" | sed 's/^,*//;s/,*$//;s/,,*/,/g')
[ -n "$NVIDIA_CSV" ] && set_secret_all "NVIDIA_API_KEYS" "$NVIDIA_CSV"

for i in 1 2 3; do
    varname="NVIDIA_KEY_${i}"
    [ -n "${!varname}" ] && set_secret_all "NVIDIA_API_KEY_${i}" "${!varname}"
done

# === OPENROUTER (6 keys, CSV) ===
echo "🔑 OpenRouter API Keys..."
OR_CSV="${OPENROUTER_KEY_1:-},${OPENROUTER_KEY_2:-},${OPENROUTER_KEY_3:-},${OPENROUTER_KEY_4:-},${OPENROUTER_KEY_5:-},${OPENROUTER_KEY_6:-}"
OR_CSV=$(echo "$OR_CSV" | sed 's/^,*//;s/,*$//;s/,,*/,/g')
[ -n "$OR_CSV" ] && set_secret_all "OPENROUTER_API_KEYS" "$OR_CSV"

# === MISTRAL (2 keys, CSV) ===
echo "🔑 Mistral API Keys..."
MISTRAL_CSV="${MISTRAL_KEY_1:-},${MISTRAL_KEY_2:-}"
MISTRAL_CSV=$(echo "$MISTRAL_CSV" | sed 's/^,*//;s/,*$//;s/,,*/,/g')
[ -n "$MISTRAL_CSV" ] && set_secret_all "MISTRAL_API_KEYS" "$MISTRAL_CSV"

# === DEEPSEEK (6 keys, CSV) ===
echo "🔑 DeepSeek API Keys..."
DS_CSV="${DEEPSEEK_KEY_1:-},${DEEPSEEK_KEY_2:-},${DEEPSEEK_KEY_3:-},${DEEPSEEK_KEY_4:-},${DEEPSEEK_KEY_5:-},${DEEPSEEK_KEY_6:-}"
DS_CSV=$(echo "$DS_CSV" | sed 's/^,*//;s/,*$//;s/,,*/,/g')
[ -n "$DS_CSV" ] && set_secret_all "DEEPSEEK_API_KEYS" "$DS_CSV"

# === ZHIPUAI / GLM (6 keys, CSV) ===
echo "🔑 ZhipuAI/GLM API Keys..."
GLM_CSV="${ZHIPUAI_KEY_1:-},${ZHIPUAI_KEY_2:-},${ZHIPUAI_KEY_3:-},${ZHIPUAI_KEY_4:-},${ZHIPUAI_KEY_5:-},${ZHIPUAI_KEY_6:-}"
GLM_CSV=$(echo "$GLM_CSV" | sed 's/^,*//;s/,*$//;s/,,*/,/g')
[ -n "$GLM_CSV" ] && set_secret_all "ZHIPUAI_API_KEYS" "$GLM_CSV"

# === PLATFORM KEYS (single values) ===
echo "🔑 Platform Keys..."
[ -n "$BRAVE_API_KEY" ] && set_secret_all "BRAVE_API_KEY" "$BRAVE_API_KEY"
[ -n "$HF_TOKEN" ] && set_secret_all "HF_TOKEN" "$HF_TOKEN"
[ -n "$MOLTBOOK_API_KEY" ] && set_secret_all "MOLTBOOK_API_KEY" "$MOLTBOOK_API_KEY"
[ -n "$ZOHO_EMAIL" ] && set_secret_all "ZOHO_EMAIL" "$ZOHO_EMAIL"
[ -n "$ZOHO_PASSWORD" ] && set_secret_all "ZOHO_PASSWORD" "$ZOHO_PASSWORD"

# === GH_PAT (GitHub Personal Access Token) ===
echo "🔑 GitHub Token..."
[ -n "$GH_PAT" ] && set_secret_all "GH_PAT" "$GH_PAT"

# === HIVEMIND ===
echo "🔑 HiveMind Gist ID..."
[ -n "$HIVEMIND_GIST_ID" ] && set_secret_all "HIVEMIND_GIST_ID" "$HIVEMIND_GIST_ID"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║  Secret unification complete!            ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next: Trigger a manual run of each agent to verify:"
echo "  gh workflow run <workflow-name> -R ${GITHUB_USER}/<repo>"
