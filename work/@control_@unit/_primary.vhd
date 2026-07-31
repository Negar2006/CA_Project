library verilog;
use verilog.vl_types.all;
entity Control_Unit is
    port(
        opcode          : in     vl_logic_vector(5 downto 0);
        funct           : in     vl_logic_vector(5 downto 0);
        mode_bit        : in     vl_logic;
        zero            : in     vl_logic;
        pc              : in     vl_logic_vector(31 downto 0);
        mem_to_reg      : out    vl_logic;
        alu_src         : out    vl_logic;
        reg_dst         : out    vl_logic;
        reg_write       : out    vl_logic;
        jump            : out    vl_logic;
        branch          : out    vl_logic;
        branch_ne       : out    vl_logic;
        alu_control     : out    vl_logic_vector(2 downto 0);
        drop_priv_en    : out    vl_logic;
        illegal_instr   : out    vl_logic;
        secure_mode_fault: out    vl_logic;
        exception_pc    : out    vl_logic_vector(31 downto 0);
        exception_taken : out    vl_logic
    );
end Control_Unit;
