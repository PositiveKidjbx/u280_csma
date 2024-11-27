module info_parser
#(
parameter ETH_HEADER_LEN = 112,       // (6 + 6 + 2) * 8
parameter IP_HEADER_LEN = 160,        //  20 * 8
parameter PROTOCAL_LOCATION = 72      // protocal in IP header, 8 bit, where 143 means info packets from switcher
    )
(
    input           sys_clk,
    input           sys_rstn,
    input           s_axis_cmac_rx_tvalid,
    input [511:0]   s_axis_cmac_rx_tdata,
    input [63:0]    s_axis_cmac_rx_tkeep,
    input           s_axis_cmac_rx_tlast,
    input           s_axis_cmac_rx_tuser_err,
  
    output  reg [511:0] byte_out_512b,
    output  reg         byte_out_strobe_512b,
    output  reg [2:0]   byte_out_count_512b,
    output  reg [7:0]   rx_packet_rate,
    output  reg [15:0]  rx_packet_len
);

//parameter
localparam [1:0] IDLE          = 2'b00;        
localparam [1:0] FINAL         = 2'b01;      
//reg    
reg [1:0] state;
//wire
wire proto_right;
wire [7:0] protocol;
wire [511:0] data_sorted;
//assign
assign protocol = data_sorted[(511-(ETH_HEADER_LEN+PROTOCAL_LOCATION)):(511-(ETH_HEADER_LEN+PROTOCAL_LOCATION+7))];
assign proto_right = (protocol == 8'ha0) ? 1'b1 : 1'b0;
    
//将axis_keep_num取以2为底的对数并且向上取�?
function integer clog2;
    input integer axis_keep_num;
    begin
        for(clog2 = 0;axis_keep_num > 0; clog2 = clog2 + 1)
            axis_keep_num = axis_keep_num >> 1;
    end
endfunction
    
// resort the data with 8bit(bytes)
generate
genvar i;
for(i=0; i<64; i=i+1) begin
  assign data_sorted[(511-i*8):(512-(i+1)*8)] = s_axis_cmac_rx_tdata[((i+1)*8-1):(i*8)];
end
endgenerate
    
// Parse the information
always@(posedge sys_clk) begin
    if(!sys_rstn) begin
        state <= IDLE;
        byte_out_512b <= 512'b0;
        byte_out_strobe_512b <= 1'b0;
        byte_out_count_512b <= 3'b0;
        rx_packet_rate <= 8'b0; 
        rx_packet_len <= 16'b0;
    end 
    else begin
        case (state)
            IDLE: begin
                if(s_axis_cmac_rx_tvalid) begin     // packet valid
                    if(s_axis_cmac_rx_tlast) begin
                        state <= FINAL;
                    end
                    else begin
                        state <= state;
                    end
                    byte_out_512b <= data_sorted;
                    byte_out_strobe_512b <= 1'b1; 
                    byte_out_count_512b <= byte_out_count_512b + 1'b1;
                    if(byte_out_count_512b == 3'b0) begin
                        rx_packet_rate <= {1'b1,data_sorted[486:480]};
                        rx_packet_len <= {data_sorted[467:464],data_sorted[479:472]};
                    end
                end 
                else begin 
                    state <= IDLE;
                    byte_out_strobe_512b <= 1'b0; 
                end
            end 
            FINAL: begin           
                state <= IDLE;
                byte_out_512b <= 512'b0;
                byte_out_strobe_512b <= 1'b0;
                byte_out_count_512b <= 3'b0;
                rx_packet_rate <= 8'b0; 
                rx_packet_len <= 16'b0;
            end
            default: ;    
        endcase
    end
end
endmodule
