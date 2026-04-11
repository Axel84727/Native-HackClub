# Native-HackClub

Build hardware that solves problems software cannot.

Native-HackClub is about taking a real problem and solving it with physical systems, so the answer is something a normal program cannot reproduce. If a solution depends on the real world, parallelism, timing, sensors, analog behavior, or custom hardware, it belongs here.

## What fits here?

- Hardware-first projects
- Problems that are impossible or impractical to solve with software alone
- Ideas that use the physical world as part of the computation
- Proof-driven projects that can be demonstrated, measured, or tested

## Example ideas

- A clock that reveals time in a way software cannot reliably read or reconstruct
- A communication system that relies on physical hardware properties instead of a standard digital algorithm
- A storage method that can only be interpreted through a custom hardware setup
- A parallel computation trick using FPGAs or other specialized devices

## Rules

- Solve a problem with hardware, not just code.
- Show why a software-only approach cannot do the same thing.
- Prove that your solution is real.
- Use any hardware you want, but make it interesting and non-trivial.
- Explain how it works and why it matters.

## Mission

CPUs are sequential. The physical world is parallel.

Our mission is to teach 50 teenagers how to bypass the OS and the CPU to solve problems in the nanosecond domain.

## Stack

- FPGAs
- Verilog / HDL
- Whatever else the hardware needs

## Resources
- [FPGA tutorials](https://www.fpga4student.com/)
- [Verilog documentation](https://www.verilog.com/)
- [Hack Club hardware resources](https://hackclub.com/hardware/)
- [Physical computing guides](https://www.arduino.cc/en/Guide/HomePage)

## Getting Started
1. Identify a problem that software cannot solve.
2. Design a hardware solution that addresses the problem.
3. Build a prototype using FPGAs or other hardware.
4. Test and demonstrate your solution.
5. Share your project and findings with the community.

## Repository structure
docs/ - Documentation and guides
- `docs/getting_started.md` - How to get started with hardware projects
- `docs/fpga_basics.md` - Introduction to FPGAs and Verilog
- `docs/verilog_cheetsheet.md` - Quick reference for Verilog syntax and constructs
- `docs/hardware_safety.md` - Guidelines for working safely with hardware

projects/ - Example projects and templates
- `projects/_template/readme.md` - Template for new projects
- `projects/_template/src/top.v` - Template Verilog file for FPGA projects
- `projects/_template/testbench/tb_top.v` - Template testbench for simulation
- `projects/_template/contraits.xdc` - Template constraints file for FPGA pin assignments
- `projects/parallel_clock/` - Example project demonstrating a parallel clock design

workshops/ - Workshop materials and exercises
-`workshops/01-blinking-led/` - Workshop on blinking LEDs with an FPGA
- `workshops/02-seven-segment/` - Workshop on controlling a seven-segment display
- `workshops/03-uart-communication/` - Workshop on UART communication between an FPGA and a microcontroller
- `workshops/04-parallel-fsm/` - Workshop on designing a parallel finite state machine in Verilog

tools/ - Scripts and utilities for hardware development
- `tools/setup.sh` - Script to set up the development environment
- `tools/sim.sh` - Script to run simulations for Verilog projects
- `tools/flash.sh` - Script to flash the FPGA with the compiled design