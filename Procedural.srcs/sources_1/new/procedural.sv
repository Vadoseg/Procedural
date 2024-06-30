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
        parameter int G_BYT             = 2,                        
        parameter int G_BIT_WIDTH       = 8 * G_BYT,                
        parameter int G_MAX_MIN_MODS    = 2,                        // Number of Maximum/Minimum Modules
        parameter int G_CHAN_NUM        = 4,                        // Number of channels
        parameter int G_ADDR_WIDTH      = 5,                        // Address width
        parameter int G_MODS            = 4,                        // Number to generate modules
        parameter int G_OUT_DATA        = 2**G_ADDR_WIDTH,          // DW for output data
        
        parameter int G_INDX_WIDTH      = 8                         // DW of INDX from max_min      
    )(
        input wire                          i_clk,
        input wire                          i_rst,
        input logic  [G_BIT_WIDTH-1:0 ]     i_data_fft = '0,
        input wire                          i_valid,
        input wire                          i_last,

        input wire                          i_arvalid,
        input wire   [G_INDX_WIDTH-1:0]     i_araddr,
        input wire                          i_rready,

        output logic  [G_OUT_DATA*2-1:0]    o_proc_data
    );

    genvar i,k;

    logic [G_BIT_WIDTH-1:0]     cnt     = '0;
    logic [G_CHAN_NUM-1:0 ]     q_last  = '0;

    localparam int G_DW_WIRE_MEM        = G_BIT_WIDTH + G_INDX_WIDTH;  // DW for wire that connects max_min and mem, also this DW will transmit in G_DATA_WIDTH for mem connected with max_min
 

    always_ff @(posedge i_clk) begin
        if (i_valid) begin
            cnt <= cnt + 1;
        end 
        if (i_last) begin 
            cnt <= '0;
        end 
        q_last <= {q_last[$size(q_last)-2:0], i_last & i_valid};
        if (cnt == G_MODS-1 ) begin // cnt == 3
            cnt <= '0;
        end
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
                    .i_rst          (i_rst              ),
                    .i_data         (i_data_fft         ),
                    .i_valid        (i_valid && cnt == i),
                    .i_last         (q_last[i]          ),

                    .o_valid        (o_valid            ),
                    .o_res_data     (w_res_data [G_MODS*k+i]),
                    .o_indx_data    (w_indx_data[G_MODS*k+i])
                 );
        
                assign w_wr_data[G_MODS*k+i] = {w_res_data[G_MODS*k+i], w_indx_data[G_MODS*k+i]};
            
                mem #(
                    .G_DATA_WIDTH   (G_DW_WIRE_MEM),
                    .G_ADDR_WIDTH   (G_ADDR_WIDTH )
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
                .i_rst          (i_rst              ),
                .i_data         (i_data_fft         ),
                .i_valid        (i_valid && cnt == i),
                .i_last         (q_last[i]          ),
                
                .o_valid        (o_valid            ),
                .o_avg_data     (w_avg_data         )
            );

            wire [G_BIT_WIDTH-1:0  ]    w_avg_data      = '0;
            
            mem #(
                .G_DATA_WIDTH   (G_BIT_WIDTH ),
                .G_ADDR_WIDTH   (G_ADDR_WIDTH)
            ) MEM_AVG (
                .i_clk          (i_clk      ),
                .i_wr_data      (w_avg_data ),
                .i_wr_valid     (o_valid    ),
                .i_rd_valid     (s_avg_ready[G_MODS+i]),

                .o_rd_data      (m_avg_data[G_DW_WIRE_MEM*i+:G_DW_WIRE_MEM])
            );

            assign  w_arr_avg[i] = m_avg_data[G_DW_WIRE_MEM*i+:G_DW_WIRE_MEM];

        end : block
    endgenerate


    proc_reg_map #(
        .G_MODS             (G_MODS       ),
        .G_DW_WIRE_MEM      (G_DW_WIRE_MEM),
        .G_INDX_WIDTH       (G_INDX_WIDTH ),
        .G_BIT_WIDTH        (G_BIT_WIDTH  )
    ) REG_MAP (
        .i_clk                  (i_clk),

        .o_mem_ready_min_max    (s_min_max_ready),
        .i_mem_data_min_max     (w_arr_max_min  ),
        .o_mem_ready_avg        (s_avg_ready    ),
        .i_mem_data_avg         (w_arr_avg      ),

        .s_axil_araddr          (i_araddr       ),
        .s_axil_arvalid         (i_arvalid      ),
        .s_axil_rready          (i_rready       ),
        .s_axil_rdata           (o_proc_data    )
        
    );

endmodule
