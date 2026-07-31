`timescale 1ns / 1ps

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
        rst = 1'b0;   // testbench overwrites this to 1 anyway, but good hygiene
    end
    always #5 clk = ~clk;

    // ------------------------------------------------------------
    // Test Variables
    // ------------------------------------------------------------
    integer i;
    reg [31:0] user_prog [0:3];
    reg [31:0] bad_prog  [0:3];
    reg [31:0] good_hash;

    // ------------------------------------------------------------
    // Test Scenarios
    // ------------------------------------------------------------
    initial begin
    $display("=========================================================");
    $display("Starting Secure Boot Testbench");
    $display("=========================================================");

    // ------------------------------------------------------------
    // SCENARIO 1: SUCCESSFUL BOOT
    // ------------------------------------------------------------
    $display("\n--- Scenario 1: Valid Program ---");
    rst = 1;
    #15 rst = 0;

    // Boot ROM is already loaded by Memory_Router's own initial block.
    $readmemh("C:/Users/Asus/Downloads/CA_Project_kharab_watchdog/CA_Project/user_prog.hex", uut.mem_inst.user_ram);
    #500;

    if (mode_bit === 1'b0)
        $display("PASS: Mode dropped to User (mode_bit=0)");
    else
        $error("FAIL: Mode did NOT drop to User!");

    if (pc >= 32'h00001000 && pc < 32'h00002000)
        $display("PASS: PC jumped to User RAM (0x%h)", pc);
    else
        $error("FAIL: PC not in User RAM (PC=0x%h)", pc);

    // ------------------------------------------------------------
    // SCENARIO 2: TAMPERED BOOT
    // ------------------------------------------------------------
    $display("\n--- Scenario 2: Tampered Program ---");
    rst = 1;
    #15 rst = 0;

    $readmemh("C:/Users/Asus/Downloads/CA_Project_kharab_watchdog/CA_Project/bad_prog.hex", uut.mem_inst.user_ram);
    #500;

    if (mode_bit === 1'b1)
        $display("PASS: Mode STAYED in Secure (mode_bit=1)");
    else
        $error("FAIL: Mode dropped to User despite bad hash!");

    if (pc < 32'h00001000)
        $display("PASS: PC stayed in Boot ROM (0x%h)", pc);
    else
        $error("FAIL: PC escaped to User RAM (PC=0x%h)", pc);

    $display("\n=========================================================");
    $display("Testbench Finished");
    $display("=========================================================");
    #50;
    $finish;
end
    // Monitor
    always @(posedge clk) begin
    $display("Time=%5t, PC=%h, Mode=%b, Exc=%b, hash_acc=%h",
              $time, pc, mode_bit, exception_taken,
              uut.mem_inst.hash_unit.hash_acc);
end

endmodule