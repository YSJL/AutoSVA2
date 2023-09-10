// This property file was autogenerated by AutoSVA on 2023-09-09
// to check the behavior of the original RTL module, whose interface is described below: 

module fifo_prop
#(
		parameter ASSERT_INPUTS = 0,
		parameter INFLIGHT_IDX = 2,
		parameter SIZE = 4
)
(		// Clock + Reset
		input  wire                          clk,
		input  wire                          rst_n,
		input  wire                          in_val,
		input  wire                          in_rdy, //output
		input  wire [SIZE-1:0]               in_data,
		
		input  wire                          out_val, //output
		input  wire                          out_rdy,
		input  wire [SIZE-1:0]               out_data //output
	);

//==============================================================================
// Local Parameters
//==============================================================================
localparam INFLIGHT = 2**INFLIGHT_IDX;

genvar j;
default clocking cb @(posedge clk);
endclocking
default disable iff (!rst_n);

// Re-defined wires 
wire [INFLIGHT_IDX-1:0] in_transid;
wire [INFLIGHT_IDX-1:0] out_transid;

// Symbolics and Handshake signals
wire [INFLIGHT_IDX-1:0] symb_in_transid;
am__symb_in_transid_stable: assume property($stable(symb_in_transid));
wire out_hsk = out_val && out_rdy;
wire in_hsk = in_val && in_rdy;

//==============================================================================
// Modeling
//==============================================================================

// Modeling incoming request for fifo
if (ASSERT_INPUTS) begin
	as__fifo_fairness: assert property (out_val |-> s_eventually(out_rdy));
end else begin
	am__fifo_fairness: assume property (out_val |-> s_eventually(out_rdy));
end

// Generate sampling signals and model
reg [3:0] fifo_transid_sampled;
wire fifo_transid_set = in_hsk && in_transid == symb_in_transid;
wire fifo_transid_response = out_hsk && out_transid == symb_in_transid;

always_ff @(posedge clk) begin
	if(!rst_n) begin
		fifo_transid_sampled <= '0;
	end else if (fifo_transid_set || fifo_transid_response ) begin
		fifo_transid_sampled <= fifo_transid_sampled + fifo_transid_set - fifo_transid_response;
	end
end
co__fifo_transid_sampled: cover property (|fifo_transid_sampled);
if (ASSERT_INPUTS) begin
	as__fifo_transid_sample_no_overflow: assert property (fifo_transid_sampled != '1 || !fifo_transid_set);
end else begin
	am__fifo_transid_sample_no_overflow: assume property (fifo_transid_sampled != '1 || !fifo_transid_set);
end


// Assert that if valid eventually ready or dropped valid
as__fifo_transid_hsk_or_drop: assert property (in_val |-> s_eventually(!in_val || in_rdy));
// Assert that every request has a response and that every reponse has a request
as__fifo_transid_eventual_response: assert property (|fifo_transid_sampled |-> s_eventually(out_val && (out_transid == symb_in_transid) ));
as__fifo_transid_was_a_request: assert property (fifo_transid_response |-> fifo_transid_set || fifo_transid_sampled);


// Modeling data integrity for fifo_transid
reg [SIZE-1:0] fifo_transid_data_model;
always_ff @(posedge clk) begin
	if(!rst_n) begin
		fifo_transid_data_model <= '0;
	end else if (fifo_transid_set) begin
		fifo_transid_data_model <= in_data;
	end
end

as__fifo_transid_data_unique: assert property (|fifo_transid_sampled |-> !fifo_transid_set);
as__fifo_transid_data_integrity: assert property (|fifo_transid_sampled && fifo_transid_response |-> (out_data == fifo_transid_data_model));

assign out_transid = multiplier.buffer_tail_reg;
assign in_transid = multiplier.buffer_head_reg;

//====DESIGNER-ADDED-SVA====//



// Property File for module multiplier

// Ensure that if the in_hsk is active, the buffer_head_reg will increase in the next cycle.
as__buffer_head_increment:
    assert property (multiplier.in_hsk |=> multiplier.buffer_head_reg == $past(multiplier.buffer_head_reg + 1'b1));

// Ensure that if the out_hsk is active, the buffer_tail_reg will increase in the next cycle.
as__buffer_tail_increment:
    assert property (multiplier.out_hsk |=> multiplier.buffer_tail_reg == $past(multiplier.buffer_tail_reg + 1'b1));

// Ensure that only one slot in the buffer can be added at any time.
as__single_slot_addition:
    assert property ($countones(multiplier.add_buffer) <= 1);

// Ensure that only one slot in the buffer can be cleared at any time.
as__single_slot_clearance:
    assert property ($countones(multiplier.clr_buffer) <= 1);

// When data is added to buffer_data_reg, it should match the input data of that cycle.
generate
    for (genvar k = 0; k < multiplier.INFLIGHT; k = k + 1) begin: buffer_data_match_gen
        as__buffer_data_match__k:
        assert property (multiplier.add_buffer[k] |=> multiplier.buffer_data_reg[k] == $past(multiplier.in_data));
    end
endgenerate

// When out_val is active, there should be at least one valid data in the buffer.
as__out_val_validity:
    assert property (multiplier.out_val -> |multiplier.buffer_val_reg);

// When all buffers are valid, in_rdy should be deasserted (not ready for new data).
as__buffers_full_in_rdy_deasserted:
    assert property (&multiplier.buffer_val_reg -> !multiplier.in_rdy);

// When not all buffers are valid, in_rdy should be asserted (ready for new data).
as__buffers_not_full_in_rdy_asserted:
    assert property (!(&multiplier.buffer_val_reg) -> multiplier.in_rdy);

// The output data should always match the data of the buffer_tail_reg.
as__output_data_correctness:
    assert property (multiplier.out_data == multiplier.buffer_data_reg[multiplier.buffer_tail_reg]);





endmodule