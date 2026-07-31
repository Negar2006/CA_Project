`timescale 1ns / 1ps

/**
 * tb_MIPS_Top (COMPLETE, CORRECTED)
 *
 * Verifies every checkpoint required by the spec for both scenarios.
 *
 * Scenario 1 - Successful Boot:
 *   1. Valid program placed in RAM
 *   2. Computed hash equals reference hash
 *   3. DROP_PRIV instruction is actually executed
 *   4. Processor enters User Mode
 *   5. User program executes correctly
 *
 * Scenario 2 - Tampered Program:
 *   1. RAM program is modified/tampered
 *   2. Computed hash differs from reference hash
 *   3. Processor stays in Secure Mode
 *   4. User program never executes
 *
 * NOTE on Requirement 4 / Scenario 2:
 * We do NOT check register file contents (e.g. $t2) to prove the user
 * program never ran, because the bootloader itself uses $t2 (r10) as a
 * scratch register to hold the crypto accelerator base address (0x2000)
 * regardless of whether the hash check passes. Checking rf[10]==0 is
 * therefore unreliable -- it will read 0x2000 (8192) even when the user
 * program correctly never executed. Instead we latch whether instruction
 * fetch ever touched the User RAM address range at all, which is the
 * actual hardware-level fact we care about.
 */

module tb_MIPS_Top();
    reg clk, rst;
    wire [31:0] pc;
    wire mode_bit;
    wire exception_taken;

    MIPS_Processor_Top uut (
        .clk(clk),
        .rst(rst),
        .pc_out(pc),
        .mode_bit(mode_bit),
        .exception_taken(exception_taken)
    );

    // ------------------------------------------------------------
    // Clock Generator
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        rst = 1'b0;
    end
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Test Variables
    // ------------------------------------------------------------
    integer errors;

    reg [31:0] expected_hash_valid;
    reg [31:0] expected_hash_tampered;

    // Latches to prove specific hardware events actually happened,
    // rather than inferring them indirectly from final PC/mode/register
    // snapshots (which can be misleading, as shown by the $t2 case above).
    reg saw_drop_priv;
    reg entered_user_ram;

    initial begin
        errors                 = 0;
        expected_hash_valid    = 32'h09085427; // 20080005 ^ 20090003 ^ 01095020 ^ 08000401
        expected_hash_tampered = 32'h09085424; // 20080006 ^ 20090003 ^ 01095020 ^ 08000401
        saw_drop_priv          = 1'b0;
        entered_user_ram       = 1'b0;
    end

    // Watch drop_priv_en directly -- proves the DROP_PRIV instruction was
    // actually decoded and acted on, not just that mode_bit changed for
    // some other reason.
    always @(posedge clk) begin
        if (uut.cu_inst.drop_priv_en)
            saw_drop_priv <= 1'b1;
    end

    // Watch instruction fetch -- proves whether the CPU ever executed
    // anything from the User RAM address range, independent of what any
    // particular register happens to contain afterward.
    always @(posedge clk) begin
        if (uut.mem_inst.instr_in_user_ram && uut.mem_inst.instr_read_en)
            entered_user_ram <= 1'b1;
    end

    // ------------------------------------------------------------
    // Test Scenarios
    // ------------------------------------------------------------
    initial begin
        $display("=========================================================");
        $display("Starting Secure Boot Testbench");
        $display("=========================================================");

        // ============================================================
        // SCENARIO 1: SUCCESSFUL BOOT
        // ============================================================
        $display("\n--- Scenario 1: Valid Program ---");
        rst = 1;
        #15 rst = 0;

        saw_drop_priv    = 1'b0;
        entered_user_ram = 1'b0;

        // Requirement 1: valid program placed in RAM
        // Boot ROM is already loaded by Memory_Router's own initial block.
        $readmemh("C:/Users/Asus/Downloads/CA_Project_kharab_watchdog/CA_Project/user_prog.hex",
                   uut.mem_inst.user_ram);

        #500;

        // --- Requirement 2: computed hash equals reference ---
        if (uut.mem_inst.hash_unit.hash_acc === expected_hash_valid)
            $display("PASS: Computed hash matches reference (%h)",
                      uut.mem_inst.hash_unit.hash_acc);
        else begin
            $error("FAIL: Hash mismatch. Got %h, expected %h",
                   uut.mem_inst.hash_unit.hash_acc, expected_hash_valid);
            errors = errors + 1;
        end

        // --- Requirement 3: DROP_PRIV was actually executed ---
        if (saw_drop_priv)
            $display("PASS: DROP_PRIV instruction was executed");
        else begin
            $error("FAIL: DROP_PRIV was never asserted");
            errors = errors + 1;
        end

        // --- Requirement 4: processor entered User Mode ---
        if (mode_bit === 1'b0)
            $display("PASS: Mode dropped to User (mode_bit=0)");
        else begin
            $error("FAIL: Mode did NOT drop to User!");
            errors = errors + 1;
        end

        if (pc >= 32'h00001000 && pc < 32'h00002000)
            $display("PASS: PC jumped to User RAM (0x%h)", pc);
        else begin
            $error("FAIL: PC not in User RAM (PC=0x%h)", pc);
            errors = errors + 1;
        end

        // --- Requirement 5: user program executed correctly ---
        // addi $t0,$zero,5 ; addi $t1,$zero,3 ; add $t2,$t0,$t1 -> $t2 = 8
        // $t0=r8, $t1=r9, $t2=r10 (standard MIPS register numbering)
        if (entered_user_ram)
            $display("PASS: Instruction fetch entered User RAM (user program ran)");
        else begin
            $error("FAIL: Instruction fetch never entered User RAM");
            errors = errors + 1;
        end

        if (uut.dp_inst.rf[8] === 32'd5)
            $display("PASS: $t0 correctly loaded (5)");
        else begin
            $error("FAIL: $t0 = %0d, expected 5", uut.dp_inst.rf[8]);
            errors = errors + 1;
        end

        if (uut.dp_inst.rf[9] === 32'd3)
            $display("PASS: $t1 correctly loaded (3)");
        else begin
            $error("FAIL: $t1 = %0d, expected 3", uut.dp_inst.rf[9]);
            errors = errors + 1;
        end

        // NOTE: $t2 is also used by the bootloader as scratch (crypto base
        // address, 0x2000) before the user program overwrites it. By the
        // time we sample it here the user program's add should have run
        // last, so we expect the final value of 8, not 0x2000.
        if (uut.dp_inst.rf[10] === 32'd8)
            $display("PASS: User program executed correctly ($t2 = %0d)",
                      uut.dp_inst.rf[10]);
        else begin
            $error("FAIL: User program did not compute expected result ($t2 = %0d, expected 8)",
                   uut.dp_inst.rf[10]);
            errors = errors + 1;
        end

        // ============================================================
        // SCENARIO 2: TAMPERED BOOT
        // ============================================================
        $display("\n--- Scenario 2: Tampered Program ---");
        rst = 1;
        #15 rst = 0;

        saw_drop_priv    = 1'b0;
        entered_user_ram = 1'b0;

        // Requirement 1: RAM program modified/tampered
        $readmemh("C:/Users/Asus/Downloads/CA_Project_kharab_watchdog/CA_Project/bad_prog.hex",
                   uut.mem_inst.user_ram);

        #500;

        // --- Requirement 2: computed hash differs from reference ---
        if (uut.mem_inst.hash_unit.hash_acc !== expected_hash_valid)
            $display("PASS: Tampered hash correctly differs from reference (%h vs %h)",
                      uut.mem_inst.hash_unit.hash_acc, expected_hash_valid);
        else begin
            $error("FAIL: Tampered hash unexpectedly matches reference!");
            errors = errors + 1;
        end

        if (uut.mem_inst.hash_unit.hash_acc === expected_hash_tampered)
            $display("PASS: Tampered hash matches expected corrupted value (%h)",
                      uut.mem_inst.hash_unit.hash_acc);
        else begin
            $error("FAIL: Tampered hash = %h, expected %h",
                   uut.mem_inst.hash_unit.hash_acc, expected_hash_tampered);
            errors = errors + 1;
        end

        // --- Requirement 3: processor stayed in Secure Mode ---
        if (mode_bit === 1'b1)
            $display("PASS: Mode STAYED in Secure (mode_bit=1)");
        else begin
            $error("FAIL: Mode dropped to User despite bad hash!");
            errors = errors + 1;
        end

        if (pc < 32'h00001000)
            $display("PASS: PC stayed in Boot ROM (0x%h)", pc);
        else begin
            $error("FAIL: PC escaped to User RAM (PC=0x%h)", pc);
            errors = errors + 1;
        end

        // --- Requirement 3b: DROP_PRIV correctly never executed ---
        if (!saw_drop_priv)
            $display("PASS: DROP_PRIV correctly never executed on tampered boot");
        else begin
            $error("FAIL: DROP_PRIV executed despite bad hash!");
            errors = errors + 1;
        end

        // --- Requirement 4: user program never executed ---
        // See header note: we check instruction fetch into User RAM, NOT
        // register contents, since the bootloader's own scratch use of
        // $t2 (0x2000) makes a register-value check unreliable here.
        if (!entered_user_ram)
            $display("PASS: Instruction fetch never entered User RAM (user program did not run)");
        else begin
            $error("FAIL: Instruction fetch entered User RAM despite bad hash!");
            errors = errors + 1;
        end

        // ============================================================
        // SUMMARY
        // ============================================================
        $display("\n=========================================================");
        if (errors == 0)
            $display("ALL CHECKS PASSED");
        else
            $display("%0d CHECK(S) FAILED", errors);
        $display("Testbench Finished");
        $display("=========================================================");
        #50;
        $finish;
    end

    // ------------------------------------------------------------
    // Monitor
    // ------------------------------------------------------------
    always @(posedge clk) begin
        $display("Time=%5t, PC=%h, Mode=%b, Exc=%b, hash_acc=%h",
                  $time, pc, mode_bit, exception_taken,
                  uut.mem_inst.hash_unit.hash_acc);
    end

endmodule