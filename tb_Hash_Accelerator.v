`timescale 1ns / 1ps

module tb_Hash_Accelerator;

    // Inputs
    reg clk;
    reg rst;
    reg cs;
    reg we;
    reg [31:0] addr;
    reg [31:0] write_data;

    // Outputs
    wire [31:0] read_data;
    
    // متغیر کمکی برای ذخیره دیتای خوانده شده از تسک
    reg [31:0] captured_data;

    // Instantiate the Unit Under Test (UUT)
    Hash_Accelerator uut (
        .clk(clk),
        .rst(rst),
        .cs(cs),
        .we(we),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Task to perform a memory-mapped write
    task write_reg(input [31:0] write_addr, input [31:0] data);
        begin
            @(negedge clk);
            cs = 1;
            we = 1;
            addr = write_addr;
            write_data = data;
            @(negedge clk);
            cs = 0;
            we = 0;
        end
    endtask

    // Task to perform a memory-mapped read and capture data
    task read_reg(input [31:0] read_addr, output [31:0] out_data);
        begin
            @(negedge clk);
            cs = 1;
            we = 0;
            addr = read_addr;
            
            // یک تاخیر کوچک برای اینکه خروجی ترکیبی آماده شود (قبل از لبه بعدی)
            #2; 
            out_data = read_data; // ذخیره دیتا در حالی که cs هنوز 1 است
            
            @(negedge clk);
            cs = 0;
        end
    endtask

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 0;
        cs = 0;
        we = 0;
        addr = 0;
        write_data = 0;

        // Apply Global Reset
        rst = 1;
        #20;
        rst = 0;
        #10;

        $display("--- Starting Hash Accelerator Tests ---");

        // Test 1: Write first data (0xAAAA_5555) to DATA_REG
        $display("Test 1: Writing Data 1");
        write_reg(32'h2004, 32'hAAAA_5555);

        // Test 2: Write second data (0x1111_1111) to DATA_REG
        $display("Test 2: Writing Data 2");
        write_reg(32'h2004, 32'h1111_1111);

        // Test 3: Read HASH_REG to verify XOR result
        // Expected: 0xAAAA_5555 ^ 0x1111_1111 = 0xBBBB_4444
        $display("Test 3: Reading Hash");
        read_reg(32'h2008, captured_data);
        if (captured_data == 32'hBBBB_4444)
            $display("PASS: Hash is correct (%h)", captured_data);
        else
            $display("FAIL: Hash is incorrect. Expected 0xBBBB_4444, Got %h", captured_data);

        // Test 4: Software Reset via CTRL_REG
        $display("Test 4: Software Reset via Control Reg");
        write_reg(32'h2000, 32'h0000_0001);

        // Test 5: Verify Hash is cleared
        $display("Test 5: Reading Hash after Reset");
        read_reg(32'h2008, captured_data);
        if (captured_data == 32'h0000_0000)
            $display("PASS: Hash was successfully cleared.");
        else
            $display("FAIL: Hash is not zero (%h)", captured_data);

        $display("--- Tests Completed ---");
        $finish;
    end

endmodule
