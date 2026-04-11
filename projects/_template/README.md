# [Project Name]

<!-- Replace this line with a one-sentence description of what your project does. -->
<!-- Example: "A hardware random number generator that uses FPGA metastability as entropy source." -->

![Simulation](https://img.shields.io/badge/simulation-passing-brightgreen)
![Board](https://img.shields.io/badge/board-Basys3-blue)

---

## Problem

<!-- Describe the problem you're solving. Be specific.
     "I wanted to make something cool" is not a problem statement.
     "Software timers have OS-induced jitter of up to 10ms, making them unusable
     for precise sensor sampling at 1kHz" IS a problem statement. -->

---

## Why not software?

<!-- This is the most important section. Make the argument clearly.
     Don't say "hardware is faster." Explain WHY software architecturally
     cannot solve your specific problem.

     Good arguments:
     - "A CPU cannot guarantee deterministic execution timing under an OS"
     - "Software cannot sample N signals truly simultaneously; it polls sequentially"
     - "The physical property I'm measuring exists only in the analog domain"

     Weak arguments:
     - "Python is slow" — get a faster laptop
     - "I didn't know how to do it in code" — go learn
     - "Hardware is cooler" — correct, still not an argument -->

---

## How it works

<!-- Explain the hardware mechanism. Diagrams welcome (link to docs/ images).
     Assume the reader knows Verilog but not your specific design. Cover:
     - The top-level structure (modules and how they connect)
     - The key insight that makes it work
     - Any non-obvious design decisions and why you made them -->

---

## Running the simulation

```bash
./tools/sim.sh projects/your-project-name
```

<!-- Describe what to look for in GTKWave. What signals should the reader inspect?
     What behavior proves the project is working? -->

**What you should see:**
- Signal `xyz` should oscillate at 1 kHz
- Signal `done` should go high after approximately 100 clock cycles
- *(add your specific observations here)*

---

## Results

<!-- Prove it works. Options:
     - Waveform screenshot (save to docs/ and link here)
     - Measured timing numbers from simulation
     - Video of the hardware working (link to it)
     - Comparison of hardware timing vs software timing

     A table of numbers is more convincing than a paragraph of claims. -->

| Metric | Hardware | Software | Improvement |
|---|---|---|---|
| Timing jitter | < 1 clock cycle (10ns @ 100MHz) | ~1-10ms | ~100,000x |
| *(add your metrics)* | | | |

---

## Limitations

<!-- Name your limitations before someone else does. -->

- This design is tested in simulation; hardware behavior may differ
- *(add your real limitations)*

---

## Future work

<!-- What would you do with another week?
     These don't need to be things you can actually build — they just
     need to be things that would make the project better or more interesting. -->

- [ ] Extend to support N channels (currently hardcoded to 1)
- [ ] Add a UART output so results can be read by a host computer
- [ ] *(add your ideas)*

---

## Files

```
src/
├── top.v          # Top-level module
└── ...            # Other source files

testbench/
└── tb_top.v       # Main testbench

constraints.xdc    # Pin assignments for [your board]
```

---

*Built for Native-HackClub. If you have questions, open an issue.*