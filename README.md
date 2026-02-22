# VHDL Joc de Memorie (FPGA) + Python UART 🎮🔟 (Nexys4 / Nexys A7)

Joc de memorie implementat pe FPGA (**Nexys4 Artix-7 / Nexys A7**) în **VHDL**, cu input de la **Pmod KYPD (tastatură 4x4)** și afișare pe **7-seg (SSD)**.  
Placa generează o secvență pseudo-aleatoare de cifre (în funcție de nivel), o afișează una câte una, iar utilizatorul trebuie să reintroducă secvența în aceeași ordine.  
După fiecare rundă, scorul (nivelul) este trimis prin **UART** către PC, unde un **script Python** citește mesajele, adaugă timestamp și salvează automat scorurile + best score.

---

## 🎯 Ideea jocului

1. FPGA **generează** o secvență de cifre (lungimea depinde de nivel).
2. Secvența se **afișează** pe SSD, cifră cu cifră.
3. Utilizatorul reintroduce secvența pe **Pmod KYPD** (în aceeași ordine).
4. Dacă este corect → **WIN** → treci la nivelul următor (dificultatea crește).
5. Dacă este greșit → **LOSE** → rămâi la același nivel și se regenerează o secvență nouă.
6. La final de rundă, se trimite prin **UART** către PC nivelul + rezultat; Python ține evidența și best score.

Dificultatea crește prin:
- **secvență mai lungă** (în funcție de nivel)
- **timp de afișare mai mic** (afișare mai rapidă la niveluri mai mari)

---

## ✅ Funcționalități

- **Game FSM** (control joc): etape clare (generare → afișare → input → verificare → rezultat)
- **Generator pseudo-aleator** pe bază de **LFSR (16-bit)**
- **SSD driver** cu multiplexare stabilă + viteză de afișare dependentă de nivel
- **KYPD controller** (scanare rând/coloană + debounce / valid)
- **Edge-detect pe key_valid** în top (o apăsare = un singur eveniment)
- **Verificare secvență** element-cu-element
- **UART TX** pentru trimitere nivel + WIN/LOSE către PC
- **Python logger**: citește serial, afișează mesaje, salvează scoruri + timestamp + best score

---

## 🧩 Block Design / Arhitectură (module)

Dacă ai poza în repo, adaug-o în README:

![Block Diagram](Diagrama_Block.png)

**Top-level integrare:**
- `top_uart.vhd` – Game FSM + integrare module + UART messages

**Periferice & logică:**
- `kypd_controller.vhd` – scanare tastatură 4x4 + `key_valid` + `key_value`
- `random_digits_gen.vhd` – generator secvență (LFSR) pentru N cifre
- `num_digits_select.vhd` – alege N (numărul de cifre) în funcție de nivel
- `ssd_divider.vhd` – temporizări (multiplexare SSD + perioadă afișare dependentă de nivel)
- `ssd.vhd` – afișare efectivă pe 7-seg (mux + decodare cifre/simboluri)
- `uart_tx.vhd` – transmitere serială către PC
- `game_log.py` – Python: citește UART, salvează scoruri + best score

---

## 🧠 FSM-ul jocului (stări)

Stări folosite (implementare extinsă pentru stabilitate / handshake):

- **IDLE** – așteaptă start
- **PRE_GEN** – 1 ciclu “pauză” pentru stabilizare semnale (ex: num_digits)
- **GEN** – pornește generatorul până la `done_gen`
- **TRIGGER_SSD** – impuls de start (handshake) pentru modulul de afișare
- **SHOW** – afișează secvența (una câte una) până la `show_done`
- **INPUT** – colectează exact N apăsări valide (edge-detect pe `key_valid`)
- **CHECK** – compară `seq_user[]` cu `seq_gen[]`
- **WIN** – afișează simbol WIN, trimite UART; la start → nivel++
- **LOSE** – afișează simbol LOSE, trimite UART; la start → regenerează (același nivel)

---

## 🎲 Generatorul de secvență (LFSR)

- **LFSR pe 16 biți**, seed: `x"ACE1"`
- Polinom (taps):
  - **x^16 + x^14 + x^13 + x^11 + 1**
- La fiecare pas se calculează următoarea stare `lfsr_next`, apoi se extrage o cifră și se mapează în **0..9**, salvând în `seq_gen[i]` până la N cifre.

---

## 🔢 SSD (7-seg) + temporizare

Modulul de afișare face două lucruri:
1) **multiplexarea** digit-urilor (stabilă, fără flicker)  
2) afișarea secvenței **cifră cu cifră**, cu viteză dependentă de nivel

Perioada de afișare (idee de bază):
- `period = BASE_PERIOD − STEP_PERIOD * lvl`

Simboluri:
- **WIN**: simbol “victorie” (linii paralele)
- **LOSE**: afișează “----” pe toate digit-urile

---

## ⌨️ KYPD (tastatură 4x4)

- Scanare pe coloane (0..3), citire rânduri.
- Dacă un rând este activ când o coloană e selectată → tasta e apăsată.
- Modulul oferă:
  - `key_value` (cod/cifră)
  - `key_valid` (apăsare detectată)

Pentru a evita dublări, în `top_uart.vhd` se folosește **edge-detect**:
- se reține `key_valid_d` (valoarea anterioară)
- apăsare nouă când: `key_valid = 1` și `key_valid_d = 0`

---

## ✅ Verificare (CHECK) – WIN / LOSE

După ce utilizatorul a introdus exact **N** cifre:
- se compară `seq_user[i]` cu `seq_gen[i]` pentru `i = 0..N-1`
- dacă toate sunt egale → **WIN**
- altfel → **LOSE**

---

## 🔌 UART + Python (scoruri pe PC)

După fiecare rundă (WIN/LOSE), FPGA trimite către PC:
- **nivel**
- (opțional) **rezultat**

Python citește serial și salvează intrările automat în fișier (cu timestamp) + calculează best score.

Mesaje tip:
- `L: <numar>` (ex: `L: 5` => LEVEL 5)

---

## 🧰 Hardware necesar

- FPGA: **Nexys4 Artix-7 / Nexys A7**
- **Pmod KYPD** (tastatură 4x4) – conectat pe PMOD (ex: JA)
- **Pmod USB-UART** (sau UART prin interfața plăcii, în funcție de setup)

---

## 🧑‍💻 Software / Tools

- **Vivado** (ex: 2024.2) – synth/impl + bitstream
- **Python 3.x**
- `pyserial` (pentru citire UART)

Instalare:
```bash
pip install pyserial
