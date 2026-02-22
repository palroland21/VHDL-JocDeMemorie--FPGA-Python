import serial
import os

COM_PORT = 'COM4'
BAUD_RATE = 9600
HIGHSCORE_FILE = "highscore.txt"

MESAJE_SPECIALE = {
    1: "Incalzirea... Asta e de nota 5, trecem clasa.",
    2: "Bun! Dar la examen subiectele sunt mai grele.",
    3: "Memorie de elefant! Memoria RAM inca rezista. Continuam?",
    4: "Atentie! Se complica materia. Vine sesiunea!",
    5: "Deja e nivel de nota 10! Felicitari!",
    6: "Wow! Aveti overclocking la creier?",
    7: "Daca treceti si de asta, meritati bursa de merit.",
    8: "Nu cumva ati scris dumneavoastra codul sursa?!",
    9: "Stack Overflow! Prea multa informatie!",
    10: "CRITICAL ERROR: Sunteti prea bun. Sistemul a cedat. 10 pe linie!"
}

def get_high_score():
    # high score din fisier
    if not os.path.exists(HIGHSCORE_FILE):
        return 0
    try:
        with open(HIGHSCORE_FILE, "r") as f:
            val = f.read().strip()
            return int(val) if val else 0
    except:
        return 0

def save_high_score(score):
    # write noul high score in fisier
    try:
        with open(HIGHSCORE_FILE, "w") as f:
            f.write(str(score))
    except Exception as e:
        print(f"[EROARE] Nu am putut salva scorul: {e}")

def main():
    try:
        ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=0.1)
        print(f"Conectat la {COM_PORT}. Resetati placa (BTN DOWN) si apasati START (Center).")
    except Exception as e:
        print(f"Eroare port: {e}")
        return

    high_score = get_high_score()
    print(f"--- RECORD ACTUAL (High Score): Nivelul {high_score} ---")

    current_level = 0

    while True:
        try:
            if ser.in_waiting > 0: # cati biti sunt in bufferul de receptie
                raw_byte = ser.read()
                try:
                    char = raw_byte.decode('utf-8') # tranforma bitul in caracter
                except:
                    char = '?'

                if char == 'L':
                    print("--> Am primit 'L', astept nivelul...")
                    lvl_byte = ser.read()
                    if lvl_byte:
                        try:
                            raw_val = lvl_byte.decode('utf-8')
                            current_level = int(raw_val)
                            print(f"[JOC] Nivel initial citit: {current_level}")
                        except ValueError:
                            print(f"[EROARE] Caracterul '{raw_val}' nu este numar!")
                    else:
                        print("[EROARE] Am primit 'L' dar nu a urmat cifra!")

                elif char == 'W':
                    print(f"[WIN] Ai trecut de nivelul {current_level}!")

                    # daca avem un mesaj special pentru acest nivel, il afisam
                    if current_level in MESAJE_SPECIALE:
                        msg = MESAJE_SPECIALE[current_level]
                        print(f"      >>> {msg} <<<")
                    else:
                        print("      >>> Bravo! Continua asa! <<<")

                    # verificare High Score
                    if current_level > high_score:
                        high_score = current_level
                        save_high_score(high_score)
                        print(f"*** RECORD NOU! Noul High Score salvat: {high_score} ***")

                    current_level += 1
                    print(f"      -> Urmeaza nivelul {current_level}...")

                elif char == 'F':
                    print(f"[FAIL] Ai pierdut la nivelul {current_level}.")
                    print(f"Recordul tau ramane: {high_score}")

        except KeyboardInterrupt:
            ser.close()
            break

if __name__ == "__main__":
    main()