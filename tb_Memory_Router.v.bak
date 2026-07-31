/**
 * Testbench for Memory Router
 */

`timescale 1ns / 1ps

module tb_Memory_Router;
    
    // Testbench Signals
    reg         clk;
    reg         rst;
    reg         mode_bit;
    reg         secure_mode_fault;
    reg         exception_taken;
    
    reg         instr_read_en;
    reg  [31:0] instr_addr;
    wire        instr_allow;
    wire [31:0] instr_read_data;
    wire        instr_violation;
    
    reg         data_read_en;
    reg  [31:0] data_read_addr;
    wire        data_read_allow;
    wire [31:0] data_read_data;
    
    reg         data_write_en;
    reg  [31:0] data_write_addr;
    reg  [31:0] data_write_data;
    wire        data_write_allow;
    
    wire        violation_detected;
    
    // Instantiate Memory Router
    Memory_Router uut (
        .clk(clk),
        .rst(rst),
        .mode_bit(mode_bit),
        .secure_mode_fault(secure_mode_fault),
        .exception_taken(exception_taken),
        .instr_read_en(instr_read_en),
        .instr_addr(instr_addr),
        .instr_allow(instr_allow),
        .instr_read_data(instr_read_data),
        .instr_violation(instr_violation),
        .data_read_en(data_read_en),
        .data_read_addr(data_read_addr),
        .data_read_allow(data_read_allow),
        .data_read_data(data_read_data),
        .data_write_en(data_write_en),
        .data_write_addr(data_write_addr),
        .data_write_data(data_write_data),
        .data_write_allow(data_write_allow),
        .violation_detected(violation_detected)
    );
    
    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test Sequence
    initial begin
        $display("================================================");
        $display("MEMORY ROUTER TESTBENCH");
        $display("================================================\n");
        
        rst = 1;
        mode_bit = 1'b1;
        secure_mode_fault = 1'b0;
        exception_taken = 1'b0;
        
        instr_read_en = 1'b0;
        instr_addr = 32'b0;
        data_read_en = 1'b0;
        data_read_addr = 32'b0;
        data_write_en = 1'b0;
        data_write_addr = 32'b0;
        data_write_data = 32'b0;
        
        #10 rst = 0;
        #5;
        
        // Test 1: Secure Mode - Instruction Fetch
        $display("=== TEST 1: SECURE MODE - INSTRUCTION FETCH ===");
        mode_bit = 1'b1;
        
        $display("\n[1.1] Fetch from Boot ROM (0x00000000)");
        instr_addr = 32'h00000000;
        instr_read_en = 1'b1;
        #10;
        if (instr_allow && !instr_violation) begin
            $display("  ✓ PASS: Boot ROM fetch allowed");
        end else begin
            $display("  ✗ FAIL: Boot ROM fetch denied");
        end
        
        $display("\n[1.2] Fetch from User RAM (0x00001000)");
        instr_addr = 32'h00001000;
        #10;
        if (instr_allow && !instr_violation) begin
            $display("  ✓ PASS: User RAM fetch allowed");
        end else begin
            $display("  ✗ FAIL: User RAM fetch denied");
        end
        
        $display("\n[1.3] Fetch from Crypto (0x00002000)");
        instr_addr = 32'h00002000;
        #10;
        if (instr_allow && !instr_violation) begin
            $display("  ✓ PASS: Crypto fetch allowed");
        end else begin
            $display("  ✗ FAIL: Crypto fetch denied");
        end
        
        instr_read_en = 1'b0;
        
        // Test 2: Secure Mode - Data Access
        $display("\n=== TEST 2: SECURE MODE - DATA ACCESS ===");
        mode_bit = 1'b1;
        
        $display("\n[2.1] Write to User RAM");
        data_write_en = 1'b1;
        data_write_addr = 32'h00001000;
        data_write_data = 32'hDEADBEEF;
        #10;
        if (data_write_allow) begin
            $display("  ✓ PASS: User RAM write allowed");
        end else begin
            $display("  ✗ FAIL: User RAM write denied");
        end
        data_write_en = 1'b0;
        
        $display("\n[2.2] Write to Crypto");
        data_write_en = 1'b1;
        data_write_addr = 32'h00002000;
        data_write_data = 32'h12345678;
        #10;
        if (data_write_allow) begin
            $display("  ✓ PASS: Crypto write allowed");
        end else begin
            $display("  ✗ FAIL: Crypto write denied");
        end
        data_write_en = 1'b0;
        
        // Test 3: User Mode - Instruction Fetch
        $display("\n=== TEST 3: USER MODE - INSTRUCTION FETCH ===");
        mode_bit = 1'b0;
        
        $display("\n[3.1] Fetch from Boot ROM - SHOULD BE DENIED");
        instr_read_en = 1'b1;
        instr_addr = 32'h00000000;
        #10;
        if (!instr_allow && instr_violation) begin
            $display("  ✓ PASS: Boot ROM fetch correctly denied");
        end else begin
            $display("  ✗ FAIL: Boot ROM fetch incorrectly allowed");
        end
        
        $display("\n[3.2] Fetch from User RAM");
        instr_addr = 32'h00001000;
        #10;
        if (instr_allow && !instr_violation) begin
            $display("  ✓ PASS: User RAM fetch allowed");
        end else begin
            $display("  ✗ FAIL: User RAM fetch denied");
        end
        
        $display("\n[3.3] Fetch from Crypto - SHOULD BE DENIED");
        instr_addr = 32'h00002000;
        #10;
        if (!instr_allow && instr_violation) begin
            $display("  ✓ PASS: Crypto fetch correctly denied");
        end else begin
            $display("  ✗ FAIL: Crypto fetch incorrectly allowed");
        end
        
        instr_read_en = 1'b0;
        
        // Test 4: User Mode - Data Access
        $display("\n=== TEST 4: USER MODE - DATA ACCESS ===");
        mode_bit = 1'b0;
        
        $display("\n[4.1] Write to User RAM");
        data_write_en = 1'b1;
        data_write_addr = 32'h00001000;
        data_write_data = 32'hCAFEBABE;
        #10;
        if (data_write_allow) begin
            $display("  ✓ PASS: User RAM write allowed");
        end else begin
            $display("  ✗ FAIL: User RAM write denied");
        end
        data_write_en = 1'b0;
        
        $display("\n[4.2] Write to Crypto - SHOULD BE DENIED");
        data_write_en = 1'b1;
        data_write_addr = 32'h00002000;
        data_write_data = 32'hDEADBEEF;
        #10;
        if (!data_write_allow) begin
            $display("  ✓ PASS: Crypto write correctly denied");
        end else begin
            $display("  ✗ FAIL: Crypto write incorrectly allowed");
        end
        data_write_en = 1'b0;
        
        // Test 5: Security Violation
        $display("\n=== TEST 5: SECURITY VIOLATION ===");
        mode_bit = 1'b1;
        
        $display("\n[5.1] Clear violations");
        secure_mode_fault = 1'b0;
        #10;
        if (!violation_detected) begin
            $display("  ✓ PASS: No violation");
        end else begin
            $display("  ✗ FAIL: Unexpected violation");
        end
        
        $display("\n[5.2] Trigger secure mode fault");
        secure_mode_fault = 1'b1;
        #10;
        if (violation_detected) begin
            $display("  ✓ PASS: Violation detected");
        end else begin
            $display("  ✗ FAIL: Violation not detected");
        end
        
        // Test 6: Boot Sequence
        $display("\n=== TEST 6: BOOT SEQUENCE ===");
        
        $display("\n[6.1] System boots in Secure Mode");
        mode_bit = 1'b1;
        #10;
        $display("  Mode = Secure (1)");
        
        $display("\n[6.2] Fetching boot code from Boot ROM");
        instr_read_en = 1'b1;
        instr_addr = 32'h00000000;
        #10;
        if (instr_allow) begin
            $display("  ✓ PASS: Boot code fetch allowed");
        end else begin
            $display("  ✗ FAIL: Boot code fetch denied");
        end
        instr_read_en = 1'b0;
        
        $display("\n[6.3] Switching to User Mode");
        mode_bit = 1'b0;
        #10;
        $display("  Mode = User (0)");
        
        $display("\n[6.4] User tries to access Boot ROM - SHOULD BE DENIED");
        instr_read_en = 1'b1;
        instr_addr = 32'h00000000;
        #10;
        if (!instr_allow) begin
            $display("  ✓ PASS: User Boot ROM access correctly denied");
        end else begin
            $display("  ✗ FAIL: User Boot ROM access incorrectly allowed");
        end
        instr_read_en = 1'b0;
        
        $display("\n================================================");
        $display("TESTBENCH COMPLETED");
        $display("================================================");
        
        #20 $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (violation_detected) begin
            $display("  ⚠ VIOLATION DETECTED at time %t", $time);
        end
    end

endmodule