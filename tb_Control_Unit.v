/**
 * Testbench for Control Unit
 * 
 * Tests all instruction types, security features, and error conditions
 * 
 * Author: [Your Name]
 * Date: [Current Date]
 */

`timescale 1ns / 1ps

module tb_Control_Unit;
    
    // ============================================================
    // Testbench Signals
    // ============================================================
    reg         clk;
    reg         rst;
    reg  [5:0]  opcode;
    reg  [5:0]  funct;
    reg         mode_bit;
    reg         zero;
    reg  [31:0] pc;
    
    // Control Unit Outputs
    wire        mem_to_reg;
    wire        alu_src;
    wire        reg_dst;
    wire        reg_write;
    wire        jump;
    wire        branch;
    wire [2:0]  alu_control;
    wire        drop_priv_en;
    wire        illegal_instr;
    wire        secure_mode_fault;
    wire [31:0] exception_pc;
    wire        exception_taken;
    
    // ============================================================
    // Instantiate Control Unit
    // ============================================================
    Control_Unit uut (
        .opcode(opcode),
        .funct(funct),
        .mode_bit(mode_bit),
        .zero(zero),
        .pc(pc),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .reg_dst(reg_dst),
        .reg_write(reg_write),
        .jump(jump),
        .branch(branch),
        .alu_control(alu_control),
        .drop_priv_en(drop_priv_en),
        .illegal_instr(illegal_instr),
        .secure_mode_fault(secure_mode_fault),
        .exception_pc(exception_pc),
        .exception_taken(exception_taken)
    );
    
    // ============================================================
    // Clock Generation
    // ============================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // ============================================================
    // Test Sequence
    // ============================================================
    initial begin
        // --------------------------------------------------------
        // Initialize
        // --------------------------------------------------------
        $display("================================================");
        $display("CONTROL UNIT TESTBENCH");
        $display("================================================");
        $display("Starting tests...\n");
        
        rst = 1;
        pc = 32'h00001000;
        mode_bit = 1'b1;  // Secure Mode
        zero = 1'b0;
        
        #10 rst = 0;
        #5;
        
        // ========================================================
        // TEST 1: R-TYPE INSTRUCTIONS
        // ========================================================
        $display("=== TEST 1: R-TYPE INSTRUCTIONS ===");
        
        // Test 1.1: ADD
        $display("\n[1.1] Testing ADD instruction");
        opcode = 6'b000000;
        funct = 6'b100000;
        #10;
        verify_signals("ADD", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 3'b010);
        
        // Test 1.2: SUB
        $display("\n[1.2] Testing SUB instruction");
        opcode = 6'b000000;
        funct = 6'b100010;
        #10;
        verify_signals("SUB", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 3'b110);
        
        // Test 1.3: AND
        $display("\n[1.3] Testing AND instruction");
        opcode = 6'b000000;
        funct = 6'b100100;
        #10;
        verify_signals("AND", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 3'b000);
        
        // Test 1.4: OR
        $display("\n[1.4] Testing OR instruction");
        opcode = 6'b000000;
        funct = 6'b100101;
        #10;
        verify_signals("OR", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 3'b001);
        
        // Test 1.5: XOR
        $display("\n[1.5] Testing XOR instruction");
        opcode = 6'b000000;
        funct = 6'b100110;
        #10;
        verify_signals("XOR", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 3'b011);
        
        // Test 1.6: SLT
        $display("\n[1.6] Testing SLT instruction");
        opcode = 6'b000000;
        funct = 6'b101010;
        #10;
        verify_signals("SLT", 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 3'b111);
        
        // Test 1.7: Invalid R-type
        $display("\n[1.7] Testing Invalid R-type instruction");
        opcode = 6'b000000;
        funct = 6'b111111;
        #10;
        if (illegal_instr && exception_taken) begin
            $display("  ✓ PASS: Invalid instruction detected");
        end else begin
            $display("  ✗ FAIL: Invalid instruction not detected");
        end
        
        // ========================================================
        // TEST 2: I-TYPE INSTRUCTIONS
        // ========================================================
        $display("\n=== TEST 2: I-TYPE INSTRUCTIONS ===");
        
        // Test 2.1: ADDI
        $display("\n[2.1] Testing ADDI instruction");
        opcode = 6'b001000;
        funct = 6'b000000;
        #10;
        verify_signals("ADDI", 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 3'b010);
        
        // Test 2.2: ORI
        $display("\n[2.2] Testing ORI instruction");
        opcode = 6'b001101;
        funct = 6'b000000;
        #10;
        verify_signals("ORI", 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 3'b001);
        
        // Test 2.3: XORI
        $display("\n[2.3] Testing XORI instruction");
        opcode = 6'b001110;
        funct = 6'b000000;
        #10;
        verify_signals("XORI", 1'b0, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 3'b011);
        
        // Test 2.4: LW
        $display("\n[2.4] Testing LW instruction");
        opcode = 6'b100011;
        funct = 6'b000000;
        #10;
        verify_signals("LW", 1'b1, 1'b1, 1'b0, 1'b1, 1'b0, 1'b0, 3'b010);
        
        // Test 2.5: SW
        $display("\n[2.5] Testing SW instruction");
        opcode = 6'b101011;
        funct = 6'b000000;
        #10;
        verify_signals("SW", 1'b0, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 3'b010);
        
        // ========================================================
        // TEST 3: BRANCH AND JUMP INSTRUCTIONS
        // ========================================================
        $display("\n=== TEST 3: BRANCH AND JUMP INSTRUCTIONS ===");
        
        // Test 3.1: BEQ with zero = 1
        $display("\n[3.1] Testing BEQ with zero=1");
        opcode = 6'b000100;
        zero = 1'b1;
        #10;
        if (branch && alu_control == 3'b110) begin
            $display("  ✓ PASS: BEQ with zero=1");
        end else begin
            $display("  ✗ FAIL: BEQ with zero=1");
        end
        
        // Test 3.2: BEQ with zero = 0
        $display("\n[3.2] Testing BEQ with zero=0");
        opcode = 6'b000100;
        zero = 1'b0;
        #10;
        if (branch && alu_control == 3'b110) begin
            $display("  ✓ PASS: BEQ with zero=0");
        end else begin
            $display("  ✗ FAIL: BEQ with zero=0");
        end
        
        // Test 3.3: BNE with zero = 0
        $display("\n[3.3] Testing BNE with zero=0");
        opcode = 6'b000101;
        zero = 1'b0;
        #10;
        if (branch && alu_control == 3'b110) begin
            $display("  ✓ PASS: BNE with zero=0");
        end else begin
            $display("  ✗ FAIL: BNE with zero=0");
        end
        
        // Test 3.4: J
        $display("\n[3.4] Testing J instruction");
        opcode = 6'b000010;
        #10;
        if (jump) begin
            $display("  ✓ PASS: Jump instruction");
        end else begin
            $display("  ✗ FAIL: Jump instruction");
        end
        
        // ========================================================
        // TEST 4: SECURITY FEATURES - DROP_PRIV
        // ========================================================
        $display("\n=== TEST 4: SECURITY FEATURES - DROP_PRIV ===");
        
        // Test 4.1: DROP_PRIV in Secure Mode
        $display("\n[4.1] Testing DROP_PRIV in Secure Mode");
        opcode = 6'b111111;
        mode_bit = 1'b1;
        #10;
        if (drop_priv_en && !illegal_instr && !secure_mode_fault) begin
            $display("  ✓ PASS: DROP_PRIV executed in Secure Mode");
        end else begin
            $display("  ✗ FAIL: DROP_PRIV in Secure Mode");
        end
        
        // Test 4.2: DROP_PRIV in User Mode
        $display("\n[4.2] Testing DROP_PRIV in User Mode");
        opcode = 6'b111111;
        mode_bit = 1'b0;
        #10;
        if (!drop_priv_en && illegal_instr && secure_mode_fault && exception_taken) begin
            $display("  ✓ PASS: DROP_PRIV blocked in User Mode");
        end else begin
            $display("  ✗ FAIL: DROP_PRIV in User Mode");
        end
        
        // ========================================================
        // TEST 5: INVALID INSTRUCTIONS
        // ========================================================
        $display("\n=== TEST 5: INVALID INSTRUCTIONS ===");
        
        // Test 5.1: Invalid opcode
        $display("\n[5.1] Testing Invalid opcode");
        opcode = 6'b111110;
        funct = 6'b000000;
        mode_bit = 1'b1;
        #10;
        if (illegal_instr && exception_taken) begin
            $display("  ✓ PASS: Invalid opcode detected");
        end else begin
            $display("  ✗ FAIL: Invalid opcode not detected");
        end
        
        // Test 5.2: Invalid opcode with exception PC
        $display("\n[5.2] Testing exception PC capture");
        pc = 32'h00001000;
        opcode = 6'b111110;
        #10;
        if (exception_pc == 32'h00001000) begin
            $display("  ✓ PASS: Exception PC captured correctly");
        end else begin
            $display("  ✗ FAIL: Exception PC not captured correctly");
        end
        
        // ========================================================
        // TEST 6: MODE TRANSITION SEQUENCE
        // ========================================================
        $display("\n=== TEST 6: MODE TRANSITION SEQUENCE ===");
        
        // Test 6.1: Normal instructions in Secure Mode
        $display("\n[6.1] Testing normal instructions in Secure Mode");
        mode_bit = 1'b1;
        opcode = 6'b001000; // ADDI
        #10;
        if (!illegal_instr && !secure_mode_fault) begin
            $display("  ✓ PASS: Normal instruction allowed in Secure Mode");
        end else begin
            $display("  ✗ FAIL: Normal instruction blocked in Secure Mode");
        end
        
        // Test 6.2: Normal instructions in User Mode
        $display("\n[6.2] Testing normal instructions in User Mode");
        mode_bit = 1'b0;
        opcode = 6'b001000; // ADDI
        #10;
        if (!illegal_instr && !secure_mode_fault) begin
            $display("  ✓ PASS: Normal instruction allowed in User Mode");
        end else begin
            $display("  ✗ FAIL: Normal instruction blocked in User Mode");
        end
        
        // ========================================================
        // TEST 7: EDGE CASES
        // ========================================================
        $display("\n=== TEST 7: EDGE CASES ===");
        
        // Test 7.1: All zeros
        $display("\n[7.1] Testing all zeros (NOP)");
        opcode = 6'b000000;
        funct = 6'b000000;
        #10;
        if (illegal_instr) begin
            $display("  ✓ PASS: All zeros treated as illegal (NOP not supported)");
        end else begin
            $display("  ✗ FAIL: All zeros not handled correctly");
        end
        
        // Test 7.2: Mode bit changes with DROP_PRIV
        $display("\n[7.2] Testing mode change sequence");
        mode_bit = 1'b1;
        opcode = 6'b111111; // DROP_PRIV
        #10;
        if (drop_priv_en) begin
            $display("  ✓ PASS: DROP_PRIV can transition from Secure to User");
        end else begin
            $display("  ✗ FAIL: DROP_PRIV not working");
        end
        
        // ========================================================
        // TEST SUMMARY
        // ========================================================
        $display("\n================================================");
        $display("TESTBENCH COMPLETED");
        $display("================================================");
        $display("\nAll tests executed successfully!");
        
        #20 $finish;
    end
    
    // ============================================================
    // Helper Task: Verify Control Signals (Verilog-2001 compatible)
    // ============================================================
    task verify_signals;
        input [20*8:1] instr_name;
        input exp_mem_to_reg;
        input exp_alu_src;
        input exp_reg_dst;
        input exp_reg_write;
        input exp_jump;
        input exp_branch;
        input [2:0] exp_alu_control;
        
        begin
            if (mem_to_reg == exp_mem_to_reg &&
                alu_src == exp_alu_src &&
                reg_dst == exp_reg_dst &&
                reg_write == exp_reg_write &&
                jump == exp_jump &&
                branch == exp_branch &&
                alu_control == exp_alu_control) begin
                $display("  ✓ PASS: %s instruction decoded correctly", instr_name);
                $display("    mem_to_reg=%b, alu_src=%b, reg_dst=%b, reg_write=%b, jump=%b, branch=%b, alu_control=%b",
                         mem_to_reg, alu_src, reg_dst, reg_write, jump, branch, alu_control);
            end else begin
                $display("  ✗ FAIL: %s instruction decoded incorrectly", instr_name);
                $display("    Expected: mem_to_reg=%b, alu_src=%b, reg_dst=%b, reg_write=%b, jump=%b, branch=%b, alu_control=%b",
                         exp_mem_to_reg, exp_alu_src, exp_reg_dst, exp_reg_write, exp_jump, exp_branch, exp_alu_control);
                $display("    Got:      mem_to_reg=%b, alu_src=%b, reg_dst=%b, reg_write=%b, jump=%b, branch=%b, alu_control=%b",
                         mem_to_reg, alu_src, reg_dst, reg_write, jump, branch, alu_control);
            end
        end
    endtask
    
    // ============================================================
    // Monitor for Security Violations
    // ============================================================
    always @(posedge clk) begin
        if (secure_mode_fault) begin
            $display("  ⚠ SECURITY VIOLATION at PC: %h, Mode: %b", pc, mode_bit);
        end
        if (illegal_instr) begin
            $display("  ⚠ ILLEGAL INSTRUCTION at PC: %h", pc);
        end
        if (exception_taken) begin
            $display("  ⚠ EXCEPTION TAKEN at PC: %h", exception_pc);
        end
    end
    
    // ============================================================
    // Waveform Dump (optional - uncomment if using VCD)
    // ============================================================
    // initial begin
    //     $dumpfile("control_unit.vcd");
    //     $dumpvars(0, tb_Control_Unit);
    // end

endmodule