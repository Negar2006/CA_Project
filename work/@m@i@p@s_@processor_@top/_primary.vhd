library verilog;
use verilog.vl_types.all;
entity MIPS_Processor_Top is
    port(
        clk             : in     vl_logic;
        rst             : in     vl_logic;
        pc_out          : out    vl_logic_vector(31 downto 0);
        mode_bit        : out    vl_logic;
        exception_taken : out    vl_logic
    );
end MIPS_Processor_Top;
