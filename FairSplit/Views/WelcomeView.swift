import SwiftUI

struct WelcomeView: View {
    var onFinish: () -> Void

    @State private var page: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $page) {
                    welcomePage
                        .tag(0)
                    privacyPage
                        .tag(1)
                    getStartedPage
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { onFinish() }
                        .accessibilityLabel("Skip welcome")
                }
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button("Back") {
                            withAnimation { page = max(0, page - 1) }
                        }
                        .disabled(page == 0)

                        Spacer()

                        if page < 2 {
                            Button("Next") {
                                withAnimation { page = min(2, page + 1) }
                            }
                        } else {
                            Button(action: onFinish) {
                                HStack { Image(systemName: "hand.thumbsup.fill"); Text("Continue") }
                            }
                        }
                    }
                }
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3.fill").font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .padding(.top, 24)
            Text("Welcome to FairSplit")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Split expenses fairly with friends, trips, and roommates.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }

    private var privacyPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield").font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .padding(.top, 24)
            Text("Your data, your control")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("No accounts. Data stays on your device. You can turn on iCloud sync in Settings any time.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }

    private var getStartedPage: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle").font(.system(size: 48))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .padding(.top, 24)
            Text("Get started")
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text("Create a group, add people, and log your first expense.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }

    // Bottom controls are provided via toolbar(.bottomBar) for native look.
}

#Preview {
    WelcomeView(onFinish: {})
}
