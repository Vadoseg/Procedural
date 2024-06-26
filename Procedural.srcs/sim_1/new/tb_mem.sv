`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/25/2024 05:19:56 PM
// Design Name: 
// Module Name: tb_mem
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


module tb_mem#(
        parameter int G_BIT_WIDTH   = 16,
        parameter int G_INDX_WIDTH  =  8,
        parameter int G_ADDR_WIDTH  =  5,
        parameter int G_MEM_DEPTH   =  2**G_ADDR_WIDTH
    )(

    );

    localparam dt = 1.0;
    
    bit i_clk, i_wr_valid, i_rd_valid;
    
    logic [ G_BIT_WIDTH-1:0] i_wr_data;
    logic [G_INDX_WIDTH-1:0] i_indx_data;
    logic [ G_BIT_WIDTH-1:0][0:G_MEM_DEPTH-1] o_rd_data;


    always #(dt/2.0) i_clk <= ~i_clk;

// initialize input
task t_init;
	begin
		i_wr_valid  = '0;
        i_rd_valid  = '0;
		i_wr_data   = '0;
        i_indx_data = '0;
	end
endtask : t_init

// simulate packet
task send_pkt;

	input int G_DATA [];
	begin
		for (int i = 0; i < $size(G_DATA); i++) begin
			
			i_wr_valid  = '1;
			i_wr_data   = G_DATA[i];
            i_indx_data = i;
			#(dt);
			i_wr_valid  = '0;
			#(3 * dt);

		end
	end
endtask : send_pkt

// getting packet
task get_pkt;
    i_rd_valid = '1;
    #(dt*100);
endtask : get_pkt

    initial begin
        t_init; #(dt * 10);
        send_pkt(.G_DATA({+4, -8, +3, -5, +11, -2, +10, -13}));
        get_pkt;
    end

    mem#(

    ) MEM (
        .i_clk          (i_clk      ),
        .i_wr_valid     (i_wr_valid ),
        .i_wr_data      (i_wr_data  ),
        .i_indx_data    (i_indx_data),
        .i_rd_valid     (i_rd_valid ),

        .o_rd_data      (o_rd_data  )
    );
endmodule
