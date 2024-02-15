`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
    // Basic counter design as an example
    logic [9:0] data_in;
    logic go, finish;
    logic [9:0] range;
    logic debug_error;

    RangeFinder #(10) dut (.data_in, .clock, .reset, .go, .finish, .range, .debug_error);

    assign io_in[9:0] = data_in;
    assign io_out[9:0] = range;
    assign io_out[12] = debug_error;
    assign io_in[10] = go;
    assign io_in[11] = finish;

    // instantiate segment display
    seg7 seg7(.counter(digit), .segments(led_out));

endmodule
