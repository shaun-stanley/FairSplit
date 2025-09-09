import SwiftUI

/// Wraps an update in a spring animation unless Reduce Motion is enabled.
func withSpringIfAllowed(_ reduceMotion: Bool, _ body: () -> Void) {
    if reduceMotion { body() } else { withAnimation(AppAnimations.spring, body) }
}

extension View {
    /// Applies the default spring animation unless Reduce Motion is enabled.
    func springAnimationIfAllowed<T: Equatable>(_ reduceMotion: Bool, value: T) -> some View {
        self.animation(reduceMotion ? nil : AppAnimations.spring, value: value)
    }
}

