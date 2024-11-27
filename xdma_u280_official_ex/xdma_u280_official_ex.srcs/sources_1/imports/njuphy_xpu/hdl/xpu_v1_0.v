
`timescale 1 ns / 1 ps

	module xpu_v1_0 #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line
		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer RSSI_HALF_DB_WIDTH = 11,
		parameter integer C_S00_AXIS_TDATA_WIDTH	= 64,
		parameter integer WIFI_TX_BRAM_ADDR_WIDTH = 10,
		parameter integer TSF_TIMER_WIDTH = 64,
		parameter integer IQ_DATA_WIDTH	= 16,
		parameter integer C_S00_AXI_DATA_WIDTH	= 32,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
		input inner_clk,
		input sys_rst_n,
		//ports to rx
		input signed [(IQ_DATA_WIDTH-1):0] ddc_i,
        input signed [(IQ_DATA_WIDTH-1):0] ddc_q,
        input  pkt_header_valid,
        input  pkt_header_valid_strobe,
        input  fcs_in_strobe,
		input  fcs_ok,
        input  [7:0]rx_packet_rate,
        input  byte_in_strobe,
		input  [7:0] byte_in,
		input  [15:0] byte_count,
		input  [511:0] byte_in_512b,
		input  byte_in_strobe_512b,
		input  [2:0] byte_count_512b,
		input  test_flag_512b,
		input  sig_valid,
		input [47:0] mac_addr,
		
		
		
		//ports to tx
		output tx_allowed,
		output [15:0] duration_to_tx,
		output cts_tx_flag,
		input phy_tx_done,
		input newtask,
		output ack_tx_flag,
		input tx_done_intr,
		output [47:0] dst_addr,
		input pulse_tx_bb_end,
		output cts_received,
        
        input rx_bb_is_ongoing,
        input tx_bb_is_ongoing,
        input rx_done,
        input tx_done,
        input cca,
        input crc_ok,
        input [15:0] rx_packet_len,
        input DATA_flag,
        input high_trigger,
        
        output rx_rstn,
        output tx_rstn,
        output [1:0] sample_freq//

	);
	reg [C_S00_AXI_DATA_WIDTH-1:0] my_reg0,my_reg1,my_reg2;
	
	wire s00_axi_areset_t;
	wire ch_idle;
	wire ack_cts_is_ongoing;
    wire tsf_pulse_1M;
    wire [(TSF_TIMER_WIDTH-1):0]tsf_runtime_val;
	wire fcs_valid;
	wire [3:0] cw_exp_used;
	wire [3:0] cw_exp_dynamic;
	wire retrans_trigger;
	wire quit_retrans;
	wire increase_cw;
	wire backoff_done;
	wire tx_try_complete_int;
	wire is_management;
	wire retrans_in_progress;
	
	wire [31:0] FC_DI;
    wire FC_DI_valid;
	wire [47:0] rx_addr;
    wire rx_addr_valid;
	wire dst_addr_valid;
	wire [47:0] addr3;
	wire addr3_valid;
	wire [47:0] addr4;
    wire addr4_valid;
	wire [15:0] SC;
    wire SC_valid;
	
	wire difs_enable;
	wire [4:0] slot_time;
	wire [6:0] sifs_time;
	wire ack_disable;
	
	wire tx_pkt_need_ack;
	wire [3:0]tx_pkt_retrans_limit;
	wire [14:0]recv_ack_timeout_top_adj;
	wire [1:0] FC_version;
	wire [1:0] FC_type;
	wire [3:0] FC_subtype;
	wire       FC_to_ds;
    wire       FC_from_ds;
    wire       FC_more_frag;
    wire       FC_retry;
    wire       FC_power_manage;
    wire       FC_more_data;
    wire       FC_protected_frame;
    wire       FC_order;
    wire [15:0] duration;
	
	//assign ch_idle = cca && (~ack_cts_is_ongoing);
	assign ch_idle = cca;
	assign fcs_valid = (fcs_in_strobe&fcs_ok);
	assign cw_exp_used = cw_exp_dynamic;
	assign FC_version = FC_DI[1:0];
	assign FC_type =    FC_DI[3:2];
    assign FC_subtype = FC_DI[7:4];
    assign FC_to_ds =   FC_DI[8];
    assign FC_from_ds = FC_DI[9];
    assign FC_more_frag =       FC_DI[10];
    assign FC_retry =           FC_DI[11];
    assign FC_power_manage =    FC_DI[12];
    assign FC_more_data =       FC_DI[13];
    assign FC_protected_frame = FC_DI[14];
    assign FC_order =           FC_DI[15];
    assign duration  =          FC_DI[31:16];
    assign duration_to_tx = duration;
    
    assign tx_allowed = backoff_done;
	
	assign sample_freq = 2'd2;
	assign ack_disable = 1'b0;
	assign difs_enable = 1'b1;
	assign slot_time = 5'd9;
	assign sifs_time = 7'd16;
	//assign mac_addr = 48'h0000_13010002;//if(STANAP==1) lmac_set_mac_addr(MAC_ADDR_H, MAC_ADDR_2);			MAC_ADDR_1 0x13010002  MAC_ADDR_H 0x0000
																//else if(STANAP==2) lmac_set_mac_addr(MAC_ADDR_H, MAC_ADDR_3);		MAC_ADDR_2 0x91900002	
																//else lmac_set_mac_addr(MAC_ADDR_H, MAC_ADDR_1);					MAC_ADDR_3 0x22800002
	assign tx_pkt_need_ack = 1'b1;
	assign tx_pkt_retrans_limit = 4'd0;//暂时不重传
	assign recv_ack_timeout_top_adj = 15'd100;
	assign is_management = (FC_type == 2'b00) ? 1'b1 : 1'b0;
	assign quit_retrans = 1'b0;
	assign rssi_thresh = 8'd200;

	//need to change
	wire [6:0] preamble_sig_time;
    wire [4:0] ofdm_symbol_time;
    wire [6:0] phy_rx_start_delay_time;
    assign preamble_sig_time =    20;
    assign ofdm_symbol_time =   4;
    assign phy_rx_start_delay_time = sample_freq==1?24:25;

	csma_ca  csma_ca_inst (
        .clk(inner_clk),
        .rstn(sys_rst_n),
        
        .tsf_pulse_1M(tsf_pulse_1M),

        .is_management(is_management),
        
        .pkt_header_valid(pkt_header_valid),
        .pkt_header_valid_strobe(pkt_header_valid_strobe),
        .signal_rate(rx_packet_rate),
        .signal_len(rx_packet_len),
        .fcs_in_strobe(fcs_in_strobe),
        .fcs_valid(fcs_valid),

        .nav_enable(1'b0),
        .difs_enable(difs_enable),
        .cw_min(cw_exp_used),
        .preamble_sig_time(preamble_sig_time),
        .ofdm_symbol_time(ofdm_symbol_time),
        .slot_time(slot_time),
        .sifs_time(sifs_time),
        .phy_rx_start_delay_time(phy_rx_start_delay_time),

        .addr1_valid(rx_addr_valid),
        .addr1(rx_addr),
        .self_mac_addr(mac_addr),

        .FC_DI_valid(FC_DI_valid),
        .FC_type(FC_type),
        .FC_subtype(FC_subtype),
        .duration(duration),

        .random_seed({ddc_q[2],ddc_i[0]}),
        .ch_idle(ch_idle),

        .retrans_trigger(retrans_trigger),
        .quit_retrans(quit_retrans),
        .high_trigger(high_trigger),
        .tx_trigger(newtask),
        .tx_bb_is_ongoing(tx_bb_is_ongoing),
        .ack_cts_is_ongoing(ack_cts_is_ongoing),

        .increase_cw(increase_cw),
        .backoff_done(backoff_done)
    );
    
    cw_exp # (
    ) cw_exp_i (
        .clk(inner_clk),
        .rstn(~sys_rst_n),
        .tx_try_complete(tx_try_complete_int),
        .start_retrans(increase_cw),
        .cw_exp(cw_exp_dynamic)
    );
    
    tx_control # (
        .RSSI_HALF_DB_WIDTH(RSSI_HALF_DB_WIDTH),
        .C_S00_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH),
        .WIFI_TX_BRAM_ADDR_WIDTH(WIFI_TX_BRAM_ADDR_WIDTH)
    ) tx_control_i (
        .clk(inner_clk),
        .rstn(sys_rst_n),

        .ack_disable(ack_disable),
        
        .sifs_time(sifs_time),

        .tx_pkt_need_ack(tx_pkt_need_ack),
        .tx_pkt_retrans_limit(tx_pkt_retrans_limit),
        .recv_ack_timeout_top_adj(recv_ack_timeout_top_adj), //100
        .pulse_tx_bb_end(pulse_tx_bb_end),
        .phy_tx_done(phy_tx_done),
        .sig_valid(sig_valid),
        .signal_len(rx_packet_len),
        .fcs_valid(fcs_valid),
        .fcs_in_strobe(fcs_in_strobe),
        .FC_type(FC_type),
        .FC_subtype(FC_subtype),
        .self_mac_addr(mac_addr),
        .addr1(rx_addr),
        .backoff_done(backoff_done),
        .ack_cts_is_ongoing(ack_cts_is_ongoing),     
        .quit_retrans(quit_retrans),
        .retrans_in_progress(retrans_in_progress),
        .cts_received(cts_received),
        .tx_try_complete(tx_try_complete_int),
        .retrans_trigger(retrans_trigger),
        .ack_tx_flag(ack_tx_flag),
        .cts_tx_flag(cts_tx_flag)
    );
	

    tsf_timer # (
	   .TIMER_WIDTH(TSF_TIMER_WIDTH)
	) tsf_timer_i (
	   .clk(inner_clk),
       .rstn(sys_rst_n),
       .tsf_runtime_val(tsf_runtime_val),
       .tsf_pulse_1M(tsf_pulse_1M)
	);
	
	phy_rx_parse phy_rx_parse_i(
	    .clk(inner_clk),
        .rstn(sys_rst_n),

        .ofdm_byte_index(byte_count),
        .ofdm_byte(byte_in),
        .ofdm_byte_valid(byte_in_strobe),
        .ofdm_byte_512b(byte_in_512b),
        .ofdm_byte_valid_512b(byte_in_strobe_512b),
        .byte_count_512b(byte_count_512b),
        .test_flag_512b(test_flag_512b),
        .sig_valid(sig_valid),
        .DATA_flag(DATA_flag),

        .FC_DI(FC_DI),
        .FC_DI_valid(FC_DI_valid),
        
        .rx_addr(rx_addr),
        .rx_addr_valid(rx_addr_valid),
        
        .dst_addr(dst_addr),
        .dst_addr_valid(dst_addr_valid),
        
        .tx_addr(addr3),
        .tx_addr_valid(addr3_valid),
        
        .SC(SC),
        .SC_valid(SC_valid),
        
        .src_addr(addr4),
        .src_addr_valid(addr4_valid)
     );
	//// Add user logic here
    assign rx_rstn = 1;
    assign tx_rstn = 1;
    
	endmodule
