// =============================================================================
// uart_tx.v — Workshop 03 Starter: UART Transmitter
// =============================================================================
// Build a UART transmitter that sends 8N1 frames at 115200 baud.
//
// Your FSM needs 4 states: IDLE, START, DATA, STOP
// The baud counter keeps each bit at the right duration.
// A shift register sends bits LSB first.
//
// Read the README before starting. The timing diagram is your spec.
// =============================================================================

`timescale 1ns / 1ps

module uart_tx (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [7:0] tx_data,    // Byte to transmit
    input  logic       tx_valid,   // Pulse high for 1 cycle to start sending
    output logic       tx_serial,  // Serial output (idle = HIGH)
    output logic       tx_busy     // High during transmission
);

    localparam CLK_FREQ    = 100_000_000;
    localparam BAUD_RATE   = 115_200;
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE; // = 868 cycles per bit

    // ── TODO: Define your state type ─────────────────────────────────────────
    // Use typedef enum logic [1:0] { ... } state_t;
    // States: IDLE, START, DATA, STOP


    // ── TODO: Declare your state and internal signals ─────────────────────────
    // You'll need:
    //   - state register (state_t)
    //   - baud counter (how many bits wide? CLKS_PER_BIT = 868 → need 10 bits)
    //   - bit index (counts 0 to 7 during DATA state)
    //   - shift register (holds the byte being transmitted)


    // ── TODO: Implement the FSM ───────────────────────────────────────────────
    // always_ff @(posedge clk or negedge rst_n) begin
    //   if (!rst_n) begin
    //     ... reset everything, tx_serial = 1 (UART idles HIGH)
    //   end else begin
    //     case (state)
    //       IDLE:  ... wait for tx_valid, latch tx_data into shift register
    //       START: ... drive tx_serial LOW for CLKS_PER_BIT cycles
    //       DATA:  ... output shift_reg[0], shift right, advance bit_index
    //       STOP:  ... drive tx_serial HIGH for CLKS_PER_BIT cycles, return to IDLE
    //     endcase
    //   end
    // end

endmodule