import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Commons
import qs.Ui
import "Model.js" as Model

BarWidget {
  id: root

  function labCommand(name) {
    if (name.startsWith("/")) return name
    return decodeURIComponent(String(Qt.resolvedUrl("bin/" + name)).replace(/^file:\/\//, ""))
  }

  LabTranslations { id: labStrings }
  function t(key, fallback) { return labStrings.t(key, fallback) }
  moduleName: "acrogenesis.lab"

  readonly property string domainName: Quickshell.env("OMARCHY_LAB_NAME") || "omarchy-lab"
  readonly property bool viewerActive: Model.viewerPresent(Hyprland.toplevels.values, domainName)
  readonly property bool keepInBar: Model.parseBarStatus(viewerSettings.text()).keepInBar
  readonly property string viewerCommand: labCommand("omarchy-lab-viewer")
  readonly property bool shown: viewerActive || keepInBar


  function summon() {
    if (bar && bar.shell) bar.shell.summon(root.moduleName, "{}")
  }

  visible: shown
  implicitWidth: shown ? button.implicitWidth : 0
  implicitHeight: button.implicitHeight

  FileView {
    id: viewerSettings
    path: Quickshell.env("OMARCHY_LAB_VIEWER_SETTINGS") || Quickshell.env("HOME") + "/.config/omarchy/lab-vm/viewer.json"
    watchChanges: true
    blockLoading: true
    printErrors: false
    onFileChanged: reload()
  }

  Process {
    id: actionProc
  }


  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰆧"
    active: root.viewerActive
    tooltipText: root.viewerActive ? labStrings.t("lab.labControlsMiddleClickFullscreenRightClickScreenshot") : labStrings.t("lab.labControlsViewerClosed")
    onPressed: function(buttonCode) {
      if (!root.viewerActive) {
        root.summon()
      } else if (buttonCode === Qt.MiddleButton) {
        actionProc.command = [root.viewerCommand, "fullscreen"]
        actionProc.running = true
      } else if (buttonCode === Qt.RightButton) {
        actionProc.command = [root.viewerCommand, "screenshot"]
        actionProc.running = true
      } else {
        root.summon()
      }
    }
  }
}
