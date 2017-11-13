module test(
    input [1:0] KEY,//0resetn//1go
    input CLOCK_50,
    input [8:0] SW,//data_in
    output [6:0] HEX0,HEX1, HEX2, HEX3
    );
    //wire ld_y, ld_x, ld_op, ld_out, ld_r;
    wire [15:0] data_result;

    wire c_en, s_en;
    control_all c1(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .go(KEY[1]),
        .c_en(c_en),
        .s_en(s_en)
        );

    datapath_all(
        .clk(CLOCK_50),
        .resetn(KEY[0]),
        .data_in(SW[7:0]),
        .s_en(s_en),
        .c_en(c_en),
        .go(KEY[1]),
        .ans(SW[8]),
        .data_result(data_result)
        );

  hex_decoder h3(
      .hex_digit(data_result[15:12]),
      .segments(HEX3)
  );
  hex_decoder h2(
      .hex_digit(data_result[11:8]),
      .segments(HEX2)
  );
  hex_decoder h1(
      .hex_digit(data_result[7:4]),
      .segments(HEX1)
  );
  hex_decoder h0(
      .hex_digit(data_result[3:0]),
      .segments(HEX0)
  );
endmodule

module control_all(
    input clk,
    input resetn,
    input go,
    output reg  c_en, s_en
    );
    reg [3:0] current_state, next_state;
    localparam  S_LOAD_CEN        = 4'd0,
                S_LOAD_CEN_WAIT   = 4'd1,
                S_LOAD_SEN        = 4'd2,
                S_LOAD_SEN_WAIT   = 4'd3;
    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                S_LOAD_CEN: next_state = go ? S_LOAD_CEN_WAIT : S_LOAD_CEN;
                // Loop in current state until value is input
                S_LOAD_CEN_WAIT: next_state = go ? S_LOAD_CEN_WAIT : S_LOAD_SEN; // Loop in current state until go signal goes low
                S_LOAD_SEN: next_state = go ? S_LOAD_SEN_WAIT : S_LOAD_SEN; // Loop in current state until value is input
                S_LOAD_SEN_WAIT: next_state = go ? S_LOAD_SEN_WAIT : S_LOAD_CEN; // Loop in current state until go signal goes low
            default:     next_state = S_LOAD_CEN;
        endcase
    end // state_table

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        c_en = 1'b0;
        s_en = 1'b0;

        case (current_state)
            S_LOAD_CEN: begin
                c_en = 1'b1;
                s_en = 1'b0;
                end
            S_LOAD_SEN: begin
                s_en = 1'b1;
                c_en = 1'b0;
                end

        endcase
    end // enable_signals
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_CEN;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath_all(
    input clk,
    input resetn,
    input [7:0] data_in,
    input s_en,c_en,
    input go, ans,
    output reg [15:0] data_result
    );
    //reg [6:0] y, x, op;
    // output of the alu
    //reg [15:0] alu_out;
    wire [15:0] chold;
    calcultor c1(
        .resetn(resetn),//1resetn
        .go(go),//2go
        .clk(clk),
        .ans(ans),
        .data_in(data_in),//data_in
        .data_result(hold)
        );

	 wire [15:0] shold;

    always @ (posedge clk) begin
        if (!resetn) begin
            data_result <= 16'd0;
        end
        else begin
            if (c_en)//calculation
                data_result <= hold;
            if (s_en) begin//sort
					 data_result <= shold; //
							end
				end
		end


endmodule

module calcultor(
    input resetn,//1resetn
    input go,//2go
    input clk,
    input ans,
    input [7:0] data_in,
    output [15:0] data_result
	 );

    wire ld_y, ld_x, ld_op, ld_out, ld_r;

    control c1(
        .clk(clk),
        .resetn(resetn),
        .go(go),
        .ans(ans),
        .ld_y(ld_y),
        .ld_x(ld_x),
        .ld_op(ld_op),
        .ld_r(ld_r),
        .ld_out(ld_out)
        );

	 wire [7:0] opration;
	 wire [7:0] x,y;

    datapath d1(
        .clk(clk),
        .resetn(resetn),
        .data_in(data_in),
        .ld_x(ld_x),
        .ld_y(ld_y),
        .ld_op(ld_op),
        .ld_out(ld_out),
        .ld_r(ld_r),
        .data_result(data_result)
        );
endmodule

