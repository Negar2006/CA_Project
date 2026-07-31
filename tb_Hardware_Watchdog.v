`timescale 1ns / 1ps

module tb_Hardware_Watchdog;

    reg clk;
    reg rst;
    reg [31:0] pc;
    reg mode_bit;
    wire watchdog_reset;

    integer errors = 0;

    Hardware_Watchdog uut (
        .clk(clk),
        .rst_in(rst),
        .PC(pc),
        .Mode_Bit(mode_bit),
        .sys_rst_out(watchdog_reset)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        pc = 32'h0000_0000;
        mode_bit = 0;

        #15 rst = 0;

        // -----------------------------------------------------------
        // Test 1: User Mode, PC in RAM -> must NOT reset
        // -----------------------------------------------------------
        $display("[%0t] Test 1: Normal execution in User Mode", $time);
        mode_bit = 0;
        pc = 32'h0000_0004; #10;
        pc = 32'h0000_0008; #10;
        pc = 32'h0000_1000; #10;

        if (!watchdog_reset)
            $display("[%0t] PASS: No reset in User Mode despite PC in RAM.", $time);
        else begin
            $display("[%0t] FAIL: Watchdog reset asserted incorrectly in User Mode.", $time);
            errors = errors + 1;
        end

        // -----------------------------------------------------------
        // Test 2: Secure Mode, PC in ROM -> must NOT reset
        // -----------------------------------------------------------
        $display("[%0t] Test 2: Entering Secure Mode (Valid PC)", $time);
        mode_bit = 1;
        pc = 32'h0000_0000; #10;
        pc = 32'h0000_0004; #10;
        pc = 32'h0000_0008; #10;

        if (!watchdog_reset)
            $display("[%0t] PASS: No reset in Secure Mode with PC in ROM.", $time);
        else begin
            $display("[%0t] FAIL: Watchdog reset asserted incorrectly with valid Secure PC.", $time);
            errors = errors + 1;
        end

        // -----------------------------------------------------------
        // Test 3: Secure Mode, PC illegally in RAM -> MUST reset
        // -----------------------------------------------------------
        $display("[%0t] Test 3: Security Violation! Secure Mode PC in RAM", $time);
        mode_bit = 1;
        pc = 32'h0000_1004;

        #20;
        if (watchdog_reset)
            $display("[%0t] PASS: Watchdog detected violation and asserted reset.", $time);
        else begin
            $display("[%0t] FAIL: Watchdog failed to assert reset on violation.", $time);
            errors = errors + 1;
        end

        // -----------------------------------------------------------
        // Test 4: External reset applied -> watchdog must self-clear
        // -----------------------------------------------------------
        $display("[%0t] Test 4: System Reset applied externally", $time);
        rst = 1;
        pc = 32'h0000_0000;
        mode_bit = 0;
        #10 rst = 0;

        #10; // let combinational logic settle post-reset
        if (!watchdog_reset)
            $display("[%0t] PASS: Watchdog cleared cleanly after external reset.", $time);
        else begin
            $display("[%0t] FAIL: Watchdog reset stuck high after external reset.", $time);
            errors = errors + 1;
        end

        // -----------------------------------------------------------
        // Test 5 (new): confirm it stays clear afterward under safe conditions
        // -----------------------------------------------------------
        pc = 32'h0000_0004; #10;
        pc = 32'h0000_0008; #10;
        if (!watchdog_reset)
            $display("[%0t] PASS: Watchdog remains clear during normal post-reset execution.", $time);
        else begin
            $display("[%0t] FAIL: Watchdog unexpectedly asserted after clean reset.", $time);
            errors = errors + 1;
        end

        #20;
        if (errors == 0)
            $display("=== ALL WATCHDOG TESTS PASSED ===");
        else
            $display("=== %0d WATCHDOG TEST(S) FAILED ===", errors);

        $stop;
    end

    initial begin
        $monitor("Time=%0t | rst=%b | mode_bit=%b | PC=%h | watchdog_reset=%b",
                 $time, rst, mode_bit, pc, watchdog_reset);
    end

endmodule