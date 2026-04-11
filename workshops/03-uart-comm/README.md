# Workshop 03 — UART Transmitter

**Duration:** ~60 minutes  
**Concepts:** Finite state machines (FSM), shift registers, baud rate generation, serial protocols

---

## The goal

Build a UART transmitter from scratch. No IP cores. No library modules.
One module, one FSM, sending bytes one bit at a time at a hardware-exact baud rate.

When you're done, you can connect this to a real board and talk to a terminal.
The bytes will arrive perfectly, every time, because the timing is in hardware.

---

## Why UART? Why not software?

UART is everywhere — GPS modules, Bluetooth adapters, microcontrollers,
debug consoles, industrial sensors. Almost every piece of embedded hardware
speaks UART.

"Bit-banging" is what you call it when software tries to do UART manually:
toggle a GPIO pin at the right moments to create the serial signal.
It works on a bare microcontroller with no OS. It falls apart on anything else:

- **Linux/macOS/Windows**: the OS schedules your process. It can pause you
  between bit transitions for *milliseconds*. The receiver sees a corrupted bit.
  There's no way to prevent this without a real-time OS.
- **Interrupts**: a hardware interrupt fires between two bit toggles.
  Your timing is off. The receiver loses sync.
- **Cache misses**: your bit-bang loop jumps out of cache.
  Execution stalls for dozens of nanoseconds. Enough to corrupt a bit.

A hardware UART counter doesn't care about any of this.
It counts clock cycles. The OS doesn't touch it. Interrupts don't touch it.
Cache doesn't touch it. Every bit is placed exactly on schedule.

That's why every UART-capable chip has a hardware UART peripheral,
not a software one.

---

## UART frame format (8N1)

```
      ┌───── 1 bit ─────┐
      │                 │
Idle: ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
Start:                   \___
 D0:                         X
 D1:                           X
 D2:                             X
 D3:                               X
 D4:                                 X
 D5:                                   X
 D6:                                     X
 D7:                                       X
Stop:                                        ‾‾‾‾
Idle:                                            ‾‾‾‾‾
```

- **Idle**: line sits HIGH (called "marking state")
- **Start bit**: line goes LOW for exactly 1 bit period — this wakes up the receiver
- **8 data bits**: sent LSB first, 1 bit per bit-period
- **Stop bit**: line goes HIGH for 1 bit period — gives receiver time to recover
- **8N1** = 8 data bits, No parity, 1 stop bit (the most common format)

At **115200 baud**: each bit lasts `1/115200 ≈ 8.68 µs`.  
At 100 MHz clock: each bit lasts exactly `100,000,000 / 115,200 = 868` clock cycles.

---

## The FSM

Your transmitter is a 4-state finite state machine:

```
      ┌─────────────────────────────────────────┐
      │                 (tx_valid)              │
      ▼                                         │
  ┌──────┐    ┌───────┐    ┌──────┐    ┌──────┐│
  │ IDLE │───▶│ START │───▶│ DATA │───▶│ STOP ││
  └──────┘    └───────┘    └──────┘    └──────┘│
                                               │
                                 (bit_index==7)┘
```

- **IDLE**: wait for `tx_valid`. Line is HIGH.
- **START**: drive line LOW for 868 cycles (1 bit period).
- **DATA**: send 8 bits, LSB first, 868 cycles each. Use a shift register.
- **STOP**: drive line HIGH for 868 cycles. Return to IDLE.

---

## Step 1: Understand the shift register

The cleanest way to send bits one at a time is a **shift register**:

```systemverilog
tx_shift_reg <= {1'b0, tx_shift_reg[7:1]}; // Shift right by 1
```

On each bit period:
1. Output `tx_shift_reg[0]` (the current bit to send)
2. Shift the register right by 1

After 8 shifts, all bits have been sent. The bit index tells us when we're done.

---

## Step 2: Build it

Open `starter/uart_tx.v`. The ports and parameters are defined.
Your job:

1. Define the 4 states using `typedef enum`
2. Implement the baud counter (counts to `CLKS_PER_BIT - 1`)
3. Implement the FSM transitions
4. Drive `tx_serial` from each state
5. Track `bit_index` to know when all 8 data bits are done

---

## Step 3: Simulate and verify

```bash
./tools/sim.sh workshops/03-uart-comm/starter
```

In GTKWave, add:
- `tx_serial` — the raw serial signal. Should look like: idle (high), start (low),
  8 bits, stop (high), idle (high).
- `state` — should cycle through IDLE → START → DATA → STOP → IDLE
- `bit_index` — should count 0 through 7 in the DATA state
- `baud_counter` — should count 0 to 867, then reset

Zoom in on `tx_serial`. Measure the width of each bit. At 100MHz simulation,
each bit should be exactly 868 × 10ns = 8.68µs wide.

That's your proof. Not an approximation. Not "close enough." 8.68µs. Every time.

---

## Step 4: Decode it manually

Pick a byte from the testbench output. Read `tx_serial` bit by bit:
- Skip the start bit (the first low pulse)
- Read 8 bits, LSB first
- Verify they match the byte you sent

This is what a UART receiver does, in hardware, for every byte.
You're doing it by hand once so you understand what the receiver sees.

---

## Questions

1. What happens if you set `BAUD_RATE` to `9600` instead of `115200`?
   How does `CLKS_PER_BIT` change? Simulate and verify the bit timing.

2. The transmitter goes IDLE between bytes. How would you modify it to
   send a string of bytes back-to-back with no gap?
   (Hint: check `tx_valid` again at the end of STOP)

3. Why do we send LSB first instead of MSB first?
   (UART is defined to send LSB first — this is just "the spec," but
   think about what it means for the receiver's shift register design)

4. What is the maximum baud rate achievable at 100 MHz?
   What limits it? What would break at 10 MBaud?

---

## Bonus challenge

Build the matching **UART receiver** (`uart_rx.v`).
The receiver needs to:
1. Detect the falling edge of the start bit
2. Wait half a bit period (to sample in the middle of bits, not at edges)
3. Sample `rx_serial` once per bit period for 8 data bits
4. Output the assembled byte when the stop bit arrives

Connect transmitter output to receiver input in a testbench.
Send a byte, receive it, verify it matches.
You've just built a working serial link. From scratch. In hardware.

---

## Solution

`workshops/03-uart-comm/solution/uart_tx.v`