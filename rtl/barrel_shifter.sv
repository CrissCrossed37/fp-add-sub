/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  barrel_shifter.sv
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

module barrel_shifter #(
  parameter int InputDataWidth  = 10,
  parameter int OutputDataWidth = 10,
  parameter int MaxShift        = 10
) (
  input  [InputDataWidth-1:0]     data_i,
  input  [$clog2(MaxShift+1)-1:0] shift_amount_i,
  output [OutputDataWidth-1:0]    data_o
);

  localparam int NumStages = $clog2(MaxShift+1);

  logic [OutputDataWidth-1:0] stage_out[0:NumStages-1];
  logic [OutputDataWidth-1:0] stage_in[0:NumStages-1];

  // Multiplexer stages
  always_comb begin
    for (int i = 0; i < NumStages; i = i + 1) begin
      if (shift_amount_i[i]) begin
        stage_out[i] = stage_in[i] << 2**i;
      end else begin
        stage_out[i] = stage_in[i];
      end
    end
  end

  // Cascading multiplexer stages
  always_comb begin
    for (int j = 0; j < NumStages; j = j + 1) begin
      if (j == 0) begin
        stage_in[j] = data_i;
      end else begin
        stage_in[j] = stage_out[j-1];
      end
    end
  end

  assign data_o = stage_out[NumStages-1];

endmodule : barrel_shifter
