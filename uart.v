module uart_transmitter
#(
    parameter   DBIT    =   8,
                SB_TICK =   16
)
(
input   wire    clk,        reset,
input   wire    tx-start,   s-tick,
input   wire    [7:0] din,
output  reg     tx-done-tick,
output  wire    tx
)

localparam [1:0]
idle    = 2'b00,
start   = 2'b01,
data    = 2'b10,
stop    = 2'b11; 

reg [1:0]   state_reg,  state_next;
reg [3:0]   s_reg,      s_next;
reg [2:0]   n_reg,      n_next;
reg [7:0]   b_reg,      b_next;
reg         tx_reg,     tx-next ; 

always @(posedge clk, posedge reset)

assign tx = tx_reg;

endmodule