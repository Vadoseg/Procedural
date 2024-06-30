/* `timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2024 03:10:24 PM
// Design Name: 
// Module Name: tb_proc_reg_map
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


module tb_proc_reg_map#(
    parameter int DW                =  16, // data bit width
	parameter int G_ADDR_WIDTH      =  5,
	parameter int G_INDX_WIDTH      = 8,
	localparam int G_DW_WIRE_MEM    = DW + G_INDX_WIDTH,
	parameter int G_MODS            = 4,

    real dt = 1.0 // clock period, nss
    )(

    );

    logic i_clk = '0;

    always #(dt/2.0) i_clk = ~i_clk; // simulate clock

    if_axil #(
		.N(G_DATA_B), 
		.A(G_ADDR_W), 
		.PAYMASK(5'b01101)) m_axil ();

    typedef logic [G_ADDR_W - 1 : 0] t_xaddr;
	typedef logic [C_DATA_W - 1 : 0] t_xdata;

    task t_axil_m_init;
		begin
			m_axil.awvalid = '0;
			m_axil.awaddr  = '0;
			m_axil.wvalid  = '0;
			m_axil.wdata   = '0;
			m_axil.wstrb   = '0;
			m_axil.bready  = '1;
			m_axil.arvalid = '0;
			m_axil.araddr  = '0;
			m_axil.rready  = '0;
		end
	endtask : t_axil_m_init

    `define MACRO_AXIL_HSK(name, miso, mosi) \
		``name``.``mosi``= '1; \
		do begin \
			#(dt); \
		end while (!(``name``.``miso`` && ``name``.``mosi``)); \
		``name``.``mosi`` = '0; \

	task t_axil_m_wr;
		input t_xaddr ADDR;
		input t_xdata DATA;
		begin

		// write address
			m_axil.awaddr = ADDR;
			`MACRO_AXIL_HSK(m_axil, awready, awvalid);
		// write data
			m_axil.wdata = DATA;
			m_axil.wstrb = '1;
			`MACRO_AXIL_HSK(m_axil, wready, wvalid);
		// write response
			`MACRO_AXIL_HSK(m_axil, bvalid, bready);

		end
	endtask : t_axil_m_wr

	task t_axil_m_rd;
		input  t_xaddr ADDR;
		begin

		// read address
			m_axil.araddr = ADDR;
			`MACRO_AXIL_HSK(m_axil, arready, arvalid);
		// read data
			`MACRO_AXIL_HSK(m_axil, rvalid, rready);
		
		end
	endtask : t_axil_m_rd

    localparam t_xaddr	TST_ADDR1   = 'h01; 
    localparam t_xaddr 	TST_ADDR2	= 'h02;
	localparam t_xaddr  TST_ADDR3   = 'h03;
    localparam t_xaddr 	TST_ADDR4	= 'h04; 
	localparam t_xaddr  WRN_ADDR1   = 'h05;
    localparam t_xaddr 	WRN_ADDR2	= 'h06;
	localparam t_xaddr  WRN_ADDR3   = 'h07;
    localparam t_xaddr 	WRN_ADDR4	= 'h08;

    initial begin
        t_axil_m_init; #10.1;

		t_axil_m_wr(.ADDR(TST_ADDR1), .DATA(111)); 	#10;			// 1
		t_axil_m_wr(.ADDR(TST_ADDR2), .DATA(222)); 	#10;			// 2
		t_axil_m_wr(.ADDR(WRN_ADDR1), .DATA(333));	#10;			// 5
		t_axil_m_wr(.ADDR(WRN_ADDR2), .DATA(333)); 	#10;			// 6

		t_axil_m_rd(.ADDR(TST_ADDR3)); 				#10;			// 7
		t_axil_m_rd(.ADDR(TST_ADDR4)); 				#10;			// 8
		t_axil_m_rd(.ADDR(WRN_ADDR3));				#10;			// 9
		t_axil_m_rd(.ADDR(WRN_ADDR4)); 				#10;			// 10
    end

    proc_reg_map #(
		.G_MODS             (G_MODS       ),
        .G_DW_WIRE_MEM      (G_DW_WIRE_MEM),
        .G_INDX_WIDTH       (G_INDX_WIDTH ),
        .G_BIT_WIDTH        (DW           )
	) u_uut_2 (
        .i_clk                  (i_clk),

        //.o_mem_ready_min_max    (s_min_max_ready),
        .i_mem_data_min_max     (w_arr_max_min  ),
        //.o_mem_ready_avg        (s_avg_ready    ),
        .i_mem_data_avg         (w_arr_avg      ),

		.s_axil_araddr		    (m_axil.araddr  ),
        .s_axil_awaddr          (m_axil.awaddr  ),
        .s_axil_awvalid         (m_axil.awvalid ),
        .s_axil_wvalid          (m_axil.wvalid  ),
        .s_axil_arvalid         (m_axil.arvalid ),
        .s_axil_rvalid          (m_axil.rvalid  ),

        .s_axil_rdata           (o_prcdrl_data  )
        //bready

	);
endmodule
 */