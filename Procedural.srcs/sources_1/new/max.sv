`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 06/05/2024 12:59:57 PM
// Module Name: max
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: Calculate Maximum data from datapack
// 
// Dependencies: None
// 
// Revision:
// Revision 0.11 - Calculating maximum
// Additional Comments: TODO reset flag
// 
//////////////////////////////////////////////////////////////////////////////////


module max#(
        parameter int G_BIT_WIDTH   = 8
    )(
        input logic                     i_clk,
        input logic                     i_rst,
        input logic [G_BIT_WIDTH-1:0]   i_data,
        input logic                     i_valid,
        input logic                     i_last,

        output logic                    o_valid     = '0,
        output logic [G_BIT_WIDTH-1:0]  o_max_data  = '0
    );

    logic [G_BIT_WIDTH-1:0] w_buf_max       = '0;
    logic                   w_max_check     = '0;
    logic                   w_last          = '0;

    logic                   q_valid         = '0;
    logic [G_BIT_WIDTH-1:0] q_data          = '0;
    logic                   q_last          = '0;

    logic                   q_valid_2       = '0;
    logic [G_BIT_WIDTH-1:0] q_data_2        = '0;
    logic                   q_last_2        = '0;

    always_ff @(i_clk) begin : maximum
        
        if (i_valid) begin
            
            q_valid     <= i_valid;
            q_data      <= i_data;     

            q_last      <= (i_last) ? 1 : 0;
        end
        
        if (q_valid) begin          
            
            w_max_check     <= (w_buf_max < q_data) ? 1 : 0;
            q_valid_2       <=  q_valid;
            q_data_2        <=  q_data;

            if (q_last) begin
                q_data      <= '0;
                q_valid     <= '0;
                q_last      <= '0;

                q_last_2    <= '1;
            end
        end

        if (q_valid_2) begin
            if (w_max_check) begin
                w_buf_max   <= q_data_2;
            end
            

            if (q_last_2) begin
                q_data_2    <= '0;
                q_valid_2   <= '0;
                q_last_2    <= '0;

                w_last      <= q_last_2;  
            end
            
        end

        if (w_last ) begin
                o_max_data      <= w_buf_max;
                o_valid         <= '1;
                w_last          <= '0;
                w_max_check     <= '0;
            end

        if (o_valid) begin
            w_buf_max   <= '0;
            o_valid     <= '0;
            o_max_data  <= '0;
        end
    end


endmodule
