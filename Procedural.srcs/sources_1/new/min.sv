`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 06/05/2024 12:59:57 PM
// Module Name: min
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: Calculate Minimum data from datapack
// 
// Dependencies: None
// 
// Revision:
// Revision 0.11 - Calculating minimum
// Additional Comments: TODO reset flag
// 
//////////////////////////////////////////////////////////////////////////////////


module min#(
        parameter int G_BIT_WIDTH   = 8
    )(
        input logic                     i_clk,
        input logic                     i_rst,
        input logic [G_BIT_WIDTH-1:0]   i_data,
        input logic                     i_valid,
        input logic                     i_last,

        output logic                    o_valid     = '0,
        output logic [G_BIT_WIDTH-1:0]  o_min_data  = '0
    );

// First delay
    logic                   q_valid         = '0;
    logic [G_BIT_WIDTH-1:0] q_data          = '0;
    logic                   q_last          = '0;

// Second delay
    logic                   q_valid_2       = '0;
    logic [G_BIT_WIDTH-1:0] q_data_2        = '0;
    logic                   q_last_2        = '0;

// Final delay
    logic [G_BIT_WIDTH-1:0] w_buf_min       = '1;
    logic                   w_min_check     = '0;   // Variable to check the minimum
    logic                   w_last          = '0;

    always_ff @(i_clk) begin : minimum
        
        if (i_valid) begin  // Original valid
            
            q_valid     <= i_valid;
            q_data      <= i_data;     

            q_last      <= (i_last) ? 1 : 0;
        end
        

        if (q_valid) begin  // First delayed Valid
            
            w_min_check     <= (w_buf_min > q_data) ? 1 : 0;    // If data will be too fast, then we will lose first data in datapack
            q_valid_2       <=  q_valid;
            q_data_2        <=  q_data;

            if (q_last) begin   // First delayed Last
                q_data      <= '0;
                q_valid     <= '0;
                q_last      <= '0;

                q_last_2    <= '1;
            end
        end


        if (q_valid_2) begin    // Second delayed valid
            
            if (w_min_check) begin
                w_buf_min   <= q_data_2;
            end
            
            if (q_last_2) begin     // Second delayed Last
                q_data_2    <= '0;
                q_valid_2   <= '0;
                q_last_2    <= '0;

                w_last      <= q_last_2;  
            end
        end


        if (w_last) begin   // Final delayed Last
            
            o_min_data      <= w_buf_min;
            o_valid         <= '1;
            w_last          <= '0;
            w_min_check     <= '0;
        end


        if (o_valid) begin
            
            w_buf_min   <= '1;
            o_valid     <= '0;
            o_min_data  <= '0;
        end
    end
endmodule
