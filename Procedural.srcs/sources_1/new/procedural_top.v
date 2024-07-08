`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 07/01/2024 12:52:03 PM
// Module Name: procedural_top
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: Wrapper for procedural.sv
// 
// Dependencies: procedural.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: 
// 
//////////////////////////////////////////////////////////////////////////////////


module procedural_top#(
        parameter   integer     G_BYT             = 4,                        
        parameter   integer     G_BIT_WIDTH       = 8 * G_BYT,                
        parameter   integer     G_MAX_MIN_MODS    = 2,                        // Number of Maximum/Minimum Modules
        parameter   integer 	G_MEM_ADDR_WIDTH  = 5,                        // Address width for mem
        parameter   integer 	G_MODS            = 4,                        // Number to generate modules
        parameter   integer     G_OUT_DATA        = 2**G_MEM_ADDR_WIDTH,      // DW for output data

        parameter   integer     G_AXIL_ADDR_W     = 8,
        parameter   integer     G_AXIL_DATA_W     = 64,
        
        parameter   integer     G_INDX_WIDTH      = 10                         // DW of INDX from max_min      
    )(
        input   wire                                i_clk,
        input   wire                                i_rst_n,
        
        input   wire    [  G_BIT_WIDTH - 1 : 0]     s_tdata,
        input   wire                                s_tvalid,
        input   wire                                s_tlast,


        output  wire                                s_axil_awready,
        input   wire                                s_axil_awvalid,
        input   wire    [G_AXIL_ADDR_W - 1 : 0]     s_axil_awaddr,
        input   wire    [                2 : 0]     s_axil_awprot,

        output  wire                                s_axil_wready,
        input   wire                                s_axil_wvalid,
        input   wire    [G_AXIL_DATA_W - 1 : 0]     s_axil_wdata,
        input   wire    [G_AXIL_ADDR_W - 1 : 0]     s_axil_wstrb,

        input   wire                                s_axil_bready,
        output  wire                                s_axil_bvalid,
        output  wire    [                1 : 0]     s_axil_bresp,

        output  wire                                s_axil_arready,
        input   wire                                s_axil_arvalid,
        input   wire    [G_AXIL_ADDR_W - 1 : 0]     s_axil_araddr,
        input   wire    [                2 : 0]     s_axil_arprot,

        input   wire                                s_axil_rready,
        output  wire                                s_axil_rvalid,
        output  wire    [G_AXIL_DATA_W - 1 : 0]     s_axil_rdata,
        output  wire    [                1 : 0]     s_axil_rresp
    );

    procedural #(
        .G_BYT                  (G_BYT           ), 
        .G_BIT_WIDTH            (G_BIT_WIDTH     ),
        .G_MAX_MIN_MODS         (G_MAX_MIN_MODS  ),
        .G_CHAN_NUM             (G_CHAN_NUM      ),
        .G_MEM_ADDR_WIDTH       (G_MEM_ADDR_WIDTH),
        .G_MODS                 (G_MODS          ),
        .G_OUT_DATA             (G_OUT_DATA      ),

        .G_AXIL_ADDR_W          (G_AXIL_ADDR_W   ),
        .G_AXIL_DATA_W          (G_AXIL_DATA_W   ),
            
        .G_INDX_WIDTH           (G_INDX_WIDTH    )

    ) Procedural (
        .i_clk                  (i_clk          ),
        .i_rst_n                (i_rst_n        ),
        
        .s_tdata                (s_tdata        ),
        .s_tvalid               (s_tvalid       ),
        .s_tlast                (s_tlast        ),


        .s_axil_awready         (s_axil_awready),     // Output
        .s_axil_awvalid         (s_axil_awvalid),     // Input
        .s_axil_awaddr          (s_axil_awaddr ),     // Input
        .s_axil_awprot          (s_axil_awprot ),     // Input


        .s_axil_wready          (s_axil_wready ),     // Output
        .s_axil_wvalid          (s_axil_wdata  ),     // Input
        .s_axil_wdata           (s_axil_wdata  ),     // Input
        .s_axil_wstrb           (s_axil_wstrb  ),     // Input


        .s_axil_bready          (s_axil_bready ),     // Input
        .s_axil_bvalid          (s_axil_bvalid ),     // Output
        .s_axil_bresp           (s_axil_bresp  ),     // Output


        .s_axil_arready         (s_axil_arready),     // Output
        .s_axil_arvalid         (s_axil_arvalid),     // Input
        .s_axil_araddr          (s_axil_araddr ),     // Input
        .s_axil_arprot          (s_axil_arprot ),     // Input

        
        .s_axil_rready          (s_axil_rready ),     // Input
        .s_axil_rvalid          (s_axil_rvalid ),     // Output
        .s_axil_rdata           (s_axil_rdata  ),     // Output
        .s_axil_rresp           (s_axil_rresp  )      // Output

    );
endmodule
