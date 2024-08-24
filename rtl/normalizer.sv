/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  normalizer.sv
//  Author         :  Fahad Haqique
//  Time created   :  August 2021
//  Last modified  :  15th August 2021
//  ---------------------------------------------
//  Dependencies   :  
//  ---------------------------------------------
//  Description    :
//  ---------------------------------------------
//  To do          :  * Overflow and underflow
//                    * Special numbers
//
/////////////////////////////////////////////////

module normalizer #(
  parameter  EXPONENT_WIDTH = 5,
  parameter  MANTISSA_WIDTH = 11
) (
  input                       clk_i,

  input                       sign_i,
  input  [EXPONENT_WIDTH-1:0] exp_i,
  input                       mant_carry_bit_i,
  input  [MANTISSA_WIDTH-1:0] mant_i,
  input                       mant_guard_bit_i,
                              mant_round_bit_i,
                              mant_sticky_bit_i,

  output [(1+EXPONENT_WIDTH-1+MANTISSA_WIDTH)-1:0] result_o  // localparam problem
);

  localparam DATA_WIDTH = 1 + EXPONENT_WIDTH - 1 + MANTISSA_WIDTH;  // -1 for hidden bit

  // Leading bit index encoder
  // ---------------------------
  
  localparam LeadingBitMaxIndex = $bits({mant_carry_bit_i,
                                         mant_i,
                                         mant_guard_bit_i});

  logic [$clog2(LeadingBitMaxIndex+1)-1:0] leading_bit_pos;

  always_comb begin : leading_bit_index_encoder
    leading_bit_pos = 0;  // default value, to avoid inferring a latch

    for (int i = LeadingBitMaxIndex - 1; i >= 0; i = i - 1) begin
      if ({mant_carry_bit_i, mant_i, mant_guard_bit_i} >= 2**i) begin
        leading_bit_pos = (LeadingBitMaxIndex - 1) - i;
        break;
      end
    end
  end : leading_bit_index_encoder

  // Barrel shifter
  // ----------------
  
  logic [(MANTISSA_WIDTH+1+1+1)-1:0] shifter_data_in;  // Carry bit not required
  logic [(MANTISSA_WIDTH+1+1+1)-1:0] shifter_data_out;

  assign shifter_data_in = {mant_i,
                            mant_guard_bit_i,
                            mant_round_bit_i,
                            mant_sticky_bit_i};

  barrel_shifter #(
    .InputDataWidth (MANTISSA_WIDTH+1+1+1),
    .OutputDataWidth(MANTISSA_WIDTH+1+1+1),
    .MaxShift       (LeadingBitMaxIndex-1)
  ) barrel_shifter_inst (
    .data_i        (shifter_data_in),
    .shift_amount_i(leading_bit_pos),
    .data_o        (shifter_data_out)
  );

  logic [MANTISSA_WIDTH-1:0] mant_unrounded;
  logic                      mant_unrounded_ulp;
  logic                      mant_unrounded_round_bit;
  logic                      mant_unrounded_sticky_bit;

  // Appending hidden bit
  assign mant_unrounded = {1'b1, shifter_data_out[(MANTISSA_WIDTH+1+1+1)-1:4]};
  assign mant_unrounded_ulp  = shifter_data_out[4];
  assign mant_unrounded_round_bit = shifter_data_out[3];
  assign mant_unrounded_sticky_bit = |shifter_data_out[2:0];

  // Rounding logic
  // ----------------

  logic [MANTISSA_WIDTH-1:0] mant_rounded;
  logic                      mant_rounded_carry_bit;

  assign {mant_rounded_carry_bit, mant_rounded} = mant_unrounded +
                                                  (mant_unrounded_round_bit &&
                                                    (mant_unrounded_sticky_bit ||
                                                      mant_unrounded_ulp));

  // Assign output fields
  // ----------------------

  logic                          result_sign_field;
  logic [EXPONENT_WIDTH-1:0]     result_exp_field;
  logic                          result_hidden_bit_field;  // Dummy variable
  logic [(MANTISSA_WIDTH-1)-1:0] result_mant_field;        // Excluding hidden bit

  assign result_sign_field = sign_i;

  assign result_exp_field = (((exp_i + 1'b1) - leading_bit_pos) + mant_rounded_carry_bit);

  // Renormalize if mantissa overflows after rounding
  // Can be optimized for FPGA's.
  // Sclr of logic elements can be used instead of a mux
  always_comb begin
    if (mant_rounded_carry_bit) begin
      result_mant_field = 0;
    end else begin
      result_mant_field = mant_rounded[(MANTISSA_WIDTH-1)-1:0];  // Drop the hidden bit
    end
  end
  
  // Output register
  // -----------------

  logic [DATA_WIDTH-1:0] result_d,
                         result_q;

  assign result_d = {result_sign_field,
                     result_exp_field,
                     result_mant_field};
  
  always @(posedge clk_i) begin
    result_q <= result_d;
  end

  assign result_o = result_q;

endmodule : normalizer
