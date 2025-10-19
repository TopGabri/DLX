# **DLX Processor Project**

**Group project for the *Microelectronic Systems* course at Politecnico di Torino.**

---

## 🌍 Overview

This project consisted in the **design and implementation of a fully pipelined, five-stage DLX processor**, developed from the **specification level** down to **synthesis and physical design**.

The **DLX** is a theoretical **RISC (Reduced Instruction Set Computer)** processor, whose architecture closely resembles that of **RISC-V**.
[More details about the DLX architecture ➜](https://en.wikipedia.org/wiki/DLX)

All components — except for a few partially written files provided by the professors — were designed entirely from scratch using **VHDL**.

---

## 🔧 Development Process

We adopted **Git** to collaborate efficiently, enabling parallel development of independent modules and precise version tracking throughout the project.

After months of ideas, sketches, studying, wrong turns, right turns, endless simulations, and long working sessions, we successfully:

* **Designed, implemented, and tested** a 5-stage pipelined DLX processor featuring:

  * Separate **instruction** and **data memory**
  * **Forwarding** and **stalling** mechanisms
  * **Data cache** integration
  * **Branch prediction** via a **Branch History Table (BHT)**

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
