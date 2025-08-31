import SwiftUI

public extension View {
  /// Apple Music–style navigation title with strict OS gating.
  @ViewBuilder
  func appleMusicNavTitle(_ title: String) -> some View {
    if #available(iOS 26, *) {
      // Native API on iOS 26
      self
        .navigationTitle(title)
        .toolbarTitleDisplayMode(.inlineLarge)
    } else {
      // Preserve our current look on iOS 18–25.
      // Mirror EXACTLY what we do today (do not remove spacing tweaks).
      self
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        // Keep our existing list mods near call sites:
        // .listStyle(.insetGrouped)
        // .listSectionSpacing(.compact)
        // .contentMargins(.top, 4)
    }
  }
}

