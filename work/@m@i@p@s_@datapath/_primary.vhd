library verilog;
use verilog.vl_types.all;
entity MIPS_Datapath is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        mem_to_reg      : in     vl_logic;
        alu_src         : in     vl_logic;
        reg_dst         : in     vl_logic;
        reg_write       : in     vl_logic;
        jump            : in     vl_logic;
        branch          : in     vl_logic;
        branch_ne       : in     vl_logic;
        alu_control     : in     vl_logic_vector(2 downto 0);
        drop_priv_en    : in     vl_logic;
        illegal_instr   : in     vl_logic;
        secure_mode_fault: in     vl_logic;
        instr           : in     vl_logic_vector(31 downto 0);
        pc_out          : out    vl_logic_vector(31 downto 0);
        read_data       : in     vl_logic_vector(31 downto 0);
        alu_result      : out    vl_logic_vector(31 downto 0);
        write_data      : out    vl_logic_vector(31 downto 0);
        mode_bit        : out    vl_logic;
        exception_taken : out    vl_logic;
        zero            : out    vl_logic
    );
end MIPS_Datapath;
