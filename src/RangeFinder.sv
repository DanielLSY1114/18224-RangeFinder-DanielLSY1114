`default_nettype none

module RangeFinder
  #(parameter WIDTH=16)
   (input logic [WIDTH-1:0] data_in,
    input logic clock, reset,
    input logic go, finish,
    output logic [WIDTH-1:0] range,
    output logic debug_error);
  logic AltB_max, AltB_min;
  logic [WIDTH-1:0] min;
  logic [WIDTH-1:0] max;
  logic en_min, en_max, clr_min, clr_max;

  RF_datapath #(WIDTH) datapath(.*);
  RF_fsm #(WIDTH) fsm(.*);
endmodule: RangeFinder

module RF_datapath
  #(parameter WIDTH=16)
   (input logic [WIDTH-1:0] data_in,
    input logic clock, reset,
    output logic AltB_min, AltB_max,
    output logic [WIDTH-1:0] min,
    output logic [WIDTH-1:0] max,
    input logic en_min, en_max, clr_min, clr_max);
  Register #(WIDTH) reg_min(.D(data_in), .en(en_min), .clear(clr_min),
                            .clock(clock), .Q(min));
  Register #(WIDTH) reg_max(.D(data_in), .en(en_max), .clear(clr_max),
                            .clock(clock), .Q(max));
  MagComp #(WIDTH) comp_min(.AltB(AltB_min), .AeqB(), .AgtB(),
                            .A(data_in), .B(min));
  MagComp #(WIDTH) comp_max(.AltB(AltB_max), .AeqB(), .AgtB(),
                            .A(max), .B(data_in));

endmodule: RF_datapath

module RF_fsm
  #(parameter WIDTH=16)
   (input logic go, finish,
    input logic [WIDTH-1:0] data_in,
    input logic clock, reset,
    output logic debug_error,
    input logic AltB_min, AltB_max,
    input logic [WIDTH-1:0] min,
    input logic [WIDTH-1:0] max,
    output logic [WIDTH-1:0] range,
    output logic en_min, en_max, clr_min, clr_max);

  enum logic [1:0] {IDLE,FAULT,S1,S2} cur_state, n_state;

  always_comb begin
    case(cur_state)
      IDLE: begin
        if(finish) begin
          n_state <= FAULT;
          debug_error <= 1;
          range <= 0;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 1;
          clr_max <= 1;
        end
        else if(go) begin
          n_state <= S1;
          debug_error <= 0;
          range <= 0;
          en_min <= 1;
          en_max <= 1;
          clr_min <= 0;
          clr_max <= 0;
        end
        else begin
          n_state=IDLE;
          debug_error <= 0;
          range <= 0;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 1;
          clr_max <= 1;
        end
      end

      FAULT: begin
        if(go) begin
          n_state <= S1;
          debug_error <= 1;
          range <= 0;
          en_min <= 1;
          en_max <= 1;
          clr_min <= 0;
          clr_max <= 0;
        end
        else begin
          n_state <= FAULT;
          debug_error <= 1;
          range <= 0;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 1;
          clr_max <= 1;
        end
      end
      S1: begin
        if(finish && AltB_max) begin
          n_state <= S2;
          debug_error <= 0;
          range <= data_in - min;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 1;
          clr_max <= 1;
        end
        else if(finish && AltB_min) begin
          n_state<=S2;
          debug_error <= 0;
          range <= max - data_in;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 1;
          clr_max <= 1;
        end
        else if(finish) begin
          n_state<=S2;
          debug_error <= 0;
          range <= max - min;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 1;
          clr_max <= 1;
        end
        else if(AltB_max) begin
          n_state<=S1;
          debug_error <= 0;
          range <= 0;
          en_min <= 0;
          en_max <= 1;
          clr_min <= 0;
          clr_max <= 0;
        end
        else if(AltB_min) begin
          n_state<=S1;
          debug_error <= 0;
          range <= 0;
          en_min <= 1;
          en_max <= 0;
          clr_min <= 0;
          clr_max <= 0;
        end
        else begin
          n_state<=S1;
          debug_error <= 0;
          range <= 0;
          en_min <= 0;
          en_max <= 0;
          clr_min <= 0;
          clr_max <= 0;
        end
      end
      S2: begin
        n_state <= IDLE;
        debug_error <= 0;
        range <= 0;
        en_min <= 0;
        en_max <= 0;
        clr_min <= 1;
        clr_max <= 1;
      end
    endcase
  end

  // flip flop
  always_ff @(posedge clock, posedge reset) 
    if (reset) begin
      cur_state <= IDLE;
    end
    else 
      cur_state <= n_state;

endmodule: RF_fsm

// WIDTH-bit magnitude comparator
module MagComp
  #(parameter WIDTH = 30)
  (output logic AltB, AeqB, AgtB,
   input logic [WIDTH-1:0] A,
   input logic [WIDTH-1:0] B);
  assign AltB= (A<B);
  assign AgtB= (A>B);
  assign AeqB= (A==B);
endmodule : MagComp

// WIDTH-bit register
module Register
  #(parameter WIDTH = 3)
  (input logic [WIDTH-1:0] D,
   input logic en, clear,
   input logic clock,
   output logic [WIDTH-1:0] Q);
  always_ff @(posedge clock)
    if (en)
      Q <= D;
    else if (clear)
      Q <= 0;
endmodule: Register