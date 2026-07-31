module Hardware_Watchdog (
    input wire clk,
    input wire rst_in,         // ریست اصلی سیستم (مثلاً کلید ریست روی برد)
    input wire [31:0] PC,      // شمارنده برنامه پردازنده
    input wire Mode_Bit,       // بیت حالت (1 = Secure, 0 = User)
    
    output wire sys_rst_out     // خروجی ریست که به پردازنده و سایر ماژول‌ها متصل می‌شود
);

    // پارامترهای آدرس بر اساس صورت پروژه
    parameter RAM_START_ADDR = 32'h0000_1000;
    parameter RAM_END_ADDR   = 32'h0000_1FFF;
    parameter SECURE_MODE    = 1'b1;

    // بررسی حضور PC در محدوده RAM
    wire pc_in_ram = (PC >= RAM_START_ADDR) && (PC <= RAM_END_ADDR);
    
    // تشخیص تخلف: پردازنده در حالت امن است اما PC در RAM است
    wire violation = (Mode_Bit == SECURE_MODE) && pc_in_ram;

    reg violation_latched;
    always @(posedge clk or posedge rst_in) begin
        if (rst_in)
            violation_latched <= 1'b0;
        else if (violation)
            violation_latched <= 1'b1;
    end

    // External reset is combinational/pass-through -> no added latency,
    // deasserts in the exact same instant rst_in does.
    assign sys_rst_out = rst_in | violation | violation_latched;

endmodule