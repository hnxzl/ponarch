pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// AI Chat dan Terjemahan. Provider: claude | gemini | openai (kompatibel OpenAI) | ollama.
// Kunci API: env PONARCH_AI_KEY (~/.config/ponarch/ponarch.env) atau "aiKey" di settings.json.
Singleton {
    id: root

    property var chat: []                  // [{ role, content, err }]
    property bool busy: false
    property var pendingCb: null
    readonly property var providers: ["claude", "gemini", "openai", "ollama"]
    readonly property string envKey: Quickshell.env("PONARCH_AI_KEY") || ""
    readonly property string key: envKey !== "" ? envKey : Settings.aiKey
    readonly property string model: Settings.aiModel !== "" ? Settings.aiModel
        : ({ claude: "claude-sonnet-5-5", gemini: "gemini-2.5-flash", openai: "gpt-4o-mini", ollama: "llama3.2" })[Settings.aiProvider]
    readonly property bool ready: Settings.aiProvider === "ollama" || key !== ""
    readonly property string systemPrompt: "Kamu Ponarch, asisten singkat di notch desktop. Jawab ringkas, dalam bahasa yang dipakai pengguna."

    function cycleProvider() {
        Settings.aiProvider = providers[(providers.indexOf(Settings.aiProvider) + 1) % providers.length]
        Settings.aiModel = ""
    }

    function ask(messages, system, cb) {
        if (busy) return
        if (!ready) { cb("", "Kunci API belum diisi (PONARCH_AI_KEY di ~/.config/ponarch/ponarch.env atau aiKey di settings.json)"); return }
        const p = Settings.aiProvider
        const base = Settings.aiBase !== "" ? Settings.aiBase
                   : p === "openai" ? "https://api.openai.com/v1" : p === "ollama" ? "http://localhost:11434" : ""
        const headers = ["content-type: application/json"]
        let url = ""
        let body = {}
        const withSys = (system ? [{ role: "system", content: system }] : []).concat(messages)
        if (p === "claude") {
            url = "https://api.anthropic.com/v1/messages"
            headers.push("x-api-key: " + key, "anthropic-version: 2023-06-01")
            body = { model: model, max_tokens: 1024, messages: messages }
            if (system) body.system = system
        } else if (p === "gemini") {
            url = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent"
            headers.push("x-goog-api-key: " + key)
            body = { contents: messages.map(m => ({ role: m.role === "assistant" ? "model" : "user", parts: [{ text: m.content }] })) }
            if (system) body.systemInstruction = { parts: [{ text: system }] }
        } else if (p === "openai") {
            url = base + "/chat/completions"
            headers.push("Authorization: Bearer " + key)
            body = { model: model, messages: withSys }
        } else {
            url = base + "/api/chat"
            body = { model: model, stream: false, messages: withSys }
        }
        const cmd = ["curl", "-s", "--max-time", "90"]
        headers.forEach(h => { cmd.push("-H", h) })
        cmd.push("-d", JSON.stringify(body), url)
        busy = true
        pendingCb = cb
        proc.command = cmd
        proc.running = true
    }

    function extract(p, j) {
        if (j.error) return { err: (j.error.message || JSON.stringify(j.error)) }
        if (p === "claude") return { text: (j.content || []).map(c => c.text || "").join("") }
        if (p === "gemini") return { text: j.candidates[0].content.parts.map(x => x.text || "").join("") }
        if (p === "openai") return { text: j.choices[0].message.content }
        return { text: j.message.content }
    }

    function send(text) {
        text = (text || "").trim()
        if (text === "" || busy) return
        chat = chat.concat([{ role: "user", content: text }])
        const msgs = chat.filter(m => !m.err).map(m => ({ role: m.role, content: m.content }))
        ask(msgs, systemPrompt, (t, e) => {
            chat = chat.concat([e ? { role: "assistant", content: e, err: true } : { role: "assistant", content: t }])
        })
    }
    function clearChat() { chat = [] }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                const cb = root.pendingCb
                root.pendingCb = null
                root.busy = false
                let r = { err: "Tidak ada balasan (cek koneksi, kunci API, atau model)" }
                try { r = root.extract(Settings.aiProvider, JSON.parse(text)) } catch (e) { }
                if (cb) cb(r.text || "", r.err || (r.text ? "" : "Balasan kosong"))
            }
        }
    }
}
