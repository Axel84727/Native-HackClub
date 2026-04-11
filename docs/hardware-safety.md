# Hardware Safety

Short document. Important document.

Software mistakes crash programs. Hardware mistakes fry chips.
Sometimes they also fry your USB port, your laptop, and your afternoon.
Please read this before touching anything.

---

## Voltage levels — the one thing that kills boards instantly

Most modern FPGAs and dev boards operate at **3.3V** logic levels.
Some use **1.8V** internally. Almost none tolerate **5V** on GPIO pins.

**The rule:** Before connecting *anything* to your FPGA's GPIO pins,
verify the voltage level of whatever you're connecting.

```
3.3V GPIO  ←→  3.3V sensor     ✓  Fine
3.3V GPIO  ←→  5V sensor        ✗  You just cooked a GPIO pin
3.3V GPIO  ←→  5V sensor + level shifter  ✓  Fine, good job
```

If you're connecting an Arduino (5V) to a Basys3 or Arty (3.3V),
you need a **voltage level shifter**. They cost $2. An FPGA costs $50-200.
Do the math.

---

## Never back-power a board through GPIO

"Back-powering" means accidentally supplying voltage *to* a board
through its GPIO pins instead of its dedicated power input.

This happens when:
- You connect a powered peripheral to the FPGA before plugging in the FPGA's USB
- Your external circuit has a pullup to 5V and the FPGA isn't powered yet
- You're wiring things while the board is on

**The rule:** Power the FPGA first. Connect external circuits after.
Disconnect external circuits before unpowering the FPGA.

---

## Discharge capacitors before touching

Large capacitors (anything over ~100µF) store enough charge to hurt you
or zap sensitive components. If you've been running a circuit with big capacitors
(motor drivers, power supplies, anything with a big electrolytic cap),
wait a few seconds after powering down before touching exposed pads.

For most dev boards this isn't an issue — they're low-power.
If you're adding your own power circuitry, it becomes relevant.

---

## Use current-limited power supplies during first power-on

When you power on a new or modified circuit for the first time,
use a bench power supply with a current limit set to something reasonable
(e.g. 200-500mA for a basic FPGA board).

If something is wired wrong and creates a short, the current limit trips
instead of components getting hot enough to emit smoke.

"But I don't have a bench supply, I'm using USB" — that's fine for normal dev boards.
It becomes relevant when you're adding your own power circuits or motors.

---

## ESD — static electricity is real

Electrostatic discharge (ESD) can silently damage integrated circuits.

The fixes are simple:
- Touch a metal surface before handling bare chips or boards (discharges your static)
- Store bare chips in anti-static bags or foam (the black/pink foamy stuff)
- Don't shuffle across carpet and then immediately grab a bare PCB

You won't always know when ESD damage happened. Chips sometimes degrade
slowly before failing completely. Just build the habit.

---

## Heat

FPGAs doing heavy computation get warm. This is normal.
FPGAs doing heavy computation without proper power decoupling get *hot*. This is not.

If your board is uncomfortably warm to the touch after a few minutes,
something might be drawing more current than expected. Check your design
for any unintentional switching (signals that are floating or oscillating).

---

## USB ports

Your laptop's USB port supplies 5V at up to 500mA (USB 2.0) or 900mA (USB 3.0).

Most dev boards are well-behaved and won't draw more than they should.
If you're connecting external motors or high-power LEDs powered from the dev board,
you might be pulling too much current from the USB port.

Symptoms: USB device disconnects randomly, laptop battery drains faster than expected,
USB port stops working. The last one is bad. Use a powered USB hub or a wall adapter
if you're running anything power-hungry.

---

## Quick reference card

| Rule | Why |
|---|---|
| Check voltages before connecting | 5V into 3.3V GPIO kills the pin |
| Power FPGA before external circuits | Prevents back-powering |
| Current limit on first power-on | Shorts pop the limit, not your chip |
| Touch metal before handling bare chips | ESD protection |
| Don't leave floating inputs | Floating inputs oscillate wildly, waste power |
| Read the board's datasheet | They put the important limits in there for a reason |

---

## If something smells like burning

1. Disconnect power immediately
2. Wait for things to cool down
3. Identify what got hot (sniff around — yes, really)
4. Don't power it on again until you understand why it happened

Burnt components usually have a visible scorch mark or a distinctive sharp smell.
FPGA boards are expensive. A few seconds of investigation is worth it.

---

*None of this should scare you. Millions of people work with FPGAs safely every day.
These are just the things worth knowing before your first oops.*