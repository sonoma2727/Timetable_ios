import SwiftUI

struct RootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if !model.initialized {
                ProgressView()
            } else if model.needLogin {
                LoginView()
            } else {
                MainTabView()
            }
        }
        .overlay(alignment: .top) {
            if let notice = model.notice {
                NoticePill(text: notice)
                    .task(id: notice) {
                        try? await Task.sleep(nanoseconds: 2_600_000_000)
                        if model.notice == notice {
                            model.clearNotice()
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: model.notice)
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                model.refreshIfStale()
            }
        }
    }
}

struct NoticePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.accentColor.opacity(0.14))
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
            )
            .foregroundColor(.primary)
    }
}
