`define MY_HOST "localhost"
`define MY_PORT  3450

//simulation ID id
`define SIM_ID  12345678
//SrcDsts
`define N_OF_SRCDSTS 2
`define INIT_SRCDSTS_DB string SrcDsts[`N_OF_SRCDSTS];\
int SrcDsts_n_signals[`N_OF_SRCDSTS];\
SrcDsts[0] = "TARGET";\
SrcDsts_n_signals[0]=4;\
SrcDsts[1] = "INITIATOR";\
SrcDsts_n_signals[1]=4;

`define N_OF_SIGNALS  8
`define N_OF_PAYLOADS 8
`define INIT_SIGNAL_DB  string signals[`N_OF_SIGNALS];\
string signals_SrcDsts[`N_OF_SIGNALS];\
string signals_type[`N_OF_SIGNALS];\
int signals_n_payload[`N_OF_SIGNALS];\
__signals_name_db[0] = "data_clk_0";\
__signals_name_db[1] = "data_clk_1";\
__signals_name_db[2] = "data_clk_2";\
__signals_name_db[3] = "data_clk_3";\
__signals_name_db[4] = "data_clk_0";\
__signals_name_db[5] = "data_clk_1";\
__signals_name_db[6] = "data_clk_2";\
__signals_name_db[7] = "data_clk_3";\
__signals_SrcDst_name_db[0] = "SRCDST";\
__signals_SrcDst_name_db[1] = "SRCDST";\
__signals_SrcDst_name_db[2] = "SRCDST";\
__signals_SrcDst_name_db[3] = "SRCDST";\
__signals_SrcDst_name_db[4] = "INITIATOR";\
__signals_SrcDst_name_db[5] = "INITIATOR";\
__signals_SrcDst_name_db[6] = "INITIATOR";\
__signals_SrcDst_name_db[7] = "INITIATOR";\
signals_type[0] = "SHUNT_BIT";\
signals_type[1] = "SHUNT_BIT";\
signals_type[2] = "SHUNT_BIT";\
signals_type[3] = "SHUNT_BIT";\
signals_type[4] = "SHUNT_BIT";\
signals_type[5] = "SHUNT_BIT";\
signals_type[6] = "SHUNT_BIT";\
signals_type[7] = "SHUNT_BIT";\
signals_n_payload[0] = 1;\
signals_n_payload[1] = 1;\
signals_n_payload[2] = 1;\
signals_n_payload[3] = 1;\
signals_n_payload[4] = 1;\
signals_n_payload[5] = 1;\
signals_n_payload[6] = 1;\
signals_n_payload[7] = 1;

