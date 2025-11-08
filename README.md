# **DLX Processor Project**

**Group project for the *Microelectronic Systems* course at Politecnico di Torino.**

---

## 🌍 Overview

This project consisted in the **design and implementation of a fully pipelined, five-stage DLX processor**, developed from the **specification** down to **synthesis and physical design** level.

The **DLX** is a theoretical **RISC (Reduced Instruction Set Computer)** processor, whose architecture closely resembles that of **RISC-V**.
[More details about the DLX architecture ➜](https://en.wikipedia.org/wiki/DLX)

All components — except for a few partially written files provided by the professors — were designed entirely from scratch using **VHDL** as Hardware Description Language.

---

## 🔧 Tools employed

* **Visual Studio Code** to organize project files, write code and documentation, and easily integrate Git
* **Git (and GitHub)** to collaborate efficiently, enabling parallel development of independent modules and precise version tracking throughout the project.
* **(AMD) Vivado** Design Suite to develop and test VHDL code
* **(Siemens) QuestaSim** to test VHDL code
* **(Synopsys) Design Vision** for the **synthesis** and **optimization**
* **(Cadence) Innovus** to perform **physical design**


## 🏆 Results achieved

After months of ideas, sketches, studying, wrong turns, right turns, endless simulations, and long working sessions, we successfully **designed, implemented, and tested** a 5-stage **pipelined** DLX processor featuring:

 * Separate **instruction** and **data memory** (Harward Architecture)
 * Data Hazards handling through **Forwarding** and **Stalling** mechanisms
 * A **Data cache** with direct mapping and write back policy 
 * **Branch prediction** in the ID stage via a 16-entry **Branch History Table (BHT)** with 2-bit prediction scheme
 * The following **instruction set**:
 
   * **Addition**: `add`, `addi`, `addu`, `addui`
   * **Subtraction**: `sub`, `subi`, `subu`, `subui`
   * **Logic**: `and`, `andi`, `or`, `ori`, `xor`, `xori`
   * **Shift**: `sll`, `slli`, `srl`, `srli`, `sra`, `srai`
   * **Comparison (signed)**: `slt`, `slti`, `sle`, `slei`, `sgt`, `sgti`, `sge`, `sgei`
   * **Comparison (unsigned)**: `sltu`, `sltui`, `sleu`, `sleui`, `sgtu`, `sgtui`, `sgeu`, `sgeui`
   * **Equality**: `seq`, `seqi`, `sne`, `snei`
   * **Branch**: `beqz`, `bnez`
   * **Jump**: `j`, `jal`, `jr`, `jalr`
   * **Memory (load)**: `lb`, `lbu`, `lh`, `lhu`, `lw`, `lhi`
   * **Memory (store)**: `sb`, `sh`, `sw`
   
You can check the source code in the <a href="./src">`src`</a> folder, and the testbenches in <a href="./testbench">`testbench`</a>. <a href="./DLX-scheme.pdf" >`DLX-scheme.pdf`</a> shows the full processor schematic (download it for better quality), while <a href="./ALU-scheme.pdf">`ALU-scheme.pdf`</a> depicts the internal logic of the ALU. 

---

## 🧩 Design Methodology

The design followed a **hierarchical approach**, building the processor **bottom-up**:

* Smaller, low-level components (down to the **gate level**) were developed and validated individually.
* These modules were then combined to form larger, higher-level blocks (following a *structural* design approach) — up to the **complete processor system**.
* For some modules, like memories or the forwarding/stalling unit, a *behavioral* design approach was instead used 

---

## ⛓️‍💥 Testing and Verification

Each module was verified through a dedicated **testbench**, forming a **chain of tested components** that enabled reliable verification of higher level components.

To validate the complete processor, we executed **assembly programs (`.asm`)** compiled with an assembler provided by the professors (therefore omitted in this repository).
A **bash script** automates the execution of the assembler on the specified `.asm` program and the loading of the generated machine code into two separate files, namely `instr_mem_init.mem` for `.text` segment and `data_mem_init.mem` for `.data` segment. 

During simulation:
* Upon **Reset**, **Instruction Memory** and **Data Memory** are loaded with the executable code and data from the respective `.mem` initialization files
* The sequence of instructions loaded into the Instruction Memory is executed 
* The **Register File**, **Data Cache** and **Data Memory** automatically write their contents to output files.

At the end of the simulation, we can inspect the produced files to verify correctness and ensure that program execution matched expected behavior.

---

## 🏹 Possible improvements

* Implement multicycle operations: **multiplication** and **division**
* Implement a **windowed register file** for **multi-threading**
* Optimize the design for **power** and **performance**
