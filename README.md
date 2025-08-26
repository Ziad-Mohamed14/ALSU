
# ALSU - Arithmetic Logic and Shift Unit

This project implements a parameterized **Arithmetic Logic and Shift Unit (ALSU)** on FPGA, supporting a variety of logical, arithmetic, and shift/rotate operations. The design features configurable operation modes, reduction operators, bypass paths, and invalid operation detection with LED indication. It is developed in Verilog, verified through a self-checking testbench, and deployable on the Basys3 FPGA board using the provided `.xdc` constraints file.

The ALSU is designed to demonstrate core datapath design concepts such as input sampling, opcode decoding, conditional logic, arithmetic operations, and FPGA-based debugging using the Integrated Logic Analyzer (ILA).
## Features

Core functionalities supported by the ALSU:
- **Configurable Input Priority and Full Adder**
  - `INPUT_PRIORITY`: Resolves bypass conflicts (priority `"A"` or `"B"`)
  - `FULL_ADDER`: Toggles carry-in support (`"ON"` or `"OFF"`)
- **Input Handling and Sampling**
  - Inputs (`A`, `B`, `opcode`, `cin`, `serial_in`, `direction`) sampled synchronously on `clk`
  - Reset (`rst`) clears all registers and outputs
- **Supported Operations** (via `opcode`)
  - `000`: AND with optional reduction (`&A` or `&B`)
  - `001`: XOR with optional reduction (`^A` or `^B`)
  - `010`: Addition (`A + B [+ cin]`) with optional carry-in
  - `011`: Multiplication (`A * B`)
  - `100`: Shift (`LEFT` or `RIGHT` with serial input)
  - `101`: Rotate (`LEFT` or `RIGHT`)
- **Bypass and Reduction Logic**
  - Direct bypass of inputs `A` or `B` when enabled
  - Reduction operators only valid for AND/XOR opcodes
- **Invalid Opcode / Condition Detection**
  - `opcode = 110` or `111` → flagged as invalid
  - Illegal use of reduction operators on unsupported opcodes → flagged as invalid
  - On invalid conditions, **all LEDs light up** as a warning
- **FPGA Debug Support**
  - Integrated Logic Analyzer (ILA) connections pre-configured in `.xdc` for real-time debugging
  - Captures input signals, opcode, output, and key control signals


## Getting Started

To simulate or implement this design, a Verilog simulator such as QuestaSim or Vivado Simulator is required.

**1. Simulating the Design (using `.do` file)**

A `project.do` script is included for automating the simulation process:
- Ensure your simulator is configured properly
- Run the following:
    - In QuestaSim console: `do run_ALSU.do`
    - Or from terminal (Linux/macOS): source `run_ALSU.do`
    - On Windows: `run_ALSU.do`

This will compile all Verilog files, run the testbench, and open the waveform viewer.

**2. Manual Simulation (Optional)**

Alternatively, manually compile all Verilog source files and run the simulation using your simulator’s GUI or terminal.

**3. Testbench Usage**

The testbench `ALSU_tb.v` is designed to verify the communication, command handling, and memory interaction between the SPI interface and the Single-Port RAM.

**Key Features:**
- Clock & reset:
  - 2 ns period clock (`#1` high/low)
  - Reset asserted at start, then released
  - Checks reset clears `out` and `leds` to zero
- Randomized stimulus & self-checks:
  - Bypass tests: both bypasses high (exercises `INPUT_PRIORITY`)
  - Opcode 0/1: AND/XOR with random reduction flags per cycle; compares with expected
  - Opcode 2: ADD with random `cin` (assumes `FULL_ADDER = "ON"` default)
  - Opcode 3: MUL compares full 6-bit product
  - Opcode 4/5: SHIFT/ROTATE randomized `direction` and `serial_in` (waveform inspection section—see Verification tips)
- Extending verification:
  - Add assertions for SHIFT/ROTATE exact expected values
  - Gate invalid-condition scenarios and check `leds == 16'hFFFF`
  - Add constrained random plus functional coverage for corner cases (e.g., all-zeros/all-ones operands)

## Design Files

- `ALSU.v`: Parameterized ALSU (registered inputs, op map, bypass & invalid guard).
- `ALSU_tb.v`: Self-checking testbench with randomized scenarios.
- `SPI_SLAVE_WITH_SINGLE_PORT_RAM.v:` Top-level wrapper that instantiates the SPI and RAM modules and connects them via control and data signals.
- `run_ALSU.do:` Simulation automation script (compile + run + wave add).
- `ALSU Constraints_basys3.xdc:` Pin constraints + ILA debug core hookups (ready to drop into Vivado).

## Basys3 Pinout (from XDC)

- **Clock:**
  - `clk` → `W5`, 100 MHz (constraint includes `create_clock -period 10.000`)
- **Switches:**
  - `opcode[2:0]` → `W16 V16 V17`
  - `A[2:0]` → `V15 W15 W17`
  - `B[2:0]` → `V2 W13 W14`
  - Flags/controls:
    - `cin` → `T3`, `red_op_A` → `T2`, `red_op_B` → `R3`
    - `bypass_A` → `W2`, `bypass_B` → `U1`
    - `direction` → `T1`, `serial_in` → `R2`
- **LEDs:**
  - `leds[15:0]` → Basys3 LED bank (`U16 ... L1` as listed in the XDC)
- **Button:**
  - `rst` → `U18`

## Usage Notes & Tips
- **Reduction flags only valid** with `opcode` `000` (AND) or `001` (XOR). Any other opcode with `red_op_*` asserted → LEDs all on (invalid).
- **SHIFT/ROTATE outputs** are shorter concatenations that are **zero-extended** to 6 bits by assignment to `out[5:0]`. This is intentional for uniform output width.
- For **tie bypass**, set `INPUT_PRIORITY = "A"` or `"B"` at instantiation:
  - `ALSU #(.INPUT_PRIORITY("B"), .FULL_ADDER("ON")) dut (/* ports */);`
- To ignore `cin` during add, set `FULL_ADDER = "OFF"`.

## Suggested Experiments
- Sweep all `opcode` values while toggling `red_op_A/B` to observe LED invalid behavior.
- Compare `ADD` with/without `cin` by toggling `FULL_ADDER` parameter.
- Use ILA triggers on `opcode` and `out` to capture interesting corner cases on hardware.
