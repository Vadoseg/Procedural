`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 06/05/2024 12:59:57 PM
// Module Name: mem
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: Contains addressed data
// 
// Dependencies: None
// 
// Revision:
// Revision 0.11 - Contains addressed data
// Additional Comments: TODO reset flag
// 
//////////////////////////////////////////////////////////////////////////////////


module mem#(
        parameter int G_BIT_WIDTH   =  16,
        parameter int G_INDX_WIDTH  =  8,
        parameter int G_ADDR_WIDTH  =  5,
        parameter int G_MEM_DEPTH   =  2**G_ADDR_WIDTH
    )(
        input   wire                        i_clk,
        input   wire                        i_wr_valid,     // Valid for input writing
        input   wire   [ G_BIT_WIDTH-1:0]   i_wr_data,      // Input Writing data
        input   wire   [G_INDX_WIDTH-1:0]   i_indx_data,    // WHAT TO DO

        input   wire                        i_rd_valid,     // Valid for output reading

        output  logic    [ G_BIT_WIDTH-1:0] [0:G_MEM_DEPTH-1]   o_rd_data = '0    // Output reading data
    );                   // Maybe change types

    reg     [G_ADDR_WIDTH-1:0]   q_wr_addr                  = '0;
    reg     [G_ADDR_WIDTH-1:0]   q_r_addr                   = '0; 
    
    reg signed    [ G_BIT_WIDTH-1:0][0:G_MEM_DEPTH-1]    q_mem    = '0;

    reg                          q_vld                      = '0;
    reg     [G_INDX_WIDTH-1:0]   q_indx                     = '0;

    always_ff@(posedge i_clk) begin
        
        if(i_wr_valid) begin
            q_wr_addr             <= q_wr_addr + 1;
            q_mem [q_wr_addr]     <= i_wr_data;
            // q_mem [q_wr_addr]     <= i_wr_data + i_indx_data;
            // q_mem     <= i_indx_data;
            q_mem [q_wr_addr] [0:$size(q_mem)-16] <= i_wr_data;
            // q_mem /* [q_wr_addr]  */[16:$size(q_mem)-8] <= i_indx_data;
            // q_vld                 <= i_wr_valid;
            // q_indx                <= i_indx_data;
        end

        // if (q_vld) begin
        //     q_mem[q_wr_addr]        <= q_indx;
        //     q_wr_addr               <= q_wr_addr + 1;
        // end

        if(i_rd_valid /* && q_r_addr <= q_wr_addr */) begin
            o_rd_data[q_r_addr]   <=  q_mem[q_r_addr];
            q_r_addr    <=  q_r_addr + 1;
        end
        
    end

endmodule
