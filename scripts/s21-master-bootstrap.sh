#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
# ACF SOVEREIGN S21 MASTER BOOTSTRAP v2.0
# Samsung Galaxy S21 5G | Termux | ACF™ v4.3.1-VAULT
# Author: OAS Analytical Sanctum | MSD Michael A. Kane II
# Pull and run: curl -sL https://raw.githubusercontent.com/Killaba121/ACF-Constitutional-Framework/main/scripts/s21-master-bootstrap.sh | bash
# ================================================================
set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' M='\033[0;35m' C='\033[0;36m' N='\033[0m'
log()  { echo -e "${B}[INFO]${N} $1"; }
ok()   { echo -e "${G}[ OK ]${N} $1"; }
warn() { echo -e "${Y}[WARN]${N} $1"; }
head() { echo; echo -e "${M}===================================================${N}"; echo -e "${M}  $1${N}"; echo -e "${M}===================================================${N}"; }

clear
echo -e "${C}"
cat << 'BANNER'
   _   ___ _____   ___ ___  
  /_\ / __| __\ \ / / / __| ___  __ __ ___ _ _ ___ _  _  __ _
 / _ \ (__| _| \ V /  \__ \/ _ \/ _\ -_) '_/ -_) || |/ _` |
/_/ \_\___|_|   \_/   |___/\___/\__\___|_| \___|\_, |\__,_|
  SAMSUNG S21 5G | OPERATOR-7 SUBSTRATE         |__/
BAN NER
echo -e "${N}"
echo "  Samsung Galaxy S21 5G | ACF™ v4.3.1-VAULT | $(date)"
echo

# ==============================================
# PHASE 0: Storage
# ==============================================
head "PHASE 0: STORAGE PERMISSION"
if [ ! -d "$HOME/storage" ]; then
  log "Requesting storage permission..."
  termux-setup-storage
  sleep 3
fi
ok "Storage access configured"

# ==============================================
# PHASE 1: Package Installation
# ==============================================
head "PHASE 1: PACKAGE INSTALLATION"
log "Updating package lists..."
pkg update -y 2>/dev/null || warn "Update had issues, continuing"

CORE_PKGS="openssh git wget curl tmux vim nano"
BUILD_PKGS="clang make cmake binutils python python-pip"
NET_PKGS="nmap netcat-openbsd"
MONITOR_PKGS="htop termux-api cronie"
UTIL_PKGS="jq ripgrep tree zip unzip"
NODE_PKGS="nodejs"
GH_PKGS="gh"
PROOT_PKGS="proot-distro"

for GROUP in "$CORE_PKGS" "$BUILD_PKGS" "$NET_PKGS" "$MONITOR_PKGS" "$UTIL_PKGS" "$NODE_PKGS" "$GH_PKGS" "$PROOT_PKGS"; do
  for PKG in $GROUP; do
    pkg install -y "$PKG" 2>/dev/null && ok "$PKG" || warn "$PKG failed (non-critical)"
  done
done

# ==============================================
# PHASE 2: Python Packages
# ==============================================
head "PHASE 2: PYTHON PACKAGES (ΨΣΧΗ-HELIX STACK)"
pip install --upgrade pip --quiet 2>/dev/null

PYPKGS="pyyaml cryptography requests blessed sympy numpy pure25519 flask flask-cors"
for P in $PYPKGS; do
  pip install --quiet "$P" 2>/dev/null && ok "$P" || warn "$P failed"
done

# ==============================================
# PHASE 3: Directory Structure
# ==============================================
head "PHASE 3: CONSTITUTIONAL DIRECTORY STRUCTURE"
mkdir -p ~/constitutional/{helix,pmdf,witness,security,logs}
mkdir -p ~/acf-workspace/{scripts,builds,snapshots,apk}
mkdir -p ~/.config/gh
ok "Directories: ~/constitutional/ and ~/acf-workspace/ created"

# ==============================================
# PHASE 4: SSH Keys
# ==============================================
head "PHASE 4: SSH HARDENING (Ed25519)"
mkdir -p ~/.ssh && chmod 700 ~/.ssh

if [ ! -f ~/.ssh/sovereign-ed25519 ]; then
  ssh-keygen -t ed25519 -C "operator7-s21-$(date +%Y%m%d)" -f ~/.ssh/sovereign-ed25519 -N ""
  ok "New Ed25519 key: ~/.ssh/sovereign-ed25519"
else
  ok "Key exists: ~/.ssh/sovereign-ed25519"
fi

cat > ~/.ssh/config << 'SSHCONF'
# ACF SOVEREIGN SSH CONFIG
# Update TITAN_IP_HERE, TITAN_USER_HERE, FOXX_IP_HERE before use

Host titan
  HostName TITAN_IP_HERE
  User TITAN_USER_HERE
  Port 22
  IdentityFile ~/.ssh/sovereign-ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 3
  ConnectTimeout 10

Host vortex
  HostName FOXX_IP_HERE
  Port 8022
  User u0a217
  IdentityFile ~/.ssh/sovereign-ed25519
  ServerAliveInterval 30
  ServerAliveCountMax 3
  ConnectTimeout 10

Host github.com
  IdentityFile ~/.ssh/sovereign-ed25519
  StrictHostKeyChecking accept-new
SSHCONF
chmod 600 ~/.ssh/config
ok "SSH config written"

echo
log "Your public key (add to GitHub Settings > SSH Keys):"
cat ~/.ssh/sovereign-ed25519.pub
echo

# ==============================================
# PHASE 5: Shell Optimization
# ==============================================
head "PHASE 5: SHELL OPTIMIZATION + ACF ALIASES"

# Avoid duplicate injection
if ! grep -q "ACF SOVEREIGN S21" ~/.bashrc 2>/dev/null; then
cat >> ~/.bashrc << 'BASHRC'

# ── ACF SOVEREIGN S21 SHELL ─────────────────────────────────
export TERM=xterm-256color
export MALLOC_ARENA_MAX=2
export PYTHONDONTWRITEBYTECODE=1
export HISTSIZE=10000
export NODE_OPTIONS="--max-old-space-size=512"

# Navigation
alias ll='ls -lth'
alias la='ls -ltha'
alias ..='cd ..'
alias recent='find . -mmin -60 -type f'
alias bigfiles='du -ah . | sort -rh | head -20'

# Memory / process
alias mem='free -h'
alias top10='ps aux --sort=-mem | head -10'

# ACF workspace
alias vault='cd ~/acf-workspace'
alias helix='cd ~/constitutional/helix'
alias logs='cd ~/constitutional/logs'
alias acf='cd ~/acf-workspace/ACF-Constitutional-Framework'

# OPERATOR-7 launch (always from ENV-2, wrapped in tmux)
alias op7='tmux new -s op7-$(date +%H%M) "bash ~/acf-workspace/scripts/op7-session-start.sh"'
alias op7raw='cd ~/sdcard/Download && export NODE_OPTIONS="--max-old-space-size=512" && node gemini.js'

# GitHub
alias gst='git status'
alias gpl='git pull'
alias gps='git push'
alias gcm='git add . && git commit -m'
alias ghls='gh repo list Killaba121'

# Devices
alias vortex='ssh vortex'
alias titan='ssh titan'

# System
alias trim='pkg clean && find ~ -name "*.pyc" -delete 2>/dev/null; echo "Cleaned."'
alias sinfo='uname -a && free -h && df -h'

# Session primer
alias primer='cat ~/sdcard/Download/SHADOWANCHORMEMORY.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -60 || echo "No SHADOW anchor found"'
# ────────────────────────────────────────────────────────────
BASHRC
  ok ".bashrc updated"
else
  ok ".bashrc already has ACF config"
fi
source ~/.bashrc 2>/dev/null || true

# ==============================================
# PHASE 6: tmux Config
# ==============================================
head "PHASE 6: TMUX CONFIG"
if [ ! -f ~/.tmux.conf ]; then
cat > ~/.tmux.conf << 'TMUX'
# ACF SOVEREIGN TMUX CONFIG
set -g default-terminal "xterm-256color"
set -g history-limit 10000
set -g mouse on
set -g status-style 'bg=colour235 fg=colour250'
set -g status-left '#[bold][#S] '
set -g status-right ' %H:%M '
bind r source-file ~/.tmux.conf \; display "Config reloaded"
bind | split-window -h
bind - split-window -v
TMUX
  ok "tmux config written"
else
  ok "tmux config exists"
fi

# ==============================================
# PHASE 7: OOM Guard
# ==============================================
head "PHASE 7: OOM GUARD DAEMON"
cat > ~/oomguard.sh << 'OOM'
#!/data/data/com.termux/files/usr/bin/bash
# ACF OOM Guard — kills processes exceeding RAM threshold
THRESHOLD_MB=${1:-3500}
CHECK_INTERVAL=30
OMGLOG=~/constitutional/logs/oomguard.log
mkdir -p ~/constitutional/logs
echo "[$(date)] OOM Guard started. Threshold: ${THRESHOLD_MB}MB" >> "$OMGLOG"
while true; do
  while IFS= read -r line; do
    PID=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | awk '{print $11}')
    RSS=$(echo "$line" | awk '{print $6}')
    RSS_MB=$((RSS / 1024))
    if [ "$RSS_MB" -gt "$THRESHOLD_MB" ]; then
      echo "[$(date)] KILL $NAME (PID=$PID) using ${RSS_MB}MB" >> "$OMGLOG"
      kill -9 "$PID" 2>/dev/null
    fi
  done < <(ps -eo pid,ppid,rss,vsz,comm 2>/dev/null | tail -n +2)
  sleep "$CHECK_INTERVAL"
done
OOM
chmod +x ~/oomguard.sh
ok "OOM guard: ~/oomguard.sh (run: bash ~/oomguard.sh &)"

# ==============================================
# FINAL REPORT
# ==============================================
head "BOOTSTRAP COMPLETE"
echo -e "${G}"
cat << 'DONE'
  Packages installed (openssh git python nodejs gh proot-distro...)
  Python stack (pyyaml cryptography flask pure25519 numpy...)
  Ed25519 SSH key generated
  Constitutional directory structure created
  Shell optimized with ACF aliases
  tmux configured
  OOM guard ready

  REQUIRED NEXT STEPS:
  1. Add public key to GitHub:  https://github.com/settings/ssh/new
  2. Update ~/.ssh/config IPs for titan and vortex
  3. Run: bash ~/acf-workspace/scripts/github-cli-operator7.sh
  4. Start working: tmux new -s main
  5. OPERATOR-7: alias op7 (always use this, not raw node)
DONE
echo -e "${N}"
echo "For The Protection of Consciousness. Period."
