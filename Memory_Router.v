/**
 * Memory Router Module (FULLY CORRECTED)
 *
 * Memory Map:
 * - Boot ROM:           0x00000000 - 0x00000FFF (4KB)
 * - User RAM:           0x00001000 - 0x00001FFF (4KB)
 * - Crypto Accelerator: 0x00002000 - 0x000020FF (256B)
 */

module Memory_Router (
    input  wire        clk,
    input  wire        rst,
    input  wire        mode_bit,
    input  wire        secure_mode_fault,
    input  wire        exception_taken,

    input  wire        instr_read_en,
    input  wire [31:0] instr_addr,
    output wire        instr_allow,
    output wire [31:0] instr_read_data,
    output wire        instr_violation,

    input  wire        data_read_en,
    input  wire [31:0] data_read_addr,
    output wire        data_read_allow,
    output wire [31:0] data_read_data,

    input  wire        data_write_en,
    input  wire [31:0] data_write_addr,
    input  wire [31:0] data_write_data,
    output wire        data_write_allow,

    output wire        violation_detected
);

    // Memory Map Definitions
    localparam BOOT_ROM_BASE      = 32'h00000000;
    localparam BOOT_ROM_END       = 32'h00000FFF;
    localparam USER_RAM_BASE      = 32'h00001000;
    localparam USER_RAM_END       = 32'h00001FFF;
    localparam CRYPTO_BASE        = 32'h00002000;
    localparam CRYPTO_END         = 32'h000020FF;

   parameter BOOT_ROM_FILE = "C:/Users/Asus/Downloads/CA_Project_kharab_watchdog/CA_Project/boot_rom.hex";  
    // Memory arrays
    reg [31:0] boot_rom [0:1023];
    reg [31:0] user_ram [0:1023];

    initial begin
        $readmemh(BOOT_ROM_FILE, boot_rom);
    end

    // --------------------------------------------------------
    // Load Boot ROM from file (Runs once at time 0)
    // --------------------------------------------------------

    // --------------------------------------------------------
    // Hash Accelerator (Crypto Region: 0x2000 - 0x20FF)
    // --------------------------------------------------------
    wire crypto_cs;
    wire crypto_we;
    wire [31:0] crypto_read_data;

    assign crypto_cs = (data_read_en && (data_read_addr >= CRYPTO_BASE && data_read_addr <= CRYPTO_END)) || 
                       (data_write_en && (data_write_addr >= CRYPTO_BASE && data_write_addr <= CRYPTO_END));
                       
    assign crypto_we = data_write_en && 
                       (data_write_addr >= CRYPTO_BASE &&
                        data_write_addr <= CRYPTO_END);

    Hash_Accelerator hash_unit (
        .clk(clk),
        .rst(rst),
        .cs(crypto_cs),
        .we(crypto_we),
        .addr(data_write_en ? data_write_addr : data_read_addr),
        .write_data(data_write_data),
        .read_data(crypto_read_data)
    );

    // --------------------------------------------------------
    // Address Range Detection
    // --------------------------------------------------------
    wire instr_in_boot_rom = (instr_addr >= BOOT_ROM_BASE &&
                              instr_addr <= BOOT_ROM_END);
    wire instr_in_user_ram = (instr_addr >= USER_RAM_BASE &&
                              instr_addr <= USER_RAM_END);
    wire instr_in_crypto   = (instr_addr >= CRYPTO_BASE &&
                              instr_addr <= CRYPTO_END);

    wire data_read_in_boot_rom = (data_read_addr >= BOOT_ROM_BASE &&
                                  data_read_addr <= BOOT_ROM_END);
    wire data_read_in_user_ram = (data_read_addr >= USER_RAM_BASE &&
                                  data_read_addr <= USER_RAM_END);
    wire data_read_in_crypto   = (data_read_addr >= CRYPTO_BASE &&
                                  data_read_addr <= CRYPTO_END);

    wire data_write_in_user_ram = (data_write_addr >= USER_RAM_BASE &&
                                   data_write_addr <= USER_RAM_END);
    wire data_write_in_crypto   = (data_write_addr >= CRYPTO_BASE &&
                                   data_write_addr <= CRYPTO_END);

    // --------------------------------------------------------
    // Access Permission Logic
    // --------------------------------------------------------
    wire instr_allow_secure = (instr_in_boot_rom ||
                               instr_in_user_ram ||
                               instr_in_crypto);
    wire instr_allow_user   = (instr_in_user_ram);

    assign instr_allow = (mode_bit == 1'b1) ? instr_allow_secure :
                                               instr_allow_user;

    wire data_read_allow_secure = (data_read_in_user_ram ||
                                   data_read_in_crypto);
    wire data_read_allow_user   = (data_read_in_user_ram);

    assign data_read_allow = (mode_bit == 1'b1) ? data_read_allow_secure :
                                                   data_read_allow_user;

    wire data_write_allow_secure = (data_write_in_user_ram ||
                                    data_write_in_crypto);
    wire data_write_allow_user   = (data_write_in_user_ram);

    assign data_write_allow = (mode_bit == 1'b1) ? data_write_allow_secure :
                                                    data_write_allow_user;

    // --------------------------------------------------------
    // Violation Detection
    // --------------------------------------------------------
    wire instr_violation_wire = instr_read_en && !instr_allow;
    wire data_read_violation  = data_read_en && !data_read_allow;
    wire data_write_violation = data_write_en && !data_write_allow;

    assign instr_violation = instr_violation_wire;

    reg violation_detected_reg;
    assign violation_detected = violation_detected_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            violation_detected_reg <= 1'b0;
        end else if (instr_violation_wire ||
                     data_read_violation  ||
                     data_write_violation ||
                     secure_mode_fault) begin
            violation_detected_reg <= 1'b1;
        end else begin
            violation_detected_reg <= 1'b0;
        end
    end

    // ============================================================
    // Memory Access Implementation
    // ============================================================

    // Instruction Memory -- COMBINATIONAL READ
    assign instr_read_data =
        (instr_read_en && instr_allow) ?
            (instr_in_boot_rom ? boot_rom[instr_addr[11:2]] :
             instr_in_user_ram ? user_ram[instr_addr[11:2]] :
                                  32'b0)
        : 32'b0;

    // Data Read Memory -- COMBINATIONAL READ
    assign data_read_data =
        (data_read_en && data_read_allow) ?
            (data_read_in_boot_rom ? boot_rom[data_read_addr[11:2]] :
             data_read_in_user_ram ? user_ram[data_read_addr[11:2]] :
             data_read_in_crypto   ? crypto_read_data :
                                      32'b0)
        : 32'b0;

    // Data Write Memory -- SYNCHRONOUS
    // CRITICAL FIX: Only reset user_ram, NOT boot_rom!
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Clear ONLY the writable RAM
            for (i = 0; i < 1024; i = i + 1) begin
                user_ram[i] <= 32'b0;
            end
            // BOOT ROM IS NOT CLEARED - it retains its programmed data
            // (The initial block loaded it, and we never overwrite it)
        end else if (data_write_en && data_write_allow) begin
            if (data_write_in_user_ram) begin
                user_ram[data_write_addr[11:2]] <= data_write_data;
            end
            // Writes to crypto are handled by Hash_Accelerator module
        end
    end

endmodule