
`timescale 1 ns / 1 ps

	module phy_rx_parse
	(
        input wire clk,
        input wire rstn,

        input wire [15:0] ofdm_byte_index,
        input wire [7:0] ofdm_byte,
        input wire ofdm_byte_valid,
        input wire [511:0] ofdm_byte_512b,
        input wire ofdm_byte_valid_512b,
        input wire [2:0] byte_count_512b,
        input wire test_flag_512b,
        input wire sig_valid,
        input wire DATA_flag,
        (*mark_debug = "true"*)output reg [31:0] FC_DI,
        (*mark_debug = "true"*)output reg FC_DI_valid,
        
        (*mark_debug = "true"*)output reg [47:0] rx_addr,
        (*mark_debug = "true"*)output reg rx_addr_valid,
        
        output reg [47:0] dst_addr,
        output reg dst_addr_valid,
        
        output reg [47:0] tx_addr,
        output reg tx_addr_valid,
        
        output reg [15:0] SC,
        output reg SC_valid,
        
        output reg [47:0] src_addr,
        output reg src_addr_valid
	);

    (*mark_debug = "true"*)reg data_field;
    wire [511:0] ofdm_byte_512b_reversed;
    //always @(posedge clk) begin
    //    if(rstn == 1'b0) 
    //        data_field <= 0;
    //    else if(sig_valid) data_field <= 1;
    //end
    generate
        genvar i;
        for(i=0; i<64; i=i+1) begin
            assign ofdm_byte_512b_reversed[(511-i*8):(512-(i+1)*8)] = ofdm_byte_512b[((i+1)*8-1):(i*8)];
        end
    endgenerate

    always @( posedge clk ) begin
    if ( rstn == 1'b0 )
        begin
        FC_DI          <= 0;
        FC_DI_valid    <= 0;
        
        rx_addr        <= 0;
        rx_addr_valid  <= 0;
        
        dst_addr       <= 0;
        dst_addr_valid <= 0;
        
        tx_addr        <= 0;
        tx_addr_valid  <= 0;
        
        SC             <= 0;
        SC_valid       <= 0;
        
        src_addr       <= 0;
        src_addr_valid <= 0;
        end
    else
        if (!test_flag_512b && ofdm_byte_valid && DATA_flag) begin
            
            // 2 bytes frame control, 2 bytes duration ID
            if (ofdm_byte_index==0) begin
                FC_DI[7:0]      <= ofdm_byte;
            end
            else if (ofdm_byte_index==1) begin
                FC_DI[15:8]     <= ofdm_byte;
            end
            else if (ofdm_byte_index==2) begin
                FC_DI[23:16]    <= ofdm_byte;
            end
            else if (ofdm_byte_index==3) begin
                FC_DI[31:24]    <= ofdm_byte;
                FC_DI_valid     <=1;
            end
            
            // 6 bytes rx_addr
            else if (ofdm_byte_index==4) begin
                rx_addr[7:0]    <= ofdm_byte;
                FC_DI_valid     <=0;
            end
            else if (ofdm_byte_index==5) begin
                rx_addr[15:8]   <= ofdm_byte;
            end
            else if (ofdm_byte_index==6) begin
                rx_addr[23:16]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==7) begin
                rx_addr[31:24]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==8) begin
                rx_addr[39:32]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==9) begin
                rx_addr[47:40]  <= ofdm_byte;
                rx_addr_valid   <=1;
            end
            
            // 6 bytes dst_addr
            else if (ofdm_byte_index==10) begin
                dst_addr[7:0]   <= ofdm_byte;
                rx_addr_valid   <=0;
            end
            else if (ofdm_byte_index==11) begin
                dst_addr[15:8]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==12) begin
                dst_addr[23:16] <= ofdm_byte;
            end
            else if (ofdm_byte_index==13) begin
                dst_addr[31:24] <= ofdm_byte;
            end
            else if (ofdm_byte_index==14) begin
                dst_addr[39:32] <= ofdm_byte;
            end
            else if (ofdm_byte_index==15) begin
                dst_addr[47:40] <= ofdm_byte;
                dst_addr_valid  <= 1;
            end
            
            // 6 bytes tx_addr
            else if (ofdm_byte_index==16) begin
                tx_addr[7:0]    <= ofdm_byte;
                dst_addr_valid  <= 0;
            end
            else if (ofdm_byte_index==17) begin
                tx_addr[15:8]   <= ofdm_byte;
            end
            else if (ofdm_byte_index==18) begin
                tx_addr[23:16]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==19) begin
                tx_addr[31:24]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==20) begin
                tx_addr[39:32]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==21) begin
                tx_addr[47:40]  <= ofdm_byte;
                tx_addr_valid   <=1;
            end
            
            // 2 bytes sequence control
            else if (ofdm_byte_index==22) begin
                SC[7:0]         <= ofdm_byte;
                tx_addr_valid   <=0;
            end
            else if (ofdm_byte_index==23) begin
                SC[15:8]        <= ofdm_byte;
                SC_valid        <=1;
            end
            
            // 6 bytes src_addr
            else if (ofdm_byte_index==24) begin
                src_addr[7:0]   <= ofdm_byte;
                SC_valid        <=0;
            end
            else if (ofdm_byte_index==25) begin
                src_addr[15:8]  <= ofdm_byte;
            end
            else if (ofdm_byte_index==26) begin
                src_addr[23:16] <= ofdm_byte;
            end
            else if (ofdm_byte_index==27) begin
                src_addr[31:24] <= ofdm_byte;
            end
            else if (ofdm_byte_index==28) begin
                src_addr[39:32] <= ofdm_byte;
            end
            else if (ofdm_byte_index==29) begin
                src_addr[47:40] <= ofdm_byte;
                src_addr_valid  <=1;
            end

            else if (ofdm_byte_index==30) begin
                src_addr_valid  <=0;
            end 
        end
        else if(test_flag_512b && ofdm_byte_valid_512b && byte_count_512b == 3'd1) begin
                FC_DI          <= ofdm_byte_512b_reversed[103:72];
                FC_DI_valid    <= 1'b1;
                rx_addr        <= ofdm_byte_512b_reversed[151:104];
                rx_addr_valid  <= 1'b1;
                dst_addr       <= ofdm_byte_512b_reversed[199:152];
                dst_addr_valid <= 1'b1;
                //此处因为RTS等帧没有以下数据，仍赋�?�为0，存在一定�?�辑错误，但是原csma中似乎未用到下方三个字段，因此暂时保留错�?
                tx_addr        <= ofdm_byte_512b_reversed[247:200];
                tx_addr_valid  <= 1'b1;
                SC             <= ofdm_byte_512b_reversed[263:248];
                SC_valid       <= 1'b1;
                src_addr       <= ofdm_byte_512b_reversed[311:264];
                src_addr_valid <= 1'b1;
        end
        else begin
            FC_DI    <= FC_DI;
            rx_addr  <= rx_addr;
            dst_addr <= dst_addr;
            tx_addr  <= tx_addr;
            SC       <= SC;
            src_addr <= src_addr;
            FC_DI_valid    <= 1'b0;
            rx_addr_valid  <= 1'b0;
            dst_addr_valid <= 1'b0;
            tx_addr_valid  <= 1'b0;
            SC_valid       <= 1'b0;
            src_addr_valid <= 1'b0;
        end
    end

	endmodule
