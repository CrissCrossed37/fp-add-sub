/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  barrel_shifter_tb.sv
//  Author         :  Fahad Haqique
//  Time created   :  August 2021
//  Last modified  :  15th August 2021
//  ---------------------------------------------
//  Dependencies   :  barrel_shifter.sv
//  ---------------------------------------------
//  Description    :  Testbench
//  ---------------------------------------------
//  To do          :  
//
/////////////////////////////////////////////////

`timescale 1ns / 1ps

module barrel_shifter_tb;

  localparam int InputDataWidth  = 11;
  localparam int OutputDataWidth = 22;
  localparam int MaxShift        = 11;
  
  // Inputs
  reg [InputDataWidth-1:0]     data_i;
  reg [$clog2(MaxShift+1)-1:0] shift_amount_i;

  // Outputs
  wire [OutputDataWidth-1:0] data_o;

  // Instantiate the Unit Under Test (UUT)
  barrel_shifter #(
    .InputDataWidth (InputDataWidth),
    .OutputDataWidth(OutputDataWidth),
    .MaxShift       (MaxShift)
  ) uut (
    .data_i        (data_i),
    .shift_amount_i(shift_amount_i),
    .data_o        (data_o)
  );

  initial begin
    data_i = 0;
    shift_amount_i = 0;
    #20 $stop;

    data_i = 1200;
    shift_amount_i = 3;
    #20 $stop;
    
    data_i = 999;
    shift_amount_i = 5;
    #20 $stop;
    
    data_i = 2003;
    shift_amount_i = 7;
    #20 $stop;
    
    data_i = 1202;
    shift_amount_i = 1;
    #20 $stop;
    
    $finish;
  end
      
endmodule
