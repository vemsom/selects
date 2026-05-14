import SwiftUI

struct ScrollWheelCapture: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> NSView {
        CaptureView(onScroll: onScroll)
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

final class CaptureView: NSView {
    let onScroll: (CGFloat) -> Void

    init(onScroll: @escaping (CGFloat) -> Void) {
        self.onScroll = onScroll
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) { nil }

    override func scrollWheel(with event: NSEvent) {
        guard abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) else { return }
        if event.scrollingDeltaX > 20 {
            onScroll(-1)
        } else if event.scrollingDeltaX < -20 {
            onScroll(1)
        }
    }
}
