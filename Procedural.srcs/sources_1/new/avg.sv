`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2024 12:59:57 PM
// Design Name: 
// Module Name: avg
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


module avg#(
        parameter int G_BIT_WIDTH   = 8
    )(
        input logic                     i_clk,
        input logic                     i_rst,
        input logic [G_BIT_WIDTH-1:0]   i_data,
        input logic                     i_valid,
        input logic                     i_last,

        output logic                    o_valid     = '0,
        output logic [G_BIT_WIDTH-1:0]  o_avg_data  = '0
    );
    
    logic   [G_BIT_WIDTH-1:0]   q_sum_buf       = '0;
    logic   [G_BIT_WIDTH-1:0]   q_data_cnt      = '0;
    logic                       q_last          = '0;
    
    logic                       q_div_vld       = '0;
    logic   [G_BIT_WIDTH-1:0]   q_div_res_dat   = '0;
    logic                       q_div_rdy       = '0;
    logic                       q_div_res_vld   = '0;
    logic                       q_div_res_dat   = '0;


    always_ff @(i_clk) begin : averange
        
        if (i_valid) begin
            
            q_sum_buf  <= q_sum_buf + i_data;
            q_data_cnt <= q_data_cnt + 1;

            if (i_last) begin
                q_last      <= '1;
                o_avg_data  <= '0;
            end
        end
        
        if(q_last) begin
            //o_avg_data  <= q_sum_buf / q_data_cnt;
            if (q_div_rdy) begin
                q_div_vld   <= '1;
                q_last      <= '0;  
            end
                
            //o_valid     <= '1;
        end

        if (q_div_res_vld) begin
            o_avg_data  <= q_div_res_dat;
            o_valid     <= '1;
            q_div_vld   <= '0;
        end
        
        if (o_valid) begin
            q_sum_buf   <= '0;
            q_data_cnt  <= '0;
            o_valid     <= '0;
            o_avg_data  <= '0;
        end
        
    end : averange



    divider #(
        .ROUNDING   ('1),
        // .USE_RESET  ('1),
        .RES_W      ( 8)
    ) DIVIDER (
        .i_div_a_clk_p  (i_clk         ),
        // .i_div_s_rst_p  (i_rst),

        .i_div_dat_vld  (q_div_vld     ),
        .i_div_dvd_dat  (q_sum_buf     ),
        .i_div_dvr_dat  (q_data_cnt    ),

        .o_div_dat_rdy  (q_div_rdy    ),
        .o_div_res_vld  (q_div_res_vld),
        .o_div_res_dat  (q_div_res_dat)
    );
endmodule   

