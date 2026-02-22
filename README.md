# 🎮 Memory Game on FPGA (VHDL) + UART Python Logger — Nexys4 / Nexys A7 (Artix-7)

![FPGA](https://img.shields.io/badge/FPGA-Nexys4%20%2F%20Nexys%20A7-blue)
![VHDL](https://img.shields.io/badge/HDL-VHDL-8A2BE2)
![UART](https://img.shields.io/badge/Comm-UART-success)
![Python](https://img.shields.io/badge/Python-3.x-yellow)
![Vivado](https://img.shields.io/badge/Vivado-2024.2-orange)

A **memory game implemented on FPGA** in **VHDL** for **Nexys4 Artix-7 / Nexys A7**, using:
- ✅ **Pmod KYPD (4x4 keypad)** for input  
- ✅ **7-seg display (SSD)** for output (multiplexed)  
- ✅ **UART TX** to send results to PC  
- ✅ **Python logger** (timestamp + history + best score)

The FPGA generates a **pseudo-random digit sequence** (length depends on level), displays it **digit by digit**, then the player must re-enter the same sequence on the keypad.

---

## 📌 Table of Contents
- [🎯 Game Idea](#-game-idea)
- [✅ Features](#-features)
- [🧩 Architecture](#-architecture)
- [🧠 Game FSM](#-game-fsm)
- [🎲 Sequence Generator (LFSR)](#-sequence-generator-lfsr)
- [🔢 SSD Display + Timing](#-ssd-display--timing)
- [⌨️ Keypad (Pmod KYPD)](#️-keypad-pmod-kypd)
- [✅ Check Logic (WIN/LOSE)](#-check-logic-winlose)
- [🔌 UART + Python Logger](#-uart--python-logger)
- [🧰 Hardware](#-hardware)
- [🧑‍💻 Software / Tools](#-software--tools)
- [▶️ How to Run](#️-how-to-run)
- [🧪 Testing Scenarios](#-testing-scenarios)
- [🗂️ Repo Structure](#️-repo-structure)
- [🗺️ Roadmap](#️-roadmap)
- [🚀 Improvements](#-improvements)

---

## 🎯 Game Idea

1. FPGA **generates** a digit sequence (length depends on the current level).
2. Sequence is **displayed** on the 7-seg, one digit at a time.
3. User re-enters the sequence on the **4x4 keypad**, in the same order.
4. If correct → **WIN** → next level (harder).
5. If incorrect → **LOSE** → same level, new sequence generated.
6. After every round, FPGA sends **level + result** over UART to the PC.
7. Python script logs everything with **timestamp** + **best score**.

Difficulty increases by:
- longer sequence length (higher level → more digits)
- faster display (higher level → shorter show time)

---

## ✅ Features

- **Game FSM** (stable control flow): generate → show → input → check → result  
- **Pseudo-random generator** using **16-bit LFSR**
- **SSD driver**: clean multiplexing (no flicker) + level-based timing
- **KYPD controller**: row/column scanning + debounce + `key_valid`
- **Edge-detect** in top module (`key_valid` rising edge = 1 press)
- **Element-by-element verification** for the entered sequence
- **UART TX**: sends `LEVEL` + `WIN/LOSE`
- **Python logger**: reads UART, timestamps, saves scores, tracks best score

---

## 🧩 Architecture

> Add your diagram to the repo and the README will show it automatically:

![Block Diagram](Diagrama_Block.png)

### 🔗 Top Integration
- `top_uart.vhd` — main Game FSM + module integration + UART messages

### 🧱 Modules
- `kypd_controller.vhd` — keypad scan + `key_valid` + `key_value`
- `random_digits_gen.vhd` — digit sequence generator (LFSR-based)
- `num_digits_select.vhd` — selects sequence length **N** based on level
- `ssd_divider.vhd` — timing: SSD mux clock + show period based on level
- `ssd.vhd` — 7-seg display driver (mux + decode digits/symbols)
- `uart_tx.vhd` — UART transmitter
- `game_log.py` — Python UART reader + score logger

---

## 🧠 Game FSM

Implemented with extra “handshake-friendly” states for stability:

- **IDLE** — wait for start  
- **PRE_GEN** — 1-cycle buffer (signals settle, e.g. `num_digits`)  
- **GEN** — generate digits until `done_gen`  
- **TRIGGER_SSD** — one pulse to start showing sequence  
- **SHOW** — display sequence until `show_done`  
- **INPUT** — collect exactly **N** valid presses (edge-detect on `key_valid`)  
- **CHECK** — compare `seq_user[]` with `seq_gen[]`  
- **WIN** — show win symbol + send UART; next start → level++  
- **LOSE** — show lose symbol + send UART; next start → regenerate (same level)

---

## 🎲 Sequence Generator (LFSR)

- **16-bit LFSR**, seed: `x"ACE1"`
- Taps polynomial:  
  **x^16 + x^14 + x^13 + x^11 + 1**

Each step:
1. Compute `lfsr_next`
2. Map bits → digit **0..9**
3. Store into `seq_gen[i]` until **N digits** are generated

---

## 🔢 SSD Display + Timing

The SSD logic handles:
1) **Digit multiplexing** (stable, no flicker)  
2) Displaying the sequence **digit by digit**, speed depends on level

Example timing idea:
- `period = BASE_PERIOD - STEP_PERIOD * level`

Symbols:
- **WIN**: custom victory symbol (parallel lines / pattern)
- **LOSE**: `----` across all digits

---

## ⌨️ Keypad (Pmod KYPD)

- Column scan (0..3), read rows  
- Press detected when row active under selected column

Outputs:
- `key_value` — decoded key/digit  
- `key_valid` — press detected

### ✅ Edge-detect (avoid duplicates)
In `top_uart.vhd`:
- store `key_valid_d` (previous)
- new press when: `key_valid=1` and `key_valid_d=0`

So holding a key won’t count multiple times.

---

## ✅ Check Logic (WIN/LOSE)

After exactly **N** digits entered:
- compare `seq_user[i]` with `seq_gen[i]` for `i = 0..N-1`
- all match → **WIN**
- any mismatch → **LOSE**

---

## 🔌 UART + Python Logger

After every round, FPGA transmits:
- **level**
- optionally: result (**WIN/LOSE**)

Example messages:
- `L: 5`
- `R: WIN`

Python reads serial, prints messages, and logs:
- timestamp
- level
- result
- best score

---

## 🧰 Hardware

- FPGA board: **Nexys4 Artix-7** or **Nexys A7**
- **Pmod KYPD** (4x4 keypad) connected to a PMOD (e.g. `JA`)
- UART to PC:
  - either **Pmod USB-UART**
  - or the board’s built-in UART (depending on setup)

---

## 🧑‍💻 Software / Tools

- **Vivado** (e.g. 2024.2)
- **Python 3.x**
- `pyserial`

Install:
```bash
pip install pyserial
