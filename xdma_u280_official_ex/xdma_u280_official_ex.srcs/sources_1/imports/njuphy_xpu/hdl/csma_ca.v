// YuanMao 23.9.1;

`timescale 1 ns / 1 ps

	module csma_ca #
	(
	  parameter integer RSSI_HALF_DB_WIDTH = 11
	)
	(// simple csma/ca, still need lots of improvements
    input wire clk,
    input wire rstn,
    
    input wire tsf_pulse_1M,
    
    input wire is_management,
    
    input  wire pkt_header_valid,
    input  wire pkt_header_valid_strobe,
    input  wire [7:0] signal_rate,
    input  wire [15:0] signal_len,

    input  wire fcs_in_strobe,
    input  wire fcs_valid,

    input wire nav_enable,
    input wire difs_enable,
    input wire [3:0] cw_min,
    input wire [6:0] preamble_sig_time,
    input wire [4:0] ofdm_symbol_time,
    input wire [4:0] slot_time,
    input wire [6:0] sifs_time,
    input wire [6:0] phy_rx_start_delay_time,
//    input wire [7:0] difs_advance,
//    input wire [7:0] backoff_advance,

    input wire addr1_valid,
    input wire [47:0] addr1,
    input wire [47:0] self_mac_addr,

    input wire FC_DI_valid,
    input wire [1:0] FC_type,
    input wire [3:0] FC_subtype,
    input wire [15:0] duration,

    input wire [1:0] random_seed,
    input wire ch_idle,

    input wire retrans_trigger,
    input wire quit_retrans,
    (*mark_debug = "true"*)input wire high_trigger,
    (*mark_debug = "true"*)input wire tx_trigger,
    input wire tx_bb_is_ongoing,
    input wire ack_cts_is_ongoing,

//    output reg [9:0] num_slot_random_log_dl,
    (*mark_debug = "true"*)output reg increase_cw,
//    output reg cw_used_dl,
    (*mark_debug = "true"*)output wire backoff_done
	);

    localparam [2:0]  IDLE =                 3'b000,
                      BACKOFF_CH_BUSY =      3'b001,
                      BACKOFF_WAIT_1 =       3'b010,
                      BACKOFF_WAIT_2 =       3'b011,
                      BACKOFF_RUN =          3'b100,
                      BACKOFF_SUSPEND =      3'b101,
                      BACKOFF_WAIT_FOR_OWN = 3'b110;

    localparam [1:0]  NAV_IDLE =              2'b00,
                      NAV_WAIT_FOR_DURATION = 2'b01,
                      NAV_CHECK_RA =          2'b10,
                      NAV_UPDATE =            2'b11;
    (*mark_debug = "true"*)reg [2:0]  backoff_state;

    reg [1:0]  nav_state;
    reg [1:0]  nav_state_old;
    (*mark_debug = "true"*)wire ch_idle_final;

    reg [14:0] nav;
    reg [14:0] nav_new;
    reg nav_reset;
    reg nav_set;
    wire [14:0] nav_for_mac;

    wire [7:0] ackcts_n_sym;
    wire [7:0] ackcts_time;
    reg  is_rts_received;
    reg  [14:0] nav_reset_timeout_count;
    reg  [14:0] nav_reset_timeout_top_after_rts;
    wire is_pspoll;
    wire is_rts;

    wire [11:0] longest_ack_time;
    wire [11:0] difs_time;
    wire [11:0] eifs_time;
    reg last_fcs_valid;
    reg take_new_random_number;
    reg [9:0]  num_slot_random;
    reg [31:0] random_number = 32'h0b00a001;
    (*mark_debug = "true"*)reg [12:0] backoff_timer;
    (*mark_debug = "true"*)reg [11:0] backoff_wait_timer;
    reg cw_used;
//    reg cw_used_dl_int;
//    reg [9:0] num_slot_random_log;
//    reg [9:0] num_slot_random_log_dl_int;
    
    
    //(* mark_debug = "true", DONT_TOUCH = "TRUE" *) 
    //wire backoff_done;

    assign is_pspoll = (((FC_type==2'b01) && (FC_subtype==4'b1010))?1:0);
    assign is_rts    = (((FC_type==2'b01) && (FC_subtype==4'b1011) && (signal_len==20))?1:0);//20 is the length of rts frame

    assign ackcts_time = preamble_sig_time + ofdm_symbol_time*ackcts_n_sym;
    assign nav_for_mac = (nav_enable?nav:0);
    
    assign longest_ack_time = 44;
    //assign difs_time = ( difs_enable?(sifs_time + 2*slot_time):0 ); // 16 + 2 * 9 = 34 
    assign difs_time = 12'd4;//方便测试用,实际用上式
    assign eifs_time = ( difs_enable?(sifs_time + difs_time + longest_ack_time):0 ); // 16 + 34 + 44 = 99

    assign ch_idle_final = (ch_idle&&(nav_for_mac==0));
    assign backoff_done =   (backoff_state==BACKOFF_WAIT_FOR_OWN);
//    assign high_tx_allowed1 = (backoff_done && slice_en1);
//    assign high_tx_allowed2 = (backoff_done && slice_en2);
//    assign high_tx_allowed3 = (backoff_done && slice_en3);

    n_sym_len14_pkt # (
    ) n_sym_ackcts_pkt_i (
      .ht_flag(signal_rate[7]),
      .rate_mcs(signal_rate[3:0]),
      .n_sym(ackcts_n_sym[2:0])
    );

    // nav update process
    always @(posedge clk) 
    begin
      if (!rstn) begin
        nav<=0;
        nav_new<=0;
        nav_reset<=0;
        nav_set<=0;
        is_rts_received<=0;
        nav_reset_timeout_count<=0;
        nav_reset_timeout_top_after_rts<=0;
        nav_state<=NAV_IDLE;
        nav_state_old<=NAV_IDLE;
      end else begin
        //nav setting/resetting and count down until 0
        if (nav_reset) begin
          nav <= 0;
          is_rts_received<=0;//if timeout after we observe a rts, after reset nav we should forget the rts we received
        end else if (nav_set) begin
          nav <= (nav_new>nav?nav_new:nav);
        end else begin 
          nav <= (nav!=0?(tsf_pulse_1M?(nav-1):nav):nav);
        end

        nav_state_old<=nav_state;

        if (pkt_header_valid_strobe) begin //pkt_header_valid_strobe is reset signal of nav state machine in case openofdm_rx core runs into abnormal status where fcs strobe never happen
          nav_new<=0;
          nav_reset<=0;
          nav_set<=0;
          if (pkt_header_valid) begin
            nav_state<=NAV_WAIT_FOR_DURATION;
          end else begin
            nav_state<=NAV_IDLE;
          end
        end else begin// //decide new nav value
          //here we do nav reset after long time no pkt arrival following previous rts nav update
          nav_reset_timeout_count <= (is_rts_received==0?0:(tsf_pulse_1M?(nav_reset_timeout_count+1):nav_reset_timeout_count));
          nav_reset <= (nav_reset_timeout_count>nav_reset_timeout_top_after_rts);

          case (nav_state)
            NAV_IDLE: begin
              nav_new<=0;
              nav_set<=0;
              nav_state<=nav_state;
            end

            NAV_WAIT_FOR_DURATION: begin
              if ( FC_DI_valid && duration[15]==0 ) begin
                nav_state<=NAV_CHECK_RA;
              end else begin
                nav_state<=nav_state;//anyhow we stay here until next reset pkt_header_valid_strobe
              end
            end

            NAV_CHECK_RA: begin // if RA is for us, we stay here until next reset pkt_header_valid_strobe because we don't need to udpate NAV: 802.11-2012. 9.3.2.4 Setting and resetting the NAV
              nav_state<=( (addr1_valid&&(addr1!=self_mac_addr))?NAV_UPDATE:nav_state );
            end
            
            NAV_UPDATE: begin
              nav_state<=(fcs_valid?NAV_IDLE:nav_state); //generate nav_set&nav_new and goto&stay idle until next reset pkt_header_valid_strobe
              nav_set<=fcs_valid;
              if (is_pspoll) begin
                nav_new<=ackcts_time+sifs_time;//9.3.2.4 Setting and resetting the NAV
              end else begin
                nav_new<=duration[14:0];
              end

              if (fcs_valid) begin
                if (is_rts) begin
                  is_rts_received <= 1;
                  nav_reset_timeout_top_after_rts<=(2*sifs_time + ackcts_time + phy_rx_start_delay_time + 2*slot_time);
                end else begin
                  is_rts_received <= 0;
                  nav_reset_timeout_top_after_rts<=nav_reset_timeout_top_after_rts;
                end
              end
            end
            
          endcase
        end
      end
    end
    
    // random number generator
    always @(posedge clk)
      if (!rstn)
         random_number <= 32'h1020f0cb;
      else if (take_new_random_number) begin
         random_number[31:1] <= random_number[30:0];
         random_number[0] <= ~^{random_number[31], random_number[21], random_number[1:0]};
      end

    always @( random_number[9:0], random_seed, cw_min[3:0] )
      begin
        case (cw_min[3:0])
          4'd0 : begin 
                num_slot_random = 0;
                end
          4'd1 : begin 
                num_slot_random = {9'h0,random_number[0]^random_seed[1]};
                end
          4'd2 : begin 
                num_slot_random = {8'h0,random_number[1],random_number[0]};
                end
          4'd3 : begin 
                num_slot_random = {7'h0,random_number[2]^random_seed[0],random_number[1]^random_seed[1],random_number[0]};
                end
          4'd4 : begin
                num_slot_random = {6'h0,random_number[3],random_number[2]^random_seed[0],random_number[1]^random_seed[1],random_number[0]};
                end
          4'd5 : begin
                num_slot_random = {5'h0,random_number[4]^random_seed[0],random_number[3],random_number[2]^random_seed[0],random_number[1]^random_seed[1],random_number[0]};
                end
          4'd6 : begin
                num_slot_random = {4'h0,random_number[5],random_number[4],random_number[3],random_number[2]^random_seed[0],random_number[1],random_number[0]^random_seed[1]};
                end
          4'd7 : begin
                num_slot_random = {3'h0,random_number[6],random_number[5]^random_seed[0],random_number[4],random_number[3],random_number[2],random_number[1]^random_seed[1],random_number[0]};
                end
          4'd8 : begin
                num_slot_random = {2'h0,random_number[7],random_number[6]^random_seed[1],random_number[5],random_number[4]^random_seed[0],random_number[3],random_number[2],random_number[1],random_number[0]^random_seed[1]};
                end
          4'd9 : begin
                num_slot_random = {1'h0,random_number[8],random_number[7]^random_seed[0],random_number[6],random_number[5]^random_seed[1],random_number[4],random_number[3]^random_seed[0],random_number[2],random_number[1]^random_seed[1],random_number[0]};
                end
          4'd10: begin
                num_slot_random = {random_number[9],random_number[8]^random_seed[0],random_number[7]^random_seed[1],random_number[6],random_number[5],random_number[4]^random_seed[1],random_number[3],random_number[2],random_number[1]^random_seed[0],random_number[0]};
                end                
          default: begin
                num_slot_random = {7'h0,random_number[2]^random_seed[0],random_number[1],random_number[0]^random_seed[1]};
                end
        endcase
      end

    // media access random backoff state machine
    always @(posedge clk) 
    begin
      if (!rstn) begin
        backoff_timer<=0;
        backoff_wait_timer<=0;
        last_fcs_valid<=0;
        take_new_random_number<=0;
        backoff_state<=IDLE;
//        num_slot_random_log<=0 ;
//        num_slot_random_log_dl_int<=0;
//        num_slot_random_log_dl<=0;
        increase_cw<=0 ;
        cw_used<=0;
//        cw_used_dl<=0;
//        cw_used_dl_int<=0;
      end else begin
        last_fcs_valid <= (fcs_in_strobe?fcs_valid:last_fcs_valid);
//        cw_used_dl_int <= cw_used ;
//        cw_used_dl <= cw_used_dl_int; // dl cw used flag by two clock pulses, to insure cw is logged correctly if quit_retrans issued
//        num_slot_random_log_dl_int<=num_slot_random_log;
//        num_slot_random_log_dl<=num_slot_random_log_dl_int; 
        case (backoff_state)
          IDLE: begin
            cw_used<=((high_trigger || quit_retrans)?0:cw_used);
//            num_slot_random_log<=((high_trigger || quit_retrans)?0:num_slot_random_log);
            backoff_timer<=0;
            take_new_random_number<=0;
            if(ch_idle_final) begin
                if((high_trigger==1)|| (quit_retrans==1) || (tx_trigger==1)) begin
                //if((high_trigger==1)|| (quit_retrans==1)) begin
                    backoff_state<=BACKOFF_WAIT_1;
                    increase_cw<=0;
//                    if (last_fcs_valid) begin
                      backoff_wait_timer<=(difs_time==0?0:difs_time);
//                    end else begin
//                      backoff_wait_timer<=(eifs_time==0?0:eifs_time);
//                    end              
                end else if (retrans_trigger==1) begin
                    backoff_state<=BACKOFF_WAIT_2;    
                    increase_cw<=(retrans_trigger?(cw_used?1:0):0);
//                    if (last_fcs_valid) begin
                      backoff_wait_timer<=(difs_time==0?0:difs_time);
//                    end else begin
//                      backoff_wait_timer<=(eifs_time==0?0:eifs_time);
//                    end                
                end
             end else begin
                  if((high_trigger==1) || (retrans_trigger==1) || (quit_retrans==1) || (tx_trigger==1)) begin
                  //if((high_trigger==1) || (retrans_trigger==1) || (quit_retrans==1)) begin
                    backoff_state<=BACKOFF_CH_BUSY; 
                    increase_cw<=(retrans_trigger?(cw_used?1:0):0);
                    backoff_wait_timer<=0;
                  end  
            end
          end // end IDLE

          BACKOFF_CH_BUSY: begin
            backoff_timer<=0;
            take_new_random_number<=0;
            increase_cw<=0;
            cw_used<=((high_trigger || quit_retrans)?0:cw_used);
//            num_slot_random_log<=((high_trigger || quit_retrans)?0:num_slot_random_log);
            if (!ch_idle_final) begin
              backoff_wait_timer<=0;
              backoff_state<=backoff_state;
            end else begin
              if (last_fcs_valid) begin
                backoff_wait_timer <= (difs_time==0?0:difs_time);
              end else begin
                backoff_wait_timer <= (eifs_time==0?0:eifs_time);
              end
              backoff_state<=BACKOFF_WAIT_2;
            end 
          end  // end CH_BUSY  

          BACKOFF_WAIT_1: begin
            backoff_wait_timer<=( backoff_wait_timer==0?backoff_wait_timer:(tsf_pulse_1M?(backoff_wait_timer-1):backoff_wait_timer) );
            take_new_random_number<=0;
            backoff_timer<=0;
            cw_used<=0;
//            num_slot_random_log<=0;
            if (ch_idle_final) begin
              if (backoff_wait_timer==0) begin
                backoff_state<=BACKOFF_WAIT_FOR_OWN;
              end else begin
                backoff_state<=backoff_state;
              end
            end else begin
              backoff_state<=BACKOFF_CH_BUSY;
            end
          end // end WAIT1

          BACKOFF_WAIT_2: begin
            if(is_management) begin
                backoff_state <= BACKOFF_WAIT_FOR_OWN;
            end
            else begin
                backoff_wait_timer<=( backoff_wait_timer==0?backoff_wait_timer:(tsf_pulse_1M?(backoff_wait_timer-1):backoff_wait_timer) );
                cw_used<=((high_trigger || quit_retrans)?0:1);
                if((backoff_wait_timer == 2) && tsf_pulse_1M) begin
                  take_new_random_number<=1;
                end else begin
                  take_new_random_number<=0;
                end
                if (ch_idle_final) begin
                  increase_cw<=0;
                  if(quit_retrans==1) begin
                    backoff_state<=BACKOFF_WAIT_1; // avoid additional back off for a new packet
    //                num_slot_random_log<=num_slot_random_log;
                  end else begin
                    if (backoff_wait_timer==0) begin
                      backoff_state<=BACKOFF_RUN;
                      backoff_timer<=(num_slot_random==0?0:(num_slot_random*slot_time));
    //                  num_slot_random_log <= num_slot_random;
                    end else begin
                      backoff_state<=backoff_state;
                      backoff_timer<=0;
    //                  num_slot_random_log<=num_slot_random_log;
                    end
                  end
                end else begin
                  backoff_state<=BACKOFF_CH_BUSY;
//                  increase_cw<=1;
                  backoff_timer<=0;
    //              num_slot_random_log<=((high_trigger || quit_retrans)?0:num_slot_random_log);
                end
            end
          end // end WAIT2

          BACKOFF_RUN: begin
            take_new_random_number<=0;
            cw_used<=((high_trigger || quit_retrans)?0:1);
//            num_slot_random_log<=((high_trigger || quit_retrans)?0:num_slot_random_log);
            if (ch_idle_final) begin
              backoff_timer<=( backoff_timer==0?backoff_timer:(tsf_pulse_1M?(backoff_timer-1):backoff_timer) );
              increase_cw<=0;
              if(quit_retrans==1) begin
                backoff_state<=BACKOFF_WAIT_1;
                if (last_fcs_valid) begin
                  backoff_wait_timer<=(backoff_timer>difs_time?(difs_time==0?0:difs_time):backoff_timer);
                end else begin
                  backoff_wait_timer<=(backoff_timer>eifs_time?(eifs_time==0?0:eifs_time):backoff_timer);
                end
              end else begin
                backoff_wait_timer<=backoff_wait_timer;
                if (backoff_timer==0) begin
                  backoff_state<=BACKOFF_WAIT_FOR_OWN;
                end else begin
                  backoff_state<=backoff_state;
                end
              end
            end else begin
              backoff_timer<=backoff_timer;
              backoff_wait_timer<=backoff_wait_timer;
              if (backoff_timer==0) begin
                backoff_state<=BACKOFF_CH_BUSY;
                increase_cw<=1;
              end else begin
                increase_cw<=0;
                backoff_state<=BACKOFF_SUSPEND;
              end
            end
          end // end RUN

          BACKOFF_SUSPEND: begin // data is calculated by calc_phy_header C program
            take_new_random_number<=0;
            backoff_timer<=backoff_timer;
//            num_slot_random_log<=((high_trigger || quit_retrans)?0:num_slot_random_log);
            cw_used<=((high_trigger || quit_retrans)?0:1);
            if (ch_idle_final) begin
              if(quit_retrans==1) begin
                backoff_state<=BACKOFF_WAIT_1;
                if (last_fcs_valid) begin
                  backoff_wait_timer<=(backoff_timer>difs_time?(difs_time==0?0:difs_time):backoff_timer);
                end else begin
                  backoff_wait_timer<=(backoff_timer>eifs_time?(eifs_time==0?0:eifs_time):backoff_timer);
                end
              end else begin
                backoff_state<=BACKOFF_RUN;
                backoff_wait_timer<=backoff_wait_timer;
              end
            end else begin
              backoff_wait_timer<=backoff_wait_timer;
              if(quit_retrans==1) begin
                backoff_state<=BACKOFF_CH_BUSY;
              end else begin
                backoff_state<=backoff_state;
              end
            end
          end // end SUSPEND

          BACKOFF_WAIT_FOR_OWN: begin
            cw_used<=((high_trigger || quit_retrans)?0:cw_used);
//            num_slot_random_log<=((high_trigger || quit_retrans)?0:num_slot_random_log);
            if(tx_bb_is_ongoing) begin
                //if (ack_cts_is_ongoing) begin
                  //backoff_state<=BACKOFF_CH_BUSY;
                  //increase_cw<=1;
                //end else begin
                  increase_cw<=0;
                  backoff_state<=IDLE;
                //end
            end
          end     


        endcase
      end
  end
  
//ila_1 ila_1_csma_inst (
//	.clk(clk), // input wire clk
//
//	.probe0(increase_cw), // input wire [0:0]  probe0  
//	.probe1(backoff_done), // input wire [0:0]  probe1 
//	.probe2(backoff_state), // input wire [2:0]  probe2 
//	.probe3(high_trigger), // input wire [0:0]  probe3 
//	.probe4(backoff_timer), // input wire [12:0]  probe4 
//	.probe5(backoff_wait_timer), // input wire [11:0]  probe5 
//	.probe6(ch_idle_final), // input wire [0:0]  probe6
//	.probe7(tx_trigger), // input wire [0:0]  probe7
//	.probe8(retrans_trigger), // input wire [0:0]  probe8
//	.probe9(tx_bb_is_ongoing), // input wire [0:0]  probe9
//	.probe10(ack_cts_is_ongoing) // input wire [0:0]  probe10
//);
	endmodule
