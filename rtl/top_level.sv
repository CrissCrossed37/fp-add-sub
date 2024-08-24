/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  top_level.v
//  Author         :  Fahad Haqique
//  Time created   :  August 2021
//  Last modified  :  15th August 2021
//  ---------------------------------------------
//  Dependencies   :  
//  ---------------------------------------------
//  Description    :  
//  ---------------------------------------------
//  To do          :  
//
/////////////////////////////////////////////////

module top_level (
  input         clk_i,
  input         addsub_i,
  input  [31:0] data_a_i,
                data_b_i,
  output [31:0] result_o
);

  fp_addsub #(
    .EXPONENT_WIDTH(8),
    .MANTISSA_WIDTH(24)
  ) fp_addsub_inst (
    .clk_i   (clk_i),
    .addsub_i(addsub_i),
    .data_a_i(data_a_i),
    .data_b_i(data_b_i),
    .result_o(result_o)
  );

endmodule
