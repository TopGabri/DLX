# **DLX Processor Project**

**Group project for the *Microelectronic Systems* course at Politecnico di Torino.**

---

## 🌍 Overview

This project consisted in the **design and implementation of a fully pipelined, five-stage DLX processor**, developed from the **specification level** down to **synthesis and physical design**.

The **DLX** is a theoretical **RISC (Reduced Instruction Set Computer)** processor, whose architecture closely resembles that of **RISC-V**.
[More details about the DLX architecture ➜](https://en.wikipedia.org/wiki/DLX)

All components — except for a few partially written files provided by the professors — were designed entirely from scratch using **VHDL**.

---

## 🔧 Development Process as a team

We adopted **Git** to collaborate efficiently, enabling parallel development of independent modules and precise version tracking throughout the project.

## 🏆 Result 

After months of ideas, sketches, studying, wrong turns, right turns, endless simulations, and long working sessions, we successfully:

* **Designed, implemented, and tested** a 5-stage **pipelined** DLX processor featuring:

  * Separate **instruction** and **data memory** (Harward Architecture)
  * Complex **Forwarding** and **stalling** mechanisms
  * **Data cache** integration
  * **Branch prediction** in the ID stage via a **Branch History Table (BHT)**
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
   
You can check the source code in the <a href="./src">`src`</a> folder, while <a href="./DLX_schematic.pdf" >`DLX_schematic.pdf`</a> shows the full processor schematic (download it for better quality).

---

## 🧩 Design Methodology

The design followed a **hierarchical approach**, building the processor **bottom-up**:

* Smaller, low-level components (down to the **gate level**) were developed and validated individually.
* These modules were then combined to form larger, higher-level blocks — up to the **complete processor system**.

---

## ⛓️‍💥 Testing and Verification

Each module was verified through a dedicated **testbench**, forming a **chain of tested components** that enabled reliable verification of higher level components.

To validate the complete processor, we executed **assembly programs (`.asm`)** compiled with a provided assembler.
A **bash script** automated the loading of the generated machine code into **instruction** and **data memory**.

During simulation:

* The **register file** and **data memory** automatically write their contents to output files.
* At the end of each simulation, we could inspect these files to verify correctness and ensure that program execution matched expected behavior.

## 🏹 Possible improvements

* Implement multicycle operations: **multiplication** and **division**
* IMplement a windowed register file for context switching
