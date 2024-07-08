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
        parameter int G_DATA_WIDTH  = 24,
        parameter int G_ADDR_WIDTH  =  5,
        
        localparam int G_MEM_DEPTH   =  2**G_ADDR_WIDTH
    )(
        input   wire                        i_clk,
        input   wire                        i_wr_valid,     // Valid for input writing
        input   wire   [G_DATA_WIDTH-1:0]   i_wr_data,      // Input Writing data
        input   wire                        i_rd_valid,     // Valid for output reading

        output  logic  [G_DATA_WIDTH-1:0]   o_rd_data       // Output reading data

    );

    reg     [G_ADDR_WIDTH-1:0]   q_wr_addr                  = '0;
    reg     [G_ADDR_WIDTH-1:0]   q_wr_addr_prev             = '0;
    reg     [G_ADDR_WIDTH-1:0]   q_r_addr                   = '0; 
    
    reg     [G_DATA_WIDTH-1:0]   q_mem [0:G_MEM_DEPTH-1]    = '{default:G_DATA_WIDTH'(1'b0)};

    always_ff@(posedge i_clk) begin
        
        if(i_wr_valid) begin
            q_wr_addr           <= q_wr_addr + 1;
            q_mem[q_wr_addr]    <= i_wr_data;
            q_wr_addr_prev      <= q_wr_addr;
            
        end

        if(i_rd_valid && q_r_addr < q_wr_addr_prev) begin
            q_r_addr    <=  q_r_addr + 1;
            
        end
        
        o_rd_data       <=  q_mem[q_r_addr];
    end
endmodule
