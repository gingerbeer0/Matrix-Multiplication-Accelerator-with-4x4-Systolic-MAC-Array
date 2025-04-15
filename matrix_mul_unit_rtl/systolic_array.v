module systolic_array(
	input [127:0] block_I, // Data input
	input [127:0] block_W, // Weight input
	input CLK,          // Clock
	input RSTN,         // Reset (active low)
	output reg [255:0] out_array, // Output array
	input update_ready, // Done signal
	input [11:0] MNT, // MNT input
	input [3:0] i_order_r_SA, // Order of input matrix
	input [3:0] w_order_r_SA, // Order of weight matrix
	output reg [3:0] i_order_out, // Group output
	output reg operation_done, // Done signal
	input operation_start,
	input [3:0] group_out_SA,
	output reg [3:0] group_out_out
);
	reg [3:0] count; // Cycle counter
	reg done;        // Done signal
	// Weight and data inputs for processing elements
	reg [7:0] block_W_P11, block_W_P12, block_W_P13, block_W_P14;
	reg [7:0] block_I_P11, block_I_P21, block_I_P31, block_I_P41;

	reg enableP11, enableP12, enableP13, enableP14, enableP21, enableP22, enableP23, enableP24, enableP31, enableP32, enableP33, enableP34, enableP41, enableP42, enableP43, enableP44;

	wire [3:0] M, N, T; // MNT parameters

	reg update_ready_MAC; // Update ready signal for MACs

	assign M = MNT[11:8];
	assign N = MNT[7:4];
	assign T = MNT[3:0];

	// Sequential logic for weight inputs
	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			// Reset all weight inputs
			block_W_P11 <= 0;
			block_W_P12 <= 0;
			block_W_P13 <= 0;
			block_W_P14 <= 0;
			block_I_P11 <= 0;
			block_I_P21 <= 0;
			block_I_P31 <= 0;
			block_I_P41 <= 0;
		end else if (update_ready) begin
			case (count)
                0: begin
               block_W_P11 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[103:96]; // b41
                    block_W_P12 <= 0;           // 0
                    block_W_P13 <= 0;           // 0
                    block_W_P14 <= 0;           // 0
               block_I_P11 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[103:96]; // a41
               block_I_P21 <= 0;           // 0
               block_I_P31 <= 0;           // 0
               block_I_P41 <= 0;           // 0
                end
                1: begin   
               block_W_P11 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[111:104]; // b31
               block_W_P12 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[71:64]; // b42
                    block_W_P13 <= 0;
                    block_W_P14 <= 0;
               block_I_P11 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[111:104]; // a31
               block_I_P21 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[71:64]; // a42
               block_I_P31 <= 0;           // 0
               block_I_P41 <= 0;           // 0
                end
                2: begin
               block_W_P11 <= (N == 0 || N == 1 || (N == 5 && (w_order_r_SA != 1 && w_order_r_SA != 3))) ? 0 : block_W[119:112]; // b21
               block_W_P12 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[79:72];   // b32
               block_W_P13 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[39:32]; // b43
                    block_W_P14 <= 0;
               block_I_P11 <= (N == 0 || N == 1 || (N == 5 && (i_order_r_SA != 1 && i_order_r_SA != 3))) ? 0 : block_I[119:112]; // a21
               block_I_P21 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[79:72]; // a32
               block_I_P31 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[39:32]; // a43
               block_I_P41 <= 0;           // 0
                end
                3: begin
               block_W_P11 <= (N == 0) ? 0 : block_W[127:120]; // b11
               block_W_P12 <= (N == 0 || N == 1 || (N == 5 && (w_order_r_SA != 1 && w_order_r_SA != 3))) ? 0 : block_W[87:80];   // b22
               block_W_P13 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[47:40]; // b33
               block_W_P14 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[7:0];   // b44
               block_I_P11 <= (N == 0) ? 0 : block_I[127:120]; // a11
               block_I_P21 <= (N == 0 || N == 1 || (N == 5 && (i_order_r_SA != 1 && i_order_r_SA != 3))) ? 0 : block_I[87:80];   // a22
               block_I_P31 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[47:40];   // a33
               block_I_P41 <= (N == 0 || N == 1 || N == 2 || N == 3 || (N == 5 || N == 6 || N == 7) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[7:0];   // a44
                end
                4: begin
                    block_W_P11 <= 0;
               block_W_P12 <= (N == 0) ? 0 : block_W[95:88]; // b12
               block_W_P13 <= (N == 0 || N == 1 || (N == 5 && (w_order_r_SA != 1 && w_order_r_SA != 3))) ? 0 : block_W[55:48]; // b23
               block_W_P14 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (w_order_r_SA != 1 && w_order_r_SA != 3)) ? 0 : block_W[15:8]; // b34
               block_I_P11 <= 0;
               block_I_P21 <= (N == 0) ? 0 : block_I[95:88]; // a12
               block_I_P31 <= (N == 0 || N == 1 || (N == 5 && (i_order_r_SA != 1 && i_order_r_SA != 3))) ? 0 : block_I[55:48]; // a23
               block_I_P41 <= (N == 0 || N == 1 || N == 2 || (N == 5 || N == 6) && (i_order_r_SA != 1 && i_order_r_SA != 3)) ? 0 : block_I[15:8]; // a34
                end
            5: begin
               block_W_P11 <= 0;
               block_W_P12 <= 0;
               block_W_P13 <= (N == 0) ? 0 : block_W[63:56]; // b13
               block_W_P14 <= (N == 0 || N == 1 || (N == 5 && (w_order_r_SA != 1 && w_order_r_SA != 3))) ? 0 : block_W[23:16]; // b24
               block_I_P11 <= 0;
               block_I_P21 <= 0;
               block_I_P31 <= (N == 0) ? 0 : block_I[63:56]; // a13
               block_I_P41 <= (N == 0 || N == 1 || (N == 5 && (i_order_r_SA != 1 && i_order_r_SA != 3))) ? 0 : block_I[23:16]; // a24
            end
            6: begin
               block_W_P11 <= 0;
               block_W_P12 <= 0;
               block_W_P13 <= 0;
               block_W_P14 <= (N == 0) ? 0 : block_W[31:24]; // b14
               block_I_P11 <= 0;
               block_I_P21 <= 0;
               block_I_P31 <= 0;
               block_I_P41 <= (N == 0) ? 0 : block_I[31:24]; // a14
            end
                default: begin
                    block_W_P11 <= 0;
                    block_W_P12 <= 0;
                    block_W_P13 <= 0;
                    block_W_P14 <= 0;
               block_I_P11 <= 0;
               block_I_P21 <= 0;
               block_I_P31 <= 0;
               block_I_P41 <= 0;
                end
            endcase
		end
	end

    // Processing elements
	wire [7:0] d_out_P11, d_out_P12, d_out_P13, d_out_P14;
	wire [7:0] w_out_P11, w_out_P12, w_out_P13, w_out_P14;
	wire [15:0] result_P11, result_P12, result_P13, result_P14;

	wire [7:0] d_out_P21, d_out_P22, d_out_P23, d_out_P24;
	wire [7:0] w_out_P21, w_out_P22, w_out_P23, w_out_P24;
	wire [15:0] result_P21, result_P22, result_P23, result_P24;

	wire [7:0] d_out_P31, d_out_P32, d_out_P33, d_out_P34;
	wire [7:0] w_out_P31, w_out_P32, w_out_P33, w_out_P34;
	wire [15:0] result_P31, result_P32, result_P33, result_P34;

	wire [7:0] d_out_P41, d_out_P42, d_out_P43, d_out_P44;
	wire [7:0] w_out_P41, w_out_P42, w_out_P43, w_out_P44;
	wire [15:0] result_P41, result_P42, result_P43, result_P44;

	MAC P11 (block_W_P11, block_I_P11, CLK, RSTN, w_out_P11, d_out_P11, result_P11, done, enableP11, update_ready_MAC);
	MAC P12 (block_W_P12, d_out_P11, CLK, RSTN, w_out_P12, d_out_P12, result_P12, done, enableP12, update_ready_MAC);
	MAC P13 (block_W_P13, d_out_P12, CLK, RSTN, w_out_P13, d_out_P13, result_P13, done, enableP13, update_ready_MAC);
	MAC P14 (block_W_P14, d_out_P13, CLK, RSTN, w_out_P14, d_out_P14, result_P14, done, enableP14, update_ready_MAC);
	
	MAC P21 (w_out_P11, block_I_P21, CLK, RSTN, w_out_P21, d_out_P21, result_P21, done, enableP21, update_ready_MAC);
	MAC P22 (w_out_P12, d_out_P21, CLK, RSTN, w_out_P22, d_out_P22, result_P22, done, enableP22, update_ready_MAC);
	MAC P23 (w_out_P13, d_out_P22, CLK, RSTN, w_out_P23, d_out_P23, result_P23, done, enableP23, update_ready_MAC);
	MAC P24 (w_out_P14, d_out_P23, CLK, RSTN, w_out_P24, d_out_P24, result_P24, done, enableP24, update_ready_MAC);

	MAC P31 (w_out_P21, block_I_P31, CLK, RSTN, w_out_P31, d_out_P31, result_P31, done, enableP31, update_ready_MAC);
	MAC P32 (w_out_P22, d_out_P31, CLK, RSTN, w_out_P32, d_out_P32, result_P32, done, enableP32, update_ready_MAC);
	MAC P33 (w_out_P23, d_out_P32, CLK, RSTN, w_out_P33, d_out_P33, result_P33, done, enableP33, update_ready_MAC);
	MAC P34 (w_out_P24, d_out_P33, CLK, RSTN, w_out_P34, d_out_P34, result_P34, done, enableP34, update_ready_MAC);

	MAC P41 (w_out_P31, block_I_P41, CLK, RSTN, w_out_P41, d_out_P41, result_P41, done, enableP41, update_ready_MAC);
	MAC P42 (w_out_P32, d_out_P41, CLK, RSTN, w_out_P42, d_out_P42, result_P42, done, enableP42, update_ready_MAC);
	MAC P43 (w_out_P33, d_out_P42, CLK, RSTN, w_out_P43, d_out_P43, result_P43, done, enableP43, update_ready_MAC);
	MAC P44 (w_out_P34, d_out_P43, CLK, RSTN, w_out_P44, d_out_P44, result_P44, done, enableP44, update_ready_MAC);

	// Output array
	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			out_array <= 0;
			operation_done <= 0;
			group_out_out <= 0;
			i_order_out <= 0;
		end else if(done) begin
			operation_done <= 1;
			group_out_out <= group_out_SA;
			i_order_out <= i_order_r_SA;
			out_array <= {result_P11, result_P12, result_P13, result_P14, result_P21, result_P22, result_P23, result_P24, result_P31, result_P32, result_P33, result_P34, result_P41, result_P42, result_P43, result_P44};
		end else begin
			operation_done <= 0;
		end
	end

	always @(posedge CLK or negedge RSTN) begin
		if (!RSTN) begin
			enableP11 <= 1;
			enableP12 <= 1;
			enableP13 <= 1;
			enableP14 <= 1;
			enableP21 <= 1;
			enableP22 <= 1;
			enableP23 <= 1;
			enableP24 <= 1;
			enableP31 <= 1;
			enableP32 <= 1;
			enableP33 <= 1;
			enableP34 <= 1;
			enableP41 <= 1;
			enableP42 <= 1;
			enableP43 <= 1;
			enableP44 <= 1;
		end else begin
			case (i_order_r_SA) 
			1, 2: begin
				case (T)
				1: begin
					enableP21 <= 0;
					enableP22 <= 0;
					enableP23 <= 0;
					enableP24 <= 0;
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				2: begin
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				3: begin
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				default: begin
					enableP11 <= 1;
					enableP12 <= 1;
					enableP13 <= 1;
					enableP14 <= 1;
					enableP21 <= 1;
					enableP22 <= 1;
					enableP23 <= 1;
					enableP24 <= 1;
					enableP31 <= 1;
					enableP32 <= 1;
					enableP33 <= 1;
					enableP34 <= 1;
					enableP41 <= 1;
					enableP42 <= 1;
					enableP43 <= 1;
					enableP44 <= 1;
				end
			endcase
			end
			3, 4: begin
				case (T)
				1: begin
					enableP11 <= 0;
					enableP12 <= 0;
					enableP13 <= 0;
					enableP14 <= 0;
					enableP21 <= 0;
					enableP22 <= 0;
					enableP23 <= 0;
					enableP24 <= 0;
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				2: begin
					enableP11 <= 0;
					enableP12 <= 0;
					enableP13 <= 0;
					enableP14 <= 0;
					enableP21 <= 0;
					enableP22 <= 0;
					enableP23 <= 0;
					enableP24 <= 0;
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				3: begin
					enableP11 <= 0;
					enableP12 <= 0;
					enableP13 <= 0;
					enableP14 <= 0;
					enableP21 <= 0;
					enableP22 <= 0;
					enableP23 <= 0;
					enableP24 <= 0;
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				4: begin
					enableP11 <= 0;
					enableP12 <= 0;
					enableP13 <= 0;
					enableP14 <= 0;
					enableP21 <= 0;
					enableP22 <= 0;
					enableP23 <= 0;
					enableP24 <= 0;
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				5: begin
					enableP21 <= 0;
					enableP22 <= 0;
					enableP23 <= 0;
					enableP24 <= 0;
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				6: begin
					enableP31 <= 0;
					enableP32 <= 0;
					enableP33 <= 0;
					enableP34 <= 0;
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				7: begin
					enableP41 <= 0;
					enableP42 <= 0;
					enableP43 <= 0;
					enableP44 <= 0;
				end
				default: begin
					enableP11 <= 1;
					enableP12 <= 1;
					enableP13 <= 1;
					enableP14 <= 1;
					enableP21 <= 1;
					enableP22 <= 1;
					enableP23 <= 1;
					enableP24 <= 1;
					enableP31 <= 1;
					enableP32 <= 1;
					enableP33 <= 1;
					enableP34 <= 1;
					enableP41 <= 1;
					enableP42 <= 1;
					enableP43 <= 1;
					enableP44 <= 1;
				end
				endcase
			end
			default: begin
				enableP11 <= 1;
				enableP12 <= 1;
				enableP13 <= 1;
				enableP14 <= 1;
				enableP21 <= 1;
				enableP22 <= 1;
				enableP23 <= 1;
				enableP24 <= 1;
				enableP31 <= 1;
				enableP32 <= 1;
				enableP33 <= 1;
				enableP34 <= 1;
				enableP41 <= 1;
				enableP42 <= 1;
				enableP43 <= 1;
				enableP44 <= 1;
			end
		endcase
		case (w_order_r_SA)
		1, 2: begin
			case (M)
			1: begin
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
				enableP12 <= 0;
				enableP22 <= 0;
				enableP32 <= 0;
				enableP42 <= 0;
			end
			2: begin
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
			end
			3: begin
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
			end
			default: begin
				enableP11 <= 1;
				enableP12 <= 1;
				enableP13 <= 1;
				enableP14 <= 1;
				enableP21 <= 1;
				enableP22 <= 1;
				enableP23 <= 1;
				enableP24 <= 1;
				enableP31 <= 1;
				enableP32 <= 1;
				enableP33 <= 1;
				enableP34 <= 1;
				enableP41 <= 1;
				enableP42 <= 1;
				enableP43 <= 1;
				enableP44 <= 1;
			end
			endcase
		end
		3, 4: begin
			case (M)
			1: begin
				enableP11 <= 0;
				enableP21 <= 0;
				enableP31 <= 0;
				enableP41 <= 0;
				enableP12 <= 0;
				enableP22 <= 0;
				enableP32 <= 0;
				enableP42 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
			end
			2: begin
				enableP11 <= 0;
				enableP21 <= 0;
				enableP31 <= 0;
				enableP41 <= 0;
				enableP12 <= 0;
				enableP22 <= 0;
				enableP32 <= 0;
				enableP42 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
			end
			3: begin
				enableP11 <= 0;
				enableP21 <= 0;
				enableP31 <= 0;
				enableP41 <= 0;
				enableP12 <= 0;
				enableP22 <= 0;
				enableP32 <= 0;
				enableP42 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
			end
			4: begin
				enableP11 <= 0;
				enableP21 <= 0;
				enableP31 <= 0;
				enableP41 <= 0;
				enableP12 <= 0;
				enableP22 <= 0;
				enableP32 <= 0;
				enableP42 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
			end
			5: begin
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
				enableP12 <= 0;
				enableP22 <= 0;
				enableP32 <= 0;
				enableP42 <= 0;
			end
			6: begin
				enableP14 <= 0;
				enableP24 <= 0;
				enableP34 <= 0;
				enableP44 <= 0;
				enableP13 <= 0;
				enableP23 <= 0;
				enableP33 <= 0;
				enableP43 <= 0;
			end
			7: begin
				enableP41 <= 0;
				enableP42 <= 0;
				enableP43 <= 0;
				enableP44 <= 0;
			end
			default: begin
				enableP11 <= 1;
				enableP12 <= 1;
				enableP13 <= 1;
				enableP14 <= 1;
				enableP21 <= 1;
				enableP22 <= 1;
				enableP23 <= 1;
				enableP24 <= 1;
				enableP31 <= 1;
				enableP32 <= 1;
				enableP33 <= 1;
				enableP34 <= 1;
				enableP41 <= 1;
				enableP42 <= 1;
				enableP43 <= 1;
				enableP44 <= 1;
			end
			endcase
		end
		default: begin
			enableP11 <= 1;
				enableP12 <= 1;
				enableP13 <= 1;
				enableP14 <= 1;
				enableP21 <= 1;
				enableP22 <= 1;
				enableP23 <= 1;
				enableP24 <= 1;
				enableP31 <= 1;
				enableP32 <= 1;
				enableP33 <= 1;
				enableP34 <= 1;
				enableP41 <= 1;
				enableP42 <= 1;
				enableP43 <= 1;
				enableP44 <= 1;
		end
		endcase
		end
	end





    // Done signal and cycle counter
    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            done <= 0;
            count <= 0;
			update_ready_MAC <= 0;
        end else begin
            if (update_ready) begin // Count only when update_ready is high
                if (count == 11) begin
                    done <= 1;
					count <= 0;
                end else begin
                    done <= 0;
                    count <= count + 1;
                end
				update_ready_MAC <= 1;
			end else begin
				count <= 0;
				done <= 0;
				update_ready_MAC <= 0;
			end
        end
    end


endmodule
