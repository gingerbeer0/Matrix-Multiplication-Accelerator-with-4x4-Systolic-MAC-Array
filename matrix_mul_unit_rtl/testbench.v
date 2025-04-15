/*****************************************
    testbench.v

    Project 2
    
    Team 05 : 
        2020104203    Park JongEun
        2020104297    Cho SangJun
*****************************************/

module testbench;

    reg             CLK, RSTN;
	reg				START;
	reg		[11:0]	MNT;

    /// CLOCK Generator ///
    parameter   PERIOD = 10.0;
    parameter   HPERIOD = PERIOD/2.0;

    initial CLK <= 1'b0;
    always #(HPERIOD) CLK <= ~CLK;


    wire              EN_W;
    wire    [2:0]     ADDR_W;
    wire    [63:0]    RDATA_W;
	wire              EN_I;
    wire    [2:0]     ADDR_I;
    wire    [63:0]    RDATA_I;
	
	wire              EN_O;
	wire			  RW_O;
    wire    [3:0]     ADDR_O;
	wire    [63:0]    RDATA_O;
    wire    [63:0]    WDATA_O;

	macarray	uMACARRAY	(
		.CLK		(CLK),
		.RSTN		(RSTN),
		.MNT		(MNT),
		.START		(START),
		.EN_W		(EN_W),
		.ADDR_W		(ADDR_W),
		.RDATA_W		(RDATA_W),
		.EN_I		(EN_I),
		.ADDR_I		(ADDR_I),
		.RDATA_I		(RDATA_I),
		.EN_O		(EN_O),
		.RW_O		(RW_O),
		.ADDR_O		(ADDR_O),
		.WDATA_O	(WDATA_O),
		.RDATA_O	(RDATA_O)
	);

	SRAM	INPUT_MEM	(
		.CLK		(CLK),
		.CSN		(~EN_I),
		.A			(ADDR_I),
		.WEN		(1'b1),
		.DI			(),
		.DOUT		(RDATA_I)
	);
	
	SRAM	WEIGHT_MEM	(
		.CLK		(CLK),
		.CSN		(~EN_W),
		.A			(ADDR_W),
		.WEN		(1'b1),
		.DI			(),
		.DOUT		(RDATA_W)
	);

	
	SRAM	OUT_MEM	(
		.CLK		(CLK),
		.CSN		(~EN_O),
		.A			(ADDR_O),
		.WEN		(~RW_O),
		.DI			(WDATA_O),
		.DOUT		(RDATA_O)
	);
	

	defparam testbench.INPUT_MEM.MEM_FILE = "input.hex";
	defparam testbench.INPUT_MEM.WRITE = 1;
	defparam testbench.WEIGHT_MEM.MEM_FILE = "weight_transpose.hex";
	defparam testbench.WEIGHT_MEM.WRITE = 1;
	// --------------------------------------------
	// Input (T X N) and Weight (N X M) test matrices should be stored as.
	// --------------------------------------------
	// Caution : Assumption : input files have hex data like below. 
	//			 Input      : (1,1) (1,2) ... (1,N)
	//          (T x N)       (2,1) (2,2) ... (2,N)
	//                        (3,1) (3,2) ... (3,N)
	//                         ...   ...  ...  ...
	//                        (T,1) (T,2) ... (T,N)
	//
	//	  Weight_transpose  : (1,1) (1,2) ... (1,N)
	//          (M x N)       (2,1) (2,2) ... (2,N)
	//                        (3,1) (3,2) ... (3,N)
	//                         ...   ...  ...  ...
	//                        (M,1) (M,2) ... (M,N)
	//
	// 	hex files will be  -> line1: (1,1)(1,2)(1,3)(1,4)(1,5)(1,6)(1,7)(1,8)
	//		  			   -> line2: (2,1)(2,2)(2,3)(2,4)(2,5)(2,6)(2,7)(2,8)
	//					   -> line3: (3,1)(3,2)(3,3)(3,4)(3,5)(3,6)(3,7)(3,8)
	//					   	   ...	  ...  ...  ...  ...  ...  ...  ...  ...
	//					   -> line8: (8,1)(8,2)(8,3)(8,4)(8,5)(8,6)(8,7)(8,8)
	
	
	
	defparam testbench.OUT_MEM.AW = 4;
	defparam testbench.OUT_MEM.ENTRY = 16;
	// --------------------------------------------
	// Output (T X M) should be stored as.
	// --------------------------------------------
	//						  (1,1) (1,2) ... (1,M)
	//          (T x M)       (2,1) (2,2) ... (2,M)
	//                        (3,1) (3,2) ... (3,M)
	//                         ...   ...  ...  ...
	//                        (T,1) (T,2) ... (T,M)
	//
	//					 --> addr0: (1,1) ... (1,4)
	// 					 --> addr1: (1,5) ... (1,8)
	// 					 --> addr2: (2,1) ... (2,4)
	// 					 --> addr3: (2,5) ... (2,8)
	// 					 --> ...
	// (Unused values (e.g. exceeding M or T) should be stored with 0s.)


	initial begin
		RSTN <= 1'b0;
		#(10*PERIOD)
		RSTN <= 1'b1;
		#(2*PERIOD)
		MNT <= 12'h568;	//M, N, T values are between 1~8
		START <= 1'b1;

		#(1000*PERIOD);
		$finish();
	end


endmodule

