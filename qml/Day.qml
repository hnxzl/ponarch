pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function clamp(v) { return Math.max(0, Math.min(1, v)) }

    function dayFrac(n) {
        const s = new Date(n.getFullYear(), n.getMonth(), n.getDate(), Settings.wakeHour).getTime()
        const e = new Date(n.getFullYear(), n.getMonth(), n.getDate(), Settings.bedHour).getTime()
        return e > s ? clamp((n.getTime() - s) / (e - s)) : 0
    }
    function weekFrac(n) {
        const dow = (n.getDay() + 6) % 7
        const s = new Date(n.getFullYear(), n.getMonth(), n.getDate() - dow).getTime()
        return clamp((n.getTime() - s) / (7 * 86400000))
    }
    function monthFrac(n) {
        const s = new Date(n.getFullYear(), n.getMonth(), 1).getTime()
        const e = new Date(n.getFullYear(), n.getMonth() + 1, 1).getTime()
        return clamp((n.getTime() - s) / (e - s))
    }
    function yearFrac(n) {
        const s = new Date(n.getFullYear(), 0, 1).getTime()
        const e = new Date(n.getFullYear() + 1, 0, 1).getTime()
        return clamp((n.getTime() - s) / (e - s))
    }
    function untilBed(n) {
        const e = new Date(n.getFullYear(), n.getMonth(), n.getDate(), Settings.bedHour).getTime()
        const m = Math.max(0, Math.round((e - n.getTime()) / 60000))
        return Math.floor(m / 60) + "j " + (m % 60) + "m"
    }
}
