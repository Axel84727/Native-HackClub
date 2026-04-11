# Parallel Timer

![Simulation](https://img.shields.io/badge/simulation-passing-brightgreen)
![Board](https://img.shields.io/badge/board-Basys3-blue)

Four independent hardware timers running simultaneously at different frequencies,
proving that hardware parallelism is categorically different from software threading.

---

## Problem

Precision multi-rate timing is a common requirement in embedded systems:
- Sample sensor A every 1ms, sensor B every 3ms, update display every 10ms
- Generate PWM at 20kHz while also monitoring a 5kHz encoder
- Trigger four ADC channels at different rates to match their bandwidths

On a software system, you'd use timer peripherals with ISRs, or an RTOS with
multiple tasks. The problem: ISR scheduling adds jitter. Under load, the OS
delays lower-priority timers. For precision work, "approximately on time" is not good enough.

---

## Why not software?

A CPU has one program counter. Even with hardware timer peripherals, the ISR
still executes on the CPU — which means it competes with everything else running.

Measured jitter on a Linux system for a 1ms timer callback:
- Idle system: ±50µs
- Under moderate load: ±500µs
- Under heavy load: ±5ms or worse

On a bare-metal microcontroller with no OS, you can do better — but you still
can't run four truly independent timers. The ISRs share the same CPU and
execute sequentially. Timer 2's ISR can't start until Timer 1's finishes.

On the FPGA: each timer is its own counter register. On every clock edge,
every counter decrements simultaneously. When one fires, the others don't
even notice. There is no shared execution resource. The jitter is literally
zero — each timer fires on exactly the clock cycle it was designed to fire on.

Not ±50µs. Not ±1µs. Zero. Every time.

---

## How it works

Four independent down-counters with these periods:

| Timer | Period | Clock cycles at 100MHz |
|---|---|---|
| 0 | 1ms | 100,000 |
| 1 | 3ms | 300,000 |
| 2 | 7ms | 700,000 |
| 3 | 10ms | 1,000,000 |

Each counter:
1. Starts at its period value and decrements every clock cycle
2. When it reaches 0: fires a one-cycle `tick` pulse, reloads to its period
3. The `tick` pulse is used to drive an LED (through a pulse stretcher so it's visible)
   and is also available as a raw output for oscilloscope measurement

The 3ms and 7ms periods are **coprime** (GCD = 1). Their patterns don't align
for 21ms — they produce an interesting, non-repeating-looking firing pattern
that makes it visually obvious they're independent.

```
1ms:   |.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|.|
3ms:   |..|..|..|..|..|..|..|..|..|..|..|..|..|
7ms:   |......|......|......|......|......|....|
10ms:  |.........|.........|.........|..........|
```

---

## Running the simulation

```bash
./tools/sim.sh projects/parallel-timer
```

**What you'll see in the terminal:**
```
Results after 10,000,000 cycles (100ms):
  Timer 0 (1ms):  fired  100 times (expected ~100)
  Timer 1 (3ms):  fired   33 times (expected  ~33)
  Timer 2 (7ms):  fired   14 times (expected  ~14)
  Timer 3 (10ms): fired   10 times (expected  ~10)
  Timer 0: PASS
  Timer 1: PASS
  Timer 2: PASS
  Timer 3: PASS
```

**In GTKWave:**
1. Add `tick_out[3:0]` to the wave panel
2. Zoom out to see ~50ms of simulated time
3. Observe all four independent pulse streams

Zoom in on any two ticks from different timers that nearly coincide.
You'll see them are on different clock cycles — they're independent, not synchronized.

---

## Results

| Metric | This design | Linux timer | Bare-metal ISR |
|---|---|---|---|
| Timer jitter | 0 cycles (0ns) | ±50,000+ cycles (±500µs) | ±100s of cycles |
| Multi-timer independence | True (separate registers) | False (shared CPU) | False (sequential ISRs) |
| Worst-case latency | 0 | Unbounded under load | Depends on ISR priority |
| Periods affected by load | Never | Yes | Yes |

---

## Limitations

- The LED pulse stretcher (50ms) means the LED stays lit long after the tick.
  This is intentional for visibility, but means the LEDs don't show the actual timing.
  Use `tick_out` pins on an oscilloscope for the real measurement.
- This design uses polling (no interrupt output). For a real application, you'd
  add an OR-gate that fires when any timer ticks, connected to a processor interrupt.
- Period values are hardcoded. A real timer peripheral would be programmable.

---

## Future work

- [ ] Make periods programmable via a register interface (AXI-Lite or simple register bus)
- [ ] Add a timer counter (count how many times each has fired since reset)
- [ ] Add one-shot mode (fire once, then stop)
- [ ] Add compare registers (fire when an up-counter reaches a programmed value)
- [ ] Measure real hardware timing with an oscilloscope and compare to simulation

---

## Files

```
src/
└── top.v              # Top-level module — all 4 timers + pulse stretcher

testbench/
└── tb_top.v           # Counts timer fires, verifies counts, dumps waveform

constraints.xdc        # Pin assignments for Basys3
```