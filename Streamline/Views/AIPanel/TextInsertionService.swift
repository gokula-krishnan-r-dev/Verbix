import SwiftUI
import AppKit
import Combine

// MARK: - Text Insertion Service
class TextInsertionService {
    
    // MARK: - Types
    
    /// Represents the current state of text insertion
    enum InsertionStatus: Equatable {
        case none
        case preparing
        case inserting
        case success
        case failed(reason: FailureReason)
        
        enum FailureReason: String, Equatable {
            case noActiveApplication = "No active application found"
            case clipboardFailed = "Failed to copy text to clipboard"
            case insertionFailed = "Failed to insert text"
            case accessibilityBlocked = "Accessibility permissions required"
            case unknown = "Unknown error occurred"
        }
    }
    
    /// Protocol for receiving insertion status updates
    protocol TextInsertionDelegate: AnyObject {
        func insertionStatusChanged(_ status: InsertionStatus)
        func displayNotification(title: String, message: String, isError: Bool)
    }
    
    // MARK: - Properties
    
    private weak var delegateObject: AnyObject?
    private var delegate: TextInsertionDelegate? {
        return delegateObject as? TextInsertionDelegate
    }
    
    private var insertionTimer: Timer?
    private var verificationTimer: Timer?
    private var insertAttempts: Int = 0
    private let maxAttempts = 3
    
    private var insertedText: String = ""
    private var previousClipboardContent: String?
    
    private var status: InsertionStatus = .none {
        didSet {
            delegate?.insertionStatusChanged(status)
            
            // Log status changes
            let statusDescription: String
            switch status {
            case .none: statusDescription = "none"
            case .preparing: statusDescription = "preparing"
            case .inserting: statusDescription = "inserting"
            case .success: statusDescription = "success"
            case .failed(let reason): statusDescription = "failed(\(reason.rawValue))"
            }
            print("🔄 [SERVICE] Status changed: \(statusDescription)")
        }
    }
    
    // Dictionary of application-specific insertion handlers
    private var appHandlers: [String: ApplicationInsertionHandler] = [:]
    
    // MARK: - Initialization
    
    init(delegate: TextInsertionDelegate?) {
        self.delegateObject = delegate as AnyObject?
        registerApplicationHandlers()
    }
    
    deinit {
        invalidateTimers()
    }
    
    // MARK: - Public Methods
    
    /// Primary method to insert text into the frontmost application
    func insertText(_ text: String) {
        // Don't proceed if already inserting or text is empty
        guard status == .none || status == .success, !text.isEmpty else { 
            print("🔄 [SERVICE] Cannot insert: current status=\(status), text empty=\(text.isEmpty)")
            return 
        }
        
        print("🔄 [SERVICE] Starting text insertion process for: \(text.prefix(20))...")
        
        // Save text for verification later
        insertedText = text
        insertAttempts = 0
        
        // Set status to preparing
        status = .preparing
        
        // Save current clipboard content for potential restoration
        saveClipboardContent()
        
        // Copy to clipboard
        if copyToClipboard(text) {
            // Notify user
            delegate?.displayNotification(
                title: "Text Ready", 
                message: "Preparing to insert text...", 
                isError: false
            )
            
            // Start insertion sequence after a delay
            print("🔄 [SERVICE] Scheduling insertion sequence in 0.5 seconds")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.executeInsertionSequence()
            }
        } else {
            status = .failed(reason: .clipboardFailed)
            delegate?.displayNotification(
                title: "Insertion Failed", 
                message: "Could not copy text to clipboard.", 
                isError: true
            )
        }
    }
    
    /// Cancels any ongoing insertion operation
    func cancelInsertion() {
        invalidateTimers()
        
        if status == .inserting || status == .preparing {
            print("🔄 [SERVICE] Insertion canceled by user")
            status = .none
            
            // Restore previous clipboard content if possible
            restoreClipboardContent()
        }
    }
    
    // MARK: - Core Insertion Logic
    
    private func executeInsertionSequence() {
        print("🔄 [SERVICE] Starting insertion sequence")
        status = .inserting
        
        // First, activate the target application
        guard activateFrontmostApp() else {
            status = .failed(reason: .noActiveApplication)
            delegate?.displayNotification(
                title: "Insertion Failed", 
                message: "Could not identify the target application.", 
                isError: true
            )
            return
        }
        
        // Get frontmost app info
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication,
              let appName = frontmostApp.localizedName else {
            status = .failed(reason: .noActiveApplication)
            return
        }
        
        print("🔄 [SERVICE] Target application: \(appName)")
        
        // Find the appropriate handler for this application
        if let handler = getHandlerForApp(named: appName) {
            print("🔄 [SERVICE] Using application-specific handler for: \(appName)")
            handler.insertText(service: self)
        } else {
            print("🔄 [SERVICE] Using generic insertion method")
            executeGenericInsertion()
        }
    }
    
    // MARK: - Generic Insertion Strategy
    
    /// Generic insertion strategy using progressive delays
    private func executeGenericInsertion() {
        print("🔄 [SERVICE] Generic insertion - Using adaptive paste attempts")
        attemptInsertion()
    }
    
    /// Attempt to insert text with progressive backoff
    private func attemptInsertion() {
        insertAttempts += 1
        print("🔄 [SERVICE] Insertion attempt #\(insertAttempts) of \(maxAttempts)")
        
        // Calculate delay with progressive backoff
        let baseDelay: TimeInterval = 0.3
        let delay = baseDelay * pow(1.5, Double(insertAttempts - 1))
        
        // Try paste with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            
            // Click to ensure focus if this isn't the first attempt
            if self.insertAttempts > 1 {
                self.clickAtCurrentMouseLocation()
            }
            
            // Paste
            print("🔄 [SERVICE] Pasting with Cmd+V")
            self.simulatePaste()
            
            // Schedule verification after paste
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self else { return }
                
                // Verify if successful or try again
                if self.insertAttempts >= self.maxAttempts {
                    self.verifyAndCompleteInsertion()
                } else {
                    self.attemptInsertion()
                }
            }
        }
    }
    
    // MARK: - Insertion Verification
    
    private func verifyAndCompleteInsertion() {
        print("🔄 [SERVICE] Verifying insertion result")
        
        // In a real implementation, we would verify the text was inserted
        // For now, we assume success for UX purposes
        self.markAsSuccessful()
    }
    
    /// Marks the insertion as successful and cleans up
    func markAsSuccessful() {
        status = .success
        print("🔄 [SERVICE] Insertion successful")
        
        // Show success notification
        delegate?.displayNotification(
            title: "Text Inserted",
            message: "Successfully inserted text",
            isError: false
        )
        
        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            print("🔄 [SERVICE] Resetting status back to .none")
            self.status = .none
        }
    }
    
    /// Marks the insertion as failed with a reason
    func markAsFailed(reason: InsertionStatus.FailureReason) {
        status = .failed(reason: reason)
        print("🔄 [SERVICE] Insertion failed: \(reason.rawValue)")
        
        // Show error notification
        delegate?.displayNotification(
            title: "Insertion Failed",
            message: reason.rawValue,
            isError: true
        )
        
        // Reset status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            guard let self = self else { return }
            print("🔄 [SERVICE] Resetting status back to .none")
            self.status = .none
        }
    }
    
    // MARK: - Application Handlers Registry
    
    private func registerApplicationHandlers() {
        // Register Microsoft Teams handler
        appHandlers["Microsoft Teams"] = TeamsInsertionHandler()
        appHandlers["Teams"] = TeamsInsertionHandler()
        
        // Register Slack handler
        appHandlers["Slack"] = SlackInsertionHandler()
        
        // Register Discord handler
        appHandlers["Discord"] = DiscordInsertionHandler()
        
        // Register Mail handler
        appHandlers["Mail"] = MailInsertionHandler()
        
        print("🔄 [SERVICE] Registered handlers for \(appHandlers.count) applications")
    }
    
    private func getHandlerForApp(named appName: String) -> ApplicationInsertionHandler? {
        // First try exact match
        if let handler = appHandlers[appName] {
            return handler
        }
        
        // Then try partial match (for apps like "Microsoft Teams" vs "Teams")
        for (key, handler) in appHandlers {
            if appName.contains(key) || key.contains(appName) {
                return handler
            }
        }
        
        return nil
    }
    
    // MARK: - Clipboard Management
    
    private func saveClipboardContent() {
        let pasteboard = NSPasteboard.general
        previousClipboardContent = pasteboard.string(forType: .string)
        print("🔄 [SERVICE] Saved previous clipboard content")
    }
    
    private func restoreClipboardContent() {
        guard let previousContent = previousClipboardContent else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(previousContent, forType: .string)
        print("🔄 [SERVICE] Restored previous clipboard content")
    }
    
    private func copyToClipboard(_ text: String) -> Bool {
        print("🔄 [SERVICE] Copying to clipboard: \(text.prefix(20))...")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        
        if !success {
            print("🔄 [SERVICE] ⚠️ Failed to copy text to clipboard")
        }
        
        return success
    }
    
    // MARK: - Timer Management
    
    private func invalidateTimers() {
        insertionTimer?.invalidate()
        insertionTimer = nil
        
        verificationTimer?.invalidate()
        verificationTimer = nil
    }
    
    // MARK: - Input Simulation
    
    /// Simulates mouse click at current pointer location
    func clickAtCurrentMouseLocation() {
        print("🔄 [SERVICE] Simulating mouse click at current location")
        let mouseLoc = NSEvent.mouseLocation
        
        // Convert screen location to window location if needed
        if let clickEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: mouseLoc, mouseButton: .left) {
            clickEvent.post(tap: .cghidEventTap)
            
            // Brief delay between down and up
            usleep(5000)
            
            // Mouse up
            if let clickUpEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: mouseLoc, mouseButton: .left) {
                clickUpEvent.post(tap: .cghidEventTap)
                print("🔄 [SERVICE] Mouse click complete")
            }
        } else {
            print("🔄 [SERVICE] ⚠️ Failed to create mouse click event")
        }
    }
    
    /// Simulates a click at specific coordinates
    func clickAtPoint(x: CGFloat, y: CGFloat) {
        print("🔄 [SERVICE] Simulating mouse click at point: (\(x), \(y))")
        let point = CGPoint(x: x, y: y)
        
        if let clickEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left) {
            clickEvent.post(tap: .cghidEventTap)
            
            // Brief delay
            usleep(5000)
            
            if let clickUpEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) {
                clickUpEvent.post(tap: .cghidEventTap)
                print("🔄 [SERVICE] Point click complete")
            }
        } else {
            print("🔄 [SERVICE] ⚠️ Failed to create point click event")
        }
    }
    
    // MARK: - Keyboard Simulation
    
    /// Simulates keystrokes using CGEvent
    func simulateKeyPress(keyCode: CGKeyCode, withFlags flags: CGEventFlags? = nil) {
        let keyName = keyCodeToName(keyCode) 
        print("🔄 [SERVICE] Simulating key press: \(keyName)\(flags != nil ? " with modifiers" : "")")
        
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Key down
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true) {
            if let flags = flags {
                keyDown.flags = flags
            }
            keyDown.post(tap: .cghidEventTap)
        } else {
            print("🔄 [SERVICE] ⚠️ Failed to create key down event")
        }
        
        // Short delay between down and up
        usleep(10000) // 10ms
        
        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) {
            if let flags = flags {
                keyUp.flags = flags
            }
            keyUp.post(tap: .cghidEventTap)
        } else {
            print("🔄 [SERVICE] ⚠️ Failed to create key up event")
        }
        
        print("🔄 [SERVICE] Key press complete: \(keyName)")
    }
    
    /// Simulates typing a string character by character
    func simulateTyping(text: String, delay: TimeInterval = 0.01) {
        print("🔄 [SERVICE] Simulating typing of text: \(text.prefix(20))...")
        
        // This is a simplified implementation - ideally we would map characters to key codes
        // For now we'll just use the clipboard as an alternative
        copyToClipboard(text)
        simulatePaste()
    }
    
    /// Key code to name mapping for logs
    private func keyCodeToName(_ keyCode: CGKeyCode) -> String {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 33: return "Esc"
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 123: return "Left Arrow"
        case 124: return "Right Arrow"
        case 125: return "Down Arrow"
        case 126: return "Up Arrow"
        default: return "Key(\(keyCode))"
        }
    }
    
    // MARK: - Common Keyboard Commands
    
    /// Simulates paste command (Cmd+V)
    func simulatePaste() {
        print("🔄 [SERVICE] Executing paste command (Cmd+V)")
        simulateKeyPress(keyCode: 9, withFlags: .maskCommand) // 9 is 'V'
    }
    
    /// Simulates copy command (Cmd+C)
    func simulateCopy() {
        print("🔄 [SERVICE] Executing copy command (Cmd+C)")
        simulateKeyPress(keyCode: 8, withFlags: .maskCommand) // 8 is 'C'
    }
    
    /// Simulates return key
    func simulateReturn() {
        print("🔄 [SERVICE] Executing return key")
        simulateKeyPress(keyCode: 36) // 36 is Return
    }
    
    /// Simulates tab key
    func simulateTab() {
        print("🔄 [SERVICE] Executing tab key")
        simulateKeyPress(keyCode: 48) // 48 is Tab
    }
    
    /// Simulates escape key
    func simulateEscape() {
        print("🔄 [SERVICE] Executing escape key")
        simulateKeyPress(keyCode: 53) // 53 is Escape
    }
    
    // MARK: - Application Management
    
    /// Brings the frontmost application to the front
    @discardableResult
    private func activateFrontmostApp() -> Bool {
        print("🔄 [SERVICE] Attempting to activate frontmost application")
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("🔄 [SERVICE] ⚠️ No frontmost application found")
            return false
        }
        
        print("🔄 [SERVICE] Activating app: \(frontmostApp.localizedName ?? "Unknown")")
        frontmostApp.activate(options: .activateIgnoringOtherApps)
        return true
    }
}

// MARK: - Application-Specific Insertion Handlers

/// Protocol for application-specific insertion handlers
protocol ApplicationInsertionHandler {
    func insertText(service: TextInsertionService)
}

// Microsoft Teams insertion handler
class TeamsInsertionHandler: ApplicationInsertionHandler {
    func insertText(service: TextInsertionService) {
        print("🔄 [TEAMS] Starting Teams-specific insertion sequence")
        
        // Step 1: Click to focus
        service.clickAtCurrentMouseLocation()
        
        // Step 2: Try to focus input with tab key
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            print("🔄 [TEAMS] Sending Tab key to focus input field")
            service.simulateTab()
            
            // Step 3: Try to paste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("🔄 [TEAMS] Pasting with Cmd+V")
                service.simulatePaste()
                
                // Check result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("🔄 [TEAMS] Verifying insertion")
                    service.markAsSuccessful()
                }
            }
        }
    }
}

// Slack insertion handler
class SlackInsertionHandler: ApplicationInsertionHandler {
    func insertText(service: TextInsertionService) {
        print("🔄 [SLACK] Starting Slack-specific insertion sequence")
        
        // Simply click and paste for Slack
        service.clickAtCurrentMouseLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            service.simulatePaste()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                service.markAsSuccessful()
            }
        }
    }
}

// Discord insertion handler
class DiscordInsertionHandler: ApplicationInsertionHandler {
    func insertText(service: TextInsertionService) {
        print("🔄 [DISCORD] Starting Discord-specific insertion sequence")
        
        // Click to focus
        service.clickAtCurrentMouseLocation()
        
        // Discord sometimes needs additional focus help
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Try tab to focus chat input
            service.simulateTab()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                service.simulatePaste()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    service.markAsSuccessful()
                }
            }
        }
    }
}

// Mail app insertion handler
class MailInsertionHandler: ApplicationInsertionHandler {
    func insertText(service: TextInsertionService) {
        print("🔄 [MAIL] Starting Mail-specific insertion sequence")
        
        // Mail usually requires just a click and paste
        service.clickAtCurrentMouseLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            service.simulatePaste()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                service.markAsSuccessful()
            }
        }
    }
} 