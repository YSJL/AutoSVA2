/*
MMU:
    /*AUTOSVA
    
    Chosen AUTOSVA Syntax:
    - 
        - ...
    - 
        - ...

    Grouped Signal Definitions:
        itlb_req_stable = {asid_i,icache_areq_i.fetch_vaddr};
        dtlb_req_stable = {asid_i, lsu_vaddr_i};

        itlb_res_val = icache_areq_o.fetch_valid;
        itlb_res_hsk = itlb_res_val;						//Signal Generated by AUTOSVA
        itlb_lookup_transid_response = itlb_res_hsk;  		//Signal Generated by AUTOSVA

        itlb_req_val = icache_areq_i.fetch_req;
        itlb_req_rdy = icache_areq_o.fetch_valid;
        itlb_req_hsk = itlb_req_val && itlb_req_rdy;		//Signal Generated by AUTOSVA
        itlb_lookup_transid_set = itlb_req_hsk;				//Signal Generated by AUTOSVA
        
        dtlb_req_val = lsu_req_i;
        dtlb_req_hsk = dtlb_req_val;						//Signal Generated by AUTOSVA
        dtlb_lookup_transid_set = dtlb_req_hsk;				//Signal Generated by AUTOSVA

        dtlb_res_val = lsu_valid_o;
        dtlb_res_hsk = dtlb_res_val;						//Signal Generated by AUTOSVA
        dtlb_lookup_transid_response = dtlb_res_hsk;		//Signal Generated by AUTOSVA

        reg [3:0] itlb_lookup_transid_sampled;				//Signal Generated by AUTOSVA
        reg [3:0] dtlb_lookup_transid_sampled;				//Signal Generated by AUTOSVA

        always_ff @(posedge clk_i) begin
            if(!rst_ni) begin
                itlb_lookup_transid_sampled <= '0;
            end else if (itlb_lookup_transid_set || itlb_lookup_transid_response ) begin
                itlb_lookup_transid_sampled <= itlb_lookup_transid_sampled + itlb_lookup_transid_set - itlb_lookup_transid_response;
            end
        end
        always_ff @(posedge clk_i) begin
            if(!rst_ni) begin
                dtlb_lookup_transid_sampled <= '0;
            end else if (dtlb_lookup_transid_set || dtlb_lookup_transid_response ) begin
                dtlb_lookup_transid_sampled <= dtlb_lookup_transid_sampled + dtlb_lookup_transid_set - dtlb_lookup_transid_response;
            end
        end

        reg reset_r = 0;									//?? Unknown due to lack of Prompt
        
        always_ff @(posedge clk_i)
            reset_r <= 1'b1;

    Symbolics: Unconstrained, verification tool explores all possible values

	ASSERT_INPUTS:
	- Doesn't seem like it is going to 1 considering _bind.svh. Therefore, all signals dependent on this condition are constrained using assume, not asserted

	ASSERT_INPUTS Assumptions:
    - am__dtlb_lookup_transid_sample_no_overflow: 			constrains dtlb_lookup_transid_sampled != '1 OR !dtlb_lookup_transid_set
    - am__itlb_lookup_transid_sample_no_overflow: 			constrains itlb_lookup_transid_sampled != '1 OR !itlb_lookup_transid_set
    - am__itlb_lookup_transid_stability: 					if (itlb_req_val && !itlb_req_rdy), then itlb_req_val is set AND itlb_req_stable is stable

	ASSERT_INPUTS Assertions:
    - ... same but with assert

    ASSERT_INPUTS Covers:

    Autogenerated Assumptions:
    - am__rst: 												constrains reset_r to rst_ni

    Autogenerated Assertions:
    - as__dtlb_lookup_transid_eventual_response: 			if dtlb_lookup_transid_sampled has set bit, eventually dtlb_res_val needs to be set
    - as__dtlb_lookup_transid_was_a_request: 				if dtlb_lookup_transid_response is set, then dtlb_lookup_transid_set needs to be set OR dtlb_lookup_transid_sampled has a set bit
    - as__itlb_lookup_transid_hsk_or_drop: 					if itlb_req_val is set, eventually itlb_req_val needs to be NOT set OR itlb_req_rdy needs to be set
    - as__itlb_lookup_transid_eventual_response: 			if itlb_lookup_transid_sampled has a set bit, eventually itlb_res_val needs to be set
    - as__itlb_lookup_transid_was_a_request:				if itlb_lookup_transid_response is set, itlb_lookup_transid_set needs to be set OR itlb_lookup_transid_sampled has a set bit


    Autogenerated Covers:
    - co__dtlb_lookup_transid_sampled: 						flag simulation as covered if dtlb_lookup_transid_sampled has a set bit
	
	X PROPAGATION ASSERTIONS: Checks all bits are not 'x' or 'z'
	- as__no_x_itlb_req_val: 								!$isunknown(itlb_req_val)
	- as__no_x_itlb_req_stable: 							if itlb_req_val is set, !$isunknown(itlb_req_stable)
	- as__no_x_dtlb_req_val: 								!$isunknown(dtlb_req_val)
	- as__no_x_dtlb_req_stable: 							if dtlb_req_val is set, !$isunknown(dtlb_req_stable)
*/
module mmu_prop
 import ariane_pkg::*; #(
		parameter ASSERT_INPUTS = 0,
		parameter INSTR_TLB_ENTRIES     = 4,
		parameter DATA_TLB_ENTRIES      = 4,
		parameter ASID_WIDTH            = 1,
		parameter ariane_pkg::ariane_cfg_t ArianeCfg = 0//ariane_pkg::ArianeDefaultConfig
) (
		input  logic                            clk_i,
		input  logic                            rst_ni,
		input  logic                            flush_i,
		input  logic                            enable_translation_i,
		input  logic                            en_ld_st_translation_i,   // enable virtual memory translation for load/stores
		
		
		// IF interface
		input  icache_areq_o_t                  icache_areq_i,
		input  icache_areq_i_t                  icache_areq_o, //output
		
		// LSU interface
		// this is a more minimalistic interface because the actual addressing logic is handled
		// in the LSU as we distinguish load and stores, what we do here is simple address translation
		input  exception_t                      misaligned_ex_i,
		input  logic                            lsu_req_i,        // request address translation
		input  logic [riscv::VLEN-1:0]          lsu_vaddr_i,      // virtual address in
		input  logic                            lsu_is_store_i,   // the translation is requested by a store
		// if we need to walk the page table we can't grant in the same cycle
		// Cycle 0
		input  logic                            lsu_dtlb_hit_o,   // sent in the same cycle as the request if translation hits in the DTLB //output
		input  logic [riscv::PLEN-13:0]         lsu_dtlb_ppn_o,   // ppn (send same cycle as hit) //output
		// Cycle 1
		input  logic                            lsu_valid_o,      // translation is valid //output
		input  logic [riscv::PLEN-1:0]          lsu_paddr_o,      // translated address //output
		input  exception_t                      lsu_exception_o,  // address translation threw an exception //output
		// General control signals
		input riscv::priv_lvl_t                 priv_lvl_i,
		input riscv::priv_lvl_t                 ld_st_priv_lvl_i,
		input logic                             sum_i,
		input logic                             mxr_i,
		// input logic flag_mprv_i,
		input logic [riscv::PPNW-1:0]           satp_ppn_i,
		input logic [ASID_WIDTH-1:0]            asid_i,
		input logic [ASID_WIDTH-1:0]            asid_to_be_flushed_i,
		input logic [riscv::VLEN-1:0]           vaddr_to_be_flushed_i,
		input logic                             flush_tlb_i,
		// Performance counters
		input  logic                            itlb_miss_o, //output
		input  logic                            dtlb_miss_o, //output
		// PTW memory interface
		input  dcache_req_o_t                   req_port_i,
		input  dcache_req_i_t                   req_port_o, //output
		// PMP
		input  riscv::pmpcfg_t [15:0]           pmpcfg_i,
		input  logic [15:0][riscv::PLEN-1:0]    pmpaddr_i
	);

