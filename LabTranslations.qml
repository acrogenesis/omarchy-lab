import QtQuick
import qs.Commons as Commons

// Standalone catalogs follow the shell language and fall back to English.
Commons.Translations {
  directory: Qt.resolvedUrl("default/lab-vm")
}
