`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: LEMZ-T
// Engineer: Nikolay A. Sysoev
// 
// Create Date: 28/09/2020 02:28:13 PM
// Design Name: 
// Module Name: divider
// Project Name: 
// Target Devices: 7Series+
// Tool Versions: SV-2012
// Description: Divide input fixed-point signals.
// 
// Dependencies: -
// 
// Revision:
// Revision 0.11 - unpacked to packed true conversion...
// Additional Comments: TODO divide by zero flag
//
//////////////////////////////////////////////////////////////////////////////////

(* KEEP_HIERARCHY = "Yes" *)
module divider #(
    parameter int DVD_W = 8, // Input dividend width
    parameter int DVR_W = 8, // Input divisor width
    parameter int RES_W = 16, // Output result width
    parameter int THROUGHPUT = 16, // Throughput for division from 1 to RES_W
    parameter bit ROUNDING = '0, // Use rounding for output value
    parameter bit SIGNED = '0, // Signed (1) or unsigned (0) operation
    parameter bit USE_RESET = '0 // Use reset input signal (1) or not use (0)
  ) (
    input   wire              i_div_s_rst_p, // Synchronous reset, active high
    input   wire              i_div_a_clk_p, // Rising edge clock

    input   wire              i_div_dat_vld, // Input data valid
    output  wire              o_div_dat_rdy, // Output data ready
    input   wire [DVD_W-1:0]  i_div_dvd_dat, // Input dividend value
    input   wire [DVR_W-1:0]  i_div_dvr_dat, // Input divisor value

    output  wire              o_div_res_vld, // Result valid 
    output  wire [RES_W-1:0]  o_div_res_dat // Result value
  );

  localparam int M = ( ROUNDING ) ? RES_W + 1 : RES_W;
  localparam int N = int'($ceil(M*1.0/THROUGHPUT));
  localparam int R = ( THROUGHPUT == 1 ) ? N-1 : N;
  localparam int L = N*THROUGHPUT;

  initial begin : check_param
    if ( !(THROUGHPUT inside {[1:M]}) )
      $error("[%s %0d-%0d] Parameter THROUGHPUT (%0d) must be in range from 1 to %0d. %m", "DIVIDER", 1, 1, THROUGHPUT, M);
  end : check_param

  typedef logic [DVR_W:0] t_dvd;
  typedef logic [DVR_W-1:0] t_dvr;

  typedef logic [$clog2(THROUGHPUT)-1:0] t_cnt;

  wire w_sgn_dat_vld = i_div_dat_vld && o_div_dat_rdy;

  logic q_sgn_dat_vld = '0;
  logic q_sgn_div_sgn = '0;
  logic [DVD_W-1:0] q_sgn_dvd_dat = '0;
  logic [DVR_W-1:0] q_sgn_dvr_dat = '0;
  always_ff @(posedge i_div_a_clk_p) begin
    q_sgn_dat_vld <= w_sgn_dat_vld;
    q_sgn_div_sgn <= i_div_dvd_dat[$high(i_div_dvd_dat)] ^ i_div_dvr_dat[$high(i_div_dvr_dat)];
    q_sgn_dvd_dat <= ( i_div_dvd_dat[$high(i_div_dvd_dat)] ) ? ~i_div_dvd_dat + DVD_W'(1'b1) : i_div_dvd_dat;
    q_sgn_dvr_dat <= ( i_div_dvr_dat[$high(i_div_dvr_dat)] ) ? ~i_div_dvr_dat + DVR_W'(1'b1) : i_div_dvr_dat;
  end

  wire w_div_dat_vld = ( SIGNED ) ? q_sgn_dat_vld : w_sgn_dat_vld;
  wire [DVD_W-1:0] w_div_dvd_dat = ( SIGNED ) ? q_sgn_dvd_dat : i_div_dvd_dat;
  wire [DVR_W-1:0] w_div_dvr_dat = ( SIGNED ) ? q_sgn_dvr_dat : i_div_dvr_dat;

  logic q_div_s_rst_p = '0;
  always_ff @(posedge i_div_a_clk_p)
    q_div_s_rst_p <= ( USE_RESET ) ? i_div_s_rst_p : '0;

  t_dvr q_div_dvr_dat [N] = '{default:'0};
  always_ff @(posedge i_div_a_clk_p)
    if ( w_div_dat_vld )
      q_div_dvr_dat[0] <= w_div_dvr_dat;

  t_dvd q_div_dvd_dat = '0;
  always_ff @(posedge i_div_a_clk_p)
    if ( w_div_dat_vld )
      q_div_dvd_dat <= ( { 1'b0, w_div_dvd_dat } >> (DVD_W-1) ) - w_div_dvr_dat;

  wire w_dly_dvd_dat [N];
  wire w_div_quo_dat [M];
  wire w_dly_quo_dat [M];

  wire t_dvd m_div_rem_dat [N];

  (* MAX_FANOUT = 35 *) logic q_div_dat_vld = '0;
  always_ff @(posedge i_div_a_clk_p)
    if ( q_div_s_rst_p )
      q_div_dat_vld <= '0;
    else
      q_div_dat_vld <= w_div_dat_vld;

  logic [L-1:0] q_reg_dvd_dat = '0;
  always_ff @(posedge i_div_a_clk_p)
    if ( q_div_s_rst_p )
      q_reg_dvd_dat <= '0;
    else if ( w_div_dat_vld )
      q_reg_dvd_dat <= ( L - DVD_W < 0 ) ? w_div_dvd_dat >> ( DVD_W - L - 1 ) : w_div_dvd_dat << ( L - DVD_W + 1 );

  t_cnt q_div_rep_cnt = '0;

  wire w_dly_dvr_ena [R];
  if ( THROUGHPUT == 1 ) begin : no_throughput

    assign o_div_dat_rdy = ( q_div_s_rst_p ) ? '0 : '1;
    assign w_dly_dvr_ena = '{default:'1};

  end : no_throughput else begin : throughput_on

    t_cnt q_div_rdy_cnt = '0;
    always_ff @(posedge i_div_a_clk_p)
      if ( q_div_s_rst_p )
        q_div_rdy_cnt <= '0;
      else if ( w_sgn_dat_vld )
        q_div_rdy_cnt <= THROUGHPUT-1;
      else if ( q_div_rdy_cnt != '0 )
        q_div_rdy_cnt <= q_div_rdy_cnt - 1;

    always_ff @(posedge i_div_a_clk_p)
      if ( w_div_dat_vld )
        q_div_rep_cnt <= '0;
      else if ( q_div_rep_cnt != THROUGHPUT-1 )
        q_div_rep_cnt <= q_div_rep_cnt + 1;

    assign w_dly_dvr_ena[0] = w_div_dat_vld;

    for ( genvar i = 1; i < R; i++ ) begin : delay_enable

      divider_delay #(
        .WIDTH ( 1 ), // Width of data
        .DELAY ( THROUGHPUT ), // Delay value
        .SHREG ( "Yes" ), // Shift Register: "Yes" or "No"
        .STYLE ( "SRL_REG" ), // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
        .RESET ( '0 ) // Reset output data if not null value
      ) u_delay_valid (
        .i_dly_s_rst_p ( '0 ), // Synchronous reset, active high, active if RESET not null
        .i_dly_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
        .i_dly_s_ena_p ( '1 ), // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period
        .i_dly_a_value ( w_dly_dvr_ena[i-1] ), // Input data
        .o_dly_a_value ( w_dly_dvr_ena[i] )  // Output delayed data
      );

    end : delay_enable

    assign o_div_dat_rdy = ( q_div_s_rst_p ) ? '0 : ( q_div_rdy_cnt == '0 ) ? '1 : '0;

  end : throughput_on

  for ( genvar i = 0; i < N; i++ ) begin : delay_dividend

    wire w_reg_dvd_dat = q_reg_dvd_dat[$high(q_reg_dvd_dat)-(i*THROUGHPUT + q_div_rep_cnt)];

    divider_delay #(
      .WIDTH ( 1 ), // Width of data
      .DELAY ( i*THROUGHPUT ), // Delay value
      .SHREG ( "Yes" ), // Shift Register: "Yes" or "No"
      .STYLE ( "SRL_REG" ), // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
      .RESET ( '0 ) // Reset output data if not null value
    ) u_delay_dividend (
      .i_dly_s_rst_p ( '0 ), // Synchronous reset, active high, active if RESET not null
      .i_dly_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
      .i_dly_s_ena_p ( '1 ), // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period
      .i_dly_a_value ( w_reg_dvd_dat ), // Input data
      .o_dly_a_value ( w_dly_dvd_dat[i] )  // Output delayed data
    );

  end : delay_dividend

  for ( genvar i = 1; i < R; i++ ) begin : delay_divisor

    divider_delay #(
      .WIDTH ( DVR_W ), // Width of data
      .DELAY ( 1 ), // Delay value
      .SHREG ( "No" ), // Shift Register: "Yes" or "No"
      .STYLE ( "Register" ), // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
      .RESET ( '0 ) // Reset output data if not null value
    ) u_delay_divisor (
      .i_dly_s_rst_p ( '0 ), // Synchronous reset, active low, active if RESET not null
      .i_dly_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
      .i_dly_s_ena_p ( w_dly_dvr_ena[i] ), // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period TODO add valid shreg for this enable
      .i_dly_a_value ( q_div_dvr_dat[i-1] ), // Input data
      .o_dly_a_value ( q_div_dvr_dat[i] )  // Output delayed data
    );

  end : delay_divisor

  for ( genvar i = 0; i < N; i++ ) begin : div_loop

    wire t_dvd w_div_rem_dat;
    if ( THROUGHPUT == 1 ) begin : no_throughput

      assign w_div_rem_dat = ( i == 0 ) ? q_div_dvd_dat : m_div_rem_dat[i-1];

    end else begin : throughput_on
      logic q_dly_rem_ena = '0;
      always_ff @(posedge i_div_a_clk_p)
        if ( q_div_s_rst_p )
          q_dly_rem_ena <= '0;
        else
          q_dly_rem_ena <= w_dly_dvr_ena[i];

      assign w_div_rem_dat = ( i == 0 && q_div_dat_vld ) ? q_div_dvd_dat : ( i != 0 && q_dly_rem_ena ) ? m_div_rem_dat[i-1] : m_div_rem_dat[i];

    end : throughput_on

    wire m_div_quo_dat;
    divider_div #(
      .DVR_W ( DVR_W ), // Devisor width
      .USE_REG ( '1 ), // Use register output
      .QUOTIENT_ONLY ( ( i == N-1 && ( THROUGHPUT == 1 || M % THROUGHPUT == 1 ) ) ? '1 : '0 ) // Quotient only output
    ) u_div (
      .i_div_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
      .i_div_dvd_dat ( w_dly_dvd_dat[i] ), // Dividend data
      .i_div_rem_dat ( w_div_rem_dat ), // Remainder data
      .i_div_dvr_dat ( q_div_dvr_dat[i] ), // Divisor data
      .o_div_rem_dat ( m_div_rem_dat[i] ), // Remainder data
      .o_div_quo_dat ( m_div_quo_dat ) // Quotient data
    );

    localparam int Q = ( i == N-1 && M % THROUGHPUT != 0 ) ? M % THROUGHPUT : THROUGHPUT;

    for ( genvar j = 0; j < Q; j++ ) begin : quo_loop
      assign w_div_quo_dat[j+THROUGHPUT*i] = m_div_quo_dat;
    end : quo_loop

  end : div_loop

  for ( genvar i = 0; i < M; i++ ) begin : delay_quotient

    divider_delay #(
      .WIDTH ( 1 ), // Width of data
      .DELAY ( M-i-1 ), // Delay value
      .SHREG ( "Yes" ), // Shift Register: "Yes" or "No"
      .STYLE ( ( i == M-2 ) ? "Register" : "SRL" ), // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
      .RESET ( '0 ) // Reset output data if not null value
    ) u_delay_quotient (
      .i_dly_s_rst_p ( '0 ), // Synchronous reset, active high, active if RESET not null
      .i_dly_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
      .i_dly_s_ena_p ( '1 ), // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period
      .i_dly_a_value ( w_div_quo_dat[i] ), // Input data
      .o_dly_a_value ( w_dly_quo_dat[i] )  // Output delayed data
    );

  end : delay_quotient

  wire m_div_res_vld;
  divider_delay #(
    .WIDTH ( 1 ), // Width of data
    .DELAY ( M-1 ), // Delay value
    .SHREG ( "Yes" ), // Shift Register: "Yes" or "No"
    .STYLE ( "SRL" ), // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
    .RESET ( USE_RESET ) // Reset output data if not null value
  ) u_delay_valid (
    .i_dly_s_rst_p ( q_div_s_rst_p ), // Synchronous reset, active high, active if RESET not null
    .i_dly_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
    .i_dly_s_ena_p ( '1 ), // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period
    .i_dly_a_value ( q_div_dat_vld ), // Input data
    .o_dly_a_value ( m_div_res_vld ) // Output delayed data
  );

  wire [M-1:0] w_div_res_dat = { >> {w_dly_quo_dat}};

  logic q_div_res_vld = '0;
  logic [M-1:0] q_div_res_dat = '0;
  always_ff @(posedge i_div_a_clk_p) begin
    q_div_res_vld <= m_div_res_vld;
    if ( m_div_res_vld )
      q_div_res_dat <= ( ROUNDING ) ? w_div_res_dat + 1'b1 : w_div_res_dat;
  end
  
  wire w_sgn_res_vld = q_div_res_vld;
  wire [RES_W-1:0] w_sgn_res_dat = ( ROUNDING ) ? q_div_res_dat[M-1:1] : q_div_res_dat;

  wire w_sgn_res_sgn;
  divider_delay #(
    .WIDTH ( 1 ), // Width of data
    .DELAY ( M+1 ), // Delay value
    .SHREG ( "Yes" ), // Shift Register: "Yes" or "No"
    .STYLE ( "SRL_REG" ), // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
    .RESET ( USE_RESET ) // Reset output data if not null value
  ) u_delay_sign (
    .i_dly_s_rst_p ( '0 ), // Synchronous reset, active high, active if RESET not null
    .i_dly_a_clk_p ( i_div_a_clk_p ), // Rising edge clock
    .i_dly_s_ena_p ( '1 ), // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period
    .i_dly_a_value ( q_sgn_div_sgn ), // Input data
    .o_dly_a_value ( w_sgn_res_sgn ) // Output delayed data
  );

  logic q_sgn_res_vld = '0;
  logic [RES_W-1:0] q_sgn_res_dat = '0;
  always_ff @(posedge i_div_a_clk_p) begin
    q_sgn_res_vld <= w_sgn_res_vld;
    q_sgn_res_dat <= ( w_sgn_res_sgn ) ? ~w_sgn_res_dat + RES_W'(1'b1) : w_sgn_res_dat;
  end

  assign o_div_res_vld = ( SIGNED ) ? q_sgn_res_vld : w_sgn_res_vld;
  assign o_div_res_dat = ( SIGNED ) ? q_sgn_res_dat : w_sgn_res_dat;

endmodule : divider

(* KEEP_HIERARCHY = "YES" *)
module divider_div #(
    parameter   int DVR_W = 8, // Devisor width
    parameter   bit USE_REG = '1, // Use register output
    parameter   bit QUOTIENT_ONLY = '0, // Quotient only output
    localparam  int REM_W = DVR_W+1 // Remainder width, readonly
  ) (
    input   wire              i_div_a_clk_p, // Rising edge clock
    input   wire              i_div_dvd_dat, // Dividend data
    input   wire [REM_W-1:0]  i_div_rem_dat, // Remainder data
    input   wire [DVR_W-1:0]  i_div_dvr_dat, // Divisor data
    output  wire [REM_W-1:0]  o_div_rem_dat, // Remainder data
    output  wire              o_div_quo_dat // Quotient data
  );

  wire w_div_quo_dat = ~ i_div_rem_dat[$high(i_div_rem_dat)];
  wire [REM_W-1:0] w_div_rem_dat = ( QUOTIENT_ONLY ) ? '0 : ( i_div_rem_dat[$high(i_div_rem_dat)] ) ? { i_div_rem_dat, i_div_dvd_dat } + i_div_dvr_dat : { i_div_rem_dat, i_div_dvd_dat } - i_div_dvr_dat;

  if ( USE_REG ) begin : with_reg

    // logic q_div_quo_dat = '0;
    // always_ff @(posedge i_div_a_clk_p) q_div_quo_dat <= w_div_quo_dat;

    logic [REM_W-1:0] q_div_rem_dat = '0;
    always_ff @(posedge i_div_a_clk_p) q_div_rem_dat <= w_div_rem_dat;

    // assign o_div_quo_dat = q_div_quo_dat;
    assign o_div_quo_dat = w_div_quo_dat;
    assign o_div_rem_dat = q_div_rem_dat;
  
  end : with_reg else begin : wout_reg

    assign o_div_quo_dat = w_div_quo_dat;
    assign o_div_rem_dat = w_div_rem_dat;

  end : wout_reg

endmodule : divider_div

(* KEEP_HIERARCHY = "YES" *)
module divider_delay #(
    parameter int WIDTH = 1, // Width of data
    parameter int DELAY = 16, // Delay value
    parameter     SHREG = "Yes", // Shift Register: "Yes" or "No"
    parameter     STYLE = "SRL", // Shift register style: [ Register | SRL | SRL_REG | REG_SRL | REG_SRL_REG | Block ]
    parameter bit RESET = '0 // Reset output data, if '1 - reset is enabled
  )  (
    input   wire              i_dly_s_rst_p, // Synchronous reset, active high, enabled if RESET not null
    input   wire              i_dly_a_clk_p, // Rising edge clock
    input   wire              i_dly_s_ena_p, // Clock enable, if not equal every clock cycle then summary delay is DELAY-1 + one clock period
    input   wire  [WIDTH-1:0] i_dly_a_value, // Input data
    output  wire  [WIDTH-1:0] o_dly_a_value // Output delayed data
  );

  // Check parameters
  initial begin : check_param
    if ( !(WIDTH inside {[0:4096]}) ) 
      $error("[%s %0d-%0d] Width of data is %d, but must be greater than 0 and less than 4096. %m", "DIVIDER_DELAY", 1, 1, WIDTH);
    if ( !(DELAY inside {[0:1048576]}) )
      $error("[%s %0d-%0d] Delay value is %d, but must be greater than 0 and less than 1048576. %m", "DIVIDER_DELAY", 1, 2, DELAY);
  end : check_param

  (* SHREG_EXTRACT = SHREG, SRL_STYLE = STYLE *) logic [DELAY-1:0][WIDTH-1:0] q_dly_a_value = '0;

  if ( DELAY == 0 ) begin : zero

    assign o_dly_a_value = i_dly_a_value;

  end : zero else if ( DELAY == 1 ) begin : ones

    if ( RESET == 0 ) begin : no_reset

      always_ff @(posedge i_dly_a_clk_p)
        if ( i_dly_s_ena_p )
          q_dly_a_value[0] <= i_dly_a_value;

      assign o_dly_a_value = q_dly_a_value[0];

    end : no_reset else begin : reset_on
      
      logic q_dly_s_rst_p = '0;
      always_ff @(posedge i_dly_a_clk_p)
        q_dly_s_rst_p <= i_dly_s_rst_p;

      always_ff @(posedge i_dly_a_clk_p)
        if ( q_dly_s_rst_p )
          q_dly_a_value[0] <= '0;
        else if ( i_dly_s_ena_p )
          q_dly_a_value[0] <= i_dly_a_value;

      assign o_dly_a_value = q_dly_a_value[0];

    end : reset_on

  end : ones else begin : many

    if ( RESET == 0 ) begin : no_reset
      
      always_ff @(posedge i_dly_a_clk_p)
        if ( i_dly_s_ena_p )
          q_dly_a_value <= { q_dly_a_value[$high(q_dly_a_value)-1:0], i_dly_a_value };

      assign o_dly_a_value = q_dly_a_value[$high(q_dly_a_value)];
      
    end : no_reset else begin : reset_on

      logic q_dly_s_rst_p = '0;
      always_ff @(posedge i_dly_a_clk_p)
        q_dly_s_rst_p <= i_dly_s_rst_p;

      logic [$clog2(DELAY):0] q_dly_counter = DELAY;
      always_ff @(posedge i_dly_a_clk_p)
        if ( q_dly_s_rst_p )
          q_dly_counter <= DELAY;
        else if ( i_dly_s_ena_p && q_dly_counter != 0 )
          q_dly_counter <= q_dly_counter - 1;

      always_ff @(posedge i_dly_a_clk_p)
        if ( i_dly_s_ena_p )
          q_dly_a_value <= { q_dly_a_value[$high(q_dly_a_value)-1:0], i_dly_a_value };

      assign o_dly_a_value = ( q_dly_counter == 0 ) ? q_dly_a_value[$high(q_dly_a_value)] : '0;

    end : reset_on

  end : many

endmodule : divider_delay
