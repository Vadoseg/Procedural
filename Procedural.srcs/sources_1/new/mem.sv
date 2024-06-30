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
        // input wire i_mem_ready

        output  bit                         o_ar_valid  = '0,
        output  logic  [G_DATA_WIDTH-1:0]   o_rd_data   = '0    // Output reading data


        /* // Master
        input  reg  s_axil_awready,  output   wire s_axil_awvalid,  reg [G_ADDR_W - 1 : 0]  s_axil_awaddr,   logic  [2 : 0]             s_axil_awprot,          //  write addr
        input  reg  s_axil_wready,   output   wire s_axil_wvalid,   reg [G_DATA_W - 1 : 0]  s_axil_wdata,    reg    [G_DATA_B - 1 : 0]  s_axil_wstrb,           //  write data 
        output   wire s_axil_bready,   input  reg  s_axil_bvalid,   reg [1 : 0]             s_axil_bresp,                                                       //  write resp 
        input  reg  s_axil_arready,  output   wire s_axil_arvalid,  reg [G_ADDR_W - 1 : 0]  s_axil_araddr,   logic  [2 : 0]             s_axil_arprot,          //  read addr 
        output   wire s_axil_rready,  input  reg  s_axil_rvalid,   reg [G_DATA_W - 1 : 0]  s_axil_rdata,    reg    [1 : 0]             s_axil_rresp           //  read data & resp */

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
        o_ar_valid      <= '1;
    end
endmodule