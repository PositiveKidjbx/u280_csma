
`timescale 1 ns / 1 ps



module cw_exp
(
    input wire  clk,
	input wire  rstn,
    input wire tx_try_complete,
//    input wire [31:0] cw_combined,
    input wire start_retrans,
//    input wire [1:0] tx_queue_idx,
    output reg [3:0] cw_exp
);



always @( posedge clk )
begin
    if ( rstn == 0 )
    begin
        cw_exp <= 4'd4;
    end else begin
        if (tx_try_complete) begin
            cw_exp <= 4'd4; 
        end else begin
            if (start_retrans && (cw_exp < 4'd10)) begin
                cw_exp <= cw_exp + 1'b1; 
            end else begin
                cw_exp <= cw_exp ;
            end
        end
    end
end

endmodule