`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/05/2024 01:13:01 PM
// Design Name: 
// Module Name: tb_max
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


module tb_max#(
        parameter int G_BYT = 1,
        parameter int G_BIT_WIDTH = 8 * G_BYT
    )(

    );

    localparam       T_CLK       = 1.0;
    logic   [7:0]    q_cnt       = '0;
    logic   [7:0]    q_data_cnt  = '0;
    logic   [7:0]    i = '0;

    logic                   i_clk   = '0;
    logic                   i_rst   = '0;
    logic      [7:0]        i_data  = '0;
    logic                   i_valid = '0;
    logic                   i_last  = '0;

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
        
    
    task send_max_check;
        begin
            #(T_CLK*5);
            i_valid <= '1;
            for (int i = 1; i < 11; i++) begin
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
    endtask : send_max_check


    always#(T_CLK/2.0) i_clk <= ~i_clk;

    task data_4;
        begin
            if (q_cnt == 4 && q_data_cnt < 10) begin
                i_valid     <= '1;
                i_data      <= i;
                q_data_cnt  <= q_data_cnt + 1;
                i <= i + 1;

            end
            else begin
                i_valid     <= '0;

            end

            if (q_data_cnt >= 10) begin
                i_data      <= '0;
        
            end
        end
    endtask 
    
    always_ff@(posedge i_clk) begin
        if (q_cnt < 4) begin
            q_data_cnt  <= q_data_cnt + 1;
            i           <= i + 1;
            q_cnt       <= q_cnt + 1;
        end
        if (q_data_cnt < 20 && q_cnt == 4) begin
            i_valid     <= '1;
            i_data      <=  i;
            q_cnt       <= '0;

        end

        if (q_data_cnt >= 20) begin
            i_data      <= '0;
            i_last      <= '1;
            q_data_cnt  <= '0;
            i           <= '0;
            i_valid     <= '0;
        end

        if (i_last) begin
            i_last      <= '0;
        end
    end

    max#(
        .G_BIT_WIDTH    (G_BIT_WIDTH)
    ) MAX (
        .i_clk      (i_clk),
        .i_rst      (i_rst),
        .i_data     (i_data),
        .i_valid    (i_valid),
        .i_last     (i_last),

        .o_max_data (o_max_data),
        .o_valid    (o_valid)
    );
endmodule
