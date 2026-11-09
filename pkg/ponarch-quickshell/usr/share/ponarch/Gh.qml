pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pull request yang menunggu review kamu (butuh `gh` dan `gh auth login`).
Singleton {
    id: root

    property var prs: []
    property string state: "idle"       // idle | loading | ok | err
    property double at: 0

    function ensure() { if (Date.now() - at > 5 * 60 * 1000) refresh() }
    function refresh() {
        if (proc.running) return
        state = "loading"
        proc.running = true
    }

    Process {
        id: proc
        command: ["gh", "search", "prs", "--review-requested=@me", "--state=open",
                  "--json", "title,url,repository,number", "--limit", "8"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.prs = JSON.parse(text); root.state = "ok" }
                catch (e) { root.state = "err" }
                root.at = Date.now()
            }
        }
    }
}
