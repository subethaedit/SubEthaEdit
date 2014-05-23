/*
// Verilog syntax highlighting test file.
 * Ryan Dalzell, 19th October 2005
 * License: as-is
 * NOTE This whole comment section should fold
 * Testing the alerts:
 * FIXME HACK NOTE NOTICE TASK TODO ###
 */

`timescale 1ns/1ns // comment in a directive.
`define ns 1

// typical Verilog syntax.
module test (clock, reset, clear, enable, d, q);

    parameter param = 8;
    parameter name = "test";
    localparam local = param*4;

    input  clock;
    input  reset;
    input  clear;
    input  enable;
    input  [param-1:0] d;
    output [param-1:0] q;

    wire [param-1:0] in;
    wire [param-1:0] out;

    // a generate block, should also fold.
    genvar i;
    generate
        for (i=0; i<param; i=i+1)
        begin: test
            buf(out[i], in[i]);
        end
    endgenerate

    reg signed [param-1:0] q;

    always @(posedge clock or negedge reset)
    begin: register // named block.
        if (!reset || clear) begin // unnamed block.
            q <= 0;
        end else begin
            if (enable) begin q <= $signed(d); end // block on one line, shouldn't fold.
        end
    end
endmodule

// a Verilog state machine.
module test2 (clock, reset, clear, enable, start, ready);

    input  clock;
    input  reset;
    input  clear;
    input  enable;
    input  start;
    output ready;

    parameter [1:0] idle  = 2'b00; // binary number.
    parameter [1:0] run   = 2'b01;
    parameter [1:0] same1 = 2'b10;
    parameter [1:0] same2 = 2'b11;

    reg  [1:0] state;
    wire state2;
    wire state3;
    wire state4;

    always @(posedge clock or negedge reset)
    begin
        if (!reset)
            state <= idle;
        else
            if (enable) begin
                case (state)
                    idle: begin
                        if (start)
                            state <= run;
                    end

                    run: begin
                        state <= idle;
                    end

                    same1, same2: begin
                        state <= idle;
                    end
                endcase
            end
    end

    // some instantiations.
    test test_positional(clock, reset, clear, enable, state, state2);
    test test_named(.clock(clock), .reset(reset), .clear(clear), .enable(enable), .d(state), .q(state3));

    // a conditional operator.
    assign state4 = state==idle? state2 : state3;

endmodule

// bad syntax
modules bad (clock, reset, clear, enable);

    inout  clock;
    inpu   reset;
    outputs enable;

endmod
