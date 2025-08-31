import SwiftUI

// Compatibility shim for future inline-large title behavior.
// Mirrors sample usage: .toolbarTitleDisplayMode(.inlineLarge)
public enum ToolbarTitleDisplayModeCompat {
    case inlineLarge
}

public struct InlineLargeTitleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        // Best-effort approximation on current SDKs:
        // - Use large title (collapses on scroll)
        // - Keep any trailing items in top bar for inline appearance
        content.navigationBarTitleDisplayMode(.large)
    }
}

public extension View {
    func toolbarTitleDisplayMode(_ mode: ToolbarTitleDisplayModeCompat) -> some View {
        switch mode {
        case .inlineLarge:
            return self.modifier(InlineLargeTitleModifier())
        }
    }
}

