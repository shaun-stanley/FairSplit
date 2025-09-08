import SwiftUI

/// Applies horizontal content margins that align scrollable content with the
/// system navigation bar title, adapting to size class and Dynamic Type.
/// - Compact widths (iPhone): 16pt
/// - Regular widths (iPad/landscape): 20pt
/// - Accessibility text sizes on compact widths: bump to 20pt for comfort
struct SystemAlignedScrollMargins: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontal
    @Environment(\.dynamicTypeSize) private var dts

    private var margin: CGFloat {
        let base: CGFloat = (horizontal == .regular) ? 20 : 16
        if horizontal != .regular, dts.isAccessibilitySize { return 20 }
        return base
    }

    func body(content: Content) -> some View {
        content.contentMargins(.horizontal, margin, for: .scrollContent)
    }
}

private extension DynamicTypeSize {
    var isAccessibilitySize: Bool {
        switch self {
        case .accessibility1, .accessibility2, .accessibility3, .accessibility4, .accessibility5:
            return true
        default:
            return false
        }
    }
}

extension View {
    /// Aligns scroll content with the large title using system-appropriate margins.
    func systemAlignedScrollContentMargins() -> some View {
        modifier(SystemAlignedScrollMargins())
    }
}

