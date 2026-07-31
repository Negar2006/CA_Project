module Control_Unit (
    input  wire [5:0]  opcode,
    input  wire [5:0]  funct,
    input  wire        mode_bit,
    input  wire        zero,
    input  wire [31:0] pc,
    output reg         mem_to_reg,
    output reg         alu_src,
    output reg         reg_dst,
    output reg         reg_write,
    output reg         jump,
    output reg         branch,
    output reg         branch_ne,
    output reg [2:0]   alu_control,
    output reg         drop_priv_en,
    output reg         illegal_instr,
    output reg         secure_mode_fault,
    output reg [31:0]  exception_pc,
    output reg         exception_taken,
    output reg         is_lui                     // <-- NEW
);

    localparam OP_R_TYPE     = 6'b000000;
    localparam OP_ADDI       = 6'b001000;
    localparam OP_ORI        = 6'b001101;
    localparam OP_XORI       = 6'b001110;
    localparam OP_LW         = 6'b100011;
    localparam OP_SW         = 6'b101011;
    localparam OP_BEQ        = 6'b000100;
    localparam OP_BNE        = 6'b000101;
    localparam OP_J          = 6'b000010;
    localparam OP_DROP_PRIV  = 6'b111111;
    localparam OP_LUI        = 6'b001111;          // <-- NEW

    localparam FUNC_ADD      = 6'b100000;
    localparam FUNC_SUB      = 6'b100010;
    localparam FUNC_AND      = 6'b100100;
    localparam FUNC_OR       = 6'b100101;
    localparam FUNC_XOR      = 6'b100110;
    localparam FUNC_SLT      = 6'b101010;

    localparam ALU_AND       = 3'b000;
    localparam ALU_OR        = 3'b001;
    localparam ALU_ADD       = 3'b010;
    localparam ALU_XOR       = 3'b011;
    localparam ALU_SUB       = 3'b110;
    localparam ALU_SLT       = 3'b111;

    always @(*) begin
        // Defaults
        mem_to_reg        = 1'b0;
        alu_src           = 1'b0;
        reg_dst           = 1'b0;
        reg_write         = 1'b0;
        jump              = 1'b0;
        branch            = 1'b0;
        branch_ne         = 1'b0;
        alu_control       = ALU_ADD;
        drop_priv_en      = 1'b0;
        illegal_instr     = 1'b0;
        secure_mode_fault = 1'b0;
        exception_pc      = 32'b0;
        exception_taken   = 1'b0;
        is_lui            = 1'b0;

        case (opcode)
            OP_R_TYPE: begin
                reg_dst   = 1'b1;
                reg_write = 1'b1;
                alu_src   = 1'b0;
                mem_to_reg = 1'b0;
                case (funct)
                    FUNC_ADD: alu_control = ALU_ADD;
                    FUNC_SUB: alu_control = ALU_SUB;
                    FUNC_AND: alu_control = ALU_AND;
                    FUNC_OR:  alu_control = ALU_OR;
                    FUNC_XOR: alu_control = ALU_XOR;
                    FUNC_SLT: alu_control = ALU_SLT;
                    default: begin
                        illegal_instr = 1'b1;
                        reg_write = 1'b0;
                        exception_pc = pc;
                        exception_taken = 1'b1;
                    end
                endcase
            end
            OP_ADDI: begin
                alu_src     = 1'b1;
                reg_write   = 1'b1;
                mem_to_reg  = 1'b0;
                alu_control = ALU_ADD;
            end
            OP_ORI: begin
                alu_src     = 1'b1;
                reg_write   = 1'b1;
                mem_to_reg  = 1'b0;
                alu_control = ALU_OR;
            end
            OP_XORI: begin
                alu_src     = 1'b1;
                reg_write   = 1'b1;
                mem_to_reg  = 1'b0;
                alu_control = ALU_XOR;
            end
            OP_LW: begin
                alu_src     = 1'b1;
                reg_write   = 1'b1;
                mem_to_reg  = 1'b1;
                alu_control = ALU_ADD;
            end
            OP_SW: begin
                alu_src     = 1'b1;
                reg_write   = 1'b0;
                mem_to_reg  = 1'b0;
                alu_control = ALU_ADD;
            end
            OP_BEQ: begin
                branch      = 1'b1;
                branch_ne   = 1'b0;
                alu_control = ALU_SUB;
            end
            OP_BNE: begin
                branch      = 1'b1;
                branch_ne   = 1'b1;
                alu_control = ALU_SUB;
            end
            OP_J: begin
                jump = 1'b1;
            end
            OP_DROP_PRIV: begin
                if (mode_bit == 1'b1) begin
                    drop_priv_en = 1'b1;
                end else begin
                    illegal_instr     = 1'b1;
                    secure_mode_fault = 1'b1;
                    exception_pc      = pc;
                    exception_taken   = 1'b1;
                end
            end
            OP_LUI: begin           // <-- NEW CASE
                alu_src     = 1'b1; // immediate is used
                reg_write   = 1'b1;
                mem_to_reg  = 1'b0;
                alu_control = ALU_ADD; // not used
                is_lui      = 1'b1;
            end
            default: begin
                illegal_instr = 1'b1;
                exception_pc  = pc;
                exception_taken = 1'b1;
            end
        endcase
    end
endmodule