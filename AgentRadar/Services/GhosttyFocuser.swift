import Foundation

struct GhosttyFocuser {
    static func focusTerminal(pwd: String) {
        let script = """
        tell application "Ghostty"
            set wlist to every window
            repeat with w in wlist
                set tabList to every tab of w
                repeat with t in tabList
                    set term to focused terminal of t
                    set termDir to working directory of term
                    if termDir is "\(pwd)" then
                        set wName to name of w
                        select tab t
                        tell application "System Events"
                            tell process "Ghostty"
                                set frontmost to true
                                perform action "AXRaise" of (first window whose name is wName)
                            end tell
                        end tell
                        return
                    end if
                end repeat
            end repeat
        end tell
        """

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }

    static func openInVSCode(path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/code")
        process.arguments = [path]
        try? process.run()
    }
}
