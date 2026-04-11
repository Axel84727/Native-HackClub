# Contributing to Native-HackClub

First of all: welcome. We're glad you want to build something physical.
Please don't submit a Python script with a comment that says "hardware."

---

## The one rule that actually matters

**Your project must solve a problem that software genuinely cannot.**

Not "software would be slower." Not "I didn't feel like writing a Python script."
*Cannot.* As in: architecturally, fundamentally, provably impossible — or so impractical
that calling it a solution is dishonest.

Good examples of valid arguments:
- "A CPU cannot guarantee sub-nanosecond timing without dedicated hardware"
- "Bit-parallel operations across 64 independent signals require 64 sequential steps in software"
- "This analog sensor output can only be sampled reliably at fixed hardware intervals"

Bad examples (don't submit these):
- "Software would have taken longer to write" — that's a you problem
- "I didn't know how to do it in Python" — also a you problem
- "Hardware is cooler" — factually correct, still not an argument

---

## Project structure

Every project lives under `projects/your-project-name/`.

Preferred layout:

```

`tools/sim.sh` also supports a flat layout for small projects:

```
projects/your-project-name/
├── README.md
├── top.v
├── tb_top.v
└── constraints.xdc
```

If you use flat layout, keep names clear (`top.v`, `tb_top.v`) and keep the README complete.
projects/your-project-name/
├── README.md          # Required. Use the template.
├── src/               # Your Verilog/SystemVerilog source files
│   └── top.v          # Top-level module goes here
├── testbench/         # Simulation testbenches
│   └── tb_top.v       # At least one testbench is required
├── constraints.xdc    # Pin assignments (even if you only simulate)
└── docs/              # Optional: waveform screenshots, diagrams, notes
```

---

## README requirements

Your project README must have all of these sections (copy from `projects/_template/README.md`):

1. **Problem** — What are you solving?
2. **Why not software?** — The hard part. Be specific. No hand-waving.
3. **How it works** — Explain the hardware mechanism. Assume the reader knows Verilog.
4. **Demo** — Exact commands to simulate. What should the reader observe?
5. **Results** — Measured numbers, waveform screenshots, or observable proof.
6. **Limitations** — Every project has them. Name yours before someone else does.
7. **Future work** — What would you do with another week?

---

## Simulation requirement

Your project **must simulate**. We run:

```bash
./tools/sim.sh projects/your-project-name
```

If it doesn't compile, the PR doesn't merge. No exceptions. Not even if your hardware works great.
The simulation is the proof. The waveform is the receipt.

---

## Code style

- Use `logic` instead of `reg`/`wire` (SystemVerilog style) — your future self will thank you
- Use `always_ff` for sequential logic, `always_comb` for combinational
- Name your signals with `_n` suffix for active-low (e.g. `rst_n`, `cs_n`)
- Comment your clock frequencies and timing assumptions — don't make people guess
- Max line width: 100 characters. We're not writing punch cards but we're also not writing novels.

---

## PR checklist

Before opening a pull request, tick these off:

- [ ] `./tools/sim.sh projects/your-project-name` runs without errors
- [ ] README has all 7 required sections
- [ ] "Why not software?" section makes a specific, defensible argument
- [ ] At least one testbench with meaningful stimulus (not just a reset pulse)
- [ ] `constraints.xdc` is present, even if mostly commented out
- [ ] No Vivado/Quartus project files committed (check your `.gitignore`)
- [ ] No `.vcd` files committed (they're huge and generated, not source)

---

## Workshop contributions

Want to add a workshop? Open an issue first and describe:
- The concept being taught
- The "aha moment" students should have
- Why it fits the curriculum sequence

Workshops are reviewed more carefully than projects because 50 people follow them.
A bug in a workshop costs 50 people an hour. A bug in your project costs one person an hour.

---

## Questions?

Open an issue. Don't suffer in silence. This is Hack Club — we help each other.

*And if you submit a Python script renamed to `.v`, we will find you.*