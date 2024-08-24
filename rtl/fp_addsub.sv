/////////////////////////////////////////////////
//
//  Project        :  Floating Point Unit
//  Organization   :  RISC Lab, SEECS, NUST
//  ---------------------------------------------
//  File           :  fp_addsub.sv
//  Author         :  Fahad Haqique
//  Time created   :  August 2021
//  Last modified  :  16th August 2021
//  ---------------------------------------------
//  Dependencies   :  * barrel_shifter.sv
//                    * normalizer.sv
//  ---------------------------------------------
//  Description    :
//  ---------------------------------------------
//  To do          :  * Pipeline optimization
//                    * Verification
//
/////////////////////////////////////////////////

module fp_addsub #(
  parameter  EXPONENT_WIDTH = 5,
  parameter  MANTISSA_WIDTH = 11
) (
  input  clk_i,

  input  addsub_i,

  input  [(1+EXPONENT_WIDTH-1+MANTISSA_WIDTH)-1:0] data_a_i,
                                                   data_b_i,

  output [(1+EXPONENT_WIDTH-1+MANTISSA_WIDTH)-1:0] result_o
);

  localparam DATA_WIDTH = 1 + EXPONENT_WIDTH - 1 + MANTISSA_WIDTH;  // -1 for hidden bit

  ///////////////////////
  //  Input Registers  //
  ///////////////////////

  logic addsub_q;

  logic [DATA_WIDTH-1:0] data_a_q,
                         data_b_q;
  
  always @(posedge clk_i) begin
    addsub_q <= addsub_i;
  end

  always @(posedge clk_i) begin
    data_a_q <= data_a_i;
    data_b_q <= data_b_i;
  end

  ////////////////////////
  //  Pipeline Stage 1  //
  ////////////////////////

  // Exponent subtractor
  // ---------------------

  logic                      exp_a_minus_b_sign;
  logic [EXPONENT_WIDTH-1:0] exp_a_minus_b;
  logic [EXPONENT_WIDTH-1:0] exp_a_minus_b_mag_d;

  assign {exp_a_minus_b_sign,
          exp_a_minus_b} = $signed({1'b0, exponent(data_a_q)}) -
                           $signed({1'b0, exponent(data_b_q)});

  // Magnitude of difference between exponents
  // Deployment of parallel adders to be considered
  always_comb begin
    if (exp_a_minus_b_sign) begin
      exp_a_minus_b_mag_d = -exp_a_minus_b;
    end else begin
      exp_a_minus_b_mag_d = exp_a_minus_b;
    end
  end

  // Comparator
  // ------------
  
  logic exp_a_less_than_b;
  logic mant_a_less_than_b;
  logic a_less_than_b;
  

  assign exp_a_less_than_b = exp_a_minus_b_sign;

  assign mant_a_less_than_b = mantissa(data_a_q) < mantissa(data_b_q);

  assign a_less_than_b = (exp_a_minus_b != 0) ?
                         exp_a_less_than_b :
                         mant_a_less_than_b;

  // Sorting multiplexers
  // ----------------------
    
  logic                      high_sign_d;
  logic [EXPONENT_WIDTH-1:0] high_exp_d;
  logic [MANTISSA_WIDTH-1:0] high_mant_d;

  logic                      low_sign_d;
  logic [MANTISSA_WIDTH-1:0] low_mant_d;

  // Higher number mux
  always_comb begin
    if (a_less_than_b) begin
      high_sign_d = sign(data_b_q) ^ addsub_q;  // Negate data b if doing subtraction
      high_exp_d = exponent(data_b_q);
      high_mant_d = mantissa(data_b_q);
    end else begin
      high_sign_d = sign(data_a_q);
      high_exp_d = exponent(data_a_q);
      high_mant_d = mantissa(data_a_q);
    end
  end

  // Lower number mux
  always_comb begin
    if (a_less_than_b) begin
      low_sign_d = sign(data_a_q);
      low_mant_d = mantissa(data_a_q);
    end else begin
      low_sign_d = sign(data_b_q) ^ addsub_q;  // Negate data b if doing subtraction
      low_mant_d = mantissa(data_b_q);
    end
  end

  // Forwarding data to next stage
  // -------------------------------

  logic [EXPONENT_WIDTH-1:0] exp_a_minus_b_mag_q;
  
  logic                      high_sign_q;
  logic [EXPONENT_WIDTH-1:0] high_exp_q;
  logic [MANTISSA_WIDTH-1:0] high_mant_q;

  logic                      low_sign_q;
  logic [MANTISSA_WIDTH-1:0] low_mant_q;
  
  always @(posedge clk_i) begin
    exp_a_minus_b_mag_q <= exp_a_minus_b_mag_d;
  end

  always @(posedge clk_i) begin
    high_sign_q <= high_sign_d;
    high_exp_q <= high_exp_d;
    high_mant_q <= high_mant_d;
  end

  always @(posedge clk_i) begin
    low_sign_q <= low_sign_d;
    low_mant_q <= low_mant_d;
  end

  ////////////////////////
  //  Pipeline Stage 2  //
  ////////////////////////

  // Mantissa aligner 
  // ------------------

  localparam MaxShift = MANTISSA_WIDTH + 1;  // To preserve rounding bit
  
  logic [MANTISSA_WIDTH-1:0]     aligner_data_in;
  logic [$clog2(MaxShift+1)-1:0] aligner_shift_amount;
  logic [2*MANTISSA_WIDTH-1:0]   aligner_data_out;

  // Reversing bit order for right shifting
  always_comb begin
    for (int i = 0; i < MANTISSA_WIDTH; i = i + 1) begin
      aligner_data_in[i] = low_mant_q[MANTISSA_WIDTH-1-i];
    end
  end

  assign aligner_shift_amount = (exp_a_minus_b_mag_q < MaxShift) ?
                                exp_a_minus_b_mag_q[$clog2(MaxShift+1)-1:0] :
                                MaxShift;

  barrel_shifter #(
    .InputDataWidth (MANTISSA_WIDTH),
    .OutputDataWidth(2 * MANTISSA_WIDTH),
    .MaxShift       (MaxShift)
  ) aligner (
    .data_i        (aligner_data_in),
    .shift_amount_i(aligner_shift_amount),
    .data_o        (aligner_data_out)
  );

  // Dropping unnecessary bits 
  // ---------------------------

  logic [MANTISSA_WIDTH-1:0] low_mant_aligned_part,
                             low_mant_dropped_part;

  logic [MANTISSA_WIDTH-1:0] low_mant_d2;
  logic                      low_mant_guard_bit_d2,
                             low_mant_round_bit_d2,
                             low_mant_sticky_bit_d2;

  // Reversing bit order of shifted signal
  always_comb begin
    for (int j = 0; j < MANTISSA_WIDTH; j = j + 1) begin
      low_mant_aligned_part[j] = aligner_data_out[MANTISSA_WIDTH-1-j];
      low_mant_dropped_part[j] = aligner_data_out[2*MANTISSA_WIDTH-1-j];
    end
  end

  assign low_mant_d2 = low_mant_aligned_part;  

  assign low_mant_guard_bit_d2 = low_mant_dropped_part[MANTISSA_WIDTH-1];
  assign low_mant_round_bit_d2 = low_mant_dropped_part[MANTISSA_WIDTH-2];
  assign low_mant_sticky_bit_d2 = |low_mant_dropped_part[MANTISSA_WIDTH-3:0];     


  // Forwarding data to next stage
  // -------------------------------

  logic                      high_sign_q2;
  logic [EXPONENT_WIDTH-1:0] high_exp_q2;
  logic [MANTISSA_WIDTH-1:0] high_mant_q2;

  logic                      low_sign_q2;
  logic [MANTISSA_WIDTH-1:0] low_mant_q2;
  logic                      low_mant_guard_bit_q2,
                             low_mant_round_bit_q2,
                             low_mant_sticky_bit_q2;
  
  always @(posedge clk_i) begin
    high_sign_q2 <= high_sign_q;
    high_exp_q2 <= high_exp_q;
    high_mant_q2 <= high_mant_q;
  end

  always @(posedge clk_i) begin
    low_sign_q2 <= low_sign_q;
    low_mant_q2 <= low_mant_d2;
    low_mant_guard_bit_q2 <= low_mant_guard_bit_d2;
    low_mant_round_bit_q2 <= low_mant_round_bit_d2;
    low_mant_sticky_bit_q2 <= low_mant_sticky_bit_d2;
  end

  ////////////////////////
  //  Pipeline Stage  3 //
  ////////////////////////

  // Mantissa adder
  // ----------------

  logic                              mant_adder_addsub;
  logic [(MANTISSA_WIDTH+1+1+1)-1:0] mant_adder_op_a,
                                     mant_adder_op_b;
  logic [(MANTISSA_WIDTH+1+1+1)-1:0] mant_adder_sum;
  logic                              mant_adder_carry;
  
  assign mant_adder_addsub = (high_sign_q2 != low_sign_q2);

  assign mant_adder_op_a = {high_mant_q2,
                            1'b0,
                            1'b0,
                            1'b0};
  
  assign mant_adder_op_b = {low_mant_q2,
                            low_mant_guard_bit_q2,
                            low_mant_round_bit_q2,
                            low_mant_sticky_bit_q2};

  // Sign bit acts as carry because sum is never negative
  assign {mant_adder_carry, mant_adder_sum} = mant_adder_addsub ?
                                              {1'b0, mant_adder_op_a} - {1'b0, mant_adder_op_b} :
                                              {1'b0, mant_adder_op_a} + {1'b0, mant_adder_op_b};

  // Assign output fields
  // ----------------------

  logic                      result_sign_d3;
  logic [EXPONENT_WIDTH-1:0] result_exp_d3;
  logic                      result_mant_carry_bit_d3;
  logic [MANTISSA_WIDTH-1:0] result_mant_d3;
  logic                      result_mant_guard_bit_d3,
                             result_mant_round_bit_d3,
                             result_mant_stikcy_bit_d3;

  assign result_sign_d3 = high_sign_q2;
  assign result_exp_d3 = high_exp_q2;
  assign result_mant_carry_bit_d3 = mant_adder_carry;
  assign result_mant_d3 = mant_adder_sum[(MANTISSA_WIDTH+1+1+1)-1:3];
  assign result_mant_guard_bit_d3 = mant_adder_sum[2];
  assign result_mant_round_bit_d3 = mant_adder_sum[1];
  assign result_mant_stikcy_bit_d3 = mant_adder_sum[0];

  // Output register
  // -----------------

  logic                      result_sign_q3;
  logic [EXPONENT_WIDTH-1:0] result_exp_q3;
  logic                      result_mant_carry_bit_q3;
  logic [MANTISSA_WIDTH-1:0] result_mant_q3;
  logic                      result_mant_guard_bit_q3,
                             result_mant_round_bit_q3,
                             result_mant_sticky_bit_q3;
  
  always @(posedge clk_i) begin
    result_sign_q3 <= result_sign_d3;
    result_exp_q3 <= result_exp_d3;
    result_mant_carry_bit_q3 <= result_mant_carry_bit_d3;
    result_mant_q3 <= result_mant_d3;
    result_mant_guard_bit_q3 <= result_mant_guard_bit_d3;
    result_mant_round_bit_q3 <= result_mant_round_bit_d3;
    result_mant_sticky_bit_q3 <= result_mant_stikcy_bit_d3;
  end
  
  ////////////////////////
  //  Pipeline Stage 4  //
  ////////////////////////

  // Normalizer
  // ------------

  normalizer #(
    .EXPONENT_WIDTH(EXPONENT_WIDTH),
    .MANTISSA_WIDTH(MANTISSA_WIDTH)
  ) normalizer_inst (
    .clk_i            (clk_i),
    .sign_i           (result_sign_q3),
    .exp_i            (result_exp_q3),
    .mant_carry_bit_i (result_mant_carry_bit_q3),
    .mant_i           (result_mant_q3),
    .mant_guard_bit_i (result_mant_guard_bit_q3),
    .mant_round_bit_i (result_mant_round_bit_q3),
    .mant_sticky_bit_i(result_mant_sticky_bit_q3),
    .result_o         (result_o)
  );

  /////////////////
  //  Functions  //
  /////////////////

  function automatic sign(input [DATA_WIDTH-1:0] fp_in);
    sign = fp_in[EXPONENT_WIDTH+MANTISSA_WIDTH-1];
  endfunction

  function automatic [EXPONENT_WIDTH-1:0] exponent(input [DATA_WIDTH-1:0] fp_in);
    exponent = fp_in[EXPONENT_WIDTH+MANTISSA_WIDTH-1-1:MANTISSA_WIDTH-1];
  endfunction

  function automatic [MANTISSA_WIDTH-1:0] mantissa(input [DATA_WIDTH-1:0] fp_in);
    mantissa = {1'b1, fp_in[MANTISSA_WIDTH-1-1:0]};
  endfunction

endmodule : fp_addsub
