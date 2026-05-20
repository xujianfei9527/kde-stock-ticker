import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support 2.0 as Plasma5Support
import org.kde.plasma.components as PlasmaComponents

PlasmoidItem {
    id: root

    property string stockCode: "513500"
    property int refreshIntervalMs: 30000
    property bool loading: true
    property string errorText: ""
    property var quote: ({
        name: "",
        price: NaN,
        change: NaN,
        changePct: NaN,
        open: NaN,
        high: NaN,
        low: NaN,
        prevClose: NaN,
        volume: NaN,
        amount: NaN,
        updateTime: ""
    })

    readonly property string scriptPath: Qt.resolvedUrl("../stock_quote.py").toString().replace("file://", "")
    readonly property string quoteCommand: "/usr/bin/python3 " + scriptPath + " " + stockCode + " --json"

    function fmtPrice(value) {
        return isNaN(value) ? "--" : value.toFixed(3);
    }

    function fmtPct(value) {
        return isNaN(value) ? "--" : (value >= 0 ? "+" : "") + value.toFixed(2) + "%";
    }

    function fmtChange(value) {
        return isNaN(value) ? "--" : (value >= 0 ? "+" : "") + value.toFixed(3);
    }

    function fmtCount(value) {
        return isNaN(value) ? "--" : Number(value).toLocaleString();
    }

    function quoteColor() {
        if (loading || isNaN(quote.change)) {
            return "#d0d7de";
        }
        if (quote.change > 0) {
            return "#e25555";
        }
        if (quote.change < 0) {
            return "#27c97a";
        }
        return "#d0d7de";
    }

    function badgeText() {
        if (loading) {
            return "--";
        }
        if (errorText.length > 0) {
            return "err";
        }
        return fmtPct(quote.changePct);
    }

    function updateQuoteFromJson(text) {
        try {
            var payload = JSON.parse(text);
            quote = {
                name: payload.name || stockCode,
                price: Number(payload.price),
                change: Number(payload.change),
                changePct: Number(payload.change_pct),
                open: payload.open === null || payload.open === undefined ? NaN : Number(payload.open),
                high: payload.high === null || payload.high === undefined ? NaN : Number(payload.high),
                low: payload.low === null || payload.low === undefined ? NaN : Number(payload.low),
                prevClose: payload.prev_close === null || payload.prev_close === undefined ? NaN : Number(payload.prev_close),
                volume: payload.volume === null || payload.volume === undefined ? NaN : Number(payload.volume),
                amount: payload.amount === null || payload.amount === undefined ? NaN : Number(payload.amount),
                updateTime: new Date().toLocaleString()
            };
            loading = false;
            errorText = "";
        } catch (e) {
            loading = false;
            errorText = "parse error";
        }
    }

    function handleQuoteData(sourceName, data) {
        var exitCode = data.exitCode !== undefined ? data.exitCode : data["exitCode"];
        if (exitCode !== undefined && exitCode !== 0) {
            loading = false;
            errorText = "exit " + exitCode;
            return;
        }

        var text = data.stdout;
        if (text === undefined) {
            text = data["stdout"];
        }
        if (text === undefined) {
            text = data.output;
        }
        if (text === undefined) {
            text = data["output"];
        }
        if (text === undefined) {
            text = data.text;
        }
        if (text === undefined) {
            text = data["text"];
        }

        if (text === undefined || text === null || String(text).trim().length === 0) {
            loading = false;
            errorText = "empty output";
            return;
        }

        updateQuoteFromJson(String(text).trim());
    }

    Plasma5Support.DataSource {
        id: quoteSource
        engine: "executable"
        connectedSources: [quoteCommand]
        interval: root.refreshIntervalMs
        onNewData: root.handleQuoteData(sourceName, data)
    }

    Component.onCompleted: {
        loading = true;
        errorText = "";
    }

    compactRepresentation: Item {
        id: compactRoot
        implicitWidth: 80
        implicitHeight: 28
        width: implicitWidth
        height: implicitHeight
        Layout.minimumWidth: 80
        Layout.preferredWidth: 80
        Layout.maximumWidth: 80
        Layout.minimumHeight: 28
        Layout.preferredHeight: 28
        Layout.maximumHeight: 28

        Rectangle {
            id: badge
            anchors.fill: parent
            radius: 10
            color: "#202833"
            border.width: 1
            border.color: root.quoteColor()
            implicitWidth: 80
            implicitHeight: 28

            PlasmaComponents.Label {
                id: badgeText
                anchors.fill: parent
                anchors.margins: 8
                text: root.badgeText()
                font.pixelSize: 14
                font.bold: true
                color: root.quoteColor()
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideNone
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Rectangle {
        id: panel
        implicitWidth: 420
        implicitHeight: 260
        radius: 18
        color: "#202833"
        border.width: 1
        border.color: "#2b3340"
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#232a35" }
            GradientStop { position: 1.0; color: "#151922" }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    PlasmaComponents.Label {
                        text: root.stockCode + "  " + (root.loading ? "Loading..." : root.quote.name)
                        font.pixelSize: 16
                        font.bold: true
                        color: "#edf2f8"
                        elide: Text.ElideRight
                    }

                    PlasmaComponents.Label {
                        text: root.errorText.length > 0 ? root.errorText : "Updated: " + (root.loading ? "--" : root.quote.updateTime)
                        font.pixelSize: 10
                        color: root.errorText.length > 0 ? "#ff8a80" : "#95a4ba"
                        elide: Text.ElideRight
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: "#2b3340"
                opacity: 0.9
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 12
                columnSpacing: 24

                PlasmaComponents.Label { text: "Price"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.loading ? "--" : root.fmtPrice(root.quote.price); color: "#edf2f8" }

                PlasmaComponents.Label { text: "Change"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.loading ? "--" : root.fmtChange(root.quote.change) + "  " + root.fmtPct(root.quote.changePct); color: root.quoteColor() }

                PlasmaComponents.Label { text: "Open"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.fmtPrice(root.quote.open); color: "#edf2f8" }

                PlasmaComponents.Label { text: "Prev Close"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.fmtPrice(root.quote.prevClose); color: "#edf2f8" }

                PlasmaComponents.Label { text: "High"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.fmtPrice(root.quote.high); color: "#edf2f8" }

                PlasmaComponents.Label { text: "Low"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.fmtPrice(root.quote.low); color: "#edf2f8" }

                PlasmaComponents.Label { text: "Volume"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.loading ? "--" : root.fmtCount(root.quote.volume); color: "#edf2f8" }

                PlasmaComponents.Label { text: "Amount"; color: "#95a4ba" }
                PlasmaComponents.Label { text: root.loading ? "--" : root.quote.amount.toFixed(2); color: "#edf2f8" }
            }
        }
    }
}
