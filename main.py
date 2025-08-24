import sys
from pathlib import Path
from PySide6.QtCore import QObject, Property, Signal, Slot, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from data_provider import DataProvider

BASE_DIR = Path(__file__).resolve().parent

class ClusterState(QObject):
    # базовые значения
    speedChanged = Signal(float)
    rpmChanged = Signal(float)
    coolantChanged = Signal(float)
    fuelChanged = Signal(float)

    # индикаторы/ошибки
    handbrakeChanged = Signal(bool)
    lightsChanged = Signal(bool)
    highBeamChanged = Signal(bool)
    leftBlinkerChanged = Signal(bool)
    rightBlinkerChanged = Signal(bool)
    checkEngineChanged = Signal(bool)
    oilPressureChanged = Signal(bool)
    batteryWarnChanged = Signal(bool)

    def __init__(self):
        super().__init__()
        self._speed = 0.0
        self._rpm = 0.0
        self._coolant = 90.0
        self._fuel = 50.0

        self._handbrake = False
        self._lights = False
        self._highBeam = False
        self._leftBlinker = False
        self._rightBlinker = False
        self._checkEngine = False
        self._oilPressure = False
        self._batteryWarn = False

    # ----- числовые свойства -----
    def getSpeed(self): return self._speed
    def setSpeed(self, v: float):
        if abs(v - self._speed) > 1e-3:
            self._speed = v
            self.speedChanged.emit(self._speed)
    speed = Property(float, getSpeed, notify=speedChanged)

    def getRpm(self): return self._rpm
    def setRpm(self, v: float):
        if abs(v - self._rpm) > 1e-3:
            self._rpm = v
            self.rpmChanged.emit(self._rpm)
    rpm = Property(float, getRpm, notify=rpmChanged)

    def getCoolant(self): return self._coolant
    def setCoolant(self, v: float):
        if abs(v - self._coolant) > 1e-3:
            self._coolant = v
            self.coolantChanged.emit(self._coolant)
    coolant = Property(float, getCoolant, notify=coolantChanged)

    def getFuel(self): return self._fuel
    def setFuel(self, v: float):
        if abs(v - self._fuel) > 1e-3:
            self._fuel = v
            self.fuelChanged.emit(self._fuel)
    fuel = Property(float, getFuel, notify=fuelChanged)

    # ----- булевые свойства (лампы/флаги) -----
    @staticmethod
    def _mk_bool_prop(attr_name: str, signal_name: str):
        def getter(self):
            return bool(getattr(self, attr_name))
        def setter(self, v: bool):
            v = bool(v)
            if v != bool(getattr(self, attr_name)):
                setattr(self, attr_name, v)
                # важно: эмитим ИНСТАНС-сигнал с self
                getattr(self, signal_name).emit(v)
        return getter, setter

    getHandbrake, setHandbrake = _mk_bool_prop.__func__("_handbrake", "handbrakeChanged")
    handbrake = Property(bool, getHandbrake, notify=handbrakeChanged)

    getLights, setLights = _mk_bool_prop.__func__("_lights", "lightsChanged")
    lights = Property(bool, getLights, notify=lightsChanged)

    getHighBeam, setHighBeam = _mk_bool_prop.__func__("_highBeam", "highBeamChanged")
    highBeam = Property(bool, getHighBeam, notify=highBeamChanged)

    getLeftBlinker, setLeftBlinker = _mk_bool_prop.__func__("_leftBlinker", "leftBlinkerChanged")
    leftBlinker = Property(bool, getLeftBlinker, notify=leftBlinkerChanged)

    getRightBlinker, setRightBlinker = _mk_bool_prop.__func__("_rightBlinker", "rightBlinkerChanged")
    rightBlinker = Property(bool, getRightBlinker, notify=rightBlinkerChanged)

    getCheckEngine, setCheckEngine = _mk_bool_prop.__func__("_checkEngine", "checkEngineChanged")
    checkEngine = Property(bool, getCheckEngine, notify=checkEngineChanged)

    getOilPressure, setOilPressure = _mk_bool_prop.__func__("_oilPressure", "oilPressureChanged")
    oilPressure = Property(bool, getOilPressure, notify=oilPressureChanged)

    getBatteryWarn, setBatteryWarn = _mk_bool_prop.__func__("_batteryWarn", "batteryWarnChanged")
    batteryWarn = Property(bool, getBatteryWarn, notify=batteryWarnChanged)

class App(QObject):
    def __init__(self):
        super().__init__()
        self.state = ClusterState()
        self.provider = DataProvider()

    @Slot()
    def start(self):
        self.provider.start(self.on_data)

    @Slot()
    def stop(self):
        self.provider.stop()

    def on_data(self, p):
        # числовые
        self.state.setSpeed(p["speed"])
        self.state.setRpm(p["rpm"])
        self.state.setCoolant(p["coolant"])
        self.state.setFuel(p["fuel"])

        # индикаторы
        self.state.setHandbrake(p["handbrake"])
        self.state.setLights(p["lights"])
        self.state.setHighBeam(p["highBeam"])
        self.state.setLeftBlinker(p["leftBlinker"])
        self.state.setRightBlinker(p["rightBlinker"])
        self.state.setCheckEngine(p["checkEngine"])
        self.state.setOilPressure(p["oilPressure"])
        self.state.setBatteryWarn(p["batteryWarn"])

def main():
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    core = App()
    engine.rootContext().setContextProperty("AppCore", core)
    engine.rootContext().setContextProperty("ClusterState", core.state)

    qml_path = BASE_DIR / "qml" / "Main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_path)))
    if not engine.rootObjects():
        sys.exit("QML load failed")

    core.start()
    try:
        ret = app.exec()
    finally:
        core.stop()
    sys.exit(ret)

if __name__ == "__main__":
    main()
