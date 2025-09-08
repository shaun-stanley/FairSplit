import SwiftUI

struct OnboardingView: View {
    var onDone: () -> Void

    @State private var selection = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                pageWelcome.tag(0)
                pagePrivacy.tag(1)
                pageGetStarted.tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .background(Color(.systemBackground))
    }

    private var pageWelcome: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Welcome to FairSplit")
                .font(.largeTitle).bold()
            Text("Track shared expenses with clarity. Log who paid, split fairly, and settle up with confidence.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Spacer()
            buttonNext
        }
        .padding()
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    private var pagePrivacy: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Privacy & Control")
                .font(.title).bold()
            VStack(alignment: .leading, spacing: 8) {
                labelRow("On-device first. No tracking.", "iphone")
                labelRow("Optional Face ID lock in Settings.", "faceid")
                labelRow("iCloud Sync is optional.", "icloud")
            }
            .frame(maxWidth: 480, alignment: .leading)
            .foregroundStyle(.secondary)
            Spacer()
            buttonNext
        }
        .padding()
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    private var pageGetStarted: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Get Started")
                .font(.title).bold()
            VStack(alignment: .leading, spacing: 8) {
                labelRow("Add your first expense from the + menu.", "plus.circle")
                labelRow("See who pays whom in Settle Up.", "arrow.right.circle")
                labelRow("Understand spending in Reports.", "chart.bar")
            }
            .frame(maxWidth: 480, alignment: .leading)
            .foregroundStyle(.secondary)
            Spacer()
            Button(action: onDone) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .contentMargins(.horizontal, 20, for: .scrollContent)
    }

    private var buttonNext: some View {
        Button {
            withAnimation(.snappy) { selection = min(selection + 1, 2) }
        } label: {
            HStack(spacing: 8) {
                Text(selection < 2 ? "Next" : "Done")
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel(selection < 2 ? "Next" : "Done")
    }

    private func labelRow(_ text: String, _ icon: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(text)
        }
    }
}

#Preview {
    OnboardingView(onDone: {})
}
