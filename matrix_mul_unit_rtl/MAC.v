module MAC(w_in, d_in, CLK, RSTN, w_out, d_out, result, done, enable, update_ready);
	input [7:0] w_in, d_in;
	output reg [7:0] w_out, d_out;
	input CLK, RSTN;
	output reg [15:0] result;
	reg [15:0] multi;
	input done;
	input enable;
	input update_ready;
	
	wire gated_clk;
	assign gated_clk = CLK & enable;

    always @(posedge gated_clk or negedge RSTN) begin
        if (!RSTN) begin
            // 비동기 리셋
            result <= 0;
            d_out <= 0;
            w_out <= 0;
            multi <= 0;
        end else if (done || !update_ready) begin
            // 연산 완료 또는 업데이트 준비되지 않은 상태 초기화
            result <= 0;
            d_out <= 0;
            w_out <= 0;
            multi <= 0;
        end else if (update_ready) begin
            // 연산 업데이트
            multi <= w_in * d_in; // 곱셈 결과 저장
            result <= result + multi; // 결과 누적
            d_out <= d_in; // 다음 데이터 전송
            w_out <= w_in; // 다음 가중치 전송
        end
    end
endmodule