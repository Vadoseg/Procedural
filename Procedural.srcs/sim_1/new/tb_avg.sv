`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2024 01:13:01 PM
// Design Name: 
// Module Name: tb_avg
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


module tb_avg#(
        parameter int G_BYT       = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT
    )(

    );

    localparam T_CLK = 1.0;
    logic i_clk = '0;
    logic i_rst = '0;
    logic [G_BIT_WIDTH-1:0] i_data = '0;
    logic i_valid = '0;
    logic i_last  = '0;

    task send_data_pkt;
        begin
            #(T_CLK*5);
            i_valid <= '1;
            for (int i = 1; i < 11; i++) begin
                i_data <= i;
                #(T_CLK/2.0);  
            end
            i_last <= '1;
            i_data <= 24;
            #(T_CLK/2.0);
            i_valid <= '0;
            i_data  <= '0;
            i_last  <= '0;
        end   
    endtask : send_data_pkt

    always#(T_CLK/2.0) i_clk <= ~i_clk;

    initial begin
        for (int i = 0; i < 5; i++) begin
            send_data_pkt;
            #(T_CLK * 10);
        end
        
        //send_data_pkt;
    end


    avg #(
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) AVG (
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_data     (i_data),
        .i_valid    (i_valid),
        .i_last     (i_last),

        .o_avg_data (o_avg_data),
        .o_valid    (o_valid)
    );
endmodule
