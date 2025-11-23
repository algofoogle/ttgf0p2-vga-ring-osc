`default_nettype none
//`timescale 1ns / 1ps

// See: https://gf180mcu-pdk.readthedocs.io/en/latest/digital/standard_cells/gf180mcu_fd_sc_mcu7t5v0/cells/inv/gf180mcu_fd_sc_mcu7t5v0__inv_1.html
`define PDK_INVERTER_CELL   gf180mcu_fd_sc_mcu7t5v0__inv_1
//NOTE: If you change this cell, the port names may need to be altered in any instances.

module inverter_cell (
    input   wire a,
    output  wire y
);

    (* keep_hierarchy *) `PDK_INVERTER_CELL pdkinv_notouch_ (
        .I  (a),
        .ZN (y)
    );

endmodule


// A chain of inverters (not a ring, itself)
module inv_chain #(
    parameter N = 10 // SHOULD BE EVEN.
) (
    input a,
    output y
);

    wire [N-1:0] ins;
    wire [N-1:0] outs;
    assign ins[0] = a;
    assign ins[N-1:1] = outs[N-2:0];
    assign y = outs[N-1];
    (* keep_hierarchy *) inverter_cell inv_array [N-1:0] ( .a(ins), .y(outs) );

endmodule


// A ring where the point of loopback is selectable:
module tapped_ring #(
    //NOTE: These parameters must be even since
    // there is a final baked-in inverter that makes the ring odd.
    //NOTE: These are deltas, i.e. each in turn is added to those before it.
    parameter TAP00 = 2,   // => 3      => 3.33 GHz
    parameter TAP01 = 4,   // => 7      => 1.43 GHz
    parameter TAP02 = 6,   // => 13     => 769 MHz
    parameter TAP03 = 2,   // => 15     => 667 MHz
    parameter TAP04 = 4,   // => 19     => 526 MHz
    parameter TAP05 = 10,  // => 29     => 345 MHz
    parameter TAP06 = 12,  // => 41     => 244 MHz
    parameter TAP07 = 18,  // => 59     => 169 MHz
    parameter TAP08 = 20,  // => 79     => 127 MHz
    parameter TAP09 = 26,  // => 105    => 95 MHz
    parameter TAP10 = 28,  // => 133    => 75 MHz
    parameter TAP11 = 34,  // => 167    => 60 MHz
    parameter TAP12 = 36,  // => 203    => 49 MHz
    parameter TAP13 = 42,  // => 245    => 41 MHz
    parameter TAP14 = 80,  // => 325    => 31 MHz
    parameter TAP15 = 170  // => 495    => 20 MHz
) (
    input ena,
    input [3:0] tap,
    output y
);
    wire ring_head;
    wire [15:0] chain;

    assign y = ena && chain[tap];

    (* keep_hierarchy *) inverter_cell         head ( .a(y),         .y(ring_head) ); // If all the counts below are even, this makes it odd.
    (* keep_hierarchy *) inv_chain #(.N(TAP00)) c00 ( .a(ring_head), .y(chain[ 0]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP01)) c01 ( .a(chain[ 0]), .y(chain[ 1]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP02)) c02 ( .a(chain[ 1]), .y(chain[ 2]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP03)) c03 ( .a(chain[ 2]), .y(chain[ 3]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP04)) c04 ( .a(chain[ 3]), .y(chain[ 4]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP05)) c05 ( .a(chain[ 4]), .y(chain[ 5]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP06)) c06 ( .a(chain[ 5]), .y(chain[ 6]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP07)) c07 ( .a(chain[ 6]), .y(chain[ 7]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP08)) c08 ( .a(chain[ 7]), .y(chain[ 8]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP09)) c09 ( .a(chain[ 8]), .y(chain[ 9]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP10)) c10 ( .a(chain[ 9]), .y(chain[10]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP11)) c11 ( .a(chain[10]), .y(chain[11]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP12)) c12 ( .a(chain[11]), .y(chain[12]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP13)) c13 ( .a(chain[12]), .y(chain[13]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP14)) c14 ( .a(chain[13]), .y(chain[14]) );
    (* keep_hierarchy *) inv_chain #(.N(TAP15)) c15 ( .a(chain[14]), .y(chain[15]) );
endmodule
