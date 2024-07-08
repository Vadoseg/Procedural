`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 06/05/2024 12:59:57 PM
// Module Name: avg
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: Calculate Averange size of datapack
// 
// Dependencies: divider.sv
// 
// Revision:
// Revision 0.11 - Calculating averange
// Additional Comments: TODO reset flag
// 
//////////////////////////////////////////////////////////////////////////////////


module avg#(
        parameter int G_BIT_WIDTH   = 32
    )(
        input logic                     i_clk,
        input logic [G_BIT_WIDTH-1:0]   i_data,
        input logic                     i_valid,
        input logic                     i_last,

        output logic                    o_valid,
        output logic [G_BIT_WIDTH-1:0]  o_avg_data
    );

// For Averange    
    logic   [G_BIT_WIDTH-1:0]   q_sum_buf       = '0;
    logic   [G_BIT_WIDTH-1:0]   q_data_cnt      = '0;

// For Divider    
    logic                       q_div_vld       = '0;
    logic   [G_BIT_WIDTH-1:0]   q_div_res_dat;
    logic                       q_div_rdy;
    logic                       q_div_res_vld;
//    logic                       q_div_res_dat   = '0;

    
    always_ff @(posedge i_clk) begin : averange
        
        if (i_valid) begin
            q_sum_buf  <= q_sum_buf + i_data;
            q_data_cnt <= q_data_cnt + 1;
        end
        
        q_div_vld   <=  i_last;

        if (q_div_res_vld) begin
            o_avg_data  <= q_div_res_dat;
            o_valid     <= '1;
        end
        
        if (o_valid) begin
            q_sum_buf   <= '0;
            q_data_cnt  <= '0;
            o_valid     <= '0;
        end
        
    end : averange



    divider #(
        .ROUNDING   ('1),
        .RES_W          (G_BIT_WIDTH   ),
        .DVD_W          (G_BIT_WIDTH   ),
        .DVR_W          (G_BIT_WIDTH   )
    ) DIVIDER (
        .i_div_a_clk_p  (i_clk         ),

        .i_div_dat_vld  (q_div_vld     ),
        .i_div_dvd_dat  (q_sum_buf     ),
        .i_div_dvr_dat  (q_data_cnt    ),

        .o_div_dat_rdy  (q_div_rdy    ),
        .o_div_res_vld  (q_div_res_vld),
        .o_div_res_dat  (q_div_res_dat)
    );
endmodule   

