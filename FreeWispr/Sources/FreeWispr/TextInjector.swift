import AppKit
import ApplicationServices

class TextInjector {

    func injectText(_ text: String) {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let element = focusedElement else {
            injectViaKeyboard(text)
            return
        }

        let axElement = element as! AXUIElement

        // Try inserting at cursor via selected text attribute
        let setResult = AXUIElementSetAttributeValue(
            axElement,
            kAXSelectedTextAttribute as CFString,
            text as CFString
        )

        if setResult != .success {
            injectViaKeyboard(text)
        }
    }

    private func injectViaKeyboard(_ text: String) {
        let source = CGEventSource(stateID: .hidSystemState)

        for character in text {
            let utf16 = Array(String(character).utf16)
            guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
                continue
            }
            keyDown.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyUp.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyDown.post(tap: .cgAnnotatedSessionEventTap)
            keyUp.post(tap: .cgAnnotatedSessionEventTap)
        }
    }
}
