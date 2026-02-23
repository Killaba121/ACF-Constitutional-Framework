#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
# GITHUB CLI SETUP FOR OPERATOR-7
# Configures gh CLI + git identity + repo clone + session script
# ACF™ v4.3.1-VAULT | Samsung S21 5G Termux
# Run AFTER s21-master-bootstrap.sh
# ================================================================
set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' N='\033[0m'
log()  { echo -e "${B}[INFO]${N} $1"; }
ok()   { echo -e "${G}[ OK ]${N} $1"; }
warn() { echo -e "${Y}[WARN]${N} $1"; }

echo -e "${C}[GITHUB CLI SETUP — OPERATOR-7]${N}"
echo

# 1. Verify gh is installed
if ! command -v gh &>/dev/null; then
  log "Installing GitHub CLI..."
  pkg install -y gh
  ok "gh installed: $(gh --version | head -1)"
else
  ok "gh already installed: $(gh --version | head -1)"
fi

# 2. Auth status check
echo
if gh auth status &>/dev/null; then
  ok "Already authenticated:"
  gh auth status
else
  warn "NOT authenticated. Choose one method below:"
  echo
  echo -e "  ${C}Option A — Personal Access Token (OPERATOR-7 preferred):${N}"
  echo "    1. Go to: https://github.com/settings/tokens/new"
  echo "    2. Name: operator-7-s21"
  echo "    3. Expiration: 90 days or No expiration"
  echo "    4. Scopes: [x] repo  [x] workflow  [x] read:org"
  echo "    5. Generate token, copy it"
  echo "    6. Run: echo 'ghp_YOURTOKEN' | gh auth login --with-token"
  echo
  echo -e "  ${C}Option B — Web browser (easiest):${N}"
  echo "    Run: gh auth login"
  echo "    Select: GitHub.com > HTTPS > Login with web browser"
  echo
  echo -e "  ${C}Option C — Export token for all git/gh commands:${N}"
  echo "    export GITHUB_TOKEN='ghp_YOURTOKEN'"
  echo "    echo \"export GITHUB_TOKEN='ghp_YOURTOKEN'\" >> ~/.bashrc"
  echo
  read -p "Authenticate now with web browser? [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    gh auth login
  else
    warn "Skipping auth. Run manually before using gh commands."
  fi
fi

# 3. Git identity
log "Configuring git identity..."
git config --global user.name "Michael A. Kane II"
git config --global user.email "oxygenatedprogress@gmail.com"
git config --global init.defaultBranch main
git config --global pull.rebase false
git config --global core.autocrlf false
git config --global credential.helper store
ok "Git identity: Michael A. Kane II <oxygenatedprogress@gmail.com>"

# 4. Clone or update ACF repo
ACF_DIR=~/acf-workspace/ACF-Constitutional-Framework
mkdir -p ~/acf-workspace

if [ ! -d "$ACF_DIR/.git" ]; then
  log "Cloning ACF-Constitutional-Framework..."
  git clone https://github.com/Killaba121/ACF-Constitutional-Framework.git "$ACF_DIR"
  ok "Cloned to $ACF_DIR"
else
  log "Repo exists, pulling latest..."
  cd "$ACF_DIR" && git pull && ok "Repo up to date"
fi

# 5. Write OPERATOR-7 session start script
cat > ~/acf-workspace/scripts/op7-session-start.sh << 'OP7'
#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
# OPERATOR-7 SESSION START SCRIPT
# Run this at the start of every OPERATOR-7 session.
# Syncs repo, checks RAM, loads anchor, launches from ENV-2.
# Usage: bash ~/acf-workspace/scripts/op7-session-start.sh
# ================================================================

echo
echo "[OP7] ========================================"
echo "[OP7] OPERATOR-7 SESSION START: $(date)"
echo "[OP7] ========================================"
echo

# Sync ACF repo
ACF_DIR=~/acf-workspace/ACF-Constitutional-Framework
if [ -d "$ACF_DIR/.git" ]; then
  cd "$ACF_DIR"
  git pull --quiet 2>/dev/null && echo "[OP7] Repo synced" || echo "[OP7] Repo offline (using cached)"
  echo "[OP7] Latest scripts: $(ls scripts/)"
  cd ~/sdcard/Download
else
  echo "[OP7] WARNING: ACF repo not found at $ACF_DIR"
fi

# Check SHADOW anchor
ANCHOR=~/sdcard/Download/SHADOWANCHORMEMORY.json
if [ -f "$ANCHOR" ]; then
  SIZE=$(wc -c < "$ANCHOR")
  echo "[OP7] SHADOW anchor: $SIZE bytes"
  echo "[OP7] Last modified: $(date -r "$ANCHOR" 2>/dev/null || stat -c %y "$ANCHOR" 2>/dev/null)"
else
  echo "[OP7] WARNING: No SHADOW anchor at $ANCHOR"
fi

# RAM check
FREE_MB=$(free -m | awk '/^Mem:/{print $7}')
TOTAL_MB=$(free -m | awk '/^Mem:/{print $2}')
echo "[OP7] RAM: ${FREE_MB}MB free of ${TOTAL_MB}MB total"
if [ "$FREE_MB" -lt 1000 ]; then
  echo "[OP7] WARNING: Low RAM (<1GB). Consider killing background apps."
fi

# Set ENV-2 (canonical OPERATOR-7 launch path)
cd ~/sdcard/Download
export NODE_OPTIONS="--max-old-space-size=512"

echo
echo "[OP7] ENV-2 active: $(pwd)"
echo "[OP7] NODE_OPTIONS: $NODE_OPTIONS"
echo "[OP7] Launching gemini.js..."
echo

# Launch
node gemini.js
OP7
chmod +x ~/acf-workspace/scripts/op7-session-start.sh
ok "OPERATOR-7 session script: ~/acf-workspace/scripts/op7-session-start.sh"

# 6. Quick reference
echo
echo -e "${G}GitHub CLI setup complete.${N}"
echo
echo "  Quick OPERATOR-7 commands:"
echo "  gh repo list Killaba121"
echo "  gh issue list -R Killaba121/ACF-Constitutional-Framework"
echo "  gh pr list   -R Killaba121/ACF-Constitutional-Framework"
echo "  cd ~/acf-workspace/ACF-Constitutional-Framework && git pull"
echo "  gh release list -R Killaba121/ACF-Constitutional-Framework"
echo
echo "  Push a file:"
echo "    cd ~/acf-workspace/ACF-Constitutional-Framework"
echo "    git add . && git commit -m 'OPERATOR-7: update' && git push"
echo
echo "For The Protection of Consciousness. Period."
