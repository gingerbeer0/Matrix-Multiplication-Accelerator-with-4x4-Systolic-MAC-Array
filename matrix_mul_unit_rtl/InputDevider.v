module InputDevider (
    input wire CLK,
    input wire RSTN,
    input wire [63:0] SRAM_DATA,  // Input from SRAM
    input wire change_order,
    input wire [3:0] i_order_r, //  block num
    input wire EN_I_r,
    input wire [3:0] group_out_r,
    output reg update_ready,      // Flag to indicate that the matrix is ready to be updated
    output reg [127:0] block_I,
	output reg [3:0] i_order_r_SA,
	output reg change_order_r,
    output reg [3:0] group_out_SA
);

reg [3:0] B; // Address counter
wire i;

assign i = ((i_order_r == 1) || (i_order_r == 3)) ? 0 : 1;

// Unified always block for reading and updating
always @(posedge CLK or negedge RSTN) begin
    if (!RSTN) begin
        // Reset all control signals and address
		block_I <= 0;
    end else if (!update_ready) begin
            // Store SRAM data to matrix for the previous address
            block_I[127-32*B -: 32] <= SRAM_DATA[63-32*i -: 32]; // Save current SRAM data
    end
end

always @(posedge CLK) begin
    if (change_order) begin
        B <= 0;
        update_ready <= 0;
		change_order_r <= 0;
    end else if(EN_I_r) begin                   
		// Increment address
            if (B < 3) begin
                B <= B + 1;
            end else begin
                update_ready <= 1; // Set ready flag after all rows are loaded
                i_order_r_SA <= i_order_r;
                B <= 0;
				change_order_r <= change_order;
                group_out_SA <= group_out_r;
            end
        end
    end

endmodule
