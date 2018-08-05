/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

interface shunt_fringe_if (input clk_i);

   localparam N=9;
   typedef bit[N-1:0] data_in_t;
  
   
   //debugging
   bit [8:0] 			shuntbox[3:0];
   
   //shunt protocol
`include "cs_common.svh"
   import shunt_dpi_pkg::*;
  
   typedef enum  {FRNG_TARGET_IDLE, FRNG_TARGET_ACTIVE, FRNG_TARGET_FINISH,FRNG_TARGET_STOP} fringe_target_status_e;
   typedef enum  {FRNG_DATA_IDLE,FRNG_DATA_VALID_GET,FRNG_DATA_VALID_PUT} fringe_data_valid_e;
   typedef enum  {FRNG_NO_PRINT,FRNG_PRINT} fringe_signal_debug_e;

   /* verilator lint_off UNPACKED */ 
   typedef struct{ 
      longint 	 target_id;
      int 	 n_signals;
      fringe_target_status_e   status;        
   } fringe_targets_descriptor_t;
   
   typedef struct{ 
      longint 	    data_type;
      longint 	    signal_id;
      int 	    signal_size;//n_payloads;
      int           index_payloads_db;
      fringe_data_valid_e  data_valid;
      int 	    timestamp;
      int           event_cntr;
      fringe_signal_debug_e debug;
   } fringe_signals_descriptor_t;
   
   /* verilator lint_on UNPACKED */
   
   //
   typedef enum{FRNG_REG_REQ,
		FRNG_REG_ACK,
		FRNG_PUT,
		FRNG_GET
		} fringe_protocol_e;
   
   //Sim DB
   fringe_signals_descriptor_t Signal;
   fringe_targets_descriptor_t Target;
   //Targets DB
   fringe_targets_descriptor_t targets_db[`N_OF_TARGETS];
   string 	__targets_name_db [`N_OF_TARGETS];
   //Signals DB
   fringe_signals_descriptor_t signals_db            [`N_OF_SIGNALS];
   string 	        __signals_target_name_db[`N_OF_SIGNALS];
   string 	        __signals_name_db       [`N_OF_SIGNALS];
   //Paylod db
   longint 		data_payloads_db[`N_OF_PAYLOADS];
   longint 		signal_id_payloads_db[`N_OF_PAYLOADS];
   
   string 		i_am="NA";
   int 			my_socket=0;
   int 			sim_id=0;
   longint              clk_i_cnt=0;
 
   always @(posedge clk_i) begin
     clk_i_cnt<=clk_i_cnt+1;
   end
   
   //
   
   //protocol Shunt functions
   
   
   ////////////////////
   //Sim general
   ///////////////////
   
   function string who_iam();
      return i_am;
   endfunction : who_iam
   
   function  bit set_iam(string i_am_inpit);
      bit success;
      success = 1;
      if(i_am == "NA") i_am = i_am_inpit;
      else success =0;
      return success; 
   endfunction : set_iam
   
   function  bit set_simid(longint sim_id_);
      /* verilator lint_off WIDTH */
      bit success;
      success = 1;
      if(sim_id == 0 ) sim_id = sim_id_;
      else success =0;
      return success;
      /* verilator lint_on WIDTH */
   endfunction : set_simid

   function string get_simid();
      return sim_id;
   endfunction : get_simid
   
   ////////////////
   //Sim DB
   ///////////////
   
   
   //Targets DB
   function  bit init_targets_db();
      bit success;
      `INIT_TARGETS_DB
      success = 1;
      for(int i=0;i<`N_OF_TARGETS;i++) begin
	 targets_db[i].target_id  = {$random,$random};
	 targets_db[i].n_signals  = targets_n_signals[i];
	 targets_db[i].status     = FRNG_TARGET_IDLE; //not active
	 //   
	 __targets_name_db[i]       = targets[i];
	 if (__targets_name_db[i] == "INITIATOR") targets_db[i].status = FRNG_TARGET_ACTIVE;
      end
      return success; 
     endfunction : init_targets_db

   function  bit print_targets_db();
      bit success;
      success = 1;
      for(int i=0;i<`N_OF_TARGETS;i++) begin
	 //print_target_descr(targets_db[i]);
	 $display("%s targets_db[%0d].target_id  =%0h",i_am,i,targets_db[i].target_id);
	 $display("%s targets_db[%0d].n_signals =%0d",i_am,i,targets_db[i].n_signals);
	 $display("%s targets_db[%0d].status  =%s",i_am,i,targets_db[i].status.name());
	 $display("%s __target_name_db[%0d]     =%s\n",i_am,i,__targets_name_db[i]);
      end
      return success; 
   endfunction : print_targets_db
   
   function  print_target_descr(input fringe_targets_descriptor_t Trg,input string Name="Trg");
      $display("%s %s.target_id  =%0h",i_am,Name,Trg.target_id);
      $display("%s %s.n_signals =%0d",i_am,Name,Trg.n_signals);
      $display("%s %s.status =%s",i_am,Name,Trg.status.name()); 
   endfunction : print_target_descr

   function  int check_repetition_targets_db(string Name,int N_repetition=1 );
      int repetition_indx;
      int repetition_entry;
      
      repetition_indx=-1;
      repetition_entry=0;
      
      //find repetition entry
      for(int i=0;i<`N_OF_TARGETS;i++) begin
	 if (__targets_name_db[i] == Name) ++repetition_entry;
	 if (repetition_entry > N_repetition) repetition_indx = i;
      end
      return repetition_indx;    
   endfunction : check_repetition_targets_db
   
   

   function  int check_idle_entry_targets_db();
      int idle_entry=-1;
      //find idle entry
      for(int i=0;i<`N_OF_TARGETS;i++) begin
	 if (targets_db[i].status==FRNG_TARGET_IDLE && idle_entry<0) idle_entry = i;
      end // for (int i=0;i<`N_OF_TARGETS;i++)
      return idle_entry; 
   endfunction : check_idle_entry_targets_db
   
   
   
   function  int get_index_by_name_targets_db(string Name);
      string s_me;
      int    index;
   
      index = -1;
      s_me = "get_index_by_name_targets_db()";
      
      for(int i=0;i<`N_OF_TARGETS;i++) begin
	 if (__targets_name_db[i] == Name && index<0) index = i;
      end // for (int i=0;i<`N_OF_TARGETS;i++)
      return index;
   endfunction : get_index_by_name_targets_db

   function  int get_index_by_hash_targets_db(longint Name_hash);
      string s_me;
      int    index;
      longint hash_;
         
      index = -1;
      s_me = "get_index_by_hash_targets_db()";
      
      for(int i=0;i<`N_OF_TARGETS;i++) begin
	 hash_ =shunt_dpi_hash(__targets_name_db[i]); 
	 if (hash_ == Name_hash && index<0) index = i;
      end // for (int i=0;i<`N_OF_TARGETS;i++)
      return index;
   endfunction : get_index_by_hash_targets_db
   

   
   function  string get_name_by_index_targets_db(int index);
      
      string s_me;
      string Name;
      
      s_me = "get_index_by_name_targets_db()";
      Name ="NA";
      if (index <`N_OF_TARGETS) Name = __targets_name_db[index];
      
      return Name;
   endfunction : get_name_by_index_targets_db
   
   //Signals DB
   
   function  bit init_signals_db();
      bit success;
      int index_payload;
      string s_me;
      int    j;
      
      `INIT_SIGNAL_DB
      s_me = "init_signals_db()";
      
      //init payloads
      foreach(data_payloads_db[i]) begin
	 data_payloads_db[i] = 0;
	 signal_id_payloads_db[i] = 0; 
      end
      
      foreach(signals_db[i])
	begin
	   signals_db[i].data_type  = shunt_dpi_hash(signals_type[i]);
	   signals_db[i].signal_id  = shunt_dpi_hash({__signals_target_name_db[i],".",__signals_name_db[i]});
	   signals_db[i].signal_size = signals_n_payload[i];
	   signals_db[i].data_valid = FRNG_DATA_IDLE;
	   signals_db[i].timestamp  = 0;
	   signals_db[i].event_cntr = 0;
	   signals_db[i].debug =FRNG_NO_PRINT;
 
	   //payload initialisation
	   //find free payload entry
	   index_payload = check_free_entry_payloads_db();
	   if(index_payload>=0) begin
	      for(j=index_payload;j<index_payload+signals_db[i].signal_size;j++) begin
		 /* verilator lint_off WIDTH */
		 data_payloads_db[j] = signals_db[i].signal_id;
		 /* verilator lint_on WIDTH */
		 signal_id_payloads_db[j] = signals_db[i].signal_id;
	      end
	   end // if (index_payload>=0)
	   else  begin 
	      $display("%s ERROR no free payload entry `N_OF_PAYLOADS = $0d ",s_me,`N_OF_PAYLOADS);
	   end
	   signals_db[i].index_payloads_db = index_payload;
	end // foreach (signals_db[i])
      return success; 
   endfunction : init_signals_db

   function  bit print_signals_db();
      bit success;
      int index_payload;
      int j;
      
      success = 1;
            
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 if (signals_db[i].debug == FRNG_PRINT)
	   begin
	      //print_target_descr(targets_db[i]);
	      $display("%s __signals_name_db[%0d]       = %s",i_am,i,__signals_name_db[i]);
	      $display("%s __signals_target_name_db[%0d]= %s",i_am,i,__signals_target_name_db[i]);
	      $display("%s signals_db[%0d].data_type  = %0h",i_am,i,signals_db[i].data_type);
	      $display("%s signals_db[%0d].signal_id  = %0h",i_am,i,signals_db[i].signal_id);
	      $display("%s signals_db[%0d].index_payloads_db = %0d",i_am,i,signals_db[i].index_payloads_db);
	      $display("%s signals_db[%0d].data_valid = %s",i_am,i,signals_db[i].data_valid.name());
	      $display("%s signals_db[%0d].timestamp  = %0h",i_am,i,signals_db[i].timestamp);
	      $display("%s signals_db[%0d].event_cntr = %0h",i_am,i,signals_db[i].event_cntr);
	      //
	      index_payload = signals_db[i].index_payloads_db;
	      for(j=index_payload;j<index_payload+signals_db[i].signal_size;j++) begin
		 $display("%s data_payloads_db[%0d]=%h",i_am,j,data_payloads_db[j]);
		 $display("%s signal_id_payloads_db[%0d]=%h",i_am,j,signal_id_payloads_db[j]);
	      end
	   end // if (signals_db[i].debug == FRNG_PRINT)
      end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return success; 
   endfunction : print_signals_db
   

   function  print_signal_descr(input fringe_signals_descriptor_t Sig,input string Name="Sig");
      $display("%s %s.data_type  = %0h",i_am,Name,Sig.data_type);
      $display("%s %s.signal_id  = %0h",i_am,Name,Sig.signal_id);
      $display("%s %s.signal_size = %0h",i_am,Name,Sig.signal_size);
      $display("%s %s.index_payloads_db = %0h",i_am,Name,Sig.index_payloads_db);
      $display("%s %s.data_valid = %s",i_am,Name,Sig.data_valid.name());
      $display("%s %s.timestamp  = %0h",i_am,Name,Sig.timestamp);
      $display("%s %s.event_cntr = %0h",i_am,Name,Sig.event_cntr);
    endfunction : print_signal_descr

    function  int check_free_entry_payloads_db();
      int free_entry=-1;
      //find free entry
       for(int i=0;i< `N_OF_PAYLOADS;i++) begin
	  if (signal_id_payloads_db[i] == 0 && free_entry<0) free_entry = i;
      end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return free_entry; 
    endfunction : check_free_entry_payloads_db
  
   function  int get_index_by_signal_id_payloads_db(longint signal_id);
      string s_me;
      int    index;
      
      index = -1;
      s_me = "get_index_by_signal_id_payloads_db()";
      
      for(int i=0;i<`N_OF_PAYLOADS;i++) begin
	 if (signal_id_payloads_db[i] == signal_id  && index<0) index = i;
      end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return index;
   endfunction : get_index_by_signal_id_payloads_db
   
   
   function  int check_repetition_signals_db(string Signal_name,string Target_name,int N_repetition=1 );
      int repetition_indx;
      int repetition_entry;
      
      repetition_indx=-1;
      repetition_entry=0;
      
      //find repetition entry
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 if (__signals_name_db[i] == Signal_name && __signals_target_name_db[i] == Target_name ) ++repetition_entry;
	 if (repetition_entry > N_repetition) repetition_indx = i;
      end
      return repetition_indx;    
    endfunction : check_repetition_signals_db
   
   function  int check_free_entry_signals_db();
      int free_entry=-1;
      //find free entry
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 if (__signals_name_db[i] == "NA" && free_entry<0) free_entry = i;
      end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return free_entry; 
   endfunction : check_free_entry_signals_db

   function  int get_index_by_name_signals_db(string Name_target, string Name_signal);
      string s_me;
      int    index;
      string Name_;
      string NameDb_;
      index = -1;
      s_me = "get_index_by_name_signals_db()";
      //
      Name_  = {Name_target,".",Name_signal};
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 NameDb_= {__signals_target_name_db[i],".",__signals_name_db[i]}; 
	 if (Name_ ==  NameDb_ && index<0) index = i;
	 //$display("%s index=%0d,__signals_name_db[%0d]=%s, __signals_target_name_db[%0d]=%s,index=%0d vs Name_target=%s,Name_signal=%s Name_=%s",s_me,index,i,__signals_name_db[i],i,__signals_target_name_db[i],index,Name_target,Name_signal,Name_);
      end // for (int i=0;i<`N_OF_TARGETS;i++)
      return index;
   endfunction : get_index_by_name_signals_db

    function  int get_index_by_full_name_signals_db(string Name);
      string s_me;
      int    index;
      
      index = -1;
      s_me = "get_index_by_full_name_signals_db";
      
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 if (Name == {__signals_target_name_db[i],".",__signals_name_db[i]} && index<0) index = i;
      end // for (int i=0;i<`N_OF_TARGETS;i++)
      return index;
    endfunction : get_index_by_full_name_signals_db
   
   
    function  int get_index_by_hash_signals_db(longint Name_hash);
      string s_me;
      int    index;
      longint hash_;
         
      index = -1;
      s_me = "get_index_by_hash_signals_db()";
      
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 hash_ =shunt_dpi_hash({__signals_target_name_db[i],".",__signals_name_db[i]}); 
	 if (hash_ == Name_hash && index<0) index = i;
      end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return index;
    endfunction : get_index_by_hash_signals_db


    function  int get_index_by_full_name_hash_signals_db(string full_Name);
       string s_me;
       int    index;
       longint hash_;
       longint Name_hash;
       
         
       index = -1;
       s_me = "get_index_by_full_name_hash_signals_db";
       Name_hash =shunt_dpi_hash(full_Name);
       for(int i=0;i<`N_OF_SIGNALS;i++) begin
	  hash_ =shunt_dpi_hash({__signals_target_name_db[i],".",__signals_name_db[i]}); 
	  if (hash_ == Name_hash && index<0) index = i;
       end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return index;
    endfunction : get_index_by_full_name_hash_signals_db

   
   function  int get_index_by_signal_id_signals_db(longint signal_id);
       string s_me;
       int    index;
      
      index = -1;
      s_me = "get_index_by_signal_id_signals_db()";
      
      for(int i=0;i<`N_OF_SIGNALS;i++) begin
	 if (signals_db[i].signal_id == signal_id  && index<0) index = i;
	 //$display("%s index=%0d,signals_db[%0d].signal_id=%h,__signals_name_db[%0d]=%s, __signals_target_name_db[%0d]=%s,index=%0d vs signal_id=%h",s_me,index,i,signals_db[i].signal_id,i,__signals_name_db[i],i,__signals_target_name_db[i],index,signal_id);
      end // for (int i=0;i<`N_OF_SIGNALS;i++)
      return index;
   endfunction : get_index_by_signal_id_signals_db
   
   
   function  string get_signal_name_by_index_signals_db(int index);
      
      string s_me;
      string Name;
      
      s_me = "get_signal_name_by_index_signals_db";
      Name ="NA";
      if (index <`N_OF_SIGNALS) Name = __signals_name_db[index];
      
      return Name;
   endfunction : get_signal_name_by_index_signals_db
   

   function  string get_target_name_by_index_signals_db(int index);
      
      string s_me;
      string Name;
      
      s_me = "get_target_name_by_index_signals_db";
      Name ="NA";
      if (index <`N_OF_SIGNALS) Name = __signals_target_name_db[index];
      
      return Name;
   endfunction : get_target_name_by_index_signals_db
     
   
   function  string get_full_name_by_index_signals_db(int index);
      
      string s_me;
      string Name;
      
      s_me = "get_full_name_by_index_signals_db";
      Name ="NA";
      if (index <`N_OF_SIGNALS) Name = {__signals_target_name_db[index],".",__signals_name_db[index]};
      
      return Name;
   endfunction : get_full_name_by_index_signals_db
      
   //set 
   
   //TCP init
   function void tcp_init();
      if(i_am == "INITIATOR") my_socket = init_initiator(`MY_PORT);
      if(i_am != "INITIATOR") my_socket = init_target(`MY_PORT, `MY_HOST);
      //
      if (my_socket >0 )  $display("\n%s: socket=%0d",i_am,my_socket); 
      else $display("\n %s ERROR : socket=%0d",i_am,my_socket);
   endfunction: tcp_init
   
   function int init_initiator(int portno);
      begin
	 int socket_id;
	 socket_id = 0;
	 socket_id = shunt_dpi_initiator_init(portno);
	 return socket_id;
      end
   endfunction : init_initiator
   
   function int init_target(int portno,string hostname);
      int    socket_id;
      socket_id = 0;
      socket_id = shunt_dpi_target_init(portno,hostname);
      return socket_id;
   endfunction : init_target
   
   //Registration
   //Target

   function bit target_registration_request(inout cs_header_t h_,input string target_name);
      bit    success;
      success = 0;
      h_.trnx_type  = shunt_dpi_hash("FRNG_REG_REQ");
      h_.data_type  = shunt_dpi_hash("SHUNT_HEADER_ONLY");
      h_.trnx_id    = shunt_dpi_hash(target_name);
      h_.n_payloads = sim_id;
      shunt_dpi_send_header(my_socket,h_);
      //
      shunt_dpi_recv_header(my_socket,h_);
      if (h_.trnx_type == shunt_dpi_hash("FRNG_REG_ACK") && h_.n_payloads == sim_id && h_.trnx_id >= 0 ) success = 1;
      return success;
   endfunction : target_registration_request
   
   
   function bit initiator_registration(inout cs_header_t h_);
      bit    success;
      fringe_targets_descriptor_t Trg;
      int    index;
      
      success = 0;
      shunt_dpi_recv_header(my_socket,h_);
      
      index = get_index_by_hash_targets_db(h_.trnx_id);
      if (h_.trnx_type ==shunt_dpi_hash("FRNG_REG_REQ") && h_.n_payloads == sim_id)
	begin 
	   h_.trnx_type  = shunt_dpi_hash("FRNG_REG_ACK");
	   if(index >= 0 && targets_db[index].status==FRNG_TARGET_IDLE) h_.trnx_id = targets_db[index].target_id;
	   else  h_.trnx_id = -1;
	   h_.data_type  = shunt_dpi_hash("SHUNT_HEADER_ONLY");
	   h_.n_payloads = sim_id;
	   shunt_dpi_send_header(my_socket,h_);
	   if(h_.trnx_id>=0) begin
	      success = 1;
	      targets_db[index].status=FRNG_TARGET_ACTIVE;
	     end
	end // if (h_.trnx_type ==shunt_dpi_hash("FRNG_REG_REQ") && h_.n_payloads == sim_id)
      return success;
   endfunction : initiator_registration



      
   function void print_reg_header(input cs_header_t h_);
      string S;
      longint Temp;
      
      $display("\n (print_reg_header) %s:",i_am);
      S="NON";
       
      //$display("FRNG_REG_ACK =%d <> %d",shunt_dpi_hash("FRNG_REG_ACK"),h_.trnx_type);
      if (h_.trnx_type == shunt_dpi_hash("FRNG_REG_ACK")) S="FRNG_REG_ACK";
      if (h_.trnx_type == shunt_dpi_hash("FRNG_PUT")) S="FRNG_PUT";
      if (h_.trnx_type == shunt_dpi_hash("FRNG_GET")) S="FRNG_GET";
      if (h_.trnx_type == shunt_dpi_hash("FRNG_REG_REQ")) S="FRNG_REG_REQ";
      if (h_.trnx_type == shunt_dpi_hash("NA")) S="NA";
      //
      $display("trnx_type = (%d)%s",h_.trnx_type,S);
      $display("trnx_id = %d", h_.trnx_id);
      S="NON";
      //$display("SHUNT_HEADER_ONLY =%d <> %d", shunt_dpi_hash("SHUNT_HEADER_ONLY"),h_.data_type);
      if (h_.data_type == shunt_dpi_hash("SHUNT_HEADER_ONLY")) S="SHUNT_HEADER_ONLY";
      if (h_.data_type == shunt_dpi_hash("SHUNT_LONGINT")) S="SHUNT_LONGINT";
      if (h_.data_type == shunt_dpi_hash("SHUNT_INT")) S="SHUNT_INT";
      if (h_.data_type == shunt_dpi_hash("SHUNT_BIT")) S="SHUNT_BIT";
      
      $display("data_type = (%d)%s ",h_.data_type,S);
      $display("n_payloads  = %0d\n", h_.n_payloads );
      
   endfunction : print_reg_header
   
   //put & get
   
   function bit fringe_put (	   
	   input string  destination_name,
	   input string  signal_name
           );
      
     
      cs_header_t h_;
      //
      string 	  s_me;
      bit 	  success;
      int 	  index;
      int 	  index_payload;
      longint	  data_;
      int 	  Result;
      int 	  i;
      
      //
      s_me = "fringe_put()";
      success =1;
      //
      h_.trnx_type  = shunt_dpi_hash("FRNG_PUT");
      h_.data_type  = -1;
      h_.trnx_id    = -1;
      h_.n_payloads = -1;
      //
      index = get_index_by_name_signals_db(destination_name,signal_name);
      //$display("%s index=%0d destination_name=%s,signal_name=%s",s_me,index,destination_name,signal_name);
     
      index_payload = signals_db[index].index_payloads_db;
      //
      if(index>=0) begin 
	 h_.trnx_type  = shunt_dpi_hash("FRNG_PUT");
	 h_.data_type  = signals_db[index].data_type;
	 h_.trnx_id    = signals_db[index].signal_id;
	 h_.n_payloads = signals_db[index].signal_size;
      end
      
      //
      //print_reg_header(h_);
      
      shunt_dpi_send_header(my_socket,h_);
      
      
      for(i=index_payload;i<index_payload+signals_db[index].signal_size;i++) begin    
	 /* verilator lint_off WIDTH */
	 data_ =  data_in_t'(data_payloads_db[i]);
	 /* verilator lint_on WIDTH */
	 $display("%s data_=%h data_payloads_db[%0d]= %h @%0d",s_me,data_,i,data_payloads_db[i],get_time());
	 Result = shunt_dpi_send_long(my_socket,data_);
	 if (Result<=0)  success =0;
      end // for (i=index_payload;i<index_payload+signals_db[index].signal_size;i++)
      
      shunt_dpi_recv_header(my_socket,h_);//ACK
      if(h_.trnx_type != shunt_dpi_hash("FRNG_GET"))        success =0;
      if(h_.trnx_id   != signals_db[index].signal_id)       success =0;
      if(h_.n_payloads <  0)                                success =0;
      //
      signals_db[index].data_valid = FRNG_DATA_IDLE;
      return success;
      
   endfunction : fringe_put
   
   function longint get_time();
      return clk_i_cnt;
   endfunction : get_time
   
  
   function bit fringe_get ();
      
      typedef bit[N-1:0] data_in_t;
      cs_header_t h_;
      //
      string 	  s_me;
      bit 	  success;
      int 	  index;
      int 	  index_payload;
      longint	  data_;
      int 	  Result;
      int 	  i;
      
      //
      s_me = "fringe_get()";
      success = 1;
      
      Result = shunt_dpi_recv_header(my_socket,h_);
      if (Result<=0)  success =0;
      //
      index = get_index_by_signal_id_signals_db(h_.trnx_id);
      if (index<0)  success =0;
      //
      index_payload = signals_db[index].index_payloads_db;
      if (index_payload <0 )  success =0;
      //      
      //$display("%s index=%0d ",s_me,index);
      //

      for(i=index_payload;i<index_payload+signals_db[index].signal_size;i++) begin    
	 Result = shunt_dpi_recv_long(my_socket,data_);
	 /* verilator lint_off WIDTH */
	 if (Result>0) data_payloads_db[i] =  longint'(data_);
	 /* verilator lint_on WIDTH */
	 else  success =0;
	 $display("%s data_=%h data_payloads_db[%0d]= %h @%0d",s_me,data_,i,data_payloads_db[i],get_time());
      end // for (i=index_payload;i<index_payload+signals_db[index].signal_size;i++)
           
      if (!success) h_.trnx_type = shunt_dpi_hash("FRNG_GET");
      /* verilator lint_off WIDTH */
      h_.trnx_id = signals_db[index].signal_id;
      h_.n_payloads = -1;//FINGE_GET ERROR
      /* verilator lint_on WIDTH */
      shunt_dpi_send_header(my_socket,h_);
      //
      signals_db[index].data_valid = FRNG_DATA_VALID_GET;
      
      return success;
   endfunction : fringe_get

   function void set_data_valid_get(int index);
      signals_db[index].data_valid = FRNG_DATA_VALID_GET; 
   endfunction //
   
   function void set_data_valid_idle(int index);
      signals_db[index].data_valid = FRNG_DATA_IDLE;
   endfunction //
   
/* -----\/----- EXCLUDED -----\/-----
  function bit shunt_get_bit_req ( 
       input string signal_name,
       input string destination_name,
       inout  bit[N-1:0] data,
       );
      
     typedef bit [N-1:0] data_in_t;
     
     
     cs_header_t h_;
     //
     string 		 s_me;
     bit 		 success;
     int 		 index;
     longint 		 data_;
     //
     s_me = "shunt_bit_get_req()";
     
     index = get_index_by_name_signals_db(destination_name,signal_name);
     //
     h_.trnx_type  = shunt_dpi_hash("FRNG_GET");
     h_.data_type  = signals_db[index].data_type;
     h_.trnx_id    = signals_db[index].signal_id;
     h_.n_payloads = signals_db[index].signal_size;
     //
     shunt_dpi_send_header(my_socket,h_);
     shunt_dpi_recv_long(my_socket,data_);
     data =  data_in_t'(data_);
     return success;
     
  endfunction : shunt_get
   
   
   function bit shunt_get_bit_resp ( 
       input string signal_name,
       input string destination_name,
       inout  bit[N-1:0] data,
       );
      
      typedef bit [N-1:0] data_in_t;
      
      cs_header_t h_;
      //
      string 		  s_me;
      bit 		  success;
      int 	  index;
      longint	  data_;
      
      
      //
      s_me = "shunt_bit_put_req()";
      
      shunt_dpi_recv_header(my_socket,h_);
      //
      index = get_index_by_signal_id_signals_db(h_.trnx_id);
 data_ =  data_in_t'(data);
       shunt_dpi_send_long(my_socket,data_);
      return success;
   endfunction : shunt_get_bit_resp
 -----/\----- EXCLUDED -----/\----- */
   
   

endinterface : shunt_fringe_if

/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
