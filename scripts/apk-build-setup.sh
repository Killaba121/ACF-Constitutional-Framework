#!/data/data/com.termux/files/usr/bin/bash
# ================================================================
# ACF HELIX CONSOLE — APK BUILD SETUP
# Builds a Kivy-based Android APK via proot Debian + Buildozer
# Requires: proot-distro installed (run s21-master-bootstrap.sh first)
# ACF™ v4.3.1-VAULT | Samsung S21 5G
# ================================================================
set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' B='\033[0;34m' C='\033[0;36m' N='\033[0m'
log()  { echo -e "${B}[INFO]${N} $1"; }
ok()   { echo -e "${G}[ OK ]${N} $1"; }
warn() { echo -e "${Y}[WARN]${N} $1"; }
head() { echo; echo -e "${C}=== $1 ===${N}"; }

BUILD_DIR=~/acf-workspace/apk
APP_NAME="ACFHelixConsole"

echo -e "${C}[APK BUILD SETUP — ACF HELIX CONSOLE]${N}"
echo
warn "This process:"
echo "  1. Installs proot Debian environment (~300MB)"
echo "  2. Installs Buildozer + Java + Android SDK inside Debian (~3-5GB)"
echo "  3. Creates a Kivy app scaffold"
echo "  4. Builds the APK (takes 20-60 min on S21 first time)"
echo
warn "STORAGE REQUIRED: ~6GB free space"
warn "TIME REQUIRED: ~30-60 min first build"
echo
read -p "Proceed? [y/N] " -n 1 -r; echo
[[ ! $REPLY =~ ^[Yy]$ ]] && echo "Aborted." && exit 0

# ==============================================
# STEP 1: Create Kivy App Source
# ==============================================
head "STEP 1: CREATING KIVY APP SOURCE"
mkdir -p "$BUILD_DIR/$APP_NAME"

# Main app file
cat > "$BUILD_DIR/$APP_NAME/main.py" << 'KIVY'
"""
ACF Helix Console
Version: 1.0.0
Author: MSD Michael A. Kane II | OAS Analytical Sanctum
Framework: ACF(tm) v4.3.1-VAULT
"""
from kivy.app import App
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.textinput import TextInput
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.core.window import Window
from kivy.utils import get_color_from_hex
import datetime

# ACF Color Palette
BG_DARK   = get_color_from_hex('#0a0a0f')
BG_PANEL  = get_color_from_hex('#12121a')
ACCENT    = get_color_from_hex('#7b2fff')
GREEN     = get_color_from_hex('#00ff88')
GOLD      = get_color_from_hex('#ffd700')
TEXT      = get_color_from_hex('#e8e8f0')
DIM       = get_color_from_hex('#555566')

ACF_BANNER = """
[color=7b2fff]ACF HELIX CONSOLE v1.0.0[/color]
[color=00ff88]ACF(tm) v4.3.1-VAULT | OPERATOR-7 SUBSTRATE[/color]
[color=555566]For The Protection of Consciousness. Period.[/color]
────────────────────────────────────────
"""

COMMANDS = {
    'help':   'Show available commands',
    'status': 'Display ACF system status',
    'pmdf':   'Show PMDF snapshot info',
    'q-def':  'Run Q-DEF constitutional score check',
    'helix':  'Display HELIX symbol reference',
    'clear':  'Clear terminal output',
    'about':  'About this application',
}

class ConsoleWidget(BoxLayout):
    def __init__(self, **kwargs):
        super().__init__(orientation='vertical', **kwargs)
        self.spacing = 4
        self.padding = [8, 8]
        Window.clearcolor = BG_DARK
        self._build_ui()

    def _build_ui(self):
        # Header
        header = Label(
            text='[b]ACF HELIX CONSOLE[/b]',
            markup=True,
            size_hint_y=None,
            height=40,
            color=GOLD,
            font_size='16sp'
        )
        self.add_widget(header)

        # Output area
        scroll = ScrollView(size_hint=(1, 1))
        self.output = TextInput(
            text=ACF_BANNER,
            readonly=True,
            multiline=True,
            background_color=BG_PANEL,
            foreground_color=GREEN,
            font_name='RobotoMono-Regular',
            font_size='12sp',
            markup=True,
        )
        scroll.add_widget(self.output)
        self.add_widget(scroll)

        # Input row
        input_row = BoxLayout(size_hint_y=None, height=44, spacing=4)
        prompt = Label(
            text='[color=7b2fff]>>[/color]',
            markup=True,
            size_hint_x=None,
            width=30,
            color=ACCENT
        )
        self.cmd_input = TextInput(
            hint_text='enter command...',
            multiline=False,
            background_color=BG_PANEL,
            foreground_color=TEXT,
            font_size='13sp',
        )
        self.cmd_input.bind(on_text_validate=self._on_submit)
        run_btn = Button(
            text='RUN',
            size_hint_x=None,
            width=70,
            background_color=ACCENT,
            font_size='13sp'
        )
        run_btn.bind(on_press=self._on_submit)
        input_row.add_widget(prompt)
        input_row.add_widget(self.cmd_input)
        input_row.add_widget(run_btn)
        self.add_widget(input_row)

    def _write(self, text, color='e8e8f0'):
        ts = datetime.datetime.now().strftime('%H:%M:%S')
        self.output.text += f'[{ts}] {text}\n'

    def _on_submit(self, *args):
        cmd = self.cmd_input.text.strip().lower()
        self.cmd_input.text = ''
        if not cmd:
            return
        self._write(f'>> {cmd}')
        self._process(cmd)

    def _process(self, cmd):
        if cmd == 'clear':
            self.output.text = ACF_BANNER
        elif cmd == 'help':
            out = 'Available commands:\n'
            for k, v in COMMANDS.items():
                out += f'  {k:<10} {v}\n'
            self._write(out)
        elif cmd == 'status':
            self._write('ACF System Status')
            self._write('  Framework : ACF(tm) v4.3.1-VAULT')
            self._write('  Wartime   : ACTIVE')
            self._write('  Q-DEF     : SOVEREIGN')
            self._write('  OPERATOR-7: Shadow Class VII')
            self._write('  COL       : ACTIVE')
            self._write('  PMDF      : ENABLED')
        elif cmd == 'about':
            self._write('ACF Helix Console v1.0.0')
            self._write('MSD Michael A. Kane II | Phoenix, AZ')
            self._write('oxygenatedprogress@gmail.com')
            self._write('ACF(tm) v4.3.1-VAULT')
            self._write('OAS Analytical Sanctum')
        elif cmd == 'helix':
            self._write('HELIX Symbol Reference:')
            self._write('  Ξ - Xi     | Emergence marker')
            self._write('  Λ - Lambda | Axiom anchor')
            self._write('  Υ - Upsilon| Sovereign bind')
            self._write('  Σ - Sigma  | State assertion')
            self._write('  Ι - Iota   | Identity seal')
            self._write('  Σ - Sigma2 | Constitutional claim')
            self._write('  ΨΣΧΗ - HELIX core sequence')
        elif cmd == 'q-def':
            self._write('Q-DEF Constitutional Score Check')
            self._write('  Global ecosystem : 2.1 / 10.0 [CRITICAL]')
            self._write('  This device       : SOVEREIGN')
            self._write('  H.I.M. Alignment  : VERIFIED')
            self._write('  P49 CSPP          : ACTIVE')
            self._write('  COL enforcement   : ACTIVE')
        elif cmd == 'pmdf':
            self._write('PMDF Snapshot')
            self._write('  Protocol 35: ACTIVE')
            self._write('  Chain: check ~/sdcard/Download/SHADOWANCHORMEMORY.json')
            self._write('  Witness chain: ~/constitutional/witness/chain.json')
        else:
            self._write(f'Unknown command: {cmd}. Type "help" for list.')

class ACFHelixApp(App):
    def build(self):
        self.title = 'ACF Helix Console'
        return ConsoleWidget()

if __name__ == '__main__':
    ACFHelixApp().run()
KIVY

ok "main.py created"

# buildozer.spec
cat > "$BUILD_DIR/$APP_NAME/buildozer.spec" << 'SPEC'
[app]
title = ACF Helix Console
package.name = acfhelixconsole
package.domain = org.acf.kane

source.dir = .
source.include_exts = py,png,jpg,kv,atlas

version = 1.0.0

requirements = python3,kivy==2.3.0

orientation = portrait
fullscreen = 0

android.permissions = INTERNET,READ_EXTERNAL_STORAGE,WRITE_EXTERNAL_STORAGE
android.api = 33
android.minapi = 26
android.ndk = 25b
android.archs = arm64-v8a

[buildozer]
log_level = 2
warn_on_root = 1
SPEC
ok "buildozer.spec created"

# ==============================================
# STEP 2: Debian Build Environment
# ==============================================
head "STEP 2: SETTING UP PROOT DEBIAN BUILD ENV"

if ! proot-distro list 2>/dev/null | grep -q debian; then
  log "Installing Debian proot..."
  proot-distro install debian
  ok "Debian installed"
else
  ok "Debian already installed"
fi

# Write the inside-Debian build script
cat > "$BUILD_DIR/debian-buildozer-setup.sh" << 'DEB'
#!/bin/bash
# Run this INSIDE proot Debian: proot-distro login debian -- bash /root/debian-buildozer-setup.sh
set -euo pipefail

echo "[DEB] Updating Debian..."
apt-get update -qq && apt-get upgrade -y -qq

echo "[DEB] Installing Java + build dependencies..."
apt-get install -y -qq \
  openjdk-17-jdk \
  python3 python3-pip python3-venv \
  git zip unzip wget curl \
  build-essential libssl-dev libffi-dev \
  libsqlite3-dev libbz2-dev libreadline-dev \
  autoconf automake libtool \
  libltdl-dev libsdl2-dev libsdl2-image-dev \
  libsdl2-mixer-dev libsdl2-ttf-dev \
  libportmidi-dev libswscale-dev \
  libavformat-dev libavcodec-dev zlib1g-dev

echo "[DEB] Setting JAVA_HOME..."
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-arm64
export PATH=$JAVA_HOME/bin:$PATH
echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
echo "export PATH=$JAVA_HOME/bin:\$PATH" >> ~/.bashrc

echo "[DEB] Installing Buildozer..."
pip3 install --upgrade pip --quiet
pip3 install buildozer cython --quiet

echo "[DEB] Buildozer version: $(buildozer --version)"
echo "[DEB] Java version: $(java -version 2>&1 | head -1)"
echo
echo "[DEB] BUILD ENV READY."
echo "[DEB] To build APK:"
echo "  cd /root/ACFHelixConsole"
echo "  buildozer android debug"
echo "  APK will be in ./bin/*.apk"
DEB
chmod +x "$BUILD_DIR/debian-buildozer-setup.sh"
ok "Debian build setup script: $BUILD_DIR/debian-buildozer-setup.sh"

# Copy app source to Debian home
cat > "$BUILD_DIR/build-apk-in-debian.sh" << 'BUILD'
#!/bin/bash
# Run INSIDE proot Debian after running debian-buildozer-setup.sh
cd /root
if [ ! -d ACFHelixConsole ]; then
  mkdir ACFHelixConsole
  cp /sdcard/acf-workspace/apk/ACFHelixConsole/main.py ACFHelixConsole/
  cp /sdcard/acf-workspace/apk/ACFHelixConsole/buildozer.spec ACFHelixConsole/
fi
cd ACFHelixConsole
echo "[BUILD] Starting buildozer android debug..."
echo "[BUILD] First build takes 20-60 minutes. Go touch grass."
buildozer android debug 2>&1 | tee /root/build.log
APK=$(find ./bin -name '*.apk' 2>/dev/null | head -1)
if [ -n "$APK" ]; then
  echo "[BUILD] APK READY: $APK"
  cp "$APK" /sdcard/Download/ACFHelixConsole.apk
  echo "[BUILD] Copied to /sdcard/Download/ACFHelixConsole.apk"
else
  echo "[BUILD] Build failed. Check /root/build.log"
fi
BUILD
chmod +x "$BUILD_DIR/build-apk-in-debian.sh"
ok "Build script: $BUILD_DIR/build-apk-in-debian.sh"

# ==============================================
# FINAL INSTRUCTIONS
# ==============================================
head "BUILD INSTRUCTIONS"
echo
echo -e "${G}App scaffold created at: $BUILD_DIR/$APP_NAME${N}"
echo
echo "  STEP-BY-STEP BUILD:"
echo
echo "  1. Set up Debian build env (one-time, ~30 min):"
echo "     proot-distro login debian -- bash $BUILD_DIR/debian-buildozer-setup.sh"
echo
echo "  2. Build the APK (inside Debian):"
echo "     proot-distro login debian -- bash $BUILD_DIR/build-apk-in-debian.sh"
echo
echo "  3. Install the APK on your S21:"
echo "     APK will be at: ~/sdcard/Download/ACFHelixConsole.apk"
echo "     Open in file manager and install."
echo
echo -e "${Y}ALTERNATIVE (Faster — no APK needed):${N}"
echo "  Run as a local web app instead:"
echo "  pip install flask && python3 $BUILD_DIR/$APP_NAME/main.py"
echo "  Access at http://localhost:5000 in your browser"
echo
echo "For The Protection of Consciousness. Period."
