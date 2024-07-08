`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2024 01:13:01 PM
// Design Name: 
// Module Name: tb_procedural
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


module tb_procedural#(
	int DW     =  32, // data bit width
	parameter int G_ADDR_WIDTH  	= 5,
	parameter int G_INDX_WIDTH  	= 10,
	localparam int G_DW_WIRE_MEM    = DW + G_INDX_WIDTH,
	parameter int G_MODS            = 4,

	real dt = 1.0 // clock period, ns


);

logic i_clk = '0, i_rst = '0;

always #(dt/2.0) i_clk = ~i_clk; // simulate clock

logic                 i_valid = '0;
logic                 i_last  = '0;
logic signed [DW-1:0] i_data  = '0;

int file_randint, file_randint1, file_randint2, file_randint3;
int r;

logic ar_valid, ar_ready, r_ready;
logic [G_INDX_WIDTH-1:0]	ar_addr;

// initialize input
task t_init;
	begin
		i_valid 	= '0;
		i_last  	= '0;
		i_data  	= '0;
		ar_valid	= '0;
		r_ready		= '0;
	end
endtask : t_init

task files_pkt;
	begin
		// Open files for reading
		file_randint  = $fopen("randint.dat", "r");
		file_randint1 = $fopen("randint2.dat", "r");
		file_randint2 = $fopen("randint3.dat", "r");
        file_randint3 = $fopen("randint4.dat", "r");

		if (!file_randint || !file_randint1 || !file_randint2 || !file_randint3) begin
			$display("CAN'T OPEN FILE!");
			$finish;
		end

		
		// Reading files
		while (!$feof(file_randint)) begin
			i_valid = '1;
			i_last = '0;
			
			r = $fscanf(file_randint, "%d\s", i_data);
			r = $fscanf(file_randint1, "%d\s", i_data);
			#(dt);
			r = $fscanf(file_randint2, "%d\s", i_data);
			#(dt);
			r = $fscanf(file_randint3, "%d\s", i_data);

			i_last <= $feof(file_randint3);
			#(dt);

			i_last = '0;
			i_valid = '0;
		end

		// Closing files
		if($feof(file_randint)) begin
			$fclose(file_randint);
			$fclose(file_randint1);
			$fclose(file_randint2);
			$fclose(file_randint3);
		end
	end
endtask : files_pkt

task addr_read;
	ar_valid		<= '1;
	r_ready			<= '1;
	
	for (int i = 0; i < 256; i += 8) begin		// Found step by experiments, needed explanation
		ar_addr	= i;
		#(dt*8);
	end	
endtask	: addr_read

// simulate input data
initial begin
	t_init; #(10.6 * dt);
	i_rst	<= '1;

	files_pkt;
	files_pkt;
	files_pkt;

	addr_read;
	// i_rst	<= '0;
	#(dt);
	files_pkt;
	files_pkt;
	files_pkt;
	files_pkt;
	files_pkt;

	addr_read;
end

	procedural #(
		// .G_ADDR_WIDTH	(G_ADDR_WIDTH)

	) u_uut_procedural (
		.i_clk          	(i_clk   ),
		.i_rst_n			(i_rst   ),

		.s_tvalid       	(i_valid ),
		.s_tlast        	(i_last  ),
		.s_tdata     		(i_data  ),

		.s_axil_arvalid		(ar_valid),
		.s_axil_araddr		(ar_addr ),
		.s_axil_rready		(r_ready )
	);

endmodule : tb_procedural

