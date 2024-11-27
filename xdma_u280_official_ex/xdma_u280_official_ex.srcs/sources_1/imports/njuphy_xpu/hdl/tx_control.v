`include "clock_speed.v"
`include "board_def.v"
// `define DEBUG_PREFIX (*mark_debug="true",DONT_TOUCH="TRUE"*)
`define DEBUG_PREFIX


`timescale 1 ns / 1 ps

	module tx_control #
	(
	   parameter integer RSSI_HALF_DB_WIDTH = 11,
	   parameter integer C_S00_AXIS_TDATA_WIDTH	= 64,
     parameter integer WIFI_TX_BRAM_ADDR_WIDTH = 10
	)
	(// main function: after receive data, send ack; after send data, disable tx for a while because need to wait for ack from peer.
        input wire clk,
        input wire rstn,
        
        input wire ack_disable,
        input wire [6:0] sifs_time,
        input wire tx_pkt_need_ack,
        input wire [3:0] tx_pkt_retrans_limit,
        input wire [14:0] recv_ack_timeout_top_adj,
        input wire pulse_tx_bb_end,
        input wire phy_tx_done,
        input wire sig_valid,
        input wire [15:0] signal_len,
        input wire fcs_valid,
        input wire fcs_in_strobe,
        input wire [1:0] FC_type,
        input wire [3:0] FC_subtype,
//        input wire [47:0] addr2,
        input wire [47:0] self_mac_addr,
        input wire [47:0] addr1,
        input wire backoff_done,
//        input wire newtask,
        input wire quit_retrans,
//        output reg [(C_S00_AXIS_TDATA_WIDTH-1):0] dina,
        output reg retrans_in_progress,
        (*mark_debug = "true"*)output reg cts_received,
        (*mark_debug = "true"*)output wire ack_cts_is_ongoing,
        (*mark_debug = "true"*)output reg retrans_trigger,
        (*mark_debug = "true"*)output reg tx_try_complete,
        (*mark_debug = "true"*)output reg ack_tx_flag,
        (*mark_debug = "true"*)output reg cts_tx_flag
	);

  localparam [2:0]    IDLE =                     3'b000,
                      SEND_ACK_CTS =             3'b001,
                      RECV_CTS =                 3'b010,
                      RECV_ACK_JUDGE =           3'b011,
                      RECV_ACK_WAIT_TX_BB_DONE = 3'b100,
                      RECV_ACK_WAIT_SIG_VALID  = 3'b101,
                      RECV_ACK       =           3'b110,
                      RECV_ACK_WAIT_BACKOFF_DONE=3'b111;
//                      WAIT_FOR_NEW_TRANS =                    3'b111;

  (*mark_debug = "true"*)reg [3:0] num_retrans;
  (*mark_debug = "true"*)reg [14:0] ack_timeout_count;
