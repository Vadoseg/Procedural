`timescale 1ns / 1ps

module tb_max_min #(
	parameter bit G_OPER_MODE = '1, // operating mode: 0 = min, 1 = max
	parameter int G_BIT_WIDTH =  8, // data bit width

	real dt = 1.0 // clock period, ns
);

logic i_clk = '0;

always #(dt/2.0) i_clk = ~i_clk; // simulate clock

logic                          i_valid = '0;
logic                          i_last  = '0;
logic signed [G_BIT_WIDTH-1:0] i_data  = '0;

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

// simulate input data
initial begin
	t_init; #(9.6 * dt);
	
	t_pkt(.G_DATA({+4, -8, +3, -5, +11, -2, +10, -13})); //#(10 * dt);
	t_pkt(.G_DATA({-4, +8, -3, +5, -11, +2, -10, +13})); //#(10 * dt);
	t_pkt(.G_DATA({+4, -8, +3, -5, +11, -2, +10, -13})); //#(10 * dt);
	t_pkt(.G_DATA({-4, +8, -3, +5, -11, +2, -10, +13})); #(10 * dt);
end

// unit under test: find max value
	max_min #(
		.G_OPER_MODE (G_OPER_MODE), // Operating mode: min = 0, max = 1 
		.G_BIT_WIDTH (G_BIT_WIDTH)  // data bit width
	) MAX_MIN (
		.i_clk   (i_clk  ),
		.i_valid (i_valid),
		.i_last  (i_last ),
		.i_data  (i_data )
	);

endmodule : tb_max_min
