`default_nettype none
//`timescale 1ns / 1ps

// See: https://gf180mcu-pdk.readthedocs.io/en/latest/digital/standard_cells/gf180mcu_fd_sc_mcu7t5v0/cells/clkbuf/gf180mcu_fd_sc_mcu7t5v0__clkbuf_8.html
`define PDK_CLKBUFF_CELL    gf180mcu_fd_sc_mcu7t5v0__clkbuf_8
//NOTE: If you change this cell, the port names may need to be altered in any instance.


module vgaringosc(
    input ena,
    input clk,
    input reset_n,
    input vga_mode, // 0=normal, 1=1440x900
    input [1:0] worker_mode, // Selects what 'work' the ring oscillator drives.
    input [3:0] clksel, // Selects clock source or ring length. 0=clk, 1=altclk, 2+ goes to RO.
    input altclk,
    output [3:0] oscdiv, // [0]=raw oscillator, [1]=div2, [2]=div4, [3]=div8
    output hsync_n,
    output vsync_n,
    output [5:0] rgb // RRGGBB
);

    wire hblank;
    wire vblank;
    wire visible;
    wire [9:0] h;
    wire [9:0] v;
    wire hmax;
    wire vmax;
    wire [5:0] rgb_raw;

    wire reset = !reset_n;

    // VGA sync generator:
    vga_sync vga_sync(
      .clk        (clk),
      .reset      (reset),
      .mode       (vga_mode),
      .o_hsync    (hsync_n),
      .o_vsync    (vsync_n),
      .o_hblank   (hblank),
      .o_vblank   (vblank),
      .o_hpos     (h),
      .o_vpos     (v),
      .o_hmax     (hmax),
      .o_vmax     (vmax),
      .o_visible  (visible)
    );

    //DECIDE: Should ring_ena always be on while system 'ena' is on?
    // Should there be an explicit ring reset, or just worker reset?
    // MAYBE not ring reset (as this is just holding ring_ena low for a while),
    // but should the ring be allowed to be free-running while the WORKER is being reset?
    wire ring_ena = ena && (clksel>=2) && !reset;
    //^^NOTE: Including reset means the ring can be flushed while the design remains selected.
    // Also, we don't want the ring running if we're trying to use a "debug" clock source.
    wire ring_clk;

    // Clock mux; not a proper glitch-free mux, but good enough for this case:
    wire worker_clock_unbuffered =
        reset       ?   clk :     // During reset, let CLK thru to the worker to help its sync. reset.
        clksel==0   ?   clk :
        clksel==1   ?   altclk :
        /*clksel>=2*/   ring_clk;
    // Buffered clock, to help CTS/SDC find the 'internal_clock' source pin:
    wire worker_clock;
    (* keep_hierarchy *) `PDK_CLKBUFF_CELL workerclkbuff_notouch_ (.I(worker_clock_unbuffered), .Z(worker_clock));

    wire worker_reset = reset || hblank; // Hold the worker in (a nice long) reset during VGA HBLANK period.

    tapped_ring tapped_ring(
        .ena      (ring_ena),
        .tap      (clksel), //NOTE: Because of ring_ena logic, only clksel>=2 applies.
        .y        (ring_clk)
    );

    ring_worker ring_worker(
        .reset    (worker_reset),
        .clk      (worker_clock),
        .mode     (worker_mode),
        .oscdiv   (oscdiv),
        .computed (rgb_raw)
    );

    assign rgb = rgb_raw & {6{visible}};

endmodule
