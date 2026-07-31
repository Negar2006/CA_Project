`timescale 1ns / 1ps

module tb_Memory_Router2();

    // Inputs
    reg clk;
    reg rst;
    reg mode_bit;
    reg secure_mode_fault;
    reg exception_taken;
    
    reg instr_read_en;
    reg [31:0] instr_addr;
    
    reg data_read_en;
    reg [31:0] data_read_addr;
    
    reg data_write_en;
    reg [31:0] data_write_addr;
    reg [31:0] data_write_data;

    // Outputs
    wire instr_allow;
    wire [31:0] instr_read_data;
    wire instr_violation;
    
    wire data_read_allow;
    wire [31:0] data_read_data;
    
    wire data_write_allow;
    wire violation_detected;

    // Instantiate the Unit Under Test (UUT)
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

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // ---------------------------------------------------
        // 1. Initialization & Reset
        // ---------------------------------------------------
        rst = 1;
        mode_bit = 1; // Secure mode
        secure_mode_fault = 0;
        exception_taken = 0;
        
        instr_read_en = 0; instr_addr = 0;
        data_read_en = 0; data_read_addr = 0;
        data_write_en = 0; data_write_addr = 0; data_write_data = 0;
        
        #20;
        rst = 0;
        #10;

        $display("--- SECURE MODE TESTS ---");
        
        // ---------------------------------------------------
        // 2. Secure Mode: Write and Read User RAM (0x1000)
        // ---------------------------------------------------
        data_write_en = 1;
        data_write_addr = 32'h00001004;
        data_write_data = 32'hDEADBEEF;
        #10;
        data_write_en = 0;
        
        data_read_en = 1;
        data_read_addr = 32'h00001004;
        #10;
        if(data_read_data == 32'hDEADBEEF) $display("[PASS] Secure RAM Read/Write");
        else $display("[FAIL] Secure RAM Read/Write");
        data_read_en = 0;

        // ---------------------------------------------------
        // 3. Secure Mode: Access Boot ROM (0x0000)
        // ---------------------------------------------------
        instr_read_en = 1;
        instr_addr = 32'h00000008; // Boot ROM addr
        #10;
        if(instr_allow == 1 && instr_violation == 0) $display("[PASS] Secure ROM Fetch Allowed");
        else $display("[FAIL] Secure ROM Fetch Allowed");
        instr_read_en = 0;

        // ---------------------------------------------------
        // 4. Secure Mode: Crypto Accelerator Data Access (0x2000)
        // ---------------------------------------------------
        data_write_en = 1;
        data_write_addr = 32'h00002010; // Crypto Write
        data_write_data = 32'hCAFEBABE;
        #10;
        data_write_en = 0;
        
        data_read_en = 1;
        data_read_addr = 32'h00002010; // Crypto Read
        #10;
        if(data_read_allow == 1) $display("[PASS] Secure Crypto Access Allowed");
        else $display("[FAIL] Secure Crypto Access Allowed");
        data_read_en = 0;

        // ---------------------------------------------------
        // 5. Secure Mode: Crypto Fetch (Should return 0, no fetch allowed in practice)
        // ---------------------------------------------------
        instr_read_en = 1;
        instr_addr = 32'h00002004;
        #10;
        if(instr_read_data == 32'b0) $display("[PASS] Secure Crypto Fetch Returns 0");
        else $display("[FAIL] Secure Crypto Fetch Returns 0");
        instr_read_en = 0;

        $display("--- USER MODE TESTS ---");
        mode_bit = 0; // Drop Privileges to User Mode
        #10;

        // ---------------------------------------------------
        // 6. User Mode: RAM Access (Allowed)
        // ---------------------------------------------------
        data_read_en = 1;
        data_read_addr = 32'h00001004;
        #10;
        if(data_read_allow == 1 && violation_detected == 0) $display("[PASS] User RAM Access Allowed");
        else $display("[FAIL] User RAM Access Allowed");
        data_read_en = 0;

        // ---------------------------------------------------
        // 7. User Mode: Boot ROM Access (Violation!)
        // ---------------------------------------------------
        @(negedge clk); // تغییر ورودی‌ها در لبه پایین‌رونده برای جلوگیری از Race Condition
        instr_read_en = 1;
        instr_addr = 32'h00000008;
        
        @(posedge clk); // صبر برای یک لبه بالارونده
        #1; // یک نانوثانیه صبر برای آپدیت شدن خروجی‌های ترکیبی (Combinational)
        if(instr_allow == 0 && instr_violation == 1) $display("[PASS] User ROM Fetch Blocked");
        else $display("[FAIL] User ROM Fetch Blocked");
        
        @(posedge clk); // صبر برای لبه بالارونده بعدی تا violation_detected رجیستر شود
        #1;
        if(violation_detected == 1) $display("[PASS] Violation correctly registered");
        else $display("[FAIL] Violation correctly registered");
        
        instr_read_en = 0; // حالا سیگنال را صفر می‌کنیم
        
        // Reset to clear violation
        @(negedge clk);
        rst = 1; 
        @(negedge clk); 
        rst = 0; 
        mode_bit = 0;

        // ---------------------------------------------------
        // 8. User Mode: Crypto Access (Violation!)
        // ---------------------------------------------------
        @(negedge clk);
        data_read_en = 1;
        data_read_addr = 32'h00002000;
        
        @(posedge clk);
        #1;
        if(data_read_allow == 0) $display("[PASS] User Crypto Access Blocked");
        else $display("[FAIL] User Crypto Access Blocked");
        
        @(posedge clk); // صبر برای ثبت شدن در رجیستر
        #1;
        if(violation_detected == 1) $display("[PASS] Crypto Access Violation Registered");
        else $display("[FAIL] Crypto Access Violation Registered");

        data_read_en = 0;

        $display("--- SIMULATION COMPLETE ---");
        $finish;
    end
endmodule
