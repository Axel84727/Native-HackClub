#!/usr/bin/env bash
# =============================================================================
# sim.sh — Compile and simulate a Native-HackClub project
# =============================================================================
# Usage:
#   ./tools/sim.sh <project_path>
#
# Examples:
#   ./tools/sim.sh workshops/01-blink-led/solution
#   ./tools/sim.sh projects/parallel-timer
#
# What this does:
#   1. Finds all .v and .sv files in <project_path>/src/ and testbench/
#   2. Compiles them with iverilog
#   3. Runs the simulation with vvp
#   4. Opens GTKWave with the output waveform (if a .vcd was generated)
#
# Flags:
#   --no-wave    Simulate but don't open GTKWave (useful in CI or headless env)
#   --waves-only Open GTKWave on an existing .vcd without re-simulating
#   --help       Show this message
#
# =============================================================================

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[sim]${NC}  $1"; }
log_ok()    { echo -e "${GREEN}[sim]${NC}  $1"; }
log_warn()  { echo -e "${YELLOW}[sim]${NC}  $1"; }
log_error() { echo -e "${RED}[sim]${NC}  $1"; }

# ── Defaults ──────────────────────────────────────────────────────────────────
OPEN_WAVE=true
WAVES_ONLY=false
PROJECT_PATH=""

# ── Parse arguments ───────────────────────────────────────────────────────────
for arg in "$@"; do
    case "$arg" in
        --no-wave)    OPEN_WAVE=false ;;
        --waves-only) WAVES_ONLY=true ;;
        --help|-h)
            echo "Usage: ./tools/sim.sh <project_path> [--no-wave] [--waves-only]"
            echo ""
            echo "  <project_path>   Path to a project or workshop directory"
            echo "  --no-wave        Don't open GTKWave after simulation"
            echo "  --waves-only     Open GTKWave on existing .vcd without re-simulating"
            echo ""
            echo "Examples:"
            echo "  ./tools/sim.sh workshops/01-blink-led/solution"
            echo "  ./tools/sim.sh projects/parallel-timer --no-wave"
            exit 0
            ;;
        *)
            if [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$arg"
            fi
            ;;
    esac
done

# ── Validate input ────────────────────────────────────────────────────────────
if [[ -z "$PROJECT_PATH" ]]; then
    log_error "No project path specified."
    log_error "Usage: ./tools/sim.sh <project_path>"
    log_error "Example: ./tools/sim.sh workshops/01-blink-led/solution"
    exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    log_error "Directory not found: ${PROJECT_PATH}"
    log_error "Make sure the path is correct (relative to repo root)."
    exit 1
fi

# Resolve to absolute path (makes error messages less confusing)
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)
PROJECT_NAME=$(basename "$PROJECT_PATH")

echo ""
echo "════════════════════════════════════"
echo "  Simulating: ${PROJECT_NAME}"
echo "════════════════════════════════════"
echo ""

# ── Output directory ──────────────────────────────────────────────────────────
# Put simulation outputs in a build/ directory so .gitignore can ignore them cleanly
BUILD_DIR="${PROJECT_PATH}/build"
mkdir -p "$BUILD_DIR"

VCD_FILE="${BUILD_DIR}/output.vcd"
SIM_BIN="${BUILD_DIR}/sim.out"

# ── Waves-only mode ───────────────────────────────────────────────────────────
if [[ "$WAVES_ONLY" == "true" ]]; then
    if [[ ! -f "$VCD_FILE" ]]; then
        log_error "No waveform found at: ${VCD_FILE}"
        log_error "Run a simulation first (without --waves-only)."
        exit 1
    fi
    log_info "Opening existing waveform: ${VCD_FILE}"
    gtkwave "$VCD_FILE" &
    exit 0
fi

# ── Find source files ─────────────────────────────────────────────────────────
# We look in src/ and testbench/ subdirectories (the standard layout).
# Also accept .sv (SystemVerilog) files in addition to .v.

log_info "Collecting source files..."

VERILOG_FILES=()

# Helper to add files from a directory if it exists
add_files_from_dir() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        while IFS= read -r -d '' file; do
            VERILOG_FILES+=("$file")
            log_info "  Found: $(basename $file)"
        done < <(find "$dir" -name "*.v" -o -name "*.sv" | sort | tr '\n' '\0')
    fi
}

# Check for standard layout (src/ + testbench/) or flat layout
if [[ -d "${PROJECT_PATH}/src" ]] || [[ -d "${PROJECT_PATH}/testbench" ]]; then
    add_files_from_dir "${PROJECT_PATH}/src"
    add_files_from_dir "${PROJECT_PATH}/testbench"
else
    # Flat layout: all .v files directly in the project directory
    add_files_from_dir "${PROJECT_PATH}"
fi

if [[ ${#VERILOG_FILES[@]} -eq 0 ]]; then
    log_error "No .v or .sv files found in: ${PROJECT_PATH}"
    log_error "Expected structure:"
    log_error "  ${PROJECT_PATH}/src/*.v"
    log_error "  ${PROJECT_PATH}/testbench/*.v"
    exit 1
fi

log_info "Found ${#VERILOG_FILES[@]} file(s)."
echo ""

# ── Compile ───────────────────────────────────────────────────────────────────
log_info "Compiling..."

# iverilog flags:
#   -g2012: use SystemVerilog 2012 syntax (supports typedef enum, logic, etc.)
#   -Wall:  enable all warnings (yes, all of them — warnings are bugs you haven't noticed yet)
#   -o:     output file
#   -I:     include path (add src/ so submodules can `include each other)

if iverilog \
    -g2012 \
    -Wall \
    -I "${PROJECT_PATH}/src" \
    -o "$SIM_BIN" \
    "${VERILOG_FILES[@]}" 2>&1; then
    log_ok "Compilation successful."
else
    echo ""
    log_error "Compilation FAILED."
    log_error "Fix the errors above, then try again."
    log_error "Common issues:"
    log_error "  - Missing semicolons (yes, really, check every end statement)"
    log_error "  - Wrong port names in module instantiation"
    log_error "  - Using 'reg' where 'logic' is needed (or vice versa)"
    log_error "  - Forgetting to declare a signal before using it"
    exit 1
fi

echo ""

# ── Run simulation ─────────────────────────────────────────────────────────────
log_info "Running simulation..."
log_info "(Output goes to: ${BUILD_DIR}/)"
echo ""

# Run in the build directory so relative paths in $dumpfile work correctly
pushd "$BUILD_DIR" > /dev/null
if vvp "$SIM_BIN"; then
    log_ok "Simulation completed successfully."
else
    SIM_EXIT=$?
    # vvp exits non-zero on $fatal — check if that's what happened
    log_warn "Simulation exited with code ${SIM_EXIT}."
    log_warn "Check the output above for FAIL messages or $fatal calls."
fi
popd > /dev/null

echo ""

# ── Open waveform ─────────────────────────────────────────────────────────────
if [[ "$OPEN_WAVE" == "false" ]]; then
    log_info "Skipping GTKWave (--no-wave flag set)."
    if [[ -f "$VCD_FILE" ]]; then
        log_info "Waveform saved at: ${VCD_FILE}"
    fi
elif [[ ! -f "$VCD_FILE" ]]; then
    log_warn "No waveform file generated."
    log_warn "Make sure your testbench includes:"
    log_warn '  $dumpfile("output.vcd");'
    log_warn '  $dumpvars(0, tb_module_name);'
else
    if command -v gtkwave &> /dev/null; then
        log_info "Opening GTKWave..."
        log_info "(Close GTKWave to return to the terminal, or run sim.sh again to re-simulate)"
        gtkwave "$VCD_FILE" &
        log_ok "GTKWave launched. Drag signals from the left panel to the wave view."
    else
        log_warn "GTKWave not found. Install it with: ./tools/setup.sh"
        log_info "Waveform saved at: ${VCD_FILE}"
        log_info "You can open it with any VCD viewer."
    fi
fi

echo ""