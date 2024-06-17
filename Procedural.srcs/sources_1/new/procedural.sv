`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2024 12:59:57 PM
// Design Name: 
// Module Name: procedural
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module procedural#(
        parameter int G_BYT = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT
    )(
        input i_clk,
        input i_rst,
        input logic /* [W-1:0] */[G_BIT_WIDTH-1:0] i_data_fft,

        output [2:0] o_data_proc   // Data from max, min, avg
    );

    
    
    max #(
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) MAX (
        .i_clk      (i_clk),
        .i_rst      (i_rst)

    );


    min #(
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) MIN (

    );

    avg #(
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) AVG (

    );

    // TODO:
    //  1. Remake testbenches for every 4 clk
    //  2. Make constrains (timing) clk
    //  3. Move last (Under clk, after vld??, under vld)
    //  4. Shift Reg

    //Connect REG_MAP by AXIL_INTERFACE
    // MAKE PLAN
endmodule
