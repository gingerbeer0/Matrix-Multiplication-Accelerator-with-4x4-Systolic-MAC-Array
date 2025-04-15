module control (
    input wire CLK,
    input wire RSTN,
    input wire [11:0] MNT,           
    input wire operation_done,    // 현재 연산 완료 신호
    input wire START,             // 연산 시작 신호

    output reg [3:0] i_order,     // 첫 번째 블록 신호
    output reg [3:0] w_order,     // 두 번째 블록 신호
    output reg operation_start,   // 연산 시작 신호
    output reg [3:0] group_out,   // 그룹 출력 신호
    output reg case_start,        // MNT 케이스 시작 신호
    output reg change_order,      // 블록 변경 신호
    output reg EN_I_s,            // 입력 메모리 활성화 신호
    output reg [2:0] ADDR_I_s,    // 입력 메모리 주소
    output reg EN_W_s,            // 가중치 메모리 활성화 신호
    output reg [2:0] ADDR_W_s     // 가중치 메모리 주소
);

    reg [7:0] operations;         // 수행해야 하는 연산 리스트 (1~8의 비트 플래그)
    reg finding;
    reg [3:0] operation_index;    // 현재 연산 인덱스
    reg [3:0] operation_current;  // 현재 연산 번호
    reg active;                   // 연산 활성화 신호
    reg [3:0] last_order_i, last_order_w;  // 이전 블록 신호
    reg [2:0] B;
    wire [4:0] T, N, M;
    reg EN_I, EN_W;
    reg [3:0] ADDR_I, ADDR_W;
    reg [11:0] prev_MNT;          // MNT의 이전 상태를 저장

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            // Reset all control signals and address
            last_order_i <= 0;
            last_order_w <= 0;
            change_order <= 0;
            EN_I_s <= 0;
            EN_W_s <= 0;
            ADDR_I_s <= 0;
            ADDR_W_s <= 0;
        end else begin
            last_order_i <= i_order;
            last_order_w <= w_order;
            change_order <= (last_order_i ^ i_order) || (last_order_w ^ w_order);
            EN_I_s <= EN_I;
            EN_W_s <= EN_W;
            ADDR_I_s <= ADDR_I;
            ADDR_W_s <= ADDR_W;
        end
    end

    assign M = MNT[11:8];
    assign N = MNT[7:4];
    assign T = MNT[3:0];

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            active <= 0;
        end else if (START) begin
            active <= 1;          // start 신호로 활성화
        end else if (operation_index >= 8) begin
            active <= 0;          // 모든 연산이 끝나면 비활성화
        end
    end

    always @(*) begin
    operations = 8'b00000000; // 기본값
            if (T > 4 && N > 4 && M > 4) begin
                operations = 8'b11111111;  // Case 1
            end else if (T > 4 && N > 4 && M <= 4) begin
                operations = 8'b11001100;  // Case 2
            end else if (T > 4 && N <= 4 && M > 4) begin
                operations = 8'b10101010;  // Case 3
            end else if (T <= 4 && N > 4 && M > 4) begin
                operations = 8'b11110000;  // Case 4
            end else if (T > 4 && N <= 4 && M <= 4) begin
                operations = 8'b10001000;  // Case 5
            end else if (T <= 4 && N > 4 && M <= 4) begin
                operations = 8'b11000000;  // Case 6
            end else if (T <= 4 && N <= 4 && M > 4) begin
                operations = 8'b10100000;  // Case 7
            end else begin
                operations = 8'b10000000;  // Case 8
            end
        end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            case_start <= 0;
            finding <= 0;
            operation_index <= 1;
            operation_current <= 0;
            operation_start <= 0;
            group_out <= 0;
            prev_MNT <= 0;  // 초기화
        end else begin
            // MNT가 변경되었을 때 case_start를 활성화
            if (MNT != prev_MNT) begin
                case_start <= 1;
                prev_MNT <= MNT;  // 이전 상태 갱신
            end else begin
                case_start <= 0;
            end
            
            if (case_start || operation_done || finding) begin
                case_start <= 0;
                operation_start <= 0;
                finding <= 0;

                if (operation_index <= 8) begin
                    case (operations)
                        8'b11111111: begin
                            operation_current <= operation_index;
                            operation_index <= operation_index + 1;
                            operation_start <= 1;
                        end
                        8'b11001100: begin
                            operation_current <= operation_index;
                            if (operation_index == 2 || operation_index == 6) begin
                                operation_index <= operation_index + 3;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        8'b10101010: begin
                            operation_current <= operation_index;
                            if (operation_index == 1 || operation_index == 3 || operation_index == 5 || operation_index == 7) begin
                                operation_index <= operation_index + 2;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        8'b11110000: begin
                            operation_current <= operation_index;
                            if (operation_index == 4 ) begin
                                operation_index <= operation_index + 5;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        8'b10001000: begin
                            operation_current <= operation_index;
                            if (operation_index == 1 || operation_index == 5) begin
                                operation_index <= operation_index + 4;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        8'b11000000: begin
                            operation_current <= operation_index;
                            if (operation_index == 2) begin
                                operation_index <= operation_index + 7;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        8'b10100000: begin
                            operation_current <= operation_index;
                            if (operation_index == 1 ) begin
                                operation_index <= operation_index + 2;
                            end else if (operation_index == 3) begin
                                operation_index <= operation_index + 6;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        8'b10000000: begin
                            operation_current <= operation_index;
                            if (operation_index == 1) begin
                                operation_index <= operation_index + 8;
                            end else begin
                                operation_index <= operation_index + 1;
                            end
                            operation_start <= 1;
                        end
                        default: begin
                            operation_current <= 0;
                            operation_start <= 0;
                        end
                    endcase
                    case (operations)
                        8'b11111111: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0001; // Group 1
                                2: group_out <= 4'b0010; // Group 2
                                3: group_out <= 4'b0010; // Group 2
                                4: group_out <= 4'b0011; // Group 3
                                5: group_out <= 4'b0011; // Group 3
                                6: group_out <= 4'b0100; // Group 4
                                7: group_out <= 4'b0100; // Group 4
                                default: group_out <= 0;
                            endcase
                        end
                        8'b11001100: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0001; // Group 1
                                2: group_out <= 4'b0001; // Group 1
                                3: group_out <= 4'b0001; // Group 1
                                4: group_out <= 4'b0011; // Group 3
                                5: group_out <= 4'b0011; // Group 3
                                6: group_out <= 4'b0011; // Group 3
                                7: group_out <= 4'b0011; // Group 3
                                default: group_out <= 0;
                            endcase
                        end
                        8'b10101010: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0010; // Group 2
                                2: group_out <= 4'b0010; // Group 2
                                3: group_out <= 4'b0011; // Group 3
                                4: group_out <= 4'b0011; // Group 3
                                5: group_out <= 4'b0100; // Group 4
                                6: group_out <= 4'b0100; // Group 4
                                7: group_out <= 4'b0100; // Group 4
                                default: group_out <= 0;
                            endcase
                        end
                        8'b11110000: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0001; // Group 1
                                2: group_out <= 4'b0010; // Group 2
                                3: group_out <= 4'b0010; // Group 2
                                4: group_out <= 4'b0010; // Group 2
                                5: group_out <= 4'b0010; // Group 2
                                6: group_out <= 4'b0010; // Group 2
                                7: group_out <= 4'b0010; // Group 2
                                default: group_out <= 0;
                            endcase
                        end
                        8'b10001000: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0001; // Group 1
                                2: group_out <= 4'b0001; // Group 1
                                3: group_out <= 4'b0011; // Group 3
                                4: group_out <= 4'b0011; // Group 3
                                5: group_out <= 4'b0011; // Group 3
                                6: group_out <= 4'b0011; // Group 3
                                7: group_out <= 4'b0011; // Group 3
                                default: group_out <= 0;
                            endcase
                        end
                        8'b11000000: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0001; // Group 1
                                2: group_out <= 4'b0001; // Group 1
                                3: group_out <= 4'b0001; // Group 1
                                4: group_out <= 4'b0001; // Group 1
                                5: group_out <= 4'b0001; // Group 1
                                6: group_out <= 4'b0001; // Group 1
                                7: group_out <= 4'b0001; // Group 1
                                default: group_out <= 0;
                            endcase
                        end
                        8'b10100000: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0010; // Group 2
                                2: group_out <= 4'b0010; // Group 2
                                3: group_out <= 4'b0010; // Group 2
                                4: group_out <= 4'b0010; // Group 2
                                5: group_out <= 4'b0010; // Group 2
                                6: group_out <= 4'b0010; // Group 2
                                7: group_out <= 4'b0010; // Group 2
                                default: group_out <= 0;
                            endcase
                        end
                        8'b10000000: begin
                            case (operation_current)
                                0: group_out <= 4'b0001; // Group 1
                                1: group_out <= 4'b0001; // Group 1
                                2: group_out <= 4'b0001; // Group 1
                                3: group_out <= 4'b0001; // Group 1
                                4: group_out <= 4'b0001; // Group 1
                                5: group_out <= 4'b0001; // Group 1
                                6: group_out <= 4'b0001; // Group 1
                                7: group_out <= 4'b0001; // Group 1
                                default: group_out <= 0;
                            endcase
                        end
                        default: group_out <= 0;
                    endcase
                end else begin
                    operation_index <= 0;
                    operation_current <= 0;
                    operation_start <= 0;
                    group_out <= 0;
                end
            end else begin
                operation_start <= 0;
            end
        end
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            // Reset all control signals and address
            EN_I <= 0;
            EN_W <= 0;
            B <= 0;
        end else if (active) begin
            EN_W <= 1;
            EN_I <= 1;
            if (B == 3) begin
                B <= 0;
            end else begin
                B <= B + 1;
            end
        end else if (!active) begin
            EN_I <= 0;
            EN_W <= 0;
            B <= 0;
        end
    end 

    // 블록 신호 설정
    always @(*) begin
        case (operation_current)
            1: begin i_order = 4'b0001; w_order = 4'b0001; end // 블록 1과 A
            2: begin i_order = 4'b0010; w_order = 4'b0010; end // 블록 2와 B
            3: begin i_order = 4'b0001; w_order = 4'b0011; end // 블록 1과 C
            4: begin i_order = 4'b0010; w_order = 4'b0100; end // 블록 2와 D
            5: begin i_order = 4'b0011; w_order = 4'b0001; end // 블록 3과 A
            6: begin i_order = 4'b0100; w_order = 4'b0010; end // 블록 4와 B
            7: begin i_order = 4'b0011; w_order = 4'b0011; end // 블록 3과 C
            8: begin i_order = 4'b0100; w_order = 4'b0100; end // 블록 4와 D
            default: begin i_order = 4'b0000; w_order = 4'b0000; end // 기본값
        endcase
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            // Reset all control signals and address
            ADDR_I <= 0;
        end else begin
            case (i_order) 
                1, 2: begin
                    case (B)
                        0: ADDR_I <= 0;
                        1: ADDR_I <= 1;
                        2: ADDR_I <= 2;
                        3: ADDR_I <= 3;
                        default: ADDR_I <= 0;
                    endcase
                end
                3, 4: begin
                    case (B)
                        0: ADDR_I <= 4;
                        1: ADDR_I <= 5;
                        2: ADDR_I <= 6;
                        3: ADDR_I <= 7;
                        default: ADDR_I <= 0;
                    endcase
                end
            endcase
        end
    end

    always @(posedge CLK or negedge RSTN) begin
        if (!RSTN) begin
            // Reset all control signals and address
            ADDR_W <= 0;
        end else begin
            case (w_order) 
                1, 2: begin
                    case (B)
                        0: ADDR_W <= 0;
                        1: ADDR_W <= 1;
                        2: ADDR_W <= 2;
                        3: ADDR_W <= 3;
                        default: ADDR_W <= 0;
                    endcase
                end
                3, 4: begin
                    case (B)
                        0: ADDR_W <= 4;
                        1: ADDR_W <= 5;
                        2: ADDR_W <= 6;
                        3: ADDR_W <= 7;
                        default: ADDR_W <= 0;
                    endcase
                end
            endcase
        end
    end

endmodule
