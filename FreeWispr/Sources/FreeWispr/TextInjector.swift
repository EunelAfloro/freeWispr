import AppKit
import ApplicationServices

class TextInjector {

    func injectText(_ text: String) {
        // Use clipboard paste — works universally (terminals, editors, web apps)
        let pasteboard = NSPasteboard.general

        // Save all pasteboard items, not just the string type, so rich content
        // (images, file references, multiple types) survives the round-trip.
        let savedItems: [NSPasteboardItem] = pasteboard.pasteboardItems?.compactMap { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    copy.setData(data, forType: type)
                }
            }
            return copy
        } ?? []

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        let changeCountAfterSet = pasteboard.changeCount

        // Simulate Cmd+V
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 9

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        // Restore previous clipboard after paste completes.
        // Only restore if nothing else has touched the clipboard since we set it.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard pasteboard.changeCount == changeCountAfterSet else { return }
            pasteboard.clearContents()
            if !savedItems.isEmpty {
                pasteboard.writeObjects(savedItems)
            }
        }
    }
}
