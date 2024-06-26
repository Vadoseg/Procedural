`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 06/05/2024 12:59:57 PM
// Module Name: max_min
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: Calculate Maximum or Minimum data from datapack
// 
// Dependencies: None
// 
// Revision:
// Revision 0.11 - Calculating maximum or minimum
// Additional Comments: TODO reset flag
// 
//////////////////////////////////////////////////////////////////////////////////


module max_min#(
        parameter bit G_OPER_MODE   = '1,   // Operating mode: min = 0, max = 1
        parameter int G_BIT_WIDTH   =  16,    // data bit width
        parameter int G_INDX_WIDTH  =  8,
        parameter int G_CNT_WIDTH   =  8
    )(
        input wire                      i_clk  ,
        input wire                      i_rst  ,
        input wire   [G_BIT_WIDTH-1:0]  i_data ,
        input wire                      i_valid,
        input wire                      i_last ,

        output logic                    o_valid     = '0,
        output logic [G_BIT_WIDTH-1:0 ] o_res_data  = '0,
        output logic [G_INDX_WIDTH-1:0] o_indx_data = '0
    );

    localparam bit [G_BIT_WIDTH-1:0] C_RES_INIT =  {1'b1, {G_BIT_WIDTH-1{1'b0}}} ^ ~{G_BIT_WIDTH{G_OPER_MODE}};

// First delay
    reg                          q_valid         = '0;
    reg signed [G_BIT_WIDTH-1:0] q_data          = '0;
    reg                          q_last          = '0;

// Second delay
    reg                          q_valid_2       = '0;
    reg signed [G_BIT_WIDTH-1:0] q_data_2        = '0;
    reg signed [G_BIT_WIDTH-1:0] q_data_diff     = '0;  // Variable to calculate diff = q_buf - q_data
    reg                          q_last_2        = '0;

// Final delay
    reg signed [G_BIT_WIDTH-1:0] q_buf       = C_RES_INIT;
    reg                          w_last      = '0;

    logic      [G_CNT_WIDTH-1:0] q_data_cnt       = '0;
    reg        [G_CNT_WIDTH-1:0] q_cnt_buf        = '0;

    always_ff @(posedge i_clk) begin : maximum
        
        q_last      <= i_last;

        if (i_valid) begin  // Original valid 
            q_valid     <= i_valid;
            q_data      <= i_data;     
            
        end
        
        q_last_2    <= q_last;
        if (q_valid) begin  // First delayed Valid

            q_valid_2       <=  q_valid;
            q_data_diff     <=  q_buf - q_data;
            q_data_2        <=  q_data;

        end

        w_last      <= q_last_2;  
        if (w_last) begin
            q_buf       <= C_RES_INIT;
            q_data_cnt  <= '0;
            q_cnt_buf   <= '0;
        end
        else if (q_valid_2) begin    // Second delayed valid
            q_data_cnt <= q_data_cnt + 1;
            
            if (q_data_diff[G_BIT_WIDTH-1] ^ ~G_OPER_MODE) begin
                q_buf       <= q_data_2;
                q_cnt_buf   <= q_data_cnt + 1;

            end;
        end

        o_valid     <= w_last;
        if (w_last) begin   // Final delayed Last
            o_res_data      <= q_buf;
            o_indx_data     <= q_cnt_buf;
        end

    end
endmodule
