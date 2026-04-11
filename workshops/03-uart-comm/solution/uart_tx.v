// =============================================================================
// uart_tx.v — Workshop 03: UART Transmitter from scratch
// =============================================================================
// UART (Universal Asynchronous Receiver/Transmitter) is one of the oldest
// serial communication protocols in computing. It's "asynchronous" because
// there's no shared clock between sender and receiver — they just agree on
// a baud rate (bits per second) and trust each other to count time correctly.
//
// WHY NOT SOFTWARE?
//   Software UART (bit-banging) is notoriously unreliable because:
//   - The OS can preempt your task between bit transitions
//   - Cache misses can add unpredictable delays
//   - A missed bit = corrupted data, with no automatic correction
//
//   Hardware UART generates each bit at EXACTLY the right moment,
//   cycle-accurate, every time, because nothing can preempt a hardware counter.
//   That's the whole point of this workshop.
//
// UART FRAME FORMAT (8N1 — 8 data bits, No parity, 1 stop bit):
//
//   Idle:  __________
//   Start:           \___
//   D0:                  _or_
//   D1:                      _or_
//   D2:                          _or_
//   D3:                              _or_
//   D4:                                  _or_
//   D5:                                      _or_
//   D6:                                          _or_
//   D7 (MSB):                                       _or_
//   Stop:                                               ‾‾‾‾
//   Idle:                                                   ‾‾‾‾
//
//   Total: 1 start bit + 8 data bits + 1 stop bit = 10 bits per byte
//   At 115200 baud: 10 bits / 115200 bits/sec ≈ 86.8 µs per byte
//
// =============================================================================

`timescale 1ns / 1ps

module uart_tx (
    input  logic       clk,         // System clock (100 MHz)
    input  logic       rst_n,       // Active-low reset
    input  logic [7:0] tx_data,     // Byte to transmit
    input  logic       tx_valid,    // Pulse high for 1 cycle to start sending
    output logic       tx_serial,   // Serial data output — connect to your cable
    output logic       tx_busy      // High while transmission is in progress
                                    // (Don't give us new data while we're busy, please)
);

    // =========================================================================
    // Baud rate generator
    // =========================================================================
    // We need to hold each bit for exactly (CLK_FREQ / BAUD_RATE) clock cycles.
    // At 100 MHz and 115200 baud: 100,000,000 / 115,200 = 868.055... cycles per bit
    // We round to 868. The resulting baud rate error is < 0.01%. Fine.
    //
    // This is the number that makes or breaks UART reliability.
    // A software timer counting to 868 will drift if interrupted.
    // A hardware counter never will. Remember that.

    localparam CLK_FREQ  = 100_000_000;
    localparam BAUD_RATE = 115_200;
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD_RATE; // = 868

    // =========================================================================
    // State machine
    // =========================================================================
    // A UART transmitter is a simple 4-state FSM:
    //
    //   IDLE → (tx_valid) → START → DATA (8 bits) → STOP → IDLE
    //
    // In IDLE, the line sits high (that's the "marking" state in UART).
    // START pulls it low for one bit period (that's how the receiver knows data is coming).
    // DATA sends each bit, LSB first.
    // STOP pulls it high for one bit period (lets the receiver recover).

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START = 2'b01,
        DATA  = 2'b10,
        STOP  = 2'b11
    } state_t;
    // typedef enum in SystemVerilog lets you give names to states.
    // Much better than: localparam IDLE = 0, START = 1, etc.
    // And FAR better than magic numbers (2'b10 means what, exactly?).

    state_t             state;
    logic [9:0]         baud_counter;  // Counts up to CLKS_PER_BIT
    logic [2:0]         bit_index;     // Which of the 8 data bits we're sending (0..7)
    logic [7:0]         tx_shift_reg;  // Holds the byte being transmitted
                                       // We shift it right as we send bits

    // =========================================================================
    // Main FSM + baud generator
    // =========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= IDLE;
            baud_counter <= '0;
            bit_index    <= '0;
            tx_shift_reg <= '0;
            tx_serial    <= 1'b1;  // UART idles HIGH (marking state)
            tx_busy      <= 1'b0;
        end else begin
            case (state)

                // ── IDLE: waiting for data to send ───────────────────────────
                IDLE: begin
                    tx_serial <= 1'b1;  // Keep line high in idle
                    tx_busy   <= 1'b0;
                    if (tx_valid) begin
                        // New byte to send! Latch it and start transmitting.
                        tx_shift_reg <= tx_data;
                        tx_busy      <= 1'b1;
                        state        <= START;
                        baud_counter <= '0;
                    end
                end

                // ── START: send the start bit (line LOW for 1 bit period) ───
                START: begin
                    tx_serial <= 1'b0;  // Start bit is always 0
                    if (baud_counter == CLKS_PER_BIT[9:0] - 1) begin
                        baud_counter <= '0;
                        bit_index    <= '0;
                        state        <= DATA;
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                // ── DATA: send 8 data bits, LSB first ────────────────────────
                DATA: begin
                    tx_serial <= tx_shift_reg[0]; // LSB goes first in UART
                    if (baud_counter == CLKS_PER_BIT[9:0] - 1) begin
                        baud_counter <= '0;
                        tx_shift_reg <= {1'b0, tx_shift_reg[7:1]}; // Shift right
                        // We shift in a 0 from the top — doesn't matter since
                        // we've already output that bit.
                        if (bit_index == 3'd7) begin
                            // All 8 bits sent — move to stop bit
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                // ── STOP: send the stop bit (line HIGH for 1 bit period) ────
                STOP: begin
                    tx_serial <= 1'b1;  // Stop bit is always 1
                    if (baud_counter == CLKS_PER_BIT[9:0] - 1) begin
                        baud_counter <= '0;
                        tx_busy      <= 1'b0;
                        state        <= IDLE;
                        // If tx_valid is already high again, we could go straight
                        // to START here. For simplicity, we always return to IDLE.
                        // Improving throughput is a future-work exercise.
                    end else begin
                        baud_counter <= baud_counter + 1'b1;
                    end
                end

                default: begin
                    // Should never happen. If it does, something is very wrong.
                    // Return to IDLE rather than hanging forever.
                    state     <= IDLE;
                    tx_serial <= 1'b1;
                    tx_busy   <= 1'b0;
                end

            endcase
        end
    end

endmodule