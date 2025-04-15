/*****************************************
    
    Team 05 : 
        2020104203    Park JongEun
        2020104297    Cho SangJun
*****************************************/



////////////////////////////////////
//  TOP MODULE
////////////////////////////////////
module macarray (
    input     wire              CLK,
    input     wire              RSTN,
	input	  wire	  [11:0]	MNT,
	input	  wire				START,
	
    output    wire              EN_I,
    output    wire    [2:0]     ADDR_I,
    input     wire    [63:0]    RDATA_I,
	output    wire              EN_W,
    output    wire    [2:0]     ADDR_W,
    input     wire    [63:0]    RDATA_W,
	
    output    wire              EN_O,
    output    wire              RW_O,
    output    wire    [3:0]     ADDR_O,
    output    wire    [63:0]    WDATA_O,
    input     wire    [63:0]    RDATA_O
);


    wire [3:0] i_order, w_order;
    wire operation_start, case_start, update_ready, START_d, operation_done;
    wire [127:0] block_I, block_W;
	wire [255:0] block_O;
    wire [2:0] bitslice_factor;
	wire change_order;

	reg EN_I_r, EN_W_r;
	reg [3:0] i_order_r, w_order_r;
	reg [3:0] group_out_r;
	wire [3:0] group_out;
	wire [3:0] i_order_r_SA, w_order_r_SA, i_order_out;
	wire [3:0] group_out_SA, group_out_out;
	

    // WRITE YOUR CONTROL SYSTEM CODE
    control uCONTROL(
        .CLK(CLK),
        .RSTN(RSTN),
        .MNT(MNT),
        .operation_done(operation_done),  // Assuming START is used as operation_done signal
        .i_order(i_order),              // Connect as needed
        .w_order(w_order),              // Connect as needed
        .operation_start(operation_start),      // Connect as needed
        .group_out(group_out),            // Connect as needed
        .case_start(case_start),           // Connect as needed
		.START(START),
		.ADDR_I_s(ADDR_I),
		.ADDR_W_s(ADDR_W),
		.EN_I_s(EN_I),
		.EN_W_s(EN_W),
		.change_order(change_order)
    );

	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			EN_I_r <= 0;
			EN_W_r <= 0;
			i_order_r <= 0;
			w_order_r <= 0;
			group_out_r <= 0;
		end else if(EN_I) begin
			EN_I_r <= 1;
			EN_W_r <= 1;
			i_order_r <= i_order;
			w_order_r <= w_order;
			group_out_r <= group_out;
		end
	end



	
	
    // WRITE YOUR MAC_ARRAY DATAPATH CODE

	InputDevider uInputDevider (
		.CLK(CLK),
		.RSTN(RSTN),
		.SRAM_DATA(RDATA_I),
		.change_order(change_order),
		.i_order_r(i_order_r),
		.EN_I_r(EN_I_r),
		.update_ready(update_ready),
		.block_I(block_I),
		.i_order_r_SA(i_order_r_SA),
		.change_order_r(change_order_r),
		.group_out_r(group_out_r),
		.group_out_SA(group_out_SA)
	);

	WeightDevider uWeightDevider (
		.CLK(CLK),
		.RSTN(RSTN),
		.SRAM_DATA(RDATA_W),
		.change_order(change_order),
		.w_order_r(w_order_r),
		.EN_W_r(EN_W_r),
		.block_W(block_W),
		.w_order_r_SA(w_order_r_SA)
	);

	systolic_array uSystolicArray (
		.block_I(block_I),
		.block_W(block_W),
		.CLK(CLK),
		.RSTN(RSTN),
		.out_array(block_O),
		.update_ready(update_ready),
		.MNT(MNT),
		.i_order_r_SA(i_order_r_SA),
		.w_order_r_SA(w_order_r_SA),
		.i_order_out(i_order_out),
		.operation_done(operation_done),
		.operation_start(operation_start),
		.group_out_SA(group_out_SA),
		.group_out_out(group_out_out)
	);

	OutputBuffer uOutputBuffer (
		.CLK(CLK),
		.RSTN(RSTN),
		.block(block_O),
		.operation_done(operation_done),
		.group_out_out(group_out_out),
		.EN_O_i(EN_O),
		.ADDR_O_r(ADDR_O),
		.WDATA_O(WDATA_O),
		.MNT(MNT),
		.i_order_out(i_order_out)
	);

	assign RW_O = 1'b1;

    




endmodule
