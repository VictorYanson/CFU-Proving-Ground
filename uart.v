`include "config.vh"

// only contains transmitter for now
module uart
#(
    parameter   DBIT    = 8,
                SB_TICK = 16,
                FIFO_W  = 4
)
(
input   wire clk, reset,
input   wire [7:0] w_data,
input   wire wr_uart,
output  wire tx_full, tx
);

wire tick,      tx_done_tick;
wire tx_empty,  tx_fifo_not_empty;
wire [7:0] tx_fifo_out;

baud_generator baud_gen_unit 
(.clk(clk), .reset(reset), .tick(tick));

fifo_buffer #(.B(DBIT), .W(FIFO_W)) fifo_tx_unit
(.clk(clk), .reset(reset), .rd(tx_done_tick),
.wr(wr_uart), .w_data(w_data), .empty(tx_empty),
.full(tx_full), .r_data(tx_fifo_out));

uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit 
(.clk(clk), .reset(reset), .tx_start(tx_fifo_not_empty),
.s_tick(tick), .din(tx_fifo_out),
.tx_done_tick(tx_done_tick), .tx(tx));

assign tx_fifo_not_empty = ~tx_empty;

endmodule


module uart_tx
#(
    parameter   DBIT    =   8,
                SB_TICK =   16
)
(
input   wire    clk,        reset,
input   wire    tx_start,   s_tick,
input   wire    [7:0] din,
output  reg     tx_done_tick,
output  wire    tx
);

localparam [1:0]
idle    = 2'b00,
start   = 2'b01,
data    = 2'b10,
stop    = 2'b11; 

reg [1:0]   state_reg,  state_next;
reg [3:0]   s_reg,      s_next;
reg [2:0]   n_reg,      n_next;
reg [7:0]   b_reg,      b_next;
reg         tx_reg,     tx_next;

always @(posedge clk, posedge reset)
    if (reset)
        begin
            state_reg   <=  idle;
            s_reg       <=  0;
            n_reg       <=  0;
            b_reg       <=  0;
            tx_reg      <=  1'b1;
        end
    else
        begin
            state_reg   <=  state_next;
            s_reg       <=  s_next;
            n_reg       <=  n_next;
            b_reg       <=  b_next;
            tx_reg      <=  tx_next;  
        end

always @*
begin
    state_next      = state_reg;
    tx_done_tick    = 1'b0;
    s_next          = s_reg;
    n_next          = n_reg;
    b_next          = b_reg;
    tx_next         = tx_reg;

    case (state_reg)
        idle:
            begin
                tx_next = 1'b1;
                if (tx_start)
                    begin
                        state_next  =   start;
                        s_next      =   0;
                        b_next      =   din;
                    end
            end
        start:
            begin
                tx_next = 1'b0;
                if (s_tick)
                    if (s_reg == 15)
                        begin
                            state_next  = data;
                            s_next      = 0;
                            n_next      = 0;
                        end
                    else
                        s_next = s_reg + 1;
            end
        data:
            begin
                tx_next = b_reg[0];
                if (s_tick)
                    if (s_reg == 15)
                        begin
                            s_next  = 0;
                            b_next  = b_reg >> 1;
                            if (n_reg == 3'(DBIT - 1))
                                state_next = stop;
                            else
                                n_next  = n_reg + 1;
                        end
                    else
                        s_next = s_reg + 1;
            end
        stop:
            begin
                tx_next = 1'b1;
                if (s_tick)
                    if (s_reg == 4'(SB_TICK - 1))
                        begin
                            state_next      = idle;
                            tx_done_tick    = 1'b1; 
                        end
                    else    s_next  =   s_reg + 1;
            end
    endcase
end

assign tx = tx_reg;

endmodule


module baud_generator 
(
input  wire clk,
input  wire reset,
output reg  tick
);

localparam integer DIVISOR = ((`CLK_FREQ_MHZ * 1000000) + (`BAUD_RATE * 8)) / (`BAUD_RATE * 16);
localparam integer WIDTH   = (DIVISOR > 1) ? $clog2(DIVISOR) : 1;

reg [WIDTH-1:0] counter;

always @(posedge clk, posedge reset) begin
    if (reset) begin
        counter <= 0;
        tick    <= 1'b0;
    end else if (counter == WIDTH'(DIVISOR - 1)) begin
        counter <= 0;
        tick    <= 1'b1;
    end else begin
        counter <= counter + 1'b1;
        tick    <= 1'b0;
    end
end

endmodule


module fifo_buffer
#(
    parameter   B = 8,
                W = 4
)
(
input   wire    clk,    reset,
input   wire    rd,     wr,
input   wire    [B-1:0] w_data,
output  wire    empty,  full,
output  wire    [B-1:0] r_data 
);

reg [B-1:0]     array_reg   [2**W-1:0];
reg [W-1:0]     w_ptr_reg,  w_ptr_next,     w_ptr_succ;
reg [W-1:0]     r_ptr_reg,  r_ptr_next,     r_ptr_succ;
reg full_reg,   empty_reg,  full_next,      empty_next;
wire wr_en;

always @(posedge clk)
    if (wr_en)
        array_reg [w_ptr_reg] <= w_data;

assign r_data = array_reg [r_ptr_reg];
assign wr_en = wr & ~full_reg;

always @(posedge clk, posedge reset)
    if (reset)
        begin
            w_ptr_reg   <= 0;
            r_ptr_reg   <= 0;
            full_reg    <= 1'b0;
            empty_reg   <= 1'b1;
        end
    else
        begin
            w_ptr_reg   <= w_ptr_next;
            r_ptr_reg   <= r_ptr_next;
            full_reg    <= full_next;
            empty_reg   <= empty_next;
        end

always @*
begin
    w_ptr_succ  = w_ptr_reg + 1;
    r_ptr_succ  = r_ptr_reg + 1;
    w_ptr_next  = w_ptr_reg;
    r_ptr_next  = r_ptr_reg;
    full_next   = full_reg;
    empty_next  = empty_reg;
    case ({wr, rd})
        2'b00:  
            begin
                // no op
            end
        2'b01:  // read
            if (~empty_reg)
                begin
                    r_ptr_next  = r_ptr_succ;
                    full_next   = 1'b0;
                    if (r_ptr_succ == w_ptr_reg)
                        empty_next = 1'b1;
                end
        2'b10:  // write
            if (~full_reg)
                begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if (w_ptr_succ == r_ptr_reg)
                        full_next = 1'b1;
                end
        2'b11:  // write and read
            begin
                w_ptr_next  = w_ptr_succ;
                r_ptr_next  = r_ptr_succ;
            end
    endcase
end

assign full     = full_reg;
assign empty    = empty_reg;

endmodule