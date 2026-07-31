/**
 * Hash Accelerator Module (XOR Accumulator)
 *
 * Memory Map (Offsets from 0x2000):
 * - 0x00 (0x2000): Control Register (Write 1 to bit 0 to reset/clear hash)
 * - 0x04 (0x2004): Data Register (Write data here to accumulate XOR)
 * - 0x08 (0x2008): Hash Output (Read the final hash value from here)
 */

module Hash_Accelerator (
    input  wire        clk,
    input  wire        rst,
    
    // Memory-Mapped I/O Interface
    input  wire        cs,          // Chip Select (1 = Accessing Crypto space)
    input  wire        we,          // Write Enable
    input  wire [31:0] addr,        // Address (Only lower bits needed for offset)
    input  wire [31:0] write_data,  // Data from processor
    output reg  [31:0] read_data    // Data to processor
);

    // Register Offsets
    localparam CTRL_REG = 8'h00; // Offset 0x00 -> 0x2000
    localparam DATA_REG = 8'h04; // Offset 0x04 -> 0x2004
    localparam HASH_REG = 8'h08; // Offset 0x08 -> 0x2008

    // Internal State: The Accumulator
    reg [31:0] hash_acc;

    // --------------------------------------------------------
    // Write Logic (Synchronous)
    // --------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hash_acc <= 32'b0;
        end else if (cs && we) begin
            if (addr[7:0] == CTRL_REG) begin
                // Reset accumulator if bit 0 is written as 1
                if (write_data[0] == 1'b1) begin
                    hash_acc <= 32'b0;
                end
            end else if (addr[7:0] == DATA_REG) begin
                // XOR new data with current hash
                hash_acc <= hash_acc ^ write_data;
            end
        end
    end

    // --------------------------------------------------------
    // Read Logic (Combinational for single-cycle datapath)
    // --------------------------------------------------------
    always @(*) begin
        read_data = 32'b0; // Default
        if (cs && !we) begin
            case (addr[7:0])
                HASH_REG: read_data = hash_acc;
                CTRL_REG: read_data = 32'b0; // Status/Control (optional to read)
                default:  read_data = 32'b0;
            endcase
        end
    end

endmodule