module control(
    input clk,
    input resetn,
    input go,
    input ans,
    output reg  ld_y, ld_op, ld_x, ld_r,ld_out
    );
    reg [3:0] current_state, next_state;
    localparam  S_LOAD_X        = 4'd0,
                S_LOAD_X_WAIT   = 4'd1,
                S_LOAD_Y        = 4'd2,
                S_LOAD_Y_WAIT   = 4'd3,
                S_LOAD_OP        = 4'd4,
                S_LOAD_OP_WAIT   = 4'd5,
                S_CYCLE_0       = 4'd6,
                S_LOAD_OUT      = 4'd7;
    // Next state logic aka our state table
    always@(*)
    begin: state_table
            case (current_state)
                S_LOAD_X: if(go & ans) //go = 1, resetn = 1
                            next_state = S_LOAD_OUT;
                        else if(go & !ans)// go = 1, resetn = 0
                            next_state = S_LOAD_X_WAIT;
                        else
                            next_state = S_LOAD_X;
                //next_state = go ? S_LOAD_X_WAIT : S_LOAD_X; // Loop in current state until value is input
                S_LOAD_X_WAIT: next_state = go ? S_LOAD_X_WAIT : S_LOAD_Y; // Loop in current state until go signal goes low
                S_LOAD_Y: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_Y; // Loop in current state until value is input
                S_LOAD_Y_WAIT: next_state = go ? S_LOAD_Y_WAIT : S_LOAD_OP; // Loop in current state until go signal goes low
                S_LOAD_OUT:next_state = go ? S_LOAD_OUT : S_LOAD_OP;
                S_LOAD_OP: next_state = go ? S_LOAD_OP_WAIT : S_LOAD_OP; // Loop in current state until value is input
                S_LOAD_OP_WAIT: next_state = go ? S_LOAD_OP_WAIT : S_CYCLE_0; // Loop in current state until go signal goes low
                S_CYCLE_0: next_state = S_LOAD_X;
            default:     next_state = S_LOAD_X;
        endcase
    end // state_table

    // Output logic aka all of our datapath control signals
    always @(*)
    begin: enable_signals
        // By default make all our signals 0
        ld_out = 1'b0;
        ld_op = 1'b0;
        ld_y = 1'b0;
        ld_x = 1'b0;
        ld_r = 1'b0;
        case (current_state)
            S_LOAD_X: begin
                ld_x = 1'b1;
                end
            S_LOAD_Y: begin
                ld_y = 1'b1;
                ld_out = 1'b0;
                end
            S_LOAD_OUT: begin
                ld_y = 1'b0;
                ld_out = 1'b1;
      end
            S_LOAD_OP: begin
                ld_op = 1'b1;
                end
            S_CYCLE_0: begin //Do result = A + C
                ld_r = 1'b1;
     end
        endcase
    end // enable_signals
    // current_state registers
    always@(posedge clk)
    begin: state_FFs
        if(!resetn)
            current_state <= S_LOAD_X;
        else
            current_state <= next_state;
    end // state_FFS
endmodule

module datapath(
    input clk,
    input resetn,
    input [7:0] data_in,
    input ld_x, ld_y, ld_op, ld_out,
    input ld_r,
    output reg [15:0] data_result
    );
    reg [6:0] y, x, op, pcount;
    // output of the alu
    reg [15:0] alu_out;
    always @ (posedge clk) begin
        if (!resetn) begin
            op <= 7'd0;
            y <= 8'd0;
            x <= 8'd0;
            pcount <= 7'd0;
        end
        else begin
            if (ld_x)
                x <= data_in; // load alu_out if load_alu_out signal is high, otherwise load from data_in
            if (ld_y) begin
                y<=data_in;
                    end
            if (ld_out)
                y <= data_result[7:0];
            if (ld_op)
                op <= data_in;
                pcount <= pcount + 1'b1;
        end
    end
    //read and write in data
    //if wren == op[0] then we only need one ram256x8
    wire [7:0] writeout;
    ram256x8 r1(
        .address(y),
        .clock(clk),
        .data(x),
        .wren(1'b1),
        .q(writeout)
        );

    wire [7:0] readout;
    ram256x8 r2(
        .address(y),
        .clock(clk),
        .data(x),
        .wren(1'b0),
        .q(readout)
        );
    wire [7:0] pc
    ecounter e1(
        .enable(ld_op),
        .clk(clk),
        .clear_b(resetn),
        .q(pc)
        );

    wire [7:0] pcounter;
    //always write
    ram256x8 r3(
        .address(8'b1111_1111),
        .clock(clk),
        .data(pcount),
        .wren(1'b1),//1'b1
        .q()
        );

    //read from it if op=12
    ram256x8 r4(
        .address(8'b1111_1111),
        .clock(clk),
        .data(pcount),
        .wren(1'b0),
        .q(pcounter)
        );

    // Output result register
    always @ (posedge clk) begin
        if (!resetn) begin
            data_result <= 8'd0;
        end
        else
            if(ld_r)
                data_result <= alu_out;
    end
    // The ALU
    always @(*)
    begin : ALU
        // alu
        case (op)
            0: begin
                   alu_out <= x + y; //performs addition
               end
            1: begin
                   alu_out <= x - y; //performs subtraction
               end
            2: begin
                    alu_out <= x * y;
                end
            3: begin
                    alu_out <= x / y;
                end
            4: begin
                    alu_out <= x & y;
                end
            5: begin
                    alu_out <= x | y;
                end
            6: begin
                    alu_out <= x ^ y;
                end
            7: begin
                    alu_out <= ~x;
                end
            8: begin//1000
                    alu_out <= x << 1;
                end
            9: begin//1001
                    alu_out <= x>>1;
                end
            //shifter * 2
            10: begin //read
                    alu_out <= readout;
                end
            11: begin //write
                    alu_out <= writeout;
                end
            12: begin //pcounter
                    alu_out <= pcounter;
                end
            default: alu_out = 8'd0;
        endcase
    end


endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;
            default: segments = 7'h7f;
        endcase
endmodule

// megafunction wizard: %RAM: 1-PORT%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: altsyncram

// ============================================================
// File Name: ram256x8.v
// Megafunction Name(s):
// 			altsyncram
//
// Simulation Library Files(s):
// 			altera_mf
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 16.0.0 Build 211 04/27/2016 SJ Lite Edition
// ************************************************************


//Copyright (C) 1991-2016 Altera Corporation. All rights reserved.
//Your use of Altera Corporation's design tools, logic functions
//and other software and tools, and its AMPP partner logic
//functions, and any output files from any of the foregoing
//(including device programming or simulation files), and any
//associated documentation or information are expressly subject
//to the terms and conditions of the Altera Program License
//Subscription Agreement, the Altera Quartus Prime License Agreement,
//the Altera MegaCore Function License Agreement, or other
//applicable license agreement, including, without limitation,
//that your use is for the sole purpose of programming logic
//devices manufactured by Altera and sold by Altera or its
//authorized distributors.  Please refer to the applicable
//agreement for further details.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module ram256x8 (
	address,
	clock,
	data,
	wren,
	q);

	input	[7:0]  address;
	input	  clock;
	input	[7:0]  data;
	input	  wren;
	output	[7:0]  q;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri1	  clock;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	altsyncram	altsyncram_component (
				.address_a (address),
				.clock0 (clock),
				.data_a (data),
				.wren_a (wren),
				.q_a (sub_wire0),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.eccstatus (),
				.q_b (),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		altsyncram_component.clock_enable_input_a = "BYPASS",
		altsyncram_component.clock_enable_output_a = "BYPASS",
		altsyncram_component.intended_device_family = "Cyclone V",
		altsyncram_component.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		altsyncram_component.lpm_type = "altsyncram",
		altsyncram_component.numwords_a = 256,
		altsyncram_component.operation_mode = "SINGLE_PORT",
		altsyncram_component.outdata_aclr_a = "NONE",
		altsyncram_component.outdata_reg_a = "UNREGISTERED",
		altsyncram_component.power_up_uninitialized = "FALSE",
		altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		altsyncram_component.widthad_a = 8,
		altsyncram_component.width_a = 8,
		altsyncram_component.width_byteena_a = 1;


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: ADDRESSSTALL_A NUMERIC "0"
// Retrieval info: PRIVATE: AclrAddr NUMERIC "0"
// Retrieval info: PRIVATE: AclrByte NUMERIC "0"
// Retrieval info: PRIVATE: AclrData NUMERIC "0"
// Retrieval info: PRIVATE: AclrOutput NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_ENABLE NUMERIC "0"
// Retrieval info: PRIVATE: BYTE_SIZE NUMERIC "8"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "1"
// Retrieval info: PRIVATE: CLOCK_ENABLE_INPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: CLOCK_ENABLE_OUTPUT_A NUMERIC "0"
// Retrieval info: PRIVATE: Clken NUMERIC "0"
// Retrieval info: PRIVATE: DataBusSeparated NUMERIC "1"
// Retrieval info: PRIVATE: IMPLEMENT_IN_LES NUMERIC "0"
// Retrieval info: PRIVATE: INIT_FILE_LAYOUT STRING "PORT_A"
// Retrieval info: PRIVATE: INIT_TO_SIM_X NUMERIC "0"
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: PRIVATE: JTAG_ENABLED NUMERIC "0"
// Retrieval info: PRIVATE: JTAG_ID STRING "NONE"
// Retrieval info: PRIVATE: MAXIMUM_DEPTH NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING ""
// Retrieval info: PRIVATE: NUMWORDS_A NUMERIC "256"
// Retrieval info: PRIVATE: RAM_BLOCK_TYPE NUMERIC "0"
// Retrieval info: PRIVATE: READ_DURING_WRITE_MODE_PORT_A NUMERIC "3"
// Retrieval info: PRIVATE: RegAddr NUMERIC "1"
// Retrieval info: PRIVATE: RegData NUMERIC "1"
// Retrieval info: PRIVATE: RegOutput NUMERIC "0"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: SingleClock NUMERIC "1"
// Retrieval info: PRIVATE: UseDQRAM NUMERIC "1"
// Retrieval info: PRIVATE: WRCONTROL_ACLR_A NUMERIC "0"
// Retrieval info: PRIVATE: WidthAddr NUMERIC "8"
// Retrieval info: PRIVATE: WidthData NUMERIC "8"
// Retrieval info: PRIVATE: rden NUMERIC "0"
// Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
// Retrieval info: CONSTANT: CLOCK_ENABLE_INPUT_A STRING "BYPASS"
// Retrieval info: CONSTANT: CLOCK_ENABLE_OUTPUT_A STRING "BYPASS"
// Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone V"
// Retrieval info: CONSTANT: LPM_HINT STRING "ENABLE_RUNTIME_MOD=NO"
// Retrieval info: CONSTANT: LPM_TYPE STRING "altsyncram"
// Retrieval info: CONSTANT: NUMWORDS_A NUMERIC "256"
// Retrieval info: CONSTANT: OPERATION_MODE STRING "SINGLE_PORT"
// Retrieval info: CONSTANT: OUTDATA_ACLR_A STRING "NONE"
// Retrieval info: CONSTANT: OUTDATA_REG_A STRING "UNREGISTERED"
// Retrieval info: CONSTANT: POWER_UP_UNINITIALIZED STRING "FALSE"
// Retrieval info: CONSTANT: READ_DURING_WRITE_MODE_PORT_A STRING "NEW_DATA_NO_NBE_READ"
// Retrieval info: CONSTANT: WIDTHAD_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTH_A NUMERIC "8"
// Retrieval info: CONSTANT: WIDTH_BYTEENA_A NUMERIC "1"
// Retrieval info: USED_PORT: address 0 0 8 0 INPUT NODEFVAL "address[7..0]"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT VCC "clock"
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL "data[7..0]"
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL "q[7..0]"
// Retrieval info: USED_PORT: wren 0 0 0 0 INPUT NODEFVAL "wren"
// Retrieval info: CONNECT: @address_a 0 0 8 0 address 0 0 8 0
// Retrieval info: CONNECT: @clock0 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @data_a 0 0 8 0 data 0 0 8 0
// Retrieval info: CONNECT: @wren_a 0 0 0 0 wren 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q_a 0 0 8 0
// Retrieval info: GEN_FILE: TYPE_NORMAL ram256x8.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL ram256x8.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL ram256x8.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL ram256x8.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL ram256x8_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL ram256x8_bb.v TRUE
// Retrieval info: LIB_FILE: altera_mf


module ecounter (enable, clk, clear_b, q);
  input enable, clk, clear_b;
  output [7:0] q;
  wire [9:0] c;
  wire [9:0] e;


  T_flip_flop t0(
    .t(enable),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[0])
    );

  assign q[0] = c[0];
  assign e[0] = c[0] & enable;

  T_flip_flop t1(
    .t(e[0]),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[1])
    );

  assign q[1] = c[1];
  assign e[1] = c[1] & e[0];

  T_flip_flop t2(
    .t(e[1]),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[2])
    );

  assign q[2] = c[2];
  assign e[2] = c[2] & e[1];

  T_flip_flop t3(
    .t(e[2]),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[3])
    );

  assign q[3] = c[3];
  assign e[3] = c[3] & e[2];

  T_flip_flop t4(
    .t(e[3]),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[4])
    );

  assign q[4] = c[4];
  assign e[4] = c[4] & e[3];

  T_flip_flop t5(
    .t(e[4]),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[5])
    );

  assign q[5] = c[5];
  assign e[5] = c[5] & e[4];

  T_flip_flop t6(
    .t(e[5]),
    .clk(clk),
    .clear_b(clear_b),
    .q(c[6])
    );

  assign q[6] = c[6];
  assign e[6] = c[6] & e[5];

  T_flip_flop t7(
    .t(e[6]),
    .clk(clk),
    .clear_b(clear_b),
    .q(q[7])
    );



endmodule // ecounter

module T_flip_flop(t, clk, clear_b, q);
  input t, clk, clear_b;
  output q;
  reg q;


  always @ (posedge clk, negedge clear_b) begin
    if(~clear_b)
      q <= 0;
    else if(t)
      q <= ~q;
  end

endmodule // T_flip_flop
