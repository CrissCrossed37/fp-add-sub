/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  normalizer_tb.sv
//  Author         :  Fahad Haqique
//  Time created   :  August 2021
//  Last modified  :  15th August 2021
//  ---------------------------------------------
//  Dependencies   :  normalizer.sv
//  ---------------------------------------------
//  Description    :  Testbench
//  ---------------------------------------------
//  To do          :  
//
/////////////////////////////////////////////////

`timescale 1ns / 1ps

module normalizer_tb;

  localparam int EXPONENT_WIDTH = 5;
  localparam int MANTISSA_WIDTH = 11;
  
  // Inputs
  reg                       clk_i;
  reg                       sign_i;
  reg  [EXPONENT_WIDTH-1:0] exp_i;
  reg                       mant_carry_bit_i;
  reg  [MANTISSA_WIDTH-1:0] mant_i;
  reg                       mant_guard_bit_i,
                            mant_round_bit_i,
                            mant_sticky_bit_i;

  // Outputs
  wire [(1+EXPONENT_WIDTH-1+MANTISSA_WIDTH)-1:0] result_o;

  // Instantiate the Unit Under Test (UUT)
  normalizer #(
    .EXPONENT_WIDTH(EXPONENT_WIDTH),
    .MANTISSA_WIDTH(MANTISSA_WIDTH)
  ) normalizer_inst (
    .clk_i            (clk_i),
    .sign_i           (sign_i),
    .exp_i            (exp_i),
    .mant_carry_bit_i (mant_carry_bit_i),
    .mant_i           (mant_i),
    .mant_guard_bit_i (mant_guard_bit_i),
    .mant_round_bit_i (mant_round_bit_i),
    .mant_sticky_bit_i(mant_sticky_bit_i),
    .result_o         (result_o)
  );

  initial begin
    clk_i = 0;

    sign_i = 1;
    exp_i = 28;
    mant_carry_bit_i = 0;
    mant_i = 11'b001_1110_1010;
    mant_guard_bit_i = 1;
    mant_round_bit_i = 1;
    mant_sticky_bit_i = 1;
    #20 $stop;

    sign_i = 1;
    exp_i = 20;
    mant_carry_bit_i = 1;
    mant_i = 11'b001_1010_1010;
    mant_guard_bit_i = 1;
    mant_round_bit_i = 0;
    mant_sticky_bit_i = 1;
    #20 $stop;
    
    sign_i = 0;
    exp_i = 10;
    mant_carry_bit_i = 0;
    mant_i = 11'b000_0000_0001;
    mant_guard_bit_i = 1;
    mant_round_bit_i = 0;
    mant_sticky_bit_i = 1;
    #20 $stop;
    
    sign_i = 1;
    exp_i = 16;
    mant_carry_bit_i = 0;
    mant_i = 11'b011_1111_1111;
    mant_guard_bit_i = 1;
    mant_round_bit_i = 1;
    mant_sticky_bit_i = 0;
    #20 $stop;
    
    $finish;
  end

  always #10 clk_i = !clk_i;
      
endmodule
