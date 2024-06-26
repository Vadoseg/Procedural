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
        parameter int G_BYT         = 2,            // Maybe 2 bcs i_data_fft will be [16-1:0]
        parameter int G_BIT_WIDTH   = 8 * G_BYT,
        parameter int G_MAX_MODS    = 4,            // Number of Maximum Modules
        parameter int G_MIN_MODS    = 4,            // Number of Minimum Modules
        parameter int G_CHAN_NUM    = 4,            // Number of channels
        parameter int G_CHAN_IDX    = 0,            // Channel number
        parameter int G_ADDR_WIDTH  = 5,            // Address width
        parameter int G_MEM_MODS    = 12            // Number of Memory Modules
    )(
        input wire                      i_clk,
        input wire                      i_rst,
        input logic  [G_BIT_WIDTH-1:0]  i_data_fft = '0, // Later make signed
        input wire                      i_valid,
        input wire                      i_last,


        output logic [2:0]              o_data_proc = '0   // Data from max, min, avg
    );

    genvar i;
    logic [G_BIT_WIDTH-1:0] cnt     = '0;
    logic [G_CHAN_NUM-1:0]  q_last  = '0;

    always_ff @(posedge i_clk) begin
        if (i_valid) begin
            cnt <= cnt + 1;
        end 
        if (i_last) begin 
            cnt <= '0;
        end 
        q_last <= {q_last[$size(q_last)-2:0], i_last & i_valid};
        if (cnt == G_MAX_MODS-1 ) begin // cnt == 3
            cnt <= '0;
        end
    end    
    

    (* keep_hierarchy="yes" *)
    generate 
        for (i = 0; i < G_MAX_MODS; i+=1) begin : max
            max_min #(
                .G_OPER_MODE    ('1         ),
                .G_BIT_WIDTH    (G_BIT_WIDTH)
            ) MAX (
                .i_clk          (i_clk              ),
                .i_rst          (i_rst              ),
                .i_data         (i_data_fft         ),
                .i_valid        (i_valid && cnt == i),
                .i_last         (q_last[i]          ),

                .o_valid        (o_valid            ),
                .o_res_data     (o_res_data         ),
                .o_indx_data    (o_indx_data        )
            );
        end : max
    endgenerate
    
    (* keep_hierarchy="yes" *)
    generate 
        for (i = 0; i < G_MIN_MODS; i+=1) begin : min
            max_min #(
                .G_OPER_MODE    ('0         ),
                .G_BIT_WIDTH    (G_BIT_WIDTH)
            ) MIN (
                .i_clk          (i_clk              ),
                .i_rst          (i_rst              ),
                .i_data         (i_data_fft         ),
                .i_valid        (i_valid && cnt == i),
                .i_last         (q_last[i]          ),

                .o_valid        (o_valid            ),
                .o_res_data     (o_res_data         ),
                .o_indx_data    (o_indx_data        )
            );
        end : min
    endgenerate

    (* keep_hierarchy="yes" *)
    generate
        for (i = 0; i < G_MIN_MODS; i+=1) begin : avg 
            avg #(
                .G_BIT_WIDTH    (G_BIT_WIDTH)
            ) AVG (
                .i_clk          (i_clk              ),
                .i_rst          (i_rst              ),
                .i_data         (i_data_fft         ),
                .i_valid        (i_valid && cnt == i),
                .i_last         (q_last[i]          ),
                
                .o_valid        (o_valid            ),
                .o_avg_data     (o_res_data         )
                // .o_indx_data    (o_indx_data        )
            );
        end : avg
    endgenerate

    (* keep_hierarchy="yes" *)
    generate
        for (i = 0; i < G_MEM_MODS; i+=1) begin : mem
            mem #(
                .G_BIT_WIDTH    (G_BIT_WIDTH ),
                .G_ADDR_WIDTH   (G_ADDR_WIDTH)
            ) MEM (
                .i_clk          (i_clk      ),
                .i_wr_data      (o_res_data ),
                .i_wr_valid     (o_valid    ),
                .i_indx_data    (o_indx_data),

                .o_rd_data      (o_rd_data  )
            );
        end : mem
    endgenerate
    
    // TODO:
    //  1. Remake testbenches for every 4 clk
    //  2. Make constrains (timing) clk
    //  3. Move last (Under clk, after vld??, under vld)
    //  4. Shift Reg
    //  5. Rework all modules 

    //Connect REG_MAP by AXIL_INTERFACE
    // MAKE PLAN
endmodule
