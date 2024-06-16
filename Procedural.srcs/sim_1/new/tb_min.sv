`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2024 01:13:01 PM
// Design Name: 
// Module Name: tb_min
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


module tb_min#(
        parameter int G_BYT = 1,
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
                #(T_CLK/2.0);   // If data will be too fast, then we will lose first data in datapack
            end
            i_last <= '1;
            i_data <= 24;
            #(T_CLK/2.0);
            i_valid <= '0;
            i_data  <= '0;
            i_last  <= '0;
        end   
    endtask : send_data_pkt
        
    
    task send_min_check;
        begin
            #(T_CLK*5);
            i_valid <= '1;
            for (int i = 11; i > 1; i--) begin
                i_data <= i;
                #(T_CLK/2.0);  
            end
            
            i_data <= 24;
            #(T_CLK/2.0);
            i_data <= 1;
            #(T_CLK/2.0);
            i_data <= 23;
            #(T_CLK/2.0);
            i_data <= 10;
            #(T_CLK/2.0);
            i_last <= '1;
            i_data <= 5;
            #(T_CLK/2.0);
            i_valid <= '0;
            i_data  <= '0;
            i_last  <= '0;
        end   
    endtask : send_min_check


    always#(T_CLK/2.0) i_clk <= ~i_clk;


    initial begin
        send_data_pkt;
        #(T_CLK * 5);
        send_min_check;
    end

    min#(
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) MIN (
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_data     (i_data),
        .i_valid    (i_valid),
        .i_last     (i_last),

        .o_min_data (o_min_data),
        .o_valid    (o_valid)
    );
endmodule