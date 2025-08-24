import threading
import time
import math
from typing import Callable, Optional, Dict

class DataProvider:
    """Генератор мок-данных ~20 Гц. Потом заменим на CAN/GPIO."""
    def __init__(self):
        self._running = False
        self._thread: Optional[threading.Thread] = None
        self._callback: Optional[Callable[[Dict[str, float]], None]] = None

    def start(self, callback: Callable[[Dict[str, float]], None]):
        self._callback = callback
        self._running = True
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self):
        self._running = False
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=1.0)

    def _loop(self):
        t = 0.0
        fuel = 65.0  # %
        while self._running:
            # Имитация адекватных значений
            speed = max(0.0, 60.0 + 60.0 * math.sin(t * 0.6))            # 0..120
            rpm = 2000.0 + 1500.0 * math.sin(t * 1.1) + 800.0 * math.sin(t * 0.23)
            rpm = max(700.0, min(6500.0, rpm))                           # 700..6500
            coolant = 90.0 + 8.0 * math.sin(t * 0.12)                    # 82..98

            # Топливо потихоньку убывает, прыгает на заправке
            if int(t) % 120 == 0 and (t % 120) < 0.05:
                fuel = min(100.0, fuel + 20.0)
            else:
                fuel = max(0.0, fuel - 0.01)

            # Поворотники мигают ~1.5 Гц
            blink = (math.sin(t * 3.0) > 0.2)
            left_blinker = blink
            right_blinker = not blink

            # Флаги-индикаторы (для примера)
            handbrake = (speed < 2.0) and (int(t) % 6 < 3)  # иногда “подтянут”
            lights = True
            high_beam = int(t) % 10 >= 5  # каждые 5 сек
            check_engine = (int(t) % 40) == 0  # иногда вспыхивает
            oil_pressure = False
            battery_warn = False

            if self._callback:
                self._callback({
                    "speed": float(speed),
                    "rpm": float(rpm),
                    "coolant": float(coolant),
                    "fuel": float(fuel),

                    "handbrake": bool(handbrake),
                    "lights": bool(lights),
                    "highBeam": bool(high_beam),
                    "leftBlinker": bool(left_blinker),
                    "rightBlinker": bool(right_blinker),

                    "checkEngine": bool(check_engine),
                    "oilPressure": bool(oil_pressure),
                    "batteryWarn": bool(battery_warn),
                })

            t += 0.05
            time.sleep(0.05)  # ~20 Гц
