import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Shapes 1.15

Window {
    id: win
    visible: true
    width: 1280
    height: 720
    color: theme.bg
    title: "E30 Cluster"
    visibility: Window.FullScreen
	
	property bool _prevCheckEngine: false
    
	// ===== ТЕМА (день/ночь) =====
    property bool night: true
    property var theme: night ? {
        "bg": "#070a0e",
        "panel": "#101721",
        "panelBorder": "#182234",
        "text": "#e7edf7",
        "muted": "#7e8aa0",
        "accent": "#12d177",
        "accent2": "#3aa0ff",
        "danger": "#ff4d4f",
        "warn": "#ff9f0a",
        "greenDark": "#0e8e5c",
        "greenLight": "#14c47d",
        "orange": "#ff9f0a",
        "red": "#ff4d4f"
    } : {
        "bg": "#111417",
        "panel": "#141c25",
        "panelBorder": "#1d293d",
        "text": "#f4f7fb",
        "muted": "#97a5bb",
        "accent": "#20d989",
        "accent2": "#53b6ff",
        "danger": "#ff6568",
        "warn": "#ffb547",
        "greenDark": "#12a26a",
        "greenLight": "#24e599",
        "orange": "#ffb547",
        "red": "#ff6568"
    }
    Behavior on color { ColorAnimation { duration: 250 } }

    function clamp(v,a,b){ return Math.max(a, Math.min(b, v)); }

    // ===== АНИМИРОВАННЫЙ ФОН =====
    component AnimatedBg: Item {
        anchors.fill: parent
        Rectangle { anchors.fill: parent; color: "#05070a" }
        Rectangle {
            id: gradLayer
            anchors.centerIn: parent
            width: parent.width  * 3.6
            height: parent.height * 3.6
            rotation: rot
            opacity: 0.95
            gradient: Gradient {
                GradientStop { id: s1; position: 0.0;  color: "#FF6800" }
                GradientStop { id: s2; position: 0.55; color: "#2b1861" }
                GradientStop { id: s3; position: 1.0;  color: "#FF6800" }
            }
        }
        property real rot: 0
        NumberAnimation on rot { from: 0; to: 360; duration: 90000; loops: Animation.Infinite; easing.type: Easing.Linear }
        SequentialAnimation {
            running: true; loops: Animation.Infinite
            NumberAnimation { target: s2; property: "position"; from: 0.45; to: 0.65; duration: 8000; easing.type: Easing.InOutSine }
            NumberAnimation { target: s2; property: "position"; from: 0.65; to: 0.45; duration: 8000; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            running: true; loops: Animation.Infinite
            ColorAnimation { target: s1; property: "color"; from: "#081238"; to: "#0d1d4e"; duration: 6000; easing.type: Easing.InOutSine }
            ColorAnimation { target: s1; property: "color"; from: "#0d1d4e"; to: "#081238"; duration: 6000; easing.type: Easing.InOutSine }
        }
    }
    AnimatedBg { id: bg; z: -100 }

    // ===== КОМПОНЕНТЫ =====
    component Lamp: Item {
        id: lp
        property bool active: false
        property string text: ""
        property color colorOn: theme.warn
        width: 120; height: 36
        opacity: active ? 1.0 : 0.35
        Behavior on opacity { NumberAnimation { duration: 100 } }
        Rectangle { id: dot; width: 12; height: 12; radius: 6; color: colorOn; anchors.verticalCenter: parent.verticalCenter; visible: active }
        Text { text: lp.text; color: theme.muted; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter; anchors.left: dot.right; anchors.leftMargin: 8 }
    }

    component Blinker: Item {
        id: bl
        property bool active: false
        property bool isLeft: true
        width: 80; height: 36
        opacity: active ? 1.0 : 0.15
        Behavior on opacity { NumberAnimation { duration: 90 } }
        scale: active ? 1.06 : 1.0
        Behavior on scale { NumberAnimation { duration: 90 } }
        Text { anchors.centerIn: parent; text: bl.isLeft ? "◀" : "▶"; font.pixelSize: 28; color: theme.accent }
    }

    component HBar: Item {
        id: hb
        property real min: 0
        property real max: 100
        property real value: 0
        property color back: theme.panelBorder
        property color fill: theme.accent
        width: 420; height: 16
        Rectangle { anchors.fill: parent; radius: height/2; color: back }
        Rectangle {
            id: prog
            height: parent.height
            radius: height/2
            width: (hb.value - hb.min) / Math.max(1e-6, (hb.max - hb.min)) * hb.width
            color: fill
            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        }
    }

    // ===== Горизонтальная "лесенка" оборотов =====
    component RpmLadderH: Item {
		id: lad
		property real rpm: 0
		property real maxRpm: 7000
		property int totalSegs: 14
		property real spacing: 6
		width: Math.min(win.width * 0.82, 1000)
		height: 150

		// плавный рост высоты от minH до maxH
		property real minH: (height - 2*spacing) * 0.25    // низ самых первых
		property real maxH: (height - 2*spacing) * 0.95    // почти весь бокс
		function smoother(t) { return t*t*(3 - 2*t); }     // плавная S-кривая
		function segHeight(i) {
			var t = totalSegs>1 ? i/(totalSegs-1) : 0;
			return minH + (maxH - minH) * smoother(t);
		}

		// непрерывное заполнение (1 сегмент = maxRpm/totalSegs = 500 rpm)
		property real segmentsFilled: clamp(rpm / (maxRpm / totalSegs), 0, totalSegs)

		Repeater {
			model: totalSegs
			delegate: Item {
				readonly property int idx: index
				readonly property color segColor: (idx < 5) ? theme.greenDark
													: (idx < 9) ? theme.greenLight
													: (idx < 12) ? theme.orange
																: theme.red
				width: (lad.width - (lad.totalSegs + 1) * lad.spacing) / lad.totalSegs
				height: lad.segHeight(index)
				anchors.bottom: parent.bottom
				x: lad.spacing + index * (width + lad.spacing)
				y: parent.height - height - lad.spacing
				clip: true   // чтобы скругления не вылезали

				// фон сегмента (тусклый)
				Rectangle {
					anchors.fill: parent
					radius: 6
					color: segColor
					opacity: 0.18
				}

				// горизонтальная заливка (доля в текущем сегменте)
				readonly property real fillFrac: Math.max(0, Math.min(1, lad.segmentsFilled - index))
				Rectangle {
					anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
					width: parent.width * fillFrac
					radius: 6
					color: segColor
					opacity: 1.0
					Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
				}

				// подписи "1000..7000" над каждой второй колонкой
				Text {
					visible: index % 2 === 1
					text: (Math.floor(index/2) + 1) + "000"
					color: theme.muted
					font.pixelSize: 12
					anchors.horizontalCenter: parent.horizontalCenter
					anchors.bottom: parent.top
					anchors.bottomMargin: 6
				}
			}
		}
	}



    // ===== Вертикальный индикатор (для топлива/температуры) =====
    component VBar: Item {
        id: vb
        property real min: 0
        property real max: 100
        property real value: 0
        property color back: theme.panelBorder
        property color fill: theme.accent
        property string title: ""
        property string subtext: ""
        // откроем доступ к области столба наружу (для меток)
        property alias barArea: barBox

        width: 110; height: 260

        Column {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 8
            // Полоса
            Item {
                id: barBox
                width: parent.width
                height: parent.height - 56
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(barBox.width, 24)
                    height: barBox.height
                    radius: width/2
                    color: Qt.darker(back, 1.1)
                }
                Rectangle {
                    id: fillRect
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(barBox.width, 24)
                    height: clamp((vb.value - vb.min) / Math.max(1e-6, (vb.max - vb.min)) * barBox.height, 0, barBox.height)
                    y: barBox.height - height
                    radius: width/2
                    color: vb.fill
                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                }
            }
            // Текст снизу
            Column {
                width: parent.width
                spacing: 4
                Text { text: vb.title; color: theme.muted; font.pixelSize: 16; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
                Text { text: vb.subtext; color: vb.fill; font.pixelSize: 18; font.bold: true; horizontalAlignment: Text.AlignHCenter; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }

    // ===== КРУГ ВОКРУГ СКОРОСТИ =====
    component CircularProgress: Item {
        id: cp
        property real value: 0
        property real max: 240
        property color backColor: Qt.rgba(1,1,1,0.08)
        property color fillColor: theme.accent
        property real thickness: Math.max(6, Math.round(Math.min(width, height) * 0.06))
        property real r: Math.min(width, height)/2 - thickness/2
        width: 220; height: 220
        Shape {
            anchors.fill: parent; antialiasing: true
            ShapePath {
                strokeWidth: cp.thickness; strokeColor: cp.backColor; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc { centerX: width/2; centerY: height/2; radiusX: cp.r; radiusY: cp.r; startAngle: 90; sweepAngle: 360 }
            }
        }
        Shape {
            anchors.fill: parent; antialiasing: true
            ShapePath {
                strokeWidth: cp.thickness; strokeColor: cp.fillColor; fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: width/2; centerY: height/2; radiusX: cp.r; radiusY: cp.r
                    startAngle: 90
                    sweepAngle: 360 * Math.max(0, Math.min(1, cp.value / Math.max(1e-6, cp.max)))
                }
            }
        }
        Behavior on value { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }

    // ===== ВЕРХНЯЯ ПАНЕЛЬ =====
    Row {
        id: topRow
        spacing: 18
        anchors.top: parent.top
        anchors.topMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        Blinker { active: ClusterState.leftBlinker; isLeft: true }
        Blinker { active: ClusterState.rightBlinker; isLeft: false }
        Row {
            spacing: 16
            anchors.verticalCenter: parent.verticalCenter
            Lamp { active: ClusterState.handbrake; text: "РУЧНИК";  colorOn: theme.danger }
            Lamp { active: ClusterState.lights;   text: "ФАРЫ";    colorOn: theme.accent }
            Lamp { active: ClusterState.highBeam; text: "ДАЛЬНИЙ"; colorOn: theme.accent2 }
            Lamp { active: ClusterState.checkEngine; text: "ДВИГАТЕЛЬ"; colorOn: theme.warn }
            Lamp { active: ClusterState.oilPressure; text: "МАСЛО";   colorOn: theme.danger }
            Lamp { active: ClusterState.batteryWarn; text: "АКБ";     colorOn: theme.danger }
        }
    }

    // ===== НИЖНИЙ ЦЕНТР =====
    ColumnLayout {
        id: centerStack
        spacing: 16
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40

        // Скорость
        Item {
            id: speedBox
            width: Math.min(win.width * 0.72, 980)
            height: Math.min(win.height * 0.28, 210)
            Layout.bottomMargin: 280
            property real speedDisplay: ClusterState.speed
            Behavior on speedDisplay { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            property int tick: Math.floor(speedDisplay / 5)
            onTickChanged: { popAnim.running = false; speedGroup.scale = 1.08; popAnim.running = true; }
            CircularProgress {
                id: speedRing
                anchors.centerIn: parent
                width: Math.min(parent.width * 2, parent.height * 2)
                height: width
                thickness: Math.round(width * 0.06)
                value: speedBox.speedDisplay
                max: 240
                backColor: Qt.rgba(1,1,1,0.08)
                fillColor: (value < 200) ? theme.accent : theme.warn
            }
            Item {
                id: speedGroup
                anchors.centerIn: parent
                scale: 1.0
                SequentialAnimation {
                    id: popAnim
                    running: false
                    NumberAnimation { target: speedGroup; property: "scale"; to: 1.08; duration: 80; easing.type: Easing.OutCubic }
                    NumberAnimation { target: speedGroup; property: "scale"; to: 1.0; duration: 120; easing.type: Easing.InCubic }
                }
                Text {
                    id: speedText
                    text: Math.round(speedBox.speedDisplay).toString()
                    color: theme.text
                    font.pixelSize: Math.round(Math.min(speedBox.width, speedBox.height) * 0.6)
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "км/ч"
                    color: theme.muted
                    font.pixelSize: Math.round(Math.min(speedBox.width, speedBox.height) * 0.16)
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: speedText.bottom
                    anchors.topMargin: 6
                }
            }
        }

        // RPM лесенка
        RpmLadderH {
            id: ladder
            rpm: ClusterState.rpm
            maxRpm: 7000
            width: Math.min(win.width * 0.82, 1000)
            height: Math.min(win.height * 0.22, 150)
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // сглаженная скорость
    Timer { interval: 60; running: true; repeat: true; onTriggered: speedBox.speedDisplay = ClusterState.speed }

    // ===== НИЖНИЕ УГЛЫ =====

    // Топливо слева — метки литров справа
    VBar {
        id: fuelV
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.leftMargin: 22
        anchors.bottomMargin: 22
        min: 0; max: 100
        value: ClusterState.fuel
        fill: (ClusterState.fuel < 10) ? theme.red : theme.accent

        // параметры бака
        property int tankCap: 55
        property int tickStep: 10

		property int fuelLiters: Math.round((ClusterState.fuel / 100) * tankCap)

        title: "ТОПЛИВО"
        subtext: fuelLiters + " л"
        width: 120; height: 300

		Item {
			anchors.top: fuelV.barArea.top
			anchors.bottom: fuelV.barArea.bottom
			width: 95
			height: 240

			// правый край дорожки (её ширина = min(barArea.width, 24)) + зазор 8
			x: fuelV.barArea.x + Math.min(fuelV.barArea.width, 24) + 8
			z: 2

			Repeater {
				model: Math.floor(fuelV.tankCap / fuelV.tickStep) + 1
				delegate: Item {
					readonly property int liters: index * fuelV.tickStep
					property int fs: 16
					width: parent.width
					height: fs + 6
					visible: liters !== 0
					// Центр делегата на нужной высоте шкалы
					y: parent.height * (1 - liters / fuelV.tankCap) - height / 2

					// Сначала текст...
					Text {
						id: lab
						text: liters + " л"
						color: theme.muted
						font.pixelSize: fs
						renderType: Text.NativeRendering
						anchors.right: parent.right
						anchors.verticalCenter: parent.verticalCenter
					}
					// ...а риску выравниваем по вертикальному центру текста
					Rectangle {
						width: 12; height: 2; radius: 1; color: theme.muted
						anchors.verticalCenter: lab.verticalCenter
						anchors.right: lab.left
						anchors.rightMargin: 6
					}
				}
			}
		}
    }

    // Температура справа — цветовые зоны
    VBar {
        id: tempV
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 22
        anchors.bottomMargin: 22
        min: 60; max: 120
        value: ClusterState.coolant
        // синий (холодно) <70, жёлтый (норма) 70..105, красный (перегрев) >105
        fill: (value < 70) ? "#2b6cff" : (value > 105 ? theme.red : theme.warn)
        title: "ТЕМПЕРАТУРА ОЖ"
        subtext: Math.round(ClusterState.coolant) + " °C"
        width: 120; height: 300
    }

    // ===== АЛЕРТЫ =====
    Rectangle {
        id: alertBanner
        width: Math.min(parent.width*0.8, 820)
        height: 56
        radius: 14
        color: theme.panel
        border.color: theme.panelBorder; border.width: 2
        anchors.horizontalCenter: parent.horizontalCenter
        y: visible ? (centerStack.y - height - 12) : win.height + 10
        visible: false
        layer.enabled: true; layer.smooth: true
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        Row { anchors.fill: parent; anchors.margins: 14; spacing: 12
            Rectangle { width: 10; height: 10; radius: 5; color: theme.warn; anchors.verticalCenter: parent.verticalCenter }
            Text { id: alertText; text: ""; color: theme.text; font.pixelSize: 18; verticalAlignment: Text.AlignVCenter }
        }
    }
	Timer {
		id: toastHider
		interval: 3500
		repeat: false
		onTriggered: alertBanner.visible = false
	}

    Timer {
		interval: 1000; running: true; repeat: true
		onTriggered: {
			// --- ЧЕК: показать ОДИН РАЗ при включении (rising edge) ---
			if (ClusterState.checkEngine && !_prevCheckEngine) {
				alertText.text = "НЕИСПРАВНОСТЬ В РАБОТЕ ДВИГАТЕЛЯ ИЛИ ЕГО СИСТЕМ";
				alertBanner.visible = true;
				toastHider.restart();              // автоскрытие через 3.5 c
			}
			_prevCheckEngine = ClusterState.checkEngine;

			// --- Остальные алерты ведём как раньше, но не перебиваем тост ---
			if (!toastHider.running) {
				if (ClusterState.fuel < 8) {
					alertText.text = "МАЛО ТОПЛИВА";
					alertBanner.visible = true;
				} else if (ClusterState.coolant > 110) {
					alertText.text = "ПЕРЕГРЕВ ДВИГАТЕЛЯ";
					alertBanner.visible = true;
				} else {
					alertBanner.visible = false;
				}
			}
		}
	}

    MouseArea { anchors.fill: parent; onDoubleClicked: night = !night }
}