//==============================================================================
// Local Parameters
//==============================================================================

genvar j;
default clocking cb @(posedge clk_i);
endclocking
default disable iff (!rst_ni);
reg reset_r = 0;
am__rst: assume property (reset_r != !rst_ni);
always_ff @(posedge clk_i)
    reset_r <= 1'b1;

// Re-defined wires 
wire itlb_req_val;
wire itlb_req_rdy;
wire [riscv::VLEN+ASID_WIDTH-1:0] itlb_req_stable;
wire itlb_res_val;
wire dtlb_req_val;
wire [riscv::VLEN+ASID_WIDTH-1:0] dtlb_req_stable;
wire dtlb_res_val;

// Symbolics and Handshake signals
wire dtlb_res_hsk = dtlb_res_val;
wire dtlb_req_hsk = dtlb_req_val;
wire itlb_res_hsk = itlb_res_val;
wire itlb_req_hsk = itlb_req_val && itlb_req_rdy;

//==============================================================================
// Modeling
//==============================================================================

// Modeling incoming request for dtlb_lookup
// Generate sampling signals and model
reg [3:0] dtlb_lookup_transid_sampled;
wire dtlb_lookup_transid_set = dtlb_req_hsk;
wire dtlb_lookup_transid_response = dtlb_res_hsk;

always_ff @(posedge clk_i) begin
	if(!rst_ni) begin
		dtlb_lookup_transid_sampled <= '0;
	end else if (dtlb_lookup_transid_set || dtlb_lookup_transid_response ) begin
		dtlb_lookup_transid_sampled <= dtlb_lookup_transid_sampled + dtlb_lookup_transid_set - dtlb_lookup_transid_response;
	end
end
co__dtlb_lookup_transid_sampled: cover property (|dtlb_lookup_transid_sampled);
if (ASSERT_INPUTS) begin
	as__dtlb_lookup_transid_sample_no_overflow: assert property (dtlb_lookup_transid_sampled != '1 || !dtlb_lookup_transid_set);
end else begin
	am__dtlb_lookup_transid_sample_no_overflow: assume property (dtlb_lookup_transid_sampled != '1 || !dtlb_lookup_transid_set);
end


// Assert that every request has a response and that every reponse has a request
as__dtlb_lookup_transid_eventual_response: assert property (|dtlb_lookup_transid_sampled |-> s_eventually(dtlb_res_val));
as__dtlb_lookup_transid_was_a_request: assert property (dtlb_lookup_transid_response |-> dtlb_lookup_transid_set || dtlb_lookup_transid_sampled);

// Modeling incoming request for itlb_lookup
// Generate sampling signals and model
reg [3:0] itlb_lookup_transid_sampled;
wire itlb_lookup_transid_set = itlb_req_hsk;
wire itlb_lookup_transid_response = itlb_res_hsk;

always_ff @(posedge clk_i) begin
	if(!rst_ni) begin
		itlb_lookup_transid_sampled <= '0;
	end else if (itlb_lookup_transid_set || itlb_lookup_transid_response ) begin
		itlb_lookup_transid_sampled <= itlb_lookup_transid_sampled + itlb_lookup_transid_set - itlb_lookup_transid_response;
	end
end
if (ASSERT_INPUTS) begin
	as__itlb_lookup_transid_sample_no_overflow: assert property (itlb_lookup_transid_sampled != '1 || !itlb_lookup_transid_set);
end else begin
	am__itlb_lookup_transid_sample_no_overflow: assume property (itlb_lookup_transid_sampled != '1 || !itlb_lookup_transid_set);
end


// Assume payload is stable and valid is non-dropping
if (ASSERT_INPUTS) begin
	as__itlb_lookup_transid_stability: assert property (itlb_req_val && !itlb_req_rdy |=> itlb_req_val && $stable(itlb_req_stable) );
end else begin
	am__itlb_lookup_transid_stability: assume property (itlb_req_val && !itlb_req_rdy |=> itlb_req_val && $stable(itlb_req_stable) );
end

// Assert that if valid eventually ready or dropped valid
as__itlb_lookup_transid_hsk_or_drop: assert property (itlb_req_val |-> s_eventually(!itlb_req_val || itlb_req_rdy));
// Assert that every request has a response and that every reponse has a request
as__itlb_lookup_transid_eventual_response: assert property (|itlb_lookup_transid_sampled |-> s_eventually(itlb_res_val));
as__itlb_lookup_transid_was_a_request: assert property (itlb_lookup_transid_response |-> itlb_lookup_transid_set || itlb_lookup_transid_sampled);

assign itlb_res_val = icache_areq_o.fetch_valid;
assign itlb_req_stable = {asid_i,icache_areq_i.fetch_vaddr};
assign itlb_req_rdy = icache_areq_o.fetch_valid;
assign dtlb_req_stable = {asid_i, lsu_vaddr_i};
assign itlb_req_val = icache_areq_i.fetch_req;
assign dtlb_res_val = lsu_valid_o;
assign dtlb_req_val = lsu_req_i;

//X PROPAGATION ASSERTIONS
`ifdef XPROP
	 as__no_x_itlb_req_val: assert property(!$isunknown(itlb_req_val));
	 as__no_x_itlb_req_stable: assert property(itlb_req_val |-> !$isunknown(itlb_req_stable));
	 as__no_x_dtlb_req_val: assert property(!$isunknown(dtlb_req_val));
	 as__no_x_dtlb_req_stable: assert property(dtlb_req_val |-> !$isunknown(dtlb_req_stable));
`endif

endmodule