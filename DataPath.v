/**
 * MIPS Datapath (CORRECTED)
 *
 * Fixes applied vs original:
 *  1. `zero` is now exposed as an output port so Control_Unit / Top can see it
 *     (it was computed internally but never surfaced before).
 *  2. Added `branch_ne` input. Branch decision now correctly distinguishes
 *     BEQ (branch on zero==1) from BNE (branch on zero==0):
 *        pc_src = branch & (branch_ne ? ~zero : zero)
 *     Previously pc_src = branch & zero, which made BNE behave like BEQ.
 *  3. `exception_taken` is now a single combinational signal
 *     (illegal_instr | secure_mode_fault), matching Control_Unit's own
 *     combinational exception_taken exactly, and is used to freeze the PC
 *     in the SAME cycle the fault is decoded (no more one-cycle-late
 *     freeze that let PC advance one extra step past a bad instruction).
 *     The old separate registered `exception_reg` has been removed to
 *     eliminate the two-independent-signals-disagreeing-by-a-cycle bug.
 */

module MIPS_Datapath (
    input  wire        clk,
    input  wire        rst,

    // Control signals from Control Unit
    input  wire        mem_to_reg,
    input  wire        alu_src,
    input  wire        reg_dst,
    input  wire        reg_write,
    input  wire        jump,
    input  wire        branch,
    input  wire        branch_ne,       // 0 = BEQ semantics, 1 = BNE semantics
    input  wire [2:0]  alu_control,
    input  wire        drop_priv_en,    // Special signal for DROP_PRIV instruction
    input  wire        illegal_instr,   // Illegal instruction flag (combinational)
    input  wire        secure_mode_fault, // Security violation flag (combinational)
    input  wire        is_lui,  

    // Instruction Memory interface
    input  wire [31:0] instr,
    output wire [31:0] pc_out,

    // Data Memory / MMIO interface (Memory Router)
    input  wire [31:0] read_data,
    output wire [31:0] alu_result,
    output wire [31:0] write_data,

    // Status outputs
    output wire        mode_bit,
    output wire        exception_taken, // combinational: illegal_instr | secure_mode_fault
    output wire        zero             // ALU zero flag, exposed for Control_Unit/Top
);

    // --- Internal registers and wires ---
    reg  [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] pc_branch;
    wire [31:0] pc_next;
    wire [31:0] pc_jump;

    wire [4:0]  write_reg;
    wire [31:0] result;
    wire [31:0] src_a;
    wire [31:0] src_b;
    wire [31:0] sign_imm;
    wire [31:0] sign_imm_sh2;

    reg         mode_reg;      // System mode register

    // --- Mode_Bit register implementation ---
    // On system reset, defaults to secure mode (1)
    // When drop_priv_en is asserted by control unit, switches to user mode (0)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mode_reg <= 1'b1; // Secure Mode
        end else if (drop_priv_en) begin
            mode_reg <= 1'b0; // User Mode
        end
    end
    assign mode_bit = mode_reg;

    // --- Exception flag (combinational, single source of truth) ---
    assign exception_taken = illegal_instr | secure_mode_fault;

    // --- Program Counter (PC) logic ---
    // Freezes PC in the SAME cycle the fault is decoded (no extra step taken).
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pc <= 32'b0;
        end else if (exception_taken) begin
            // On exception, hold PC. Exception handler redirection (if any)
            // is expected to be layered in by the Top module / handler logic.
            pc <= pc;
        end else begin
            pc <= pc_next;
        end
    end
    assign pc_out = pc;
    assign pc_plus_4 = pc + 4;

    // --- Register File (32x32) ---
    reg [31:0] rf [31:0];
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) rf[i] <= 32'b0;
        end else if (reg_write && write_reg != 5'b0) begin
            rf[write_reg] <= result;
        end
    end
    assign src_a = rf[instr[25:21]]; // rs
    assign write_data = rf[instr[20:16]]; // rt (sent as write data to memory)

    // Destination register selection (rt or rd)
    assign write_reg = reg_dst ? instr[15:11] : instr[20:16];

    // Sign Extension
    assign sign_imm = {{16{instr[15]}}, instr[15:0]};

    // --- ALU (Arithmetic Logic Unit) ---
    assign src_b = alu_src ? sign_imm : write_data;

    reg [31:0] alu_out_reg;
    always @(*) begin
        case (alu_control)
            3'b000: alu_out_reg = src_a & src_b;       // AND
            3'b001: alu_out_reg = src_a | src_b;       // OR
            3'b010: alu_out_reg = src_a + src_b;       // ADD
            3'b011: alu_out_reg = src_a ^ src_b;       // XOR
            3'b110: alu_out_reg = src_a - src_b;       // SUB
            3'b111: alu_out_reg = (src_a < src_b) ? 1 : 0; // SLT
            default: alu_out_reg = 32'b0;
        endcase
    end
    assign alu_result = alu_out_reg;
    assign zero = (alu_result == 32'b0);

    // --- Branch and Jump logic ---
    assign sign_imm_sh2 = {sign_imm[29:0], 2'b00};
    assign pc_branch = pc_plus_4 + sign_imm_sh2;

    // BEQ: taken when zero==1. BNE: taken when zero==0.
    wire branch_condition = branch_ne ? ~zero : zero;
    wire pc_src = branch & branch_condition;

    wire [31:0] pc_mux_branch = pc_src ? pc_branch : pc_plus_4;

    //assign pc_jump = {pc_plus_4[31:28], instr[25:0], 2'b00};
    // assign pc_next = jump ? pc_jump : pc_mux_branch;
    localparam USER_ENTRY_POINT = 32'h00001000;

    assign pc_jump = {pc_plus_4[31:28], instr[25:0], 2'b00};
    assign pc_next = drop_priv_en ? USER_ENTRY_POINT :
                    jump          ? pc_jump :
                                    pc_mux_branch;
                                    
    // --- Data write-back to register file ---
     wire [31:0] lui_result = {instr[15:0], 16'b0};
    assign result = is_lui ? lui_result : (mem_to_reg ? read_data : alu_result);

endmodule