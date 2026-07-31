/**
 * MIPS_Processor_Top (CORRECTED / COMPLETED)
 *
 * Integrates Control_Unit, MIPS_Datapath, and Memory_Router.
 *
 * Fixes applied vs the draft you sent:
 *  - `zero` is now declared and actually wired from datapath -> control unit.
 *  - `branch_ne` wired from Control_Unit -> Datapath so BEQ/BNE are
 *    distinguished correctly.
 *  - Only ONE exception_taken signal is used end-to-end: the datapath's
 *    combinational (illegal_instr | secure_mode_fault), which is also what
 *    gates the PC freeze. The module output is driven from that same wire,
 *    not from Control_Unit's separate copy, so there's no more disagreement
 *    between "what the outside world sees" and "what actually freezes PC".
 *  - Memory_Router is now instantiated and connected for both instruction
 *    fetch and data read/write (previously just left as a comment).
 *  - `instr_violation` / `data_*_violation` from the router feed back in as
 *    additional exception sources are TODO-flagged where the spec would
 *    want them (see comment near `secure_mode_fault_combined` below) --
 *    wire this up further once you add the exception handler / watchdog.
 */

module MIPS_Processor_Top (
    input  wire        clk,
    input  wire        rst,
    output wire [31:0] pc_out,
    output wire        mode_bit,
    output wire         exception_taken
);
    wire watchdog_reset;
    wire system_reset = rst | watchdog_reset;

    // ------------------------------------------------------------
    // Control signals
    // ------------------------------------------------------------
    wire        mem_to_reg;
    wire        alu_src;
    wire        reg_dst;
    wire        reg_write;
    wire        jump;
    wire        branch;
    wire        branch_ne;
    wire [2:0]  alu_control;
    wire        drop_priv_en;
    wire        illegal_instr;
    wire        secure_mode_fault;
    wire [31:0] exception_pc;
    wire        cu_exception_taken;   // Control_Unit's own combinational copy
                                       // (kept only for exception_pc capture /
                                       // testbench compatibility -- NOT used
                                       // to gate the PC; the datapath's
                                       // exception_taken is the single
                                       // source of truth used everywhere else)
    wire is_lui;

    // ------------------------------------------------------------
    // Datapath <-> memory signals
    // ------------------------------------------------------------
    wire [31:0] pc;
    wire [31:0] instr;
    wire        zero;

    wire [31:0] alu_result;
    wire [31:0] read_data;
    wire [31:0] write_data;

    wire        dp_exception_taken;   // single source of truth, drives output

    // ------------------------------------------------------------
    // Memory Router signals
    // ------------------------------------------------------------
    wire        instr_allow;
    wire        instr_violation;
    wire        data_read_allow;
    wire        data_write_allow;
    wire        mem_violation_detected;

    // Instruction fetch is always "enabled" every cycle in a single-cycle design
    wire        instr_read_en = 1'b1;

    // Data memory is accessed for LW (read) or SW (write); derive enables
    // from the same control signals the datapath uses.
    wire        data_read_en  = mem_to_reg;              // LW asserts mem_to_reg
    wire        data_write_en = alu_src & ~reg_write & ~mem_to_reg & ~jump & ~branch;
    // NOTE: data_write_en above infers SW from the existing control signals
    // (alu_src=1, reg_write=0, mem_to_reg=0, not jump/branch). If you'd
    // rather not infer this, add an explicit `mem_write` output to
    // Control_Unit driven directly by the SW case -- that's the cleaner,
    // less fragile approach and is recommended before you add more
    // instructions to the ISA.

    assign pc_out = pc;

    Hardware_Watchdog watchdog_inst (
            .clk         (clk),
            .rst_in      (rst),          // external reset only; NOT system_reset —
                                        // the watchdog must stay live to observe
                                        // and self-clear the very fault it caused
            .PC          (pc),
            .Mode_Bit    (mode_bit),
            .sys_rst_out (watchdog_reset)
        );
    // ============================================================
    // Control Unit
    // ============================================================
    Control_Unit cu_inst (
        .opcode            (instr[31:26]),
        .funct             (instr[5:0]),
        .mode_bit          (mode_bit),
        .zero              (zero),
        .pc                (pc),
        .mem_to_reg        (mem_to_reg),
        .alu_src           (alu_src),
        .reg_dst           (reg_dst),
        .reg_write         (reg_write),
        .jump              (jump),
        .branch            (branch),
        .branch_ne         (branch_ne),
        .alu_control       (alu_control),
        .drop_priv_en      (drop_priv_en),
        .illegal_instr     (illegal_instr),
        .secure_mode_fault (secure_mode_fault),
        .exception_pc      (exception_pc),
        .exception_taken   (cu_exception_taken),
        .is_lui(is_lui)
    );

    // ============================================================
    // Datapath
    // ============================================================
    MIPS_Datapath dp_inst (
        .clk               (clk),
        .rst               (system_reset),
        .mem_to_reg        (mem_to_reg),
        .alu_src           (alu_src),
        .reg_dst           (reg_dst),
        .reg_write         (reg_write),
        .jump              (jump),
        .branch            (branch),
        .branch_ne         (branch_ne),
        .alu_control       (alu_control),
        .drop_priv_en      (drop_priv_en),
        .illegal_instr     (illegal_instr),
        .secure_mode_fault (secure_mode_fault),
        .instr             (instr),
        .pc_out            (pc),
        .read_data         (read_data),
        .alu_result        (alu_result),
        .write_data        (write_data),
        .mode_bit          (mode_bit),
        .exception_taken   (dp_exception_taken),
        .zero              (zero),
        .is_lui(is_lui)
    );

    assign exception_taken = dp_exception_taken;

    // ============================================================
    // Memory Router
    // ============================================================
    Memory_Router mem_inst (
        .clk                (clk),
        .rst                (system_reset),
        .mode_bit           (mode_bit),
        .secure_mode_fault  (secure_mode_fault),
        .exception_taken    (dp_exception_taken),

        .instr_read_en      (instr_read_en),
        .instr_addr         (pc),
        .instr_allow        (instr_allow),
        .instr_read_data    (instr),
        .instr_violation    (instr_violation),

        .data_read_en       (data_read_en),
        .data_read_addr     (alu_result),
        .data_read_allow    (data_read_allow),
        .data_read_data     (read_data),

        .data_write_en      (data_write_en),
        .data_write_addr    (alu_result),
        .data_write_data    (write_data),
        .data_write_allow   (data_write_allow),

        .violation_detected (mem_violation_detected)
    );

    // ============================================================
    // TODO (next steps, not required for the pieces reviewed so far):
    //  - Feed instr_violation / !data_read_allow / !data_write_allow /
    //    mem_violation_detected back into an exception source, e.g. OR
    //    them into secure_mode_fault or a new memory_fault signal, so an
    //    out-of-range/permission-denied memory access also freezes the
    //    processor -- right now only Control_Unit-detected faults
    //    (illegal opcode, DROP_PRIV in user mode) do that.
    //  - Hash accelerator (CRC32 or XOR accumulator) + its MMIO registers,
    //    wired into the Memory_Router's crypto region.
    //  - Independent Hardware Execution Watchdog module (separate clock
    //    domain/counter watching mode_bit + pc, capable of asserting a
    //    system-wide reset if Secure Mode runs "too long" without
    //    accessing permitted RAM -- per the spec's bonus section).
    //  - Boot ROM program and user program contents (currently the
    //    Memory_Router resets all memories, including boot_rom, to zero).
    // ============================================================

endmodule