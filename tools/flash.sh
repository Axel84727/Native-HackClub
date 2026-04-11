#!/usr/bin/env bash
# =============================================================================
# flash.sh — Flash a compiled bitfile to an FPGA board
# =============================================================================
# Usage:
#   ./tools/flash.sh <bitfile_path> [--board <board_name>] [--dry-run]
#
# Examples:
#   ./tools/flash.sh projects/parallel-timer/build/top.bit
#   ./tools/flash.sh projects/parallel-timer/build/top.bit --board basys3
#   ./tools/flash.sh projects/parallel-timer/build/top.bit --dry-run
#
# Supported boards (via openFPGALoader):
#   basys3     — Digilent Basys3 (Artix-7 35T)
#   arty-a7    — Digilent Arty A7 (Artix-7 35T or 100T)
#   nexys4ddr  — Digilent Nexys4 DDR (Artix-7 100T)
#
# Prerequisites:
#   openFPGALoader — install with: sudo apt install openfpgaloader (Ubuntu)
#                                  or: brew install openfpgaloader (macOS)
#   Vivado's xc3sprog is an alternative but openFPGALoader is more actively maintained
#   and doesn't require a full Vivado install.
#
# Note: You need to have synthesized your design first using Vivado or
#       another synthesis tool to produce the .bit file.
#       Icarus Verilog (iverilog) only simulates — it doesn't produce bitfiles.
#
# =============================================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[flash]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[flash]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[flash]${NC} $1"; }
log_error() { echo -e "${RED}[flash]${NC} $1"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
BITFILE=""
BOARD="auto"   # "auto" = let openFPGALoader detect the board
DRY_RUN=false

# ── Parse arguments ───────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --board)
            BOARD="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./tools/flash.sh <bitfile> [--board <name>] [--dry-run]"
            echo ""
            echo "  <bitfile>          Path to the .bit file from Vivado synthesis"
            echo "  --board <name>     Board name (basys3, arty-a7, nexys4ddr)"
            echo "                     Default: auto-detect"
            echo "  --dry-run          Validate the bitfile without programming"
            echo ""
            echo "Supported boards: basys3, arty-a7, nexys4ddr"
            echo ""
            echo "Prerequisites: openFPGALoader (sudo apt install openfpgaloader)"
            exit 0
            ;;
        *)
            if [[ -z "$BITFILE" ]]; then
                BITFILE="$1"
            else
                log_error "Unknown argument: $1"
                exit 1
            fi
            shift
            ;;
    esac
done

# ── Validate input ────────────────────────────────────────────────────────────
if [[ -z "$BITFILE" ]]; then
    log_error "No bitfile specified."
    log_error "Usage: ./tools/flash.sh <bitfile_path>"
    log_error ""
    log_error "A .bit file is produced by running synthesis + implementation in Vivado."
    log_error "iverilog (used by sim.sh) only simulates — it doesn't produce .bit files."
    exit 1
fi

if [[ ! -f "$BITFILE" ]]; then
    log_error "Bitfile not found: ${BITFILE}"
    log_error "Check the path. Vivado puts bitfiles in:"
    log_error "  <project>.runs/impl_1/<top_module>.bit"
    exit 1
fi

# Validate file extension
EXTENSION="${BITFILE##*.}"
if [[ "$EXTENSION" != "bit" ]] && [[ "$EXTENSION" != "bin" ]]; then
    log_warn "File doesn't have a .bit or .bin extension: ${BITFILE}"
    log_warn "Proceeding anyway, but double-check you have the right file."
fi

echo ""
echo "════════════════════════════════════"
echo "  Flashing to FPGA"
echo "════════════════════════════════════"
echo ""
log_info "Bitfile: ${BITFILE}"
log_info "Board:   ${BOARD}"
log_info "Size:    $(du -sh "$BITFILE" | cut -f1)"
echo ""

# ── Check for openFPGALoader ──────────────────────────────────────────────────
if ! command -v openFPGALoader &> /dev/null; then
    log_error "openFPGALoader not found."
    log_error ""
    log_error "Install it:"
    log_error "  Ubuntu/Debian: sudo apt install openfpgaloader"
    log_error "  macOS:         brew install openfpgaloader"
    log_error "  From source:   https://github.com/trabucayre/openFPGALoader"
    log_error ""
    log_error "If you prefer Vivado's built-in programmer (Vivado Hardware Manager):"
    log_error "  File → Programming → Open Hardware Manager → Auto Connect → Program Device"
    exit 1
fi

# ── Map board name to openFPGALoader target ───────────────────────────────────
# openFPGALoader uses specific board name strings.
# Check 'openFPGALoader --list-boards' for the full list.
get_board_flag() {
    case "$1" in
        basys3)    echo "--board basys3" ;;
        arty-a7)   echo "--board arty_a7_35t" ;;
        nexys4ddr) echo "--board nexys4_ddr" ;;
        auto)      echo "" ;;  # Let openFPGALoader auto-detect
        *)
            log_warn "Unknown board: ${1}. Passing it directly to openFPGALoader."
            log_warn "Run 'openFPGALoader --list-boards' for valid board names."
            echo "--board $1"
            ;;
    esac
}

BOARD_FLAG=$(get_board_flag "$BOARD")

# ── Dry run mode ──────────────────────────────────────────────────────────────
if [[ "$DRY_RUN" == "true" ]]; then
    log_info "DRY RUN — checking bitfile validity without programming."
    log_info ""
    log_info "Would run:"
    log_info "  openFPGALoader ${BOARD_FLAG} ${BITFILE}"
    log_info ""
    log_info "Bitfile looks valid (exists, non-zero size)."
    log_ok "Dry run complete. Remove --dry-run to actually program the board."
    exit 0
fi

# ── Check for connected board ─────────────────────────────────────────────────
log_info "Looking for connected FPGA board..."

# Try to detect connected devices (openFPGALoader can list them)
if openFPGALoader --detect 2>&1 | grep -q "No device found"; then
    log_error "No FPGA board detected."
    log_error ""
    log_error "Things to check:"
    log_error "  1. Is the board plugged in via USB?"
    log_error "  2. Is the board powered? (USB should power most dev boards)"
    log_error "  3. Do you have USB device permissions?"
    log_error "     On Linux, you may need to add udev rules:"
    log_error "     https://trabucayre.github.io/openFPGALoader/guide/install.html#udev-rules"
    log_error "  4. Try a different USB cable or port."
    exit 1
fi

log_ok "Device detected."
echo ""

# ── Flash! ─────────────────────────────────────────────────────────────────────
log_info "Programming device..."
log_warn "(Don't unplug the board while programming — that's a bad time for everyone.)"
echo ""

FLASH_CMD="openFPGALoader ${BOARD_FLAG} ${BITFILE}"
log_info "Running: ${FLASH_CMD}"
echo ""

if eval "$FLASH_CMD"; then
    echo ""
    log_ok "Programming complete!"
    log_ok "Your design is now running on the FPGA."
    log_info ""
    log_info "The FPGA is now configured. If you power-cycle the board, the"
    log_info "configuration will be lost (SRAM-based programming)."
    log_info ""
    log_info "To make it survive power cycles, program it to flash memory:"
    log_info "  openFPGALoader --write-flash ${BOARD_FLAG} ${BITFILE}"
    log_warn "(Flash write is slower and has limited write cycles — use sparingly.)"
else
    echo ""
    log_error "Programming FAILED."
    log_error ""
    log_error "Common causes:"
    log_error "  - Wrong bitfile for this board (Artix-7 35T vs 100T, etc.)"
    log_error "  - Board not in programming mode (some boards need a specific jumper)"
    log_error "  - USB permission issue (see above)"
    log_error "  - Corrupted bitfile (re-run synthesis in Vivado)"
    exit 1
fi

echo ""