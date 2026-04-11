# Workshop 04 — Two FSMs in Parallel

**Duration:** ~60 minutes  
**Concepts:** True hardware parallelism, independent FSMs, timing comparison vs software

---

## The goal

Build two completely independent state machines that run simultaneously
on the same clock. Watch them advance in lockstep in the waveform.
Understand why this is physically different from threading or coroutines.

---

## Background: what "parallel" actually means

When a programmer says "parallel," they usually mean one of:
- **Multi-threading**: the OS switches between threads very quickly
- **Async/await**: one thread, but tasks yield while waiting
- **Multi-core**: 2–16 separate CPUs sharing memory

All of these are different flavors of the same idea: **time-sharing**.
Multiple logical tasks share a finite number of execution units.
The OS or runtime decides who gets to run and when.

On an FPGA, "parallel" means something different:
**both things exist in hardware simultaneously.**

There is no scheduler. There is no "who runs now."
Two state machines each have their own registers.
On every clock edge, every register in every FSM updates.
Both. At the same time. In the same nanosecond.

Not "very quickly one after the other."
*At the same time.*

This workshop makes that concrete. You'll build:
- **FSM A**: a traffic light controller (Red → Green → Yellow)
- **FSM B**: a morse code transmitter (spells "SOS" on repeat)

They share a clock. They share nothing else.
Neither knows the other exists.
Watch both in GTKWave at the same time. They advance together.

---

## Why this matters

Consider a software equivalent:

```python
import threading, time

def traffic_light():
    while True:
        set_light("red");   time.sleep(2.0)
        set_light("green"); time.sleep(2.0)
        set_light("yellow");time.sleep(0.5)

def morse_sos():
    while True:
        for _ in range(3): beep(0.2); pause(0.2)  # S
        for _ in range(3): beep(0.6); pause(0.2)  # O
        for _ in range(3): beep(0.2); pause(0.2)  # S
        pause(1.4)

t1 = threading.Thread(target=traffic_light)
t2 = threading.Thread(target=morse_sos)
t1.start(); t2.start()
```

Problems:
- `time.sleep(2.0)` is not 2.0 seconds. It's "at least 2.0 seconds, give or take
  whatever the OS scheduler decides."
- If both threads want to sleep until the same moment, one will wake up first.
  The other gets its turn when the scheduler allows.
- On a single-core machine: they literally take turns. One runs, one waits.
- `time.sleep(0.2)` for morse timing? On a busy system, that 200ms will drift.
  Your SOS becomes unintelligible noise.

On the FPGA:
- Both FSMs advance every clock cycle. No scheduler.
- The traffic light counter and the morse timer are separate registers.
  They both increment on the same clock edge. Always.
- The yellow light is exactly 50,000,000 cycles. Not "approximately."
- Morse timing is cycle-exact. Your SOS is always intelligible.

---

## Step 1: Understand the design

Open `solution/dual_fsm.v` and read it completely before writing any starter code.
Pay attention to:
- How the two FSMs are completely separate blocks of `always_ff` code
- How the timing parameters work (UNIT_CYCLES for morse, RED/GREEN/YEL cycles for lights)
- How the morse sequence is stored as a lookup table in `always_comb`

---

## Step 2: Build the traffic light FSM

Open `starter/dual_fsm.v`. The ports are defined. Start with FSM A:

1. Define `typedef enum` with three states: `RED`, `GREEN`, `YELLOW`
2. Declare a state register and a counter
3. In `always_ff`: on each clock edge, increment counter; when counter hits
   the target, transition to the next state and reset counter
4. In `always_comb`: decode the state to drive `light_red`, `light_green`, `light_yellow`

Test this alone first before adding FSM B.

---

## Step 3: Add the morse FSM

With FSM A working, add FSM B alongside it — in the **same module**, with **separate** registers:

1. Define the morse sequence as a `case` statement on sequence index
2. Declare a sequence index register and a timer
3. In a **second** `always_ff` block: step through the sequence, holding each
   symbol for its duration in UNIT_CYCLES, then advancing to the next symbol
4. Assign `morse_out = current_symbol_is_tone`

The key: you now have **two** `always_ff` blocks in the same module.
Both update on every `posedge clk`. Neither knows about the other.
Neither waits for the other. They just both happen.

---

## Step 4: Simulate and observe

```bash
./tools/sim.sh workshops/04-parallel-fsm/starter
```

In GTKWave, add ALL of these signals at once:
- `clk`
- `light_red`, `light_yellow`, `light_green`
- `morse_out`
- `light_state` (enum — shows state names if GTKWave supports it)
- `morse_seq_idx`

Zoom out to see many seconds of simulated time.

**What to observe:**
1. `light_red` goes HIGH for 2 seconds (200M cycles), then LOW
2. `light_green` goes HIGH for 2 seconds, then LOW
3. `light_yellow` goes HIGH for 0.5 seconds, then LOW
4. Meanwhile, `morse_out` pulses in the SOS pattern, completely independent
5. The SOS pattern does NOT pause when the traffic light changes state
6. The traffic light does NOT pause when morse transitions happen

That's parallelism. Real parallelism. Not time-sliced. Not scheduled.
Both circuits are literally active on every single clock edge.

---

## Step 5: The comparison experiment

Modify the testbench to add a simulation counter and log every state transition
to the console with `$display`. You'll see:

```
[t=       0] light=RED     morse_idx=0  morse_out=0
[t= 2000000] light=GREEN   morse_idx=14 morse_out=1
[t= 4000000] light=YELLOW  morse_idx=17 morse_out=0
[t= 4500000] light=RED     morse_idx=0  morse_out=0
```

The morse index at `t=2000000` is 14 — it has been advancing independently
the entire time the light was red. It didn't stop. It didn't wait.
There was no "context switch" into morse-mode. It just kept going.

---

## Questions

1. **On a single-core CPU**, what is the minimum timing jitter you'd expect
   for the software threading version? What causes it?

2. In the FPGA design, both `always_ff` blocks are in the same module.
   Could you split them into two separate modules instead?
   What would change? What would stay the same?

3. The morse FSM uses a `case` statement to look up sequence data.
   This synthesizes to a ROM (read-only memory block on the FPGA).
   How many bits of ROM does it need? Calculate it.

4. Both FSMs share the `clk` and `rst_n` signals. If you wanted FSM B
   to run at half the frequency of FSM A, how would you do it?
   (Hint: clock enable, not a separate clock — see "clock domain crossing"
   for why separate clocks cause problems)

---

## Bonus challenge

Add a third FSM: a **PWM (Pulse Width Modulation) generator** that controls
an LED brightness. It should cycle through 5 brightness levels (0%, 25%, 50%, 75%, 100%)
once per second, independently of both the traffic light and the morse code.

You now have three independent hardware processes. On a CPU, you'd need three threads,
an RTOS, or at minimum a carefully written cooperative scheduler.
On the FPGA: three `always_ff` blocks. Three sets of registers. All running at once.

---

## Solution

`workshops/04-parallel-fsm/solution/dual_fsm.v`