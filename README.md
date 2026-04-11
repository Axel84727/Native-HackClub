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
`docs/` - Documentation and guides
- `docs/getting-started.md` - Install tools and run your first simulation
- `docs/fpga-primer.md` - FPGA and Verilog fundamentals
- `docs/verilog-cheatsheet.md` - Quick Verilog/SystemVerilog reference
- `docs/hardware-safety.md` - Hardware safety checklist

`projects/` - Example projects and templates
- `projects/_template/README.md` - Project write-up template
- `projects/_template/top.v` - Top-level Verilog template
- `projects/_template/tb_top.v` - Testbench template
- `projects/_template/constraints.xdc` - Basys3 constraints template
- `projects/parallel-timer/` - Example project: independent hardware timers

`workshops/` - Workshop materials and exercises
- `workshops/01-blink-led/` - Blink an LED with a cycle-accurate divider
- `workshops/02-seven-segment/` - 7-segment decoding with combinational logic
- `workshops/03-uart-comm/` - UART transmitter from scratch
- `workshops/04-parallel-fsm/` - Two independent FSMs on one clock

`tools/` - Scripts and utilities for hardware development
- `tools/setup.sh` - Install simulation dependencies
- `tools/sim.sh` - Compile and run simulations
- `tools/flash.sh` - Program bitfiles onto supported boards

Here's the structure of the repo!
```
native-hackclub/
├── docs/                     # Concepts, primers, references
│   ├── getting-started.md    # Your first simulation in 10 minutes
│   ├── fpga-primer.md        # What is an FPGA, really
│   ├── verilog-cheatsheet.md # The stuff you'll look up every single time
│   └── hardware-safety.md    # Please read this before touching the board
│
├── projects/                 # Student & example projects
│   ├── _template/            # Copy this when starting a new project
│   └── parallel-timer/       # Example: true parallel counters
│
├── workshops/                # Guided activities, 4 sessions
│   ├── 01-blink-led/         # Hello World, but in hardware
│   ├── 02-seven-segment/     # Combinational logic + displays
│   ├── 03-uart-comm/         # Bit-exact serial communication
│   └── 04-parallel-fsm/      # Two FSMs, one clock, zero compromises
│
└── tools/                    # Shell scripts so you don't have to type
    ├── setup.sh              # Install everything
    ├── sim.sh                # Compile & simulate a project
    └── flash.sh              # Flash to real hardware
```