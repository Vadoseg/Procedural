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
	bit OPMODE = '1, // operating mode: 0 = min, 1 = max
	int DW     =  8, // data bit width

	real dt = 1.0 // clock period, ns
);

logic i_clk = '0;

always #(dt/2.0) i_clk = ~i_clk; // simulate clock

logic                 i_valid = '0;
logic                 i_last  = '0;
logic signed [DW-1:0] i_data  = '0;

int file_randint, file_randint1, file_randint2, file_randint3;
int r;


// initialize input
task t_init;
	begin
		i_valid = '0;
		i_last  = '0;
		i_data  = '0;
	end
endtask : t_init

// simulate packet
task t_pkt;

	input int G_DATA [];
	begin
		for (int i = 0; i < $size(G_DATA); i++) begin
			
			//for (int i = 0; i < $size(G_DATA); i++) begin \\ k
			
			
			i_valid = '1;
			i_last  = (i == $size(G_DATA) - 1 /* && k == 3 */);
			i_data  = G_DATA[i];
			#(dt);
			i_valid = '0;
			i_last  = '0;
			#(3 * dt);
		end
	end
endtask : t_pkt

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
//		#(dt*5);

		// Reading files
		while (!$feof(file_randint)) begin
			i_valid = '1;
			i_last = '0;
			r = $fscanf(file_randint, "%d\s", i_data);
			//#(dt);
			// i_last <= $feof(file_randint) && !$feof(file_randint1);
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



// simulate input data
initial begin
	t_init; #(10 * dt);
	
	files_pkt;
	files_pkt;
	files_pkt;
	/* t_pkt(.G_DATA({+4, -8, +3, -5, +11, -2, +10, -13})); //#(10 * dt); */
	/* t_pkt(.G_DATA({-4, +8, -3, +5, -11, +2, -10, +13})); //#(10 * dt); */
	/* t_pkt(.G_DATA({+4, -8, +3, -5, +11, -2, +10, -13})); //#(10 * dt); */
	/* t_pkt(.G_DATA({-4, +8, -3, +5, -11, +2, -10, +13})); #(10 * dt); */
//	for (int k = 0; k < 8; k++) begin
//		t_pkt(.G_DATA({4, -8, 3, -5, 11, -2, 10})); #(10 * dt);
//	end
end

// unit under test: find max value
	procedural #(
		
	) u_uut (
		.i_clk          (i_clk  ),
		.i_valid        (i_valid),
		.i_last         (i_last ),
		.i_data_fft     (i_data )
	);

endmodule : tb_procedural

