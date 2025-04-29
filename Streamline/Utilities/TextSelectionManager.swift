import Foundation
import AppKit

class TextSelectionManager {
    static let shared = TextSelectionManager()
    
    private init() {}
    
    // Main method to get selected text using multiple methods
    func getSelectedText() -> String {
        // Try to get selected text using different methods in order of reliability
        
        // 1. Try clipboard (most reliable)
        if let clipboardText = getSelectedTextFromPasteboard() {
            return clipboardText
        }
        
        // 2. Try AppleScript (works for many apps but can fail)
        if let scriptText = getSelectedTextFromAppleScript() {
            return scriptText
        }
        
        // 3. If nothing worked, return empty string
        return ""
    }
    
    // Using AppleScript to get selected text from various applications
    private func getSelectedTextFromAppleScript() -> String? {
        // First, detect the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        let appName = frontmostApp.localizedName ?? ""
        
        // Different applications need different AppleScript commands
        var script = ""
        
        switch appName {
        case "Safari", "Google Chrome", "Firefox", "Arc":
            script = """
            tell application "\(appName)"
                set selectedText to ""
                try
                    set selectedText to (do JavaScript "window.getSelection().toString();" in front document)
                on error
                    -- Handle error silently
                end try
                return selectedText
            end tell
            """
            
        case "Microsoft Word":
            script = """
            tell application "Microsoft Word"
                set selectedText to ""
                try
                    if selection is not missing value then
                        set selectedText to content of selection as string
                    end if
                on error
                    -- Handle error silently
                end try
                return selectedText
            end tell
            """
            
        case "TextEdit", "Pages":
            script = """
            tell application "\(appName)"
                set selectedText to ""
                try
                    tell front document
                        set selectedText to text of selection
                    end tell
                on error
                    -- Handle error silently
                end try
                return selectedText
            end tell
            """
            
        case "Finder":
            script = """
            tell application "Finder"
                set selectedText to ""
                try
                    set selectedItems to selection
                    set selectedText to name of item 1 of selectedItems
                on error
                    -- Handle error silently
                end try
                return selectedText
            end tell
            """
            
        default:
            // Generic AppleScript for other applications
            script = """
            tell application "System Events"
                set frontApp to first application process whose frontmost is true
                set selectedText to ""
                try
                    tell frontApp
                        set selectedText to value of attribute "AXSelectedText" of first window
                    end tell
                on error
                    -- Handle error silently
                end try
                return selectedText
            end tell
            """
        }
        
        // Execute the AppleScript
        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        
        if let result = appleScript?.executeAndReturnError(&error).stringValue, !result.isEmpty {
            return result
        }
        
        if let error = error {
            // Log error but don't throw
            print("AppleScript error: \(error)")
        }
        
        return nil
    }
    
    // Using pasteboard to get selected text
    private func getSelectedTextFromPasteboard() -> String? {
        let pasteboard = NSPasteboard.general
        
        // Save current pasteboard contents to restore later
        let originalContents = pasteboard.pasteboardItems?.first
        let originalTypes = pasteboard.types
        
        // Clear the pasteboard and perform copy
        pasteboard.clearContents()
        
        // Simulate Cmd+C to copy selected text
        let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: true) // 'c' key
        keyDownEvent?.flags = .maskCommand
        keyDownEvent?.post(tap: .cgAnnotatedSessionEventTap)
        
        let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0x08, keyDown: false)
        keyUpEvent?.flags = .maskCommand
        keyUpEvent?.post(tap: .cgAnnotatedSessionEventTap)
        
        // Wait a moment for the pasteboard to update
        usleep(50000) // 50ms
        
        // Get the text from pasteboard
        let selectedText = pasteboard.string(forType: .string)
        
        // Restore original pasteboard contents if possible
        if let originalContents = originalContents, let originalTypes = originalTypes {
            pasteboard.clearContents()
            for type in originalTypes {
                if let data = originalContents.data(forType: type) {
                    pasteboard.setData(data, forType: type)
                }
            }
        }
        
        return selectedText
    }
    
    func clearSelection() {
        // Implement if needed to clear a selection
    }
} 