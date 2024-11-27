`timescale 1ps / 1ps
module xdma_app #(
  parameter TCQ                         = 1,
  parameter C_M_AXI_ID_WIDTH            = 4,
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 16,
  parameter C_DATA_WIDTH                = 512,
  parameter C_M_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_RQ_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 137 : 62),
  parameter C_S_AXIS_CQP_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 183 : 88),
  parameter C_M_AXIS_RC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 161 : 75),
  parameter C_S_AXIS_CC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ?  81 : 33),
  parameter C_S_KEEP_WIDTH              = C_S_AXI_DATA_WIDTH / 32,
  parameter C_M_KEEP_WIDTH              = (C_M_AXI_DATA_WIDTH / 32),
  parameter C_XDMA_NUM_CHNL             = 1
)
(

//VU9P_TUL_EX_String= FALSE

      // AXI streaming ports
    output wire [C_DATA_WIDTH-1:0] s_axis_c2h_tdata_0,  
    output wire s_axis_c2h_tlast_0,
    output wire s_axis_c2h_tvalid_0,
    input  wire s_axis_c2h_tready_0,
    output wire [C_DATA_WIDTH/8-1:0] s_axis_c2h_tkeep_0,
    input  wire [C_DATA_WIDTH-1:0] m_axis_h2c_tdata_0,
    input  wire m_axis_h2c_tlast_0,
    input  wire m_axis_h2c_tvalid_0,
    output wire m_axis_h2c_tready_0,
    input  wire [C_DATA_WIDTH/8-1:0] m_axis_h2c_tkeep_0,

  // System IO signals
  input  wire         user_resetn,
  input  wire         sys_rst_n,
 
  input  wire         user_clk,
  input  wire         user_lnk_up,
 
  output wire   [3:0] leds

);
  //parameter
  localparam [1:0] DATA = 2'b00;
  localparam [1:0] ACK  = 2'b01;
  localparam [1:0] CTS  = 2'b10;
  localparam [1:0] RTS  = 2'b11;
  // wire/reg declarations
  wire            sys_reset;
  reg  [25:0]     user_clk_heartbeat;

  (*mark_debug = "true"*)wire [511:0] rxpu_byte_in;
  (*mark_debug = "true"*)wire         rxpu_byte_in_strobe;
  (*mark_debug = "true"*)wire [2:0]   rxpu_byte_in_count;
  (*mark_debug = "true"*)wire [7:0]   rxpu_packet_rate;
  (*mark_debug = "true"*)wire [15:0]  rxpu_packet_len;
  
  (*mark_debug = "true"*)wire [511:0] txpu_byte_in;
  (*mark_debug = "true"*)wire         txpu_byte_in_strobe;
  (*mark_debug = "true"*)wire [2:0]   txpu_byte_in_count;
  (*mark_debug = "true"*)wire [7:0]   txpu_packet_rate;
  (*mark_debug = "true"*)wire [15:0]  txpu_packet_len;
  
  wire    [15:0]  ddc_i;
  wire    [15:0]  ddc_q;
  wire            txpu_sig_valid;
  wire            rxpu_sig_valid;
  (*mark_debug = "true"*)wire            txpu_cca;
  (*mark_debug = "true"*)wire            rxpu_cca;
  wire            cca;
  wire    [7:0]   rssi_thresh;
  (*mark_debug = "true"*)wire            txpu_tx_allowed;
  (*mark_debug = "true"*)wire            rxpu_tx_allowed;
  wire    [15:0]  duration_to_tx;
  wire            cts_tx_flag;
  (*mark_debug = "true"*)wire            rxpu_ack_tx_flag;
  wire            rxpu_ack_tx_flag_pos;
  wire            rxpu_tx_allowed_pos;
  wire    [47:0]  addr2;
  wire            cts_received;
  wire            rx_rstn;
  wire            tx_rstn;
  wire            pkt_header_valid;
  wire            pkt_header_valid_strobe;
  wire            txpu_tx_bb_is_ongoing;
  wire            txpu_rx_bb_is_ongoing;
  wire            rxpu_tx_bb_is_ongoing;
  wire            rxpu_rx_bb_is_ongoing;
  wire  [47:0]    txpu_mac_addr;
  wire  [47:0]    rxpu_mac_addr;
  wire            crc_ok;
  reg             txpu_phy_tx_done;
  reg             rxpu_phy_tx_done;
  reg             newtask;
  wire            tx_done_intr;
  wire            pulse_tx_bb_end;
  wire            txpu_fcs_in_strobe;
  wire            txpu_fcs_ok;
  wire            rxpu_fcs_in_strobe;
  wire            rxpu_fcs_ok;
  wire            need_rts;
  wire            txpu_high_trigger;
  (*mark_debug = "true"*)wire            m_axis_tready;
  (*mark_debug = "true"*)wire            s_axis_tready;
  (*mark_debug = "true"*)wire            fifo_out_m_axis_tvalid;
  (*mark_debug = "true"*)wire [511 : 0]  fifo_out_m_axis_tdata;
  (*mark_debug = "true"*)wire [63 : 0]   fifo_out_m_axis_tkeep;
  (*mark_debug = "true"*)wire            fifo_out_m_axis_tlast;
  (*mark_debug = "true"*)wire            fifo_out_valid;
  
  wire [511:0]    ACK_frame;
  
  reg             txpu_byte_in_strobe_par_dly0;
  reg             rxpu_byte_in_strobe_par_dly0;
  reg             m_axis_tvalid_dly0;
  reg             m_axis_h2c_tvalid_0_dly0;
  reg             fifo_out_m_axis_tvalid_dly0;
  reg             rxpu_ack_tx_flag_dly0;
  reg             rxpu_tx_allowed_dly0;
  reg             m_axis_tready_reg;
  reg  [1:0]      trans_type_state;
  reg             ctl_start;
  reg  [1:0]      FC_type_new;
  reg  [3:0]      FC_subtype_new;
  reg             rts_done;
  reg             s_axis_c2h_tready_reg;
  wire  [511:0]   txpu_byte_in_dly;
  wire            txpu_byte_in_strobe_dly;
  wire            txpu_byte_tlast_dly;
  wire [511:0]    rxpu_byte_in_dly;
  wire            rxpu_byte_in_strobe_dly;
  wire            rxpu_byte_in_tlast_dly;
  reg  [511:0]    rxpu_byte_out_reg;
  reg             rxpu_byte_out_strobe_reg;
  reg             rxpu_byte_out_tlast_reg;
  // The sys_rst_n input is active low based on the core configuration
  assign sys_resetn = sys_rst_n;

      // AXI streaming ports
      assign s_axis_c2h_tdata_0 =  m_axis_h2c_tdata_0;   
      assign s_axis_c2h_tlast_0 =  m_axis_h2c_tlast_0;   
      assign s_axis_c2h_tvalid_0 =  m_axis_h2c_tvalid_0;   
      assign s_axis_c2h_tkeep_0 =  m_axis_h2c_tkeep_0;  
      assign m_axis_h2c_tready_0 = s_axis_c2h_tready_0;
      //ACK Frame
      assign ACK_frame = {320'd0,8'h00,8'h00,8'h13,8'h01,8'h00,8'h02,8'h00,8'h00,8'h91,8'h90,8'h00,8'h02,8'h00,8'h00,8'h00,8'hd4,8'h03,8'h3c,8'h06,8'h00,8'h0e,8'h00,8'h00,8'h0e,8'h0b};
                                 //tx_addr                           //rx_addr                           //FC_DI           //FC_type                         //len    //rate
    //xpu logic assign
    //assign sig_valid = (pkt_header_valid_strobe & pkt_header_valid);
    assign txpu_mac_addr = 48'h0000_91900002;
    assign rxpu_mac_addr = 48'h0000_13010002;
    assign txpu_sig_valid = txpu_byte_in_strobe;//暂定
    assign rxpu_sig_valid = rxpu_byte_in_strobe;//暂定
    assign fifo_out_valid = fifo_out_m_axis_tvalid && m_axis_tready;
    
    assign txpu_tx_bb_is_ongoing = fifo_out_valid;
    assign txpu_rx_bb_is_ongoing = txpu_byte_in_strobe;
    
    assign rxpu_tx_bb_is_ongoing = rxpu_byte_out_strobe_reg;
    assign rxpu_rx_bb_is_ongoing = rxpu_byte_in_strobe;
    
    assign txpu_cca = (~txpu_rx_bb_is_ongoing) && (~txpu_tx_bb_is_ongoing);
    assign rxpu_cca = (~rxpu_rx_bb_is_ongoing) && (~rxpu_tx_bb_is_ongoing);
    assign cca = txpu_cca && rxpu_cca;
    assign txpu_fcs_in_strobe = (~txpu_byte_in_strobe) && txpu_byte_in_strobe_par_dly0; //negedge
    assign txpu_fcs_ok = txpu_fcs_in_strobe;
    assign rxpu_fcs_in_strobe = (~rxpu_byte_in_strobe) && rxpu_byte_in_strobe_par_dly0; //negedge
    assign rxpu_fcs_ok = rxpu_fcs_in_strobe;
    assign need_rts = 1'b0;//由于暂时设计的交互仅有data和ack，暂时置0
    assign txpu_high_trigger = m_axis_h2c_tvalid_0 && (~m_axis_h2c_tvalid_0_dly0); //posedge
    assign rxpu_ack_tx_flag_pos = rxpu_ack_tx_flag && (~rxpu_ack_tx_flag_dly0);//posedge
    assign rxpu_tx_allowed_pos = rxpu_tx_allowed && (~rxpu_tx_allowed_dly0); //posedge
    assign m_axis_tready = m_axis_tready_reg;
    //xpu logic always
    always @(posedge user_clk) begin
        if(!sys_resetn) begin
            txpu_byte_in_strobe_par_dly0  <= 1'd0;
            rxpu_byte_in_strobe_par_dly0  <= 1'd0;
            fifo_out_m_axis_tvalid_dly0   <= 1'd0;
            m_axis_h2c_tvalid_0_dly0      <= 1'd0;
            rxpu_ack_tx_flag_dly0         <= 1'd0;
            rxpu_tx_allowed_dly0          <= 1'd0;
        end else begin
            txpu_byte_in_strobe_par_dly0  <= txpu_byte_in_strobe;
            rxpu_byte_in_strobe_par_dly0  <= rxpu_byte_in_strobe;
            fifo_out_m_axis_tvalid_dly0   <= fifo_out_m_axis_tvalid;
            m_axis_h2c_tvalid_0_dly0      <= m_axis_h2c_tvalid_0;
            rxpu_tx_allowed_dly0          <= rxpu_tx_allowed;
            rxpu_ack_tx_flag_dly0         <= rxpu_ack_tx_flag;
        end
    end
    
    always @(posedge user_clk) begin
        if(!sys_resetn) begin
            m_axis_tready_reg <= 1'd0;
            txpu_phy_tx_done <= 1'b0;
        end else begin
            if(txpu_tx_allowed) begin
                m_axis_tready_reg <= 1'b1;
            end
            else if((~fifo_out_m_axis_tvalid) && fifo_out_m_axis_tvalid_dly0) begin //negedge
                m_axis_tready_reg <= 1'b0;
                txpu_phy_tx_done <= 1'b1;
            end
            else begin
                m_axis_tready_reg <= m_axis_tready_reg;
                txpu_phy_tx_done <= 1'b0;
            end
        end
    end
    
    always @(posedge user_clk) begin
        if(!sys_resetn) begin
            newtask <= 1'b0;
            trans_type_state <= DATA;
            rxpu_byte_out_reg <= 512'b0;
            rxpu_byte_out_strobe_reg <= 1'b0;
            rxpu_byte_out_tlast_reg <= 1'b0;
            rxpu_phy_tx_done <= 1'b0;
        end
        else begin
            case(trans_type_state)
                DATA: begin
                    rxpu_byte_out_reg <= 512'b0;
                    rxpu_byte_out_strobe_reg <= 1'b0;
                    rxpu_byte_out_tlast_reg <= 1'b0;
                    rxpu_phy_tx_done <= 1'b0;
                    if(newtask)
                        rts_done <= 0;
                    if(rxpu_ack_tx_flag_pos)begin
                        trans_type_state <= ACK;
                        ctl_start <= 1;
                        FC_type_new <= 2'b01;
                        FC_subtype_new <= 4'b1101;
                        newtask <= 1'b1;
                    end
                    else if(cts_tx_flag)begin
                        trans_type_state <= CTS;
                        ctl_start <= 1;
                        FC_type_new <= 2'b01;
                        FC_subtype_new <= 4'b1100;
                        newtask <= 1'b1;
                    end
                    else if(need_rts&&(!rts_done))begin
                        trans_type_state <= RTS;
                        FC_type_new <= 2'b01;
                        FC_subtype_new <= 4'b1011;
                        newtask <= 1'b1;
                    end
                end
                ACK:begin
                    if(rxpu_tx_allowed_pos) begin 
                        trans_type_state <= DATA;                     
                        rxpu_byte_out_reg <= ACK_frame;
                        rxpu_byte_out_strobe_reg <= 1'b1;
                        rxpu_byte_out_tlast_reg <= 1'b1;
                        rxpu_phy_tx_done <= 1'b1;
                        newtask <= 1'b0;
                    end
                    else begin
                        ctl_start <= 1'b0; 
                        newtask <= 1'b0;
                        trans_type_state <= trans_type_state;
                    end
                end
                CTS:begin
                
                end
                RTS:begin
                
                end
            endcase
        end
    end
//delay
delay_T #(.DATA_WIDTH(514), .DELAY(10)) txpu_delay_inst (
    .clock(user_clk),
    .rst_n(sys_resetn),

    .data_in({rxpu_byte_out_reg, rxpu_byte_out_strobe_reg,rxpu_byte_out_tlast_reg}),
    .data_out({txpu_byte_in_dly, txpu_byte_in_strobe_dly, txpu_byte_tlast_dly})
);
// parse the info packet 
  info_parser  txpu_parser_inst (
    .sys_clk                        (user_clk),
    .sys_rstn                       (sys_resetn),
    .s_axis_cmac_rx_tvalid          (txpu_byte_in_strobe_dly),
    .s_axis_cmac_rx_tdata           (txpu_byte_in_dly),
    .s_axis_cmac_rx_tkeep           (),
    .s_axis_cmac_rx_tlast           (txpu_byte_tlast_dly),

    .byte_out_512b                  (txpu_byte_in),
    .byte_out_strobe_512b           (txpu_byte_in_strobe),
    .byte_out_count_512b            (txpu_byte_in_count),
    .rx_packet_rate                 (txpu_packet_rate),
    .rx_packet_len                  (txpu_packet_len)
  );
//xpu tx
	xpu_v1_0 inst_xpu_tx (
	   ////////////////////////input/////////////////
		.inner_clk               (user_clk),
		.sys_rst_n               (sys_resetn),
		.ddc_i                   (16'hf8ed),//暂定
		.ddc_q                   (16'hfea5),//暂定
		.pkt_header_valid        (1'b0),//由于未使用nav而无作用
		.pkt_header_valid_strobe (1'b0),//由于未使用nav而无作用
		.fcs_in_strobe           (txpu_fcs_in_strobe),
		.fcs_ok                  (txpu_fcs_ok),
		.rx_packet_rate          (txpu_packet_rate),
		.rx_packet_len           (txpu_packet_len),
		.byte_in_512b            (txpu_byte_in),
		.byte_in_strobe_512b     (txpu_byte_in_strobe),
		.byte_count_512b         (txpu_byte_in_count),
		.test_flag_512b          (1'b1),
		.sig_valid               (txpu_sig_valid),
		.mac_addr                (txpu_mac_addr),
		.tx_bb_is_ongoing        (txpu_tx_bb_is_ongoing),
		.cca                     (cca),
		.phy_tx_done             (txpu_phy_tx_done),
		.newtask                 (),
		.pulse_tx_bb_end         (txpu_phy_tx_done),//暂时和phy_tx_done相同
		.high_trigger            (txpu_high_trigger),
		//////////////////////////output////////////////////
		.tx_allowed              (txpu_tx_allowed),
		.duration_to_tx          (),
		.cts_tx_flag             (),
		.ack_tx_flag             (),
		.dst_addr                (),
		.cts_received            ()
		);
//fifo
fifo_generator_0 fifo_generator_0_inst (
  .s_aclk(user_clk),                // input wire s_aclk
  .s_aresetn(sys_resetn),          // input wire s_aresetn
  .s_axis_tvalid(m_axis_h2c_tvalid_0),  // input wire s_axis_tvalid
  .s_axis_tready(s_axis_tready),  // output wire s_axis_tready
  .s_axis_tdata(m_axis_h2c_tdata_0),    // input wire [511 : 0] s_axis_tdata
  .s_axis_tkeep(m_axis_h2c_tkeep_0),    // input wire [63 : 0] s_axis_tkeep
  .s_axis_tlast(m_axis_h2c_tlast_0),    // input wire s_axis_tlast
  .m_axis_tvalid(fifo_out_m_axis_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),  // input wire m_axis_tready
  .m_axis_tdata(fifo_out_m_axis_tdata),    // output wire [511 : 0] m_axis_tdata
  .m_axis_tkeep(fifo_out_m_axis_tkeep),    // output wire [63 : 0] m_axis_tkeep
  .m_axis_tlast(fifo_out_m_axis_tlast)    // output wire m_axis_tlast
);
//delay
delay_T #(.DATA_WIDTH(514), .DELAY(10)) rxpu_delay_inst (
    .clock(user_clk),
    .rst_n(sys_resetn),

    .data_in({fifo_out_m_axis_tdata, fifo_out_valid,fifo_out_m_axis_tlast}),
    .data_out({rxpu_byte_in_dly,rxpu_byte_in_strobe_dly,rxpu_byte_in_tlast_dly})
);
// parse the info packet 
  info_parser  rxpu_parser_inst (
    .sys_clk                        (user_clk),
    .sys_rstn                       (sys_resetn),
    .s_axis_cmac_rx_tvalid          (rxpu_byte_in_strobe_dly),
    .s_axis_cmac_rx_tdata           (rxpu_byte_in_dly),
    .s_axis_cmac_rx_tkeep           (),
    .s_axis_cmac_rx_tlast           (rxpu_byte_in_tlast_dly),

    .byte_out_512b                  (rxpu_byte_in),
    .byte_out_strobe_512b           (rxpu_byte_in_strobe),
    .byte_out_count_512b            (rxpu_byte_in_count),
    .rx_packet_rate                 (rxpu_packet_rate),
    .rx_packet_len                  (rxpu_packet_len)
  );
//xpu rx
	xpu_v1_0 inst_xpu_rx (
	   ////////////////////////input/////////////////
		.inner_clk               (user_clk),
		.sys_rst_n               (sys_resetn),
		.ddc_i                   (16'hf8ed),//暂定
		.ddc_q                   (16'hfea5),//暂定
		.pkt_header_valid        (1'b0),//由于未使用nav而无作用
		.pkt_header_valid_strobe (1'b0),//由于未使用nav而无作用
		.fcs_in_strobe           (rxpu_fcs_in_strobe),
		.fcs_ok                  (rxpu_fcs_ok),
		.rx_packet_rate          (rxpu_packet_rate),
		.rx_packet_len           (rxpu_packet_len),
		.byte_in_512b            (rxpu_byte_in),
		.byte_in_strobe_512b     (rxpu_byte_in_strobe),
		.byte_count_512b         (rxpu_byte_in_count),
		.test_flag_512b          (1'b1),
		.sig_valid               (rxpu_sig_valid),
		.mac_addr                (rxpu_mac_addr),
		.tx_bb_is_ongoing        (rxpu_tx_bb_is_ongoing),
		.cca                     (cca),
		.phy_tx_done             (rxpu_phy_tx_done),
		.newtask                 (newtask),
		.pulse_tx_bb_end         (rxpu_phy_tx_done),//暂时和phy_tx_done相同
		.high_trigger            (),
		//////////////////////////output////////////////////
		.tx_allowed              (rxpu_tx_allowed),
		.duration_to_tx          (),
		.cts_tx_flag             (),
		.ack_tx_flag             (rxpu_ack_tx_flag),
		.dst_addr                (dst_addr),
		.cts_received            (cts_received)
		);
	//ila 
ila_0 ila_0_inst (
	.clk(user_clk), // input wire clk


	.probe0(rxpu_byte_in), // input wire [511:0]  probe0  
	.probe1(rxpu_byte_in_strobe), // input wire [0:0]  probe1 
	.probe2(rxpu_byte_in_count), // input wire [2:0]  probe2 
	.probe3(s_axis_tready), // input wire [0:0]  probe3 
	.probe4(fifo_out_m_axis_tvalid), // input wire [0:0]  probe4 
	.probe5(m_axis_tready), // input wire [0:0]  probe5 
	.probe6(rxpu_byte_in_dly), // input wire [511:0]  probe6 
	.probe7(fifo_out_m_axis_tkeep), // input wire [63:0]  probe7 
	.probe8(rxpu_byte_in_tlast_dly), // input wire [0:0]  probe8 
	.probe9(txpu_tx_allowed), // input wire [0:0]  probe9 
	.probe10(rxpu_byte_in_strobe_dly), // input wire [0:0]  probe10 
	.probe11(rxpu_tx_allowed_pos), // input wire [0:0]  probe11 
	.probe12(rxpu_ack_tx_flag_pos), // input wire [0:0]  probe12 
	.probe13(txpu_byte_in), // input wire [511:0]  probe13 
	.probe14(txpu_byte_in_strobe), // input wire [0:0]  probe14 
	.probe15(txpu_byte_in_count), // input wire [2:0]  probe15 
	.probe16(txpu_packet_rate), // input wire [7:0]  probe16 
	.probe17(txpu_packet_len), // input wire [15:0]  probe17
	.probe18(trans_type_state), // input wire [1:0]  probe18 
	.probe19(txpu_cca), // input wire [0:0]  probe19 
	.probe20(rxpu_cca), // input wire [0:0]  probe20
	.probe21(newtask), // input wire [0:0]  probe21
	.probe22(rxpu_ack_tx_flag), // input wire [0:0]  probe22 
	.probe23(rxpu_ack_tx_flag_dly0), // input wire [0:0]  probe23 
	.probe24(rxpu_tx_allowed), // input wire [0:0]  probe24 
	.probe25(rxpu_tx_allowed_dly0) // input wire [0:0]  probe2
);
	
endmodule
