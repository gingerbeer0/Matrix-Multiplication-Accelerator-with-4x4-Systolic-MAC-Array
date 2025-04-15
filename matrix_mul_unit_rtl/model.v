/*
    SINGLE-PORT SYNCHRONOUS MEMORY MODEL

    FUNCTION TABLE:

    CLK        CSN      WEN      A        DI       DOUT        COMMENT
    ======================================================================
    posedge    H        X        X        X        DOUT(t-1)   DESELECTED
    posedge    L        L        VALID    VALID    DOUT(t-1)   WRITE CYCLE
    posedge    L        H        VALID    X        MEM(A)      READ CYCLE

    USAGE:

    SRAM    #(.BW(32), .AW(10), .ENTRY(1024)) InstMemory (
                    .CLK    (CLK),
                    .CSN    (1'b0),
                    .A      (),
                    .WEN    (),
                    .DI     (),
                    .DOUT   ()
    );
*/

module SRAM #(parameter BW = 64, AW = 3, ENTRY = 8, WRITE = 0, MEM_FILE="mem.hex") (
    input    wire                CLK,
    input    wire                CSN,    // CHIP SELECT (ACTIVE LOW)
    input    wire    [AW-1:0]    A,      // ADDRESS
    input    wire                WEN,    // READ/WRITE ENABLE
    input    wire    [BW-1:0]    DI,     // DATA INPUT
    output   wire    [BW-1:0]    DOUT    // DATA OUTPUT
);

    parameter    ATIME    = 2;

    reg        [BW-1:0]    ram[0:ENTRY-1];
    reg        [BW-1:0]    outline;

    initial begin
	    if(WRITE>0)
		    $readmemh(MEM_FILE, ram);
    end

    always @ (posedge CLK)
    begin
        if (~CSN)
        begin
            if (WEN)    outline    <= ram[A];
            else        ram[A]    <= DI;
        end
    end

    assign    #(ATIME)    DOUT    = outline;

endmodule
