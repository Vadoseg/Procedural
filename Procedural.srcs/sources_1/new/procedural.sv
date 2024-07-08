`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Vadim V. Hvatov
// 
// Create Date: 06/05/2024 12:59:57 PM
// Module Name: procedural
// Project Name: Procedural
// Target Devices: 7Series+
// Tool Versions: 
// Description: 
// 
// Dependencies: divider.sv
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: TODO reset flag
// 
//////////////////////////////////////////////////////////////////////////////////


module procedural#(
        parameter   int     G_BYT             = 4,                        
        parameter   int     G_BIT_WIDTH       = 8 * G_BYT,                
        parameter   int     G_MAX_MIN_MODS    = 2,                        // Number of Maximum/Minimum Modules
        parameter   int     G_MEM_ADDR_WIDTH  = 5,                        // Address width for mem
        parameter   int     G_MODS            = 4,                        // Number to generate modules
        parameter   int     G_OUT_DATA        = 2**G_MEM_ADDR_WIDTH,      // DW for output data
        parameter   int     G_AXIL_ADDR_W     = 8,
        parameter   int     G_AXIL_DATA_W     = 64,
        parameter   int     G_CNT_W           = $ceil($clog2(G_MODS)),
        parameter   int     G_INDX_WIDTH      = 10                         // DW of INDX from max_min      
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

    genvar i,k;
    
    logic [G_CNT_W-1:0]     cnt     = '0;
    logic [G_MODS-1:0 ]     q_last  = '0;

    localparam int G_DW_WIRE_MEM        = G_BIT_WIDTH + G_INDX_WIDTH;  // DW for wire that connects max_min and mem, also this DW will transmit in G_DATA_WIDTH for mem connected with max_min
 

    always_ff @(posedge i_clk) begin
        if (s_tvalid) begin
            cnt <= cnt + 1;
        end 
        
        if (s_tlast || cnt == G_MODS-1) begin // cnt == 3
            cnt <= '0;
        end 
        
        q_last <= {q_last[$size(q_last)-2:0], s_tlast & s_tvalid};
    end    


    wire [G_BIT_WIDTH-1:0  ]    w_res_data  [0:G_MODS*2-1];
    wire [G_INDX_WIDTH-1:0 ]    w_indx_data [0:G_MODS*2-1];
    wire [G_DW_WIRE_MEM-1:0]    w_wr_data   [0:G_MODS*2-1];

    wire    [              2*G_MODS-1:0]   s_min_max_ready;
    wire    [G_DW_WIRE_MEM*2*G_MODS-1:0]   m_min_max_data;

    wire    [G_DW_WIRE_MEM-1:0]  w_arr_max_min   [0:G_MODS*2-1];
            

    wire    [              G_MODS-1:0]     s_avg_ready;
    wire    [G_BIT_WIDTH*2*G_MODS-1:0]     m_avg_data;

    wire    [G_BIT_WIDTH-1:0]  w_arr_avg   [0:G_MODS-1];
            
    wire    [G_BIT_WIDTH-1:0]   w_avg_data [0:G_MODS-1];
    generate
        for (i = 0; i < G_MODS; i+=1) begin : block
            (* keep_hierarchy="yes" *)
            for (k = 0; k < 2; k+=1) begin : min_max
                
                max_min #(
                    .G_OPER_MODE    (k           ),
                    .G_BIT_WIDTH    (G_BIT_WIDTH ),
                    .G_INDX_WIDTH   (G_INDX_WIDTH)
                ) MIN_MAX (
                    .i_clk          (i_clk              ),
                    .i_data         (s_tdata            ),
                    .i_valid        (s_tvalid && cnt == i),
                    .i_last         (q_last[i]          ),

                    .o_valid        (o_valid            ),
                    .o_res_data     (w_res_data [G_MODS*k+i]),
                    .o_indx_data    (w_indx_data[G_MODS*k+i])
                 );
        
                assign w_wr_data[G_MODS*k+i] = {w_res_data[G_MODS*k+i], w_indx_data[G_MODS*k+i]};
            
                mem #(
                    .G_DATA_WIDTH   (G_DW_WIRE_MEM),
                    .G_ADDR_WIDTH   (G_MEM_ADDR_WIDTH )
                ) MEM_MIN_MAX (
                    .i_clk          (i_clk      ),
                    .i_wr_data      (w_wr_data[G_MODS*k+i]),
                    .i_wr_valid     (o_valid    ), 
                    .i_rd_valid     (s_min_max_ready[G_MODS*k+i]),
                    
                    .o_rd_data      (m_min_max_data[G_DW_WIRE_MEM*(G_MODS*k+i)+:G_DW_WIRE_MEM])
                );
                
                assign  w_arr_max_min[G_MODS*k+i] = m_min_max_data[G_DW_WIRE_MEM*(G_MODS*k+i)+:G_DW_WIRE_MEM];
            end : min_max

    
            avg #(
                .G_BIT_WIDTH    (G_BIT_WIDTH)
            ) AVG (
                .i_clk          (i_clk              ),
                .i_data         (s_tdata            ),
                .i_valid        (s_tvalid && cnt == i),
                .i_last         (q_last[i]          ),
                
                .o_valid        (o_valid            ),
                .o_avg_data     (w_avg_data[i]         )
            );
            
            mem #(
                .G_DATA_WIDTH   (G_BIT_WIDTH ),
                .G_ADDR_WIDTH   (G_MEM_ADDR_WIDTH)
            ) MEM_AVG (
                .i_clk          (i_clk      ),
                .i_wr_data      (w_avg_data[i] ),
                .i_wr_valid     (o_valid    ),
                .i_rd_valid     (s_avg_ready[i]),

                .o_rd_data      (m_avg_data[G_DW_WIRE_MEM*i+:G_DW_WIRE_MEM])
            );

            assign  w_arr_avg[i] = m_avg_data[G_DW_WIRE_MEM*i+:G_DW_WIRE_MEM];

        end : block
    endgenerate


    Rega #(
        .C_S_AXI_DATA_WIDTH (G_AXIL_DATA_W),
        .C_S_AXI_ADDR_WIDTH (G_AXIL_ADDR_W),
        .G_MODS             (G_MODS       ),
        .G_DW_WIRE_MEM      (G_DW_WIRE_MEM),
        .G_INDX_WIDTH       (G_INDX_WIDTH ),
        .G_BIT_WIDTH        (G_BIT_WIDTH  )
    ) REGA (
        .S_AXI_ACLK                  (i_clk ),
        .S_AXI_ARESETN              (i_rst_n),            //active-low

        .o_mem_ready_min_max    (s_min_max_ready),
        .i_mem_data_min_max     (w_arr_max_min  ),
        .o_mem_ready_avg        (s_avg_ready    ),
        .i_mem_data_avg         (w_arr_avg      ),

        .S_AXI_AWREADY         (s_axil_awready),     // Output
        .S_AXI_AWVALID         (s_axil_awvalid),     // Input
        .S_AXI_AWADDR          (s_axil_awaddr ),     // Input
        .S_AXI_AWPROT          (s_axil_awprot ),     // Input


        .S_AXI_WREADY          (s_axil_wready ),     // Output
        .S_AXI_WVALID          (s_axil_wvalid ),     // Input
        .S_AXI_WDATA           (s_axil_wdata  ),     // Input
        .S_AXI_WSTRB           (s_axil_wstrb  ),     // Input


        .S_AXI_BREADY          (s_axil_bready ),     // Input
        .S_AXI_BVALID          (s_axil_bvalid ),     // Output
        .S_AXI_BRESP           (s_axil_bresp  ),     // Output


        .S_AXI_ARREADY         (s_axil_arready),     // Output
        .S_AXI_ARVALID         (s_axil_arvalid),     // Input
        .S_AXI_ARADDR          (s_axil_araddr ),     // Input
        .S_AXI_ARPROT          (s_axil_arprot ),     // Input

        
        .S_AXI_RREADY          (s_axil_rready ),     // Input
        .S_AXI_RVALID          (s_axil_rvalid ),     // Output
        .S_AXI_RDATA           (s_axil_rdata  ),     // Output
        .S_AXI_RRESP           (s_axil_rresp  )     // Output
    

    );

endmodule

