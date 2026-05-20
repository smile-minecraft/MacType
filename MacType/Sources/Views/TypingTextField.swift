import SwiftUI
import AppKit

/// 包裝 NSView 來捕捉鍵盤按下事件並回呼 SwiftUI
struct KeyboardCaptureView: NSViewRepresentable {
    var onKeyDown: ((String) -> Void)?
    var onBackspace: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(onKeyDown: onKeyDown, onBackspace: onBackspace)
    }

    func makeNSView(context: Context) -> CaptureNSView {
        let view = CaptureNSView()
        view.coordinator = context.coordinator
        return view
    }

    func updateNSView(_ nsView: CaptureNSView, context: Context) {
        nsView.coordinator = context.coordinator
    }

    class Coordinator {
        var onKeyDown: ((String) -> Void)?
        var onBackspace: (() -> Void)?

        init(onKeyDown: ((String) -> Void)?, onBackspace: (() -> Void)?) {
            self.onKeyDown = onKeyDown
            self.onBackspace = onBackspace
        }
    }
}

class CaptureNSView: NSView {
    weak var coordinator: KeyboardCaptureView.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        // Backspace
        if event.keyCode == 51 || event.charactersIgnoringModifiers == "\u{7F}" {
            coordinator?.onBackspace?()
            return
        }

        // 取得一般字元（shift + letter -> 大寫字母，其他不處理複雜修飾）
        if let chars = event.characters, let char = chars.first {
            // 忽略修飾鍵 alone（command/option/control 不單獨當輸入）
            if event.modifierFlags.contains(.command) ||
               event.modifierFlags.contains(.control) ||
               event.modifierFlags.contains(.option) {
                // 組合鍵不當打字輸入
                return
            }
            coordinator?.onKeyDown?(String(char))
        }
    }
}