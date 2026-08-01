# Dual-Mode MIPS Processor with Secure Boot

## Project Introduction
This project is a 32-bit single-cycle processor based on the `MIPS` architecture that supports two execution modes: **Secure** and **User**. The main goal of this architecture is to implement a `Secure Boot` mechanism; such that the processor only allows the execution of user code after verifying its integrity (via a hardware hash accelerator).

## Architecture & Modules
This system is designed based on the collaboration of two main components:

1. **MIPS Core:**
   - **DataPath & Control Unit:** Supports basic MIPS instructions (such as `ADD`, `SUB`, `LW`, `SW`, `BEQ`, `J`, etc.) along with full support for the `Mode_Bit`.
   - **DROP_PRIV Instruction:** A custom opcode ($6'b111111$) that transitions the processor from Secure mode to User mode and sets the `PC` to address $0x1000$.

2. **Memory System & Peripherals:**
   - **Memory Router:** Manages memory access based on the `Mode_Bit`. In User mode, reading from the ROM or accessing the hash accelerator is blocked and generates a security fault.
   - **Hash Accelerator:** A hardware accelerator based on an `XOR Accumulator` connected to the `MMIO` bus (base address $0x2000$).
   - **Hardware Watchdog (Bonus Section):** Monitors the `PC`. If the processor is in Secure mode but the `PC` enters the User RAM range, the system is immediately locked and reset.

## Memory Map
- $0x0000$ to $0x0FFF$: `Boot ROM` (Contains the Bootloader)
- $0x1000$ to $0x1FFF$: `User RAM` (User program code and data)
- $0x2000$ to $0x20FF$: `Crypto / Hash Accelerator`

## Secure Boot Flow
1. The system resets and starts in `Secure` mode with $PC = 0$.
2. The `Bootloader` program is executed from the ROM.
3. The program reads the words stored in the `User RAM` and sends them to the `Hash Accelerator`.
4. The calculated hash is compared with a reference value.
5. **On Match:** The `DROP_PRIV` instruction is executed, and the processor enters `User Mode` to run the user program.
6. **On Mismatch:** The system remains in `Secure` mode, and user code execution is halted.

## Project Files

This project includes the following Verilog files:

### Core Modules
- `MIPS_Processor_Top.v`: Top-Level module that connects all components.
- `DataPath.v`: Processor datapath including the register file, ALU, and PC.
- `Control_Unit.v`: Control unit for decoding instructions and managing `Mode_Bit` and `DROP_PRIV`.
- `Memory_Router.v`: Memory router for managing access and applying security restrictions.
- `Hash_Accelerator.v`: Hardware hash accelerator (MMIO).
- `Hardware_Watchdog.v`: Hardware watchdog to reset the system in case of a security violation.

### Testbenches
- `MIPS_Processor_Top_tb.v`: Main and final testbench of the system for simulating Secure Boot (success and failure scenarios).
- `tb_Hardware_Watchdog.v`: Isolated testbench for checking the hardware watchdog's functionality.
- `tb_Control_Unit.v` / `tb_Memory_Router.v` / `tb_Memory_Router2.v` / `tb_Hash_Accelerator.v`: Module-level testbenches to verify the functionality of each part individually.

## Input Files and Simulation
The following hex files are required to test the system:
- `boot_rom.hex`: Machine code for the Bootloader.
- `user_prog.hex`: Valid user program (for success test).
- `bad_prog.hex`: Manipulated program (for Secure Boot failure test).

To simulate the system, run the `MIPS_Processor_Top_tb.v` file in your simulation software (such as ModelSim or QuestaSim). This testbench automatically checks both valid and malicious code scenarios and prints the results in the console (as PASS/FAIL).
