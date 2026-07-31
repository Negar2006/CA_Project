library verilog;
use verilog.vl_types.all;
entity Memory_Router is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        mode_bit        : in     vl_logic;
        secure_mode_fault: in     vl_logic;
        exception_taken : in     vl_logic;
        instr_read_en   : in     vl_logic;
        instr_addr      : in     vl_logic_vector(31 downto 0);
        instr_allow     : out    vl_logic;
        instr_read_data : out    vl_logic_vector(31 downto 0);
        instr_violation : out    vl_logic;
        data_read_en    : in     vl_logic;
        data_read_addr  : in     vl_logic_vector(31 downto 0);
        data_read_allow : out    vl_logic;
        data_read_data  : out    vl_logic_vector(31 downto 0);
        data_write_en   : in     vl_logic;
        data_write_addr : in     vl_logic_vector(31 downto 0);
        data_write_data : in     vl_logic_vector(31 downto 0);
        data_write_allow: out    vl_logic;
        violation_detected: out    vl_logic
    );
end Memory_Router;