//  reg [47:0] ack_addr;
  (*mark_debug = "true"*)reg [2:0] tx_control_state;
  // reg [2:0] tx_control_state_priv;
  wire is_data;
  wire is_ack;
  wire is_rts;
  wire is_cts;



  // `DEBUG_PREFIX wire [2:0] num_data_ofdm_symbol;
  // reg  [2:0] num_data_ofdm_symbol_reg;
  reg [14:0] num_data_ofdm_symbol_reg_tmp;
  reg [14:0] send_ack_wait_top_scale;
  // `DEBUG_PREFIX wire [2:0] ackcts_n_sym;
  // reg  [2:0] ackcts_n_sym_reg;
  
  reg [14:0] recv_ack_timeout_top;
  

  reg [14:0] recv_ack_timeout_top_adj_scale;
  (*mark_debug = "true"*)reg retrans_started ;

  assign is_data =        ((FC_type == 2'b10) ? 1 : 0);
  assign is_ack =    (((FC_type == 2'b01) && (FC_subtype == 4'b1101)) ? 1 : 0);
  assign is_rts = (((FC_type == 2'b01) && (FC_subtype == 4'b1011)) ? 1 : 0);
  assign is_cts = (((FC_type == 2'b01) && (FC_subtype == 4'b1100)) ? 1 : 0);

  assign ack_cts_is_ongoing = tx_control_state == SEND_ACK_CTS;
  // // this is not needed. we should assume the peer always send us ack @ 6Mbps
  // n_sym_len14_pkt # (
  // ) n_sym_len14_pkt_i0 (
  //   .ht_flag(signal_rate[7]),
  //   .rate_mcs(signal_rate[3:0]),
  //   .n_sym(num_data_ofdm_symbol)
  // );

  // // this is not needed. we should assume the peer always send us ack @ 6Mbps
  // n_sym_len14_pkt # (
  // ) n_sym_len14_pkt_i1 (
  //   .ht_flag(0),
  //   .rate_mcs(ackcts_rate),
  //   .n_sym(ackcts_n_sym)
  // );

	always @(posedge clk)                                             
    begin
      if (!rstn)
      // Synchronous reset (active low)                                       
        begin
          ack_timeout_count<=0;
//          ack_addr <=0;
          ack_tx_flag<=0;
          tx_control_state  <= IDLE;
//          duration_new<=0;
//          FC_type_new<=0;
//          FC_subtype_new<=0;
          // tx_control_state_priv <= IDLE;
          tx_try_complete<=0;
          num_retrans<=0;
          recv_ack_timeout_top<=0;
          retrans_in_progress<=0;
          retrans_started<=0;

          // num_data_ofdm_symbol_reg <= 0;
          // num_data_ofdm_symbol_reg_tmp <= 0;
          num_data_ofdm_symbol_reg_tmp <= (({3'd6,2'd0})*`NUM_CLK_PER_US); // ack/cts use 6 ofdm symbols at 6Mbps      4800
          send_ack_wait_top_scale <= (({3'd6,2'd0})*`NUM_CLK_PER_US); //4800 == 24 * 200
          // ackcts_n_sym_reg <= 0;

          recv_ack_timeout_top_adj_scale <= 0;
        end
      else begin
        // tx_control_state_priv<=tx_control_state;
        
        //ackcts_rate <= (cts_torts_rate[4]?signal_rate[3:0]:cts_torts_rate[3:0]); // this is not needed. we should assume the peer always send us ack @ 6Mbps
        // ackcts_time <= preamble_sig_time + ofdm_symbol_time*({4'd0,ackcts_n_sym_reg}); 

        // num_data_ofdm_symbol_reg <= num_data_ofdm_symbol;
        // num_data_ofdm_symbol_reg_tmp <= (({num_data_ofdm_symbol_reg,2'd0})*`NUM_CLK_PER_US);
        // ackcts_n_sym_reg <= ackcts_n_sym;
        recv_ack_timeout_top_adj_scale <= (recv_ack_timeout_top_adj*`NUM_CLK_PER_US); //20_000 = 100 * 200

        case (tx_control_state)
          IDLE: begin
            ack_tx_flag<=0;
            cts_tx_flag<=0;
            ack_timeout_count<=0;
            tx_try_complete<=0;
            recv_ack_timeout_top<=0;
            retrans_trigger<=0;
            cts_received<=0;
//            duration_new<=0;
//            FC_type_new<=0;
//            FC_subtype_new<=0;
//            ack_addr <= addr2;
            // tx_status<=tx_status; //maintain status from state RECV_ACK for ARM reading
            // num_retrans<=num_retrans;
            // retrans_in_progress<=retrans_in_progress;

            //8.3.1.4 ACK frame format: The RA field of the ACK frame is copied from the Address 2 field of the immediately previous individually
            //addressed data, management, BlockAckReq, BlockAck, or PS-Poll frames.
            if ( fcs_valid && (is_data||is_rts)
                           && (self_mac_addr==addr1)) // send ACK will not back to this IDLE until the last IQ sample sent.
              begin
                  tx_control_state  <= (ack_disable?tx_control_state:SEND_ACK_CTS); //we also send cts (if rts is received) in SEND_ACK status
              end 
            //else if ( pulse_tx_bb_end && tx_pkt_type[0]==1 && (core_state_old!=SEND_ACK) )// need to recv ACK! We need to miss this pulse_tx_bb_end intentionally when send ACK, because ACK don't need ACK
            //else if ( phy_tx_done && (core_state_old!=SEND_ACK) )// need to recv ACK! We need to miss this pulse_tx_bb_end intentionally when send ACK, because ACK don't need ACK
            else if ( phy_tx_done &&(!ack_tx_flag)&&(!cts_tx_flag)) // because SEND_ACK won't be back until phy_tx_done. So here phy_tx_done must be from high layer
              begin
                  tx_control_state  <= RECV_ACK_JUDGE;
              end
            else if ((quit_retrans == 1) && (retrans_in_progress==1)) 
              begin 
                  //tx_control_state <= QUIT_RETX;
                  tx_control_state<= IDLE;
                  tx_try_complete<=1;
                  num_retrans<=0;
                  retrans_in_progress<=0;
                  retrans_started<=0;
              end 
            else if ((backoff_done == 1)&&(retrans_in_progress==1) && (retrans_started==0))
              begin
                  tx_control_state  <= RECV_ACK_WAIT_BACKOFF_DONE;
              end
          end

          SEND_ACK_CTS: begin 
            if(is_data)
                ack_tx_flag <= 1;
            else if(is_rts)
                cts_tx_flag <= 1;
            ack_timeout_count <= ack_timeout_count + 1;
            tx_control_state <=  ((phy_tx_done||(ack_timeout_count==send_ack_wait_top_scale))?IDLE:tx_control_state);
          end

          RECV_CTS: begin
            cts_received <= 0;
            tx_control_state <=  IDLE;
            
          end

          RECV_ACK_JUDGE: begin
            // ack_tx_flag<=ack_tx_flag;
            // wea<=wea;
            // dina<=dina;
            // send_ack_count <= send_ack_count;
            // ack_addr <= ack_addr;
            // ack_timeout_count<=ack_timeout_count;
            // start_retrans<=start_retrans;
            // tx_dpram_op_counter<=tx_dpram_op_counter;
            // douta_reg<=douta_reg;
            // recv_ack_timeout_top<=recv_ack_timeout_top;
            retrans_started<=0;
            if (tx_pkt_need_ack==1) // continue to actual ACK receiving
                begin
                tx_control_state<= RECV_ACK_WAIT_SIG_VALID;
                tx_try_complete<=0;
                // tx_status<=tx_status; //maintain status from state RECV_ACK for ARM reading
                // num_retrans<=num_retrans;
                retrans_in_progress<=1;
                end
            else
                begin
                tx_control_state<= IDLE;
                // addra<=addra;
                tx_try_complete<=1;
                // tx_status<={1'b0,num_retrans}; // because interrupt will be raised, set status
                num_retrans<=0;
                retrans_in_progress<=0;
                end

          end

          RECV_ACK_WAIT_TX_BB_DONE: begin
            // ack_tx_flag<=ack_tx_flag;
            // recv_ack_timeout_top<=recv_ack_timeout_top;

            // addra<=addra;

            // send_ack_count <= send_ack_count;
            // ack_addr <= ack_addr;
            // ack_timeout_count<=ack_timeout_count;
            // // tx_status<=tx_status; //maintain status from state RECV_ACK for ARM reading
            // num_retrans<=num_retrans;
            // tx_try_complete<=tx_try_complete;
            // start_retrans<=start_retrans;
            // retrans_in_progress<=retrans_in_progress;

            if (pulse_tx_bb_end) begin
                tx_control_state<= RECV_ACK_WAIT_SIG_VALID;
            end 
            // else begin
            //     tx_control_state<= tx_control_state;
            // end
            
          end

          RECV_ACK_WAIT_SIG_VALID: begin
            // ack_tx_flag<=ack_tx_flag;
            // wea<=wea;
            // addra<=addra;
            // dina<=dina;
            // send_ack_count <= send_ack_count;
            // ack_addr <= ack_addr;
            // tx_dpram_op_counter<=tx_dpram_op_counter;
            // douta_reg<=douta_reg;
            // recv_ack_timeout_top<=recv_ack_timeout_top;

            ack_timeout_count<= ack_timeout_count+1;
            if ( sig_valid && (signal_len==14) ) begin //before timeout, we detect a sig valid, signal length field is ACK
                tx_control_state<= RECV_ACK;
                // tx_try_complete<=tx_try_complete;
                // tx_status<=tx_status;
                // num_retrans<=num_retrans;
                // start_retrans<=start_retrans;
                // retrans_in_progress<=retrans_in_progress;
                // ack_timeout_count<=0;
                recv_ack_timeout_top <= num_data_ofdm_symbol_reg_tmp+recv_ack_timeout_top_adj_scale;  // 4800 + 20_000 = 24800
            end else if ( ack_timeout_count==recv_ack_timeout_top_adj_scale ) begin // sig valid timeout
                tx_control_state<= IDLE;
                if  ((num_retrans == tx_pkt_retrans_limit) || (tx_pkt_retrans_limit == 4'd0)) begin// should not run into this state. but just in case
                    tx_try_complete<=1;
                    // tx_status<={1'b1,num_retrans};
                    num_retrans<=0;
                    // start_retrans<=start_retrans;
                    retrans_in_progress<=0;
                end else begin
                    // tx_try_complete<=tx_try_complete;
                    // tx_status<=tx_status;
                    num_retrans<=num_retrans+1;
                    retrans_trigger<=1;// start retransmission if ack did not arrive in time --
                    // retrans_in_progress<=retrans_in_progress;
                end
            end 
            // else begin
            //     tx_control_state<= tx_control_state;
            //     tx_try_complete<=tx_try_complete;
            //     // tx_status<=tx_status; //maintain status from state RECV_ACK for ARM reading
            //     num_retrans<=num_retrans;
            //     start_retrans<=start_retrans;
            //     retrans_in_progress<=retrans_in_progress;
            // end
          end

          RECV_ACK: begin
            // ack_tx_flag<=ack_tx_flag;
            // wea<=wea;
            // addra<=addra;
            // dina<=dina;
            // send_ack_count <= send_ack_count;
            // ack_addr <= ack_addr;
            // tx_dpram_op_counter<=tx_dpram_op_counter;
            // douta_reg<=douta_reg;
            // recv_ack_timeout_top <= recv_ack_timeout_top;

            ack_timeout_count<=ack_timeout_count+1;
            if ( (ack_timeout_count<recv_ack_timeout_top) && fcs_in_strobe && is_ack && (self_mac_addr==addr1)) begin//before timeout, we detect a ACK type frame fcs valid
//                tx_control_state<= IDLE;
                tx_control_state<= IDLE;
                tx_try_complete<=1;
                // tx_status<={1'b0,num_retrans};
                num_retrans<=0;
                // start_retrans<=start_retrans;
                retrans_in_progress<=0;
            end 
            else if((ack_timeout_count<recv_ack_timeout_top)&&fcs_in_strobe && is_cts && (self_mac_addr==addr1))
            begin
                cts_received <= 1;
                num_retrans<=0;
                tx_control_state  <= RECV_CTS;
            end else if ( ack_timeout_count==recv_ack_timeout_top ) begin// timeout 
                tx_control_state<= IDLE;
                if  ((num_retrans == tx_pkt_retrans_limit) || (tx_pkt_retrans_limit == 4'd0)) begin// should not run into this state. but just in case
                    tx_try_complete<=1;
                    // tx_status<={1'b1,num_retrans};
                    num_retrans<=0;
                    retrans_in_progress<=0;
                end else begin
                    // tx_try_complete<=tx_try_complete;
                    // tx_status<=tx_status;
                    tx_control_state<= IDLE;
                    num_retrans<=num_retrans+1;
                    retrans_trigger<=1; // start retranmission if ack did not receive in time -- 
                    // retrans_in_progress<=retrans_in_progress;
                end
            end 
            // else begin
            //     tx_control_state<= tx_control_state;
            //     tx_try_complete<=tx_try_complete;
            //     // tx_status<=tx_status; //maintain status from state RECV_ACK for ARM reading
            //     num_retrans<=num_retrans;
            //     start_retrans<=start_retrans;
            //     retrans_in_progress<=retrans_in_progress;
            // end

          end
          
          RECV_ACK_WAIT_BACKOFF_DONE: begin
            tx_control_state<= IDLE;
            if(quit_retrans) begin
              tx_try_complete<=1;
              num_retrans<=0;
              retrans_in_progress<=0;
              retrans_started<=0;
            end else begin
                retrans_in_progress<=1;
                retrans_started<=1;
            end
         end
        endcase
      end
    end
    
//ila
ila_1 tx_control_ila_inst (
	.clk(clk), // input wire clk

	.probe0(tx_control_state), // input wire [2:0]  probe0  
	.probe1(is_data), // input wire [0:0]  probe1 
	.probe2(fcs_valid), // input wire [0:0]  probe2 
	.probe3(phy_tx_done), // input wire [0:0]  probe3
	.probe4(self_mac_addr), // input wire [47:0]  probe4 
	.probe5(addr1), // input wire [47:0]  probe5
	.probe6(FC_type), // input wire [1:0]  probe6 
	.probe7(FC_subtype), // input wire [3:0]  probe7 
	.probe8(is_ack), // input wire [0:0]  probe8 
	.probe9(ack_timeout_count), // input wire [14:0]  probe9 
	.probe10(recv_ack_timeout_top) // input wire [14:0]  probe10
);
	endmodule
