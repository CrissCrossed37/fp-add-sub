/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  fp_addsub_tb.sv
//  Author         :  Fahad Haqique
//  Time created   :  August 2021
//  Last modified  :  16th August 2021
//  ---------------------------------------------
//  Dependencies   :  fp_addsub.sv
//  ---------------------------------------------
//  Description    :  Testbench
//  ---------------------------------------------
//  To do          :  
//
/////////////////////////////////////////////////

`timescale 1ns / 1ps

module fp_addsub_tb;

  localparam int EXPONENT_WIDTH = 8;
  localparam int MANTISSA_WIDTH = 24;
  
  // Inputs
  reg clk_i;
  reg addsub_i;
  reg [(1+EXPONENT_WIDTH-1+MANTISSA_WIDTH)-1:0] data_a_i,
                                                data_b_i;

  // Outputs
  wire [(1+EXPONENT_WIDTH-1+MANTISSA_WIDTH)-1:0] result_o;

  // Output file
  int fd;

  // Instantiate the Unit Under Test (UUT)
  fp_addsub #(
    .EXPONENT_WIDTH(EXPONENT_WIDTH),
    .MANTISSA_WIDTH(MANTISSA_WIDTH)
  ) uut (
    .clk_i   (clk_i),
    .addsub_i(addsub_i),
    .data_a_i(data_a_i),
    .data_b_i(data_b_i),
    .result_o(result_o)
  );

  initial begin
    fd = $fopen("fp_addsub_data.txt", "w");
    
    clk_i = 0;
    addsub_i = 0;
    data_a_i = 0;
    data_b_i = 0;
  end

  logic sign_a, sign_b;
  logic [EXPONENT_WIDTH-1:0] exponent_a, exponent_b;
  logic [MANTISSA_WIDTH-1:0] mantissa_a, mantissa_b;

  initial begin
    #50;

    for (int i = 0; i < 100000; i = i + 1) begin
      sign_a = $urandom_range(1, 0);
      sign_b = $urandom_range(1, 0);

      exponent_a = $urandom_range(100, 50);
      exponent_b = $urandom_range(100, 50);

      mantissa_a = $urandom_range(2*16777216-1, 16777216);
      mantissa_b = $urandom_range(2*16777216-1, 16777216);

      data_a_i = {sign_a, exponent_a, mantissa_a[(MANTISSA_WIDTH-1)-1:0]};
      data_b_i = {sign_b, exponent_b, mantissa_b[(MANTISSA_WIDTH-1)-1:0]};

      $fdisplay(fd, "%d + %d = %d", data_a_i, data_b_i, result_o);
      
      #10;
    end

    $fclose(fd);
    
    $finish;
  end

  always #5 clk_i = !clk_i;

endmodule
