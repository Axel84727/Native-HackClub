// =============================================================================
// dual_fsm.v — Workshop 04: Two FSMs running in parallel
// =============================================================================
// This is the workshop where the FPGA starts to feel genuinely different.
//
// We have two completely independent finite state machines:
//   - FSM A: a traffic light controller (Red → Green → Yellow → repeat)
//   - FSM B: a morse code transmitter (dots and dashes on a separate output)
//
// Both FSMs run on the SAME clock. Neither waits for the other.
// Neither knows the other exists. They just... both happen. Every clock cycle.
//
// On a CPU, you'd use threads or coroutines or an event loop.
// The OS would decide when each "gets a turn."
// There's no guarantee they advance at the same rate, or react at the same time.
//
// On the FPGA: both FSMs have their state registers. Both registers update on
// every clock edge. No scheduling. No preemption. No "your turn."
// It's not concurrent — it's genuinely, provably, physically simultaneous.
//
// That's the point of this workshop. Watch the waveform and see both FSMs
// advancing in lockstep, every single cycle.
//
// =============================================================================

`timescale 1ns / 1ps

module dual_fsm (
    input  logic clk,
    input  logic rst_n,

    // ── Traffic light FSM outputs ─────────────────────────────────────────────
    output logic light_red,     // Red light
    output logic light_yellow,  // Yellow light
    output logic light_green,   // Green light

    // ── Morse FSM outputs ─────────────────────────────────────────────────────
    output logic morse_out,     // The morse code output (0 = off, 1 = tone)
    output logic morse_busy     // High while a symbol is being transmitted
);

    // =========================================================================
    // Timing parameters
    // =========================================================================
    // Using small values so simulation doesn't take all day.
    // Swap CLK_FREQ to 100_000_000 and adjust UNIT_CYCLES for real hardware.

    localparam CLK_FREQ       = 100_000_000; // 100 MHz
    localparam LIGHT_RED_MS   = 2000;        // Red light duration: 2 seconds
    localparam LIGHT_GREEN_MS = 2000;        // Green light duration: 2 seconds
    localparam LIGHT_YEL_MS   = 500;         // Yellow light duration: 0.5 seconds
    localparam MORSE_UNIT_MS  = 200;         // Morse unit (1 dot = 200ms)

    // Convert ms to clock cycles
    localparam RED_CYCLES   = CLK_FREQ / 1000 * LIGHT_RED_MS;
    localparam GREEN_CYCLES = CLK_FREQ / 1000 * LIGHT_GREEN_MS;
    localparam YEL_CYCLES   = CLK_FREQ / 1000 * LIGHT_YEL_MS;
    localparam UNIT_CYCLES  = CLK_FREQ / 1000 * MORSE_UNIT_MS;

    // =========================================================================
    // ── FSM A: Traffic light controller ──────────────────────────────────────
    // =========================================================================
    // States: RED → GREEN → YELLOW → RED → ...
    // A simple 3-state cycle. Real traffic lights have more complexity
    // (pedestrian phases, sensors, etc.). This is the concept, not the product.

    typedef enum logic [1:0] {
        LIGHT_RED_STATE    = 2'b00,
        LIGHT_GREEN_STATE  = 2'b01,
        LIGHT_YELLOW_STATE = 2'b10
    } light_state_t;

    light_state_t  light_state;
    logic [26:0]   light_counter; // 27 bits to hold up to 200M cycles

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            light_state   <= LIGHT_RED_STATE;
            light_counter <= '0;
        end else begin
            case (light_state)

                LIGHT_RED_STATE: begin
                    if (light_counter == RED_CYCLES[26:0] - 1) begin
                        light_state   <= LIGHT_GREEN_STATE;
                        light_counter <= '0;
                    end else begin
                        light_counter <= light_counter + 1'b1;
                    end
                end

                LIGHT_GREEN_STATE: begin
                    if (light_counter == GREEN_CYCLES[26:0] - 1) begin
                        light_state   <= LIGHT_YELLOW_STATE;
                        light_counter <= '0;
                    end else begin
                        light_counter <= light_counter + 1'b1;
                    end
                end

                LIGHT_YELLOW_STATE: begin
                    if (light_counter == YEL_CYCLES[26:0] - 1) begin
                        light_state   <= LIGHT_RED_STATE;
                        light_counter <= '0;
                    end else begin
                        light_counter <= light_counter + 1'b1;
                    end
                end

                default: light_state <= LIGHT_RED_STATE;

            endcase
        end
    end

    // Traffic light output decoding (combinational — no flip-flop needed here)
    always_comb begin
        light_red    = 1'b0;
        light_yellow = 1'b0;
        light_green  = 1'b0;
        case (light_state)
            LIGHT_RED_STATE:    light_red    = 1'b1;
            LIGHT_GREEN_STATE:  light_green  = 1'b1;
            LIGHT_YELLOW_STATE: light_yellow = 1'b1;
            default:            light_red    = 1'b1; // Safe default: show red
        endcase
    end

    // =========================================================================
    // ── FSM B: Morse code transmitter (spells "SOS" → repeating) ─────────────
    // =========================================================================
    // Morse code timing rules:
    //   - Dot  = 1 unit ON
    //   - Dash = 3 units ON
    //   - Gap between symbols in same letter = 1 unit OFF
    //   - Gap between letters = 3 units OFF
    //   - Gap between words = 7 units OFF
    //
    // SOS in morse: ... --- ...
    // Full sequence: dot gap dot gap dot  letter-gap  dash gap dash gap dash  letter-gap  dot gap dot gap dot  word-gap
    //
    // We encode this as a sequence of (duration, level) pairs.
    // The FSM steps through them one at a time.

    // Sequence for "SOS":
    // S = dot dot dot
    // O = dash dash dash
    // S = dot dot dot
    // Then a long gap before repeating

    // We'll encode each symbol as: {duration_in_units, tone_on}
    // 16 symbols total (including gaps)
    localparam SEQ_LEN = 20;

    // Symbol durations in UNIT_CYCLES multiples
    // Encoded as: [3:0] = units, [4] = tone_on
    // (We use a ROM-style approach with a case statement below)

    typedef enum logic [4:0] {
        MORSE_IDLE  = 5'b00000
    } morse_state_t;
    // (We'll use a simple counter approach rather than a full FSM enum here)

    logic [4:0]  morse_seq_idx;   // Current position in the sequence
    logic [26:0] morse_timer;     // Counts units within current symbol
    logic [2:0]  morse_duration;  // Duration of current symbol in units
    logic        morse_tone;      // Whether current symbol is tone-on or tone-off

    // Sequence lookup: return (duration, is_tone) for each sequence index
    // SOS: dot gap dot gap dot | letter-gap | dash gap dash gap dash | letter-gap | dot gap dot gap dot | word-gap
    always_comb begin
        case (morse_seq_idx)
            // S: dot gap dot gap dot
            5'd0:  begin morse_duration = 3'd1; morse_tone = 1'b1; end // dot
            5'd1:  begin morse_duration = 3'd1; morse_tone = 1'b0; end // symbol gap
            5'd2:  begin morse_duration = 3'd1; morse_tone = 1'b1; end // dot
            5'd3:  begin morse_duration = 3'd1; morse_tone = 1'b0; end // symbol gap
            5'd4:  begin morse_duration = 3'd1; morse_tone = 1'b1; end // dot
            5'd5:  begin morse_duration = 3'd3; morse_tone = 1'b0; end // letter gap (3 units)
            // O: dash gap dash gap dash
            5'd6:  begin morse_duration = 3'd3; morse_tone = 1'b1; end // dash
            5'd7:  begin morse_duration = 3'd1; morse_tone = 1'b0; end // symbol gap
            5'd8:  begin morse_duration = 3'd3; morse_tone = 1'b1; end // dash
            5'd9:  begin morse_duration = 3'd1; morse_tone = 1'b0; end // symbol gap
            5'd10: begin morse_duration = 3'd3; morse_tone = 1'b1; end // dash
            5'd11: begin morse_duration = 3'd3; morse_tone = 1'b0; end // letter gap
            // S: dot gap dot gap dot
            5'd12: begin morse_duration = 3'd1; morse_tone = 1'b1; end // dot
            5'd13: begin morse_duration = 3'd1; morse_tone = 1'b0; end // symbol gap
            5'd14: begin morse_duration = 3'd1; morse_tone = 1'b1; end // dot
            5'd15: begin morse_duration = 3'd1; morse_tone = 1'b0; end // symbol gap
            5'd16: begin morse_duration = 3'd1; morse_tone = 1'b1; end // dot
            5'd17: begin morse_duration = 3'd7; morse_tone = 1'b0; end // word gap (7 units)
            // Wrap: back to start
            default: begin morse_duration = 3'd7; morse_tone = 1'b0; end
        endcase
    end

    // Morse FSM: step through the sequence
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            morse_seq_idx <= '0;
            morse_timer   <= '0;
        end else begin
            // Calculate the number of clock cycles for current symbol
            if (morse_timer >= (morse_duration * UNIT_CYCLES[26:0] - 1)) begin
                // This symbol is done — advance to next
                morse_timer   <= '0;
                if (morse_seq_idx == 5'd17)
                    morse_seq_idx <= '0; // Wrap back to start of SOS
                else
                    morse_seq_idx <= morse_seq_idx + 1'b1;
            end else begin
                morse_timer <= morse_timer + 1'b1;
            end
        end
    end

    assign morse_out  = morse_tone;
    assign morse_busy = 1'b1; // This transmitter is always busy (it loops forever)

endmodule