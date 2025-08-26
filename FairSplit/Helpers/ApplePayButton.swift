import SwiftUI

#if canImport(PassKit)
import PassKit

struct ApplePayButton: UIViewRepresentable {
    var type: PKPaymentButtonType = .plain
    var style: PKPaymentButtonStyle = .black
    var action: () -> Void

    func makeUIView(context: Context) -> PKPaymentButton {
        let button = PKPaymentButton(paymentButtonType: type, paymentButtonStyle: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.onTap), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: PKPaymentButton, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(action: action) }

    final class Coordinator: NSObject {
        let action: () -> Void
        init(action: @escaping () -> Void) { self.action = action }
        @objc func onTap() { action() }
    }
}
#endif

