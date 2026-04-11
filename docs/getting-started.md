# Getting Started

You will be simulating hardware on your computer within 10 minutes.
No board required.

---

## What you're installing

Two tools. That's it.

| Tool | What it does |
|---|---|
| **Icarus Verilog** (`iverilog`) | Compiles your Verilog and runs the simulation |
| **GTKWave** | Opens the waveform output so you can *see* what your hardware did |

Think of `iverilog` as the compiler and GTKWave as the debugger.
Except instead of watching variable values, you're watching voltage levels over time.
It's honestly more satisfying.

---
## Installation

We have a script for this. Run it and trust it:

```bash
./tools/setup.sh
```

If you're the type who doesn't run scripts you haven't read (good instincts),
here's what it does:

**macOS:**
```bash
brew install icarus-verilog gtkwave
```

**Linux (Debian/Ubuntu):**
```bash
sudo apt-get update
sudo apt-get install iverilog gtkwave
```

**Windows(good luck):**
Download the [Icarus Verilog Windows installer](http://bleyer.org/icarus/) and
[GTKWave for Windows](https://sourceforge.net/projects/gtkwave/files/).
Then add `iverilog` to your PATH. Then consider installing WSL instead.

---

## Verify it works

Run the following command:

```bash 
iverilog -V
# Should print something like: Icarus Verilog version 11.0 ...

gtkwave --version
# Should print: GTKWave Analyzer v3.x.x
```

If either command says "command not found," re-run `setup.sh` or open an issue.

---

## Your first simulation

Let's simulate a blinking LED. This is the "Hello World" of hardware -
except instead of printing text, you're toggling a wire.

```bash
./tools/sim.sh workshops/01-blink-led/solution --no-wave
```
Then open the waveform:

```bash
gtkwave workshops/01-blink-led/solution/build/output.vcd
```

In GTKWave, drag `led` from the signal list into the wave panel.
You should see a square wave: high for a while, low for a while, repeating.

That is your LED blinking. In simulation. At full hardware speed.
No LED was harmed in the making of this tutorial.
 
---

## Understanding what just happened

When you ran `sim.sh`, it did three things:

1. **Compiled** your `.v` files with `iverilog` → produced a simulation binary
2. **Ran** the simulation binary → produced a `.vcd` waveform file
3. **Opened** GTKWave with that `.vcd` file

The `.vcd` file is basically a recording of every signal in your design,
at every point in simulated time. GTKWave plays it back so you can inspect it.
 
---

## GTKWave crash course (the 2 minutes you actually need)

| Action | How |
|---|---|
| Add a signal to the wave panel | Double-click it in the signal list |
| Zoom in on the waveform | Scroll wheel, or `Ctrl +` |
| Zoom to fit everything | Press `Ctrl + Shift + F` |
| Move the time cursor | Click anywhere in the wave panel |
| Search for a signal | `Edit → Search Signal` |

You'll discover the rest as you need it. GTKWave has a lot of buttons.
Most of them exist for historical reasons. You don't need them.
 
---

## Next steps

1. Read `docs/fpga-primer.md` — seriously, it's short and it'll make everything click
2. Work through the workshops in order: `workshops/01-blink-led/` → `workshops/04-parallel-fsm/`
3. Copy `projects/_template/` and build something that solves a real problem
4. Submit a PR and show the world what you made

Welcome to the nanosecond domain. It's fast here.