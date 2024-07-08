`timescale 1ns / 1ps

module proc_reg_map #(
    
    int G_ADDR_W = 8,                    // AXIL xADDR bit width
	    G_DATA_B = 8,                    // AXIL xDATA number of bytes (B)
        G_MODS   = 4,                    
        G_INDX_WIDTH    = 10, 
        G_BIT_WIDTH     = 32,
        G_DW_WIRE_MEM   = 24,


    localparam int G_DATA_W = G_DATA_B << 3,       //  AXIL xDATA width
    localparam int G_ADDR_OFF = $ceil($clog2(G_DATA_B))

)(
    input   logic   i_clk,
                    i_aresetn,

    output logic [G_DATA_W-1:0]         o_mem_ready_min_max,
    output logic [G_DATA_W-1:0]         o_mem_ready_avg,
    input  logic [G_DW_WIRE_MEM-1:0]    i_mem_data_min_max      [0:G_MODS*2-1], 
    input  logic [  G_BIT_WIDTH-1:0]    i_mem_data_avg          [  0:G_MODS-1],


    //  slave AXI

    output  reg  s_axil_awready,  input   wire s_axil_awvalid,  reg [G_ADDR_W - 1 : 0]  s_axil_awaddr,   logic  [2 : 0]             s_axil_awprot,          //  write addr
    output  reg  s_axil_wready,   input   wire s_axil_wvalid,   reg [G_DATA_W - 1 : 0]  s_axil_wdata,    reg    [G_DATA_B - 1 : 0]  s_axil_wstrb,           //  write data 
    input   wire s_axil_bready,   output  reg  s_axil_bvalid,   reg [1 : 0]             s_axil_bresp,                                                       //  write resp 
    output  reg  s_axil_arready,  input   wire s_axil_arvalid,  reg [G_ADDR_W - 1 : 0]  s_axil_araddr,   logic  [2 : 0]             s_axil_arprot,          //  read addr 
    input   wire s_axil_rready,   output  reg  s_axil_rvalid,   wire [G_DATA_W - 1 : 0]  s_axil_rdata,    reg    [1 : 0]             s_axil_rresp           //  read data & resp

    );

    typedef logic [G_ADDR_W - 1 : 0] t_xaddr;
	typedef logic [G_DATA_W - 1 : 0] t_xdata; 

    t_xaddr     WADDR, RADDR;  

    t_xdata     q_wr_data = '0;
    t_xdata     q_rd_data = '0;

    assign s_axil_bresp = 2'b00;
    assign s_axil_rresp = 2'b00;

    reg q_rena = '0;

    wire    [63:0] w_map_max_min [0:G_MODS*2-1];
    wire    [63:0] w_map_avg     [0:G_MODS-1  ];


    for (genvar i = 0; i < G_MODS; i+=1) begin  : avg
        for (genvar k = 0; k < 2; k+=1) begin : max_min
            assign  w_map_max_min[G_MODS*k+i] = {16'(i_mem_data_min_max[i][G_INDX_WIDTH-1:0]), 48'(i_mem_data_min_max[i][G_DW_WIRE_MEM-1:G_INDX_WIDTH])};
        
        end : max_min
        
        assign  w_map_avg[i] = 64'(i_mem_data_avg[i]);
    
    end  : avg

    assign s_axil_rdata = q_rd_data;

    always_ff @(posedge i_clk) begin

        if (s_axil_awready & s_axil_awvalid) begin

            WADDR <= s_axil_awaddr;
        end

        if (s_axil_wready & s_axil_wvalid) begin

            q_wr_data <= s_axil_wdata;
        end

        if (s_axil_wready & s_axil_wvalid) begin

            s_axil_bvalid <= 1;
        end

        if (s_axil_bvalid & s_axil_bready) begin

            s_axil_bvalid <= 0;
        end 


        s_axil_arready <= '1;
        
        if (s_axil_arready & s_axil_arvalid) begin
            s_axil_arready <= '0;
            q_rena <= '1;
            RADDR <= s_axil_araddr;
            
        end

        o_mem_ready_min_max     <= '0; // reset read requests by default
        o_mem_ready_avg         <= '0;

        if (q_rena) begin

            case(RADDR[$size(RADDR)-1:G_ADDR_OFF]) // truncate address

                0 : begin
                    o_mem_ready_min_max[0]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[0];
                end

                1 : begin
                    o_mem_ready_min_max[1]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[1];
                end

                2 : begin
                    o_mem_ready_min_max[2]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[2];
                end

                3 : begin
                    o_mem_ready_min_max[3]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[3];
                end
                
                4 : begin
                    o_mem_ready_min_max[4]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[4];
                end
                
                5 : begin
                    o_mem_ready_min_max[5]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[5];
                end
                
                6 : begin
                    o_mem_ready_min_max[6]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[6];
                end
                
                7 : begin
                    o_mem_ready_min_max[7]  <= '1; // enable read request
                    q_rd_data               <= w_map_max_min[7];
                end
                
                8 : begin
                    o_mem_ready_avg[0]      <= '1; // enable read request
                    q_rd_data               <= w_map_avg[0];
                end

                9 : begin
                    o_mem_ready_avg[1]      <= '1; // enable read request
                    q_rd_data               <= w_map_avg[1];
                end

                10 : begin
                    o_mem_ready_avg[2]      <= '1; // enable read request
                    q_rd_data               <= w_map_avg[2];
                end

                11 : begin
                    o_mem_ready_avg[3]      <= '1; // enable read request
                    q_rd_data               <= w_map_avg[3];
                end
                
                default : q_rd_data <= '0;
                
            endcase 
            q_rena <= '0;          
//            s_axil_rdata    <= q_rd_data;
            s_axil_rvalid   <= 1;

        end

        
        if (s_axil_rvalid & s_axil_rready)
            s_axil_rvalid   <= 0;

        if (!i_aresetn) begin

            s_axil_awready  <= 0;
            s_axil_wready   <= 0;
            s_axil_arready  <= 0;
            s_axil_bvalid   <= 0;
            s_axil_rvalid   <= 0;

        end 

    end

endmodule
