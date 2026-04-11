// =============================================================================
// seg7.v — Workshop 02 Starter: 7-Segment Decoder
// =============================================================================
// Your job: fill in the case statement so each digit maps to the right segments.
//
// Segment encoding: {a, b, c, d, e, f, g}
// Active-LOW: 0 = segment ON, 1 = segment OFF
//
// Run: ./tools/sim.sh workshops/02-seven-segment/starter
// Then inspect `segments` in GTKWave for each digit value.
// =============================================================================

`timescale 1ns / 1ps

module seg7 (
    input  logic [3:0] digit,    // 4-bit input: 0–F
    output logic [6:0] segments  // Active-LOW: {a,b,c,d,e,f,g}
);

    always_comb begin
        case (digit)
            4'h0: segments = /* TODO */ 7'b0000000;
            4'h1: segments = /* TODO */ 7'b0000000;
            4'h2: segments = /* TODO */ 7'b0000000;
            4'h3: segments = /* TODO */ 7'b0000000;
            4'h4: segments = /* TODO */ 7'b0000000;
            4'h5: segments = /* TODO */ 7'b0000000;
            4'h6: segments = /* TODO */ 7'b0000000;
            4'h7: segments = /* TODO */ 7'b0000000;
            4'h8: segments = /* TODO */ 7'b0000000;
            4'h9: segments = /* TODO */ 7'b0000000;
            4'hA: segments = /* TODO */ 7'b0000000;
            4'hB: segments = /* TODO */ 7'b0000000;
            4'hC: segments = /* TODO */ 7'b0000000;
            4'hD: segments = /* TODO */ 7'b0000000;
            4'hE: segments = /* TODO */ 7'b0000000;
            4'hF: segments = /* TODO */ 7'b0000000;
            // TODO: add a default case! (Hint: all segments off = 7'b1111111)
        endcase
    end

endmodule