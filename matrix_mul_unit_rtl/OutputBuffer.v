module OutputBuffer(
    input wire CLK,
    input wire RSTN, 
    input [255:0] block,
	input operation_done,
    input [3:0] group_out_out,
    output reg EN_O_i,
    output reg [3:0] ADDR_O_r,
    output reg [63:0] WDATA_O,
	input [11:0] MNT,
	input [3:0] i_order_out
);

    // Intermediate 128-bit sums
    reg [3:0] count;
    reg [4:0] mem_loc;

    reg [1:0] ADDR_count; // Declare ADDR_count as a reg

	reg [1:0] operation_done_count;
	reg count_start, slice_start, EN_O_t, EN_O, wipe, EN_O_r;
	reg [2:0] bitslice_factor;
	reg [15:0] EN_count;
	reg wipe_r;
	reg [2:0] group_out_out_prev;
	reg activity_halt;

	wire [3:0] M, N, T;
	assign M = MNT[11:8];
	assign N = MNT[7:4];
	assign T = MNT[3:0];

	wire [3:0] EN_c;

	reg [255:0] mem_data;

	assign CLK_G = CLK & !activity_halt;

	assign EN_c = 
	(T == 1 || (T == 5 && i_order_out == 3)) ? 1 :
	(T == 2 || (T == 6 && i_order_out == 3)) ? 2 :
	(T == 3 || (T == 7 && i_order_out == 3)) ? 3 : 4;

	// Output address
	reg [3:0] ADDR_O, ADDR_O_i;

	reg [3:0] N_reg; // N 값을 동기화하여 저장할 레지스터

	always @(posedge CLK_G or negedge RSTN) begin
    	if (!RSTN) begin
        	N_reg <= 0; // Reset N_reg
    	end else begin
        	N_reg <= N; // N 값을 동기화
    	end
	end

 	// EN_O 0되는 else부분 나중에 수정
	always @(posedge CLK_G or negedge RSTN) begin
		if (!RSTN) begin
			// Reset all control signals and address
			operation_done_count <= 0;
			EN_O <= 0;
		end else begin
			if(operation_done) begin
				if(N_reg<=4) begin
					operation_done_count <= 2;
				end else begin
					operation_done_count <= operation_done_count + 1;
				end
			end	else if(operation_done_count == 2) begin
				operation_done_count <= 0;
				EN_O <= 1;
			end else begin
				EN_O <= 0;
			end
			
		end
	end

		// Unified always block for reading and updating
	always @(posedge CLK_G or negedge RSTN) begin
		if (!RSTN) begin
			// Reset all control signals and address
			WDATA_O <= 0;
			ADDR_O_r <= 0;
			EN_O_r <= 0;
		end else if (slice_start) begin
				// Store SRAM data to matrix for the previous address
				WDATA_O	<= mem_data[255-64*bitslice_factor -: 64]; // Save current SRAM data
				ADDR_O_r <= ADDR_O_i;
				EN_O_r <= EN_O_i;
		end
	end

	always @(posedge CLK_G or negedge RSTN) begin
        if (!RSTN) begin
            ADDR_O <= 0;
			count_start <= 0;
			ADDR_count <= 0;
        end else if(operation_done) begin
            case (group_out_out)
                1 : ADDR_O <= 0;
                2 : ADDR_O <= 1;
                3 : ADDR_O <= 8;
                4 : ADDR_O <= 9;
            endcase
			count_start <= 1;					
		end else begin
			if(ADDR_count > 3) begin
                ADDR_count <= 0;
            end else begin
                ADDR_O <= ADDR_O + 2;
                ADDR_count <= ADDR_count + 1;
            end
		end
    end

    always @(posedge CLK_G or negedge RSTN) begin
        if (!RSTN) begin
            bitslice_factor <= 0;
			ADDR_O_i <= 0;
			slice_start <= 0;
        end else if(count_start) begin
			ADDR_O_i <= ADDR_O;
			case (ADDR_O)
                0,1,8,9 : bitslice_factor <= 0;
                2,3,10,11 : bitslice_factor <= 1;
                4,5,12,13 : bitslice_factor <= 2;
                6,7,14,15 : bitslice_factor <= 3;
                default: bitslice_factor <= 0; // Default case to handle unexpected values
            endcase
			slice_start <= 1;
		end 
    end


	always @(posedge CLK_G or negedge RSTN) begin
		if (!RSTN) begin
			EN_O_i <= 0;
			EN_count <= 5;
			wipe <= 0;
		end else begin
			if (EN_O) begin
				EN_O_i <= 1;
				EN_count <= 1;
			end else begin
				if (EN_count == EN_c) begin
					EN_O_i <= 0;
					wipe <= 1;
				end else begin
					wipe <= 0;
				end
				EN_count <= EN_count + 1;
			end
		end
	end

	always @(posedge CLK_G or negedge RSTN) begin
		if (!RSTN) begin
			wipe_r <= 0;
		end else begin
			wipe_r <= wipe;
		end
	end

	always @(posedge CLK_G or negedge RSTN) begin
		if (!RSTN) begin
			EN_O_t <= 0;
		end else begin
			EN_O_t <= EN_O_r;
		end
	end


	always @(posedge CLK_G or negedge RSTN) begin
    if (!RSTN) begin
        group_out_out_prev <= 0;
        activity_halt <= 0;
    end else begin
        group_out_out_prev <= group_out_out;

        // group_out_out이 1, 2, 3, 4에서 0으로 떨어질 때 activity_halt 활성화
        if ((group_out_out_prev != 0) && (group_out_out == 0)) begin
            activity_halt <= 1; // 활동 중지
        end
    end
end
    
always @(posedge CLK_G or negedge RSTN) begin
    if (!RSTN) begin
        mem_data <= 0; // Reset mem_data
    end else if (wipe_r) begin // wipe_r는 동기화된 상태에서 평가
        mem_data <= 0;
    end else if (operation_done) begin
        mem_data <= block + mem_data;
    end
end

endmodule
