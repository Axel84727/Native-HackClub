#!/usr/bin/env bash
# =============================================================================
# setup.sh — Install everything you need to simulate FPGA designs
# =============================================================================
# Installs:
#   - Icarus Verilog (iverilog): the simulator
#   - GTKWave: the waveform viewer
#
# Supports: macOS (Homebrew), Ubuntu/Debian (apt), Windows (winget)
#           Fedora/RHEL (dnf) and Arch (pacman) as bonus.
#
# After running this, try:
#   ./tools/sim.sh workshops/01-blink-led/solution
#
# If something goes wrong, open an issue — don't suffer in silence.
# =============================================================================

set -euo pipefail
# set -e: exit immediately on error (no silent failures)
# set -u: error on undefined variables (no mysterious empty-string bugs)
# set -o pipefail: a pipe fails if any command in it fails
# Together, these make bash scripts that actually tell you when something is wrong.

# ── Colors (makes output readable) ───────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC}  $1"; }
log_ok()      { echo -e "${GREEN}[OK]${NC}    $1"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Check if a command exists ─────────────────────────────────────────────────
command_exists() {
    command -v "$1" &> /dev/null
}

# ── Detect OS ─────────────────────────────────────────────────────────────────
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"   # Ubuntu, Debian, Raspberry Pi OS, etc.
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# ── Install on macOS ──────────────────────────────────────────────────────────
install_macos() {
    log_info "Detected macOS. Using Homebrew."

    if ! command_exists brew; then
        log_warn "Homebrew not found. Installing it now..."
        log_warn "(This will take a few minutes. Go get a coffee.)"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    log_info "Installing icarus-verilog..."
    brew install icarus-verilog

    log_info "Installing gtkwave..."
    # GTKWave on macOS comes as a cask (graphical app)
    brew install --cask gtkwave || {
        log_warn "Cask install failed. Trying formula instead..."
        brew install gtkwave
    }
}

# ── Install on Debian/Ubuntu ──────────────────────────────────────────────────
install_debian() {
    log_info "Detected Debian/Ubuntu. Using apt."

    log_info "Updating package lists..."
    sudo apt-get update -qq

    log_info "Installing iverilog and gtkwave..."
    sudo apt-get install -y iverilog gtkwave
}

# ── Install on Fedora/RHEL ────────────────────────────────────────────────────
install_fedora() {
    log_info "Detected Fedora. Using dnf."
    sudo dnf install -y iverilog gtkwave
}

# ── Install on Arch Linux ─────────────────────────────────────────────────────
install_arch() {
    log_info "Detected Arch Linux. Using pacman."
    # Arch users are usually capable of doing this themselves,
    # but we respect the principle of least surprise.
    sudo pacman -Sy --noconfirm iverilog gtkwave
}

# ── Instructions for Windows ──────────────────────────────────────────────────
install_windows() {
    log_warn "Windows detected."
    log_warn ""
    log_warn "Option 1 (recommended): Install WSL2 and run setup.sh inside it."
    log_warn "  WSL2 gives you a real Linux environment and everything just works."
    log_warn "  https://learn.microsoft.com/en-us/windows/wsl/install"
    log_warn ""
    log_warn "Option 2: Native Windows (more painful but it works):"
    log_warn "  1. Download Icarus Verilog installer:"
    log_warn "     http://bleyer.org/icarus/"
    log_warn "  2. Download GTKWave for Windows:"
    log_warn "     https://sourceforge.net/projects/gtkwave/files/"
    log_warn "  3. Add both to your PATH"
    log_warn "  4. Restart your terminal"
    log_warn ""
    log_warn "Option 3 (if you have winget):"
    log_warn "  winget install IcarusVerilog.IcarusVerilog"
    log_warn ""
    log_warn "After installing, run: iverilog -V"
    log_warn "If it prints a version number, you're good."
    exit 0
}

# ── Smoke test: simulate the blink example ────────────────────────────────────
smoke_test() {
    log_info "Running smoke test..."

    if ! command_exists iverilog; then
        log_error "iverilog still not found after installation. Something went wrong."
        log_error "Try running: iverilog -V"
        log_error "If that fails, check your PATH or open an issue."
        exit 1
    fi

    if ! command_exists gtkwave; then
        log_warn "gtkwave not found in PATH. Simulation will work but waveforms won't open."
        log_warn "You can install it separately or view .vcd files with another tool."
    fi

    # Create a minimal test to verify iverilog actually works
    TMPDIR_VAL=$(mktemp -d)
    cat > "${TMPDIR_VAL}/smoke.v" << 'VERILOG'
module smoke;
    initial begin
        $display("Icarus Verilog is working. Your FPGA journey begins now.");
        $finish;
    end
endmodule
VERILOG

    if iverilog -o "${TMPDIR_VAL}/smoke.out" "${TMPDIR_VAL}/smoke.v" && \
       vvp "${TMPDIR_VAL}/smoke.out" 2>&1 | grep -q "Icarus Verilog is working"; then
        log_ok "Smoke test passed!"
    else
        log_error "Smoke test failed. iverilog compiled but didn't run correctly."
        log_error "Try running: iverilog -o /tmp/test.out /tmp/smoke.v && vvp /tmp/test.out"
        exit 1
    fi

    rm -rf "${TMPDIR_VAL}"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo "════════════════════════════════════════"
    echo "  Native-HackClub Setup"
    echo "  Installing: Icarus Verilog + GTKWave"
    echo "════════════════════════════════════════"
    echo ""

    OS=$(detect_os)
    log_info "Detected OS: ${OS}"

    case "$OS" in
        macos)   install_macos   ;;
        debian)  install_debian  ;;
        fedora)  install_fedora  ;;
        arch)    install_arch    ;;
        windows) install_windows ;;
        unknown)
            log_error "Unknown OS. Couldn't auto-detect your package manager."
            log_error "Please install iverilog and gtkwave manually:"
            log_error "  https://bleyer.org/icarus/  (Icarus Verilog)"
            log_error "  https://gtkwave.sourceforge.net/  (GTKWave)"
            exit 1
            ;;
    esac

    smoke_test

    echo ""
    log_ok "Setup complete!"
    log_ok "iverilog: $(iverilog -V 2>&1 | head -1)"
    echo ""
    log_info "Next step: run your first simulation:"
    log_info "  ./tools/sim.sh workshops/01-blink-led/solution"
    echo ""
}

main "$@"