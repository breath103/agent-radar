import Foundation

struct GhosttyFocuser {
    static func focusTerminal(shellPID: Int) {
        let cacheFile = "/tmp/ghostty-claude-\(shellPID)"
        guard let contents = try? String(contentsOfFile: cacheFile, encoding: .utf8) else { return }

        let lines = contents.components(separatedBy: "\n").filter { !$0.isEmpty }
        guard lines.count >= 2 else { return }

        let winID = lines[0]
        let tabID = lines[1]

        let script = """
        tell application "Ghostty"
            activate
            set t to tab id "\(tabID)" of window id "\(winID)"
            select tab t
        end tell
        """

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    static func openInVSCode(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/code")
        process.arguments = [path]
        try? process.run()
    }
}
