import SwiftUI

struct AccountSuccessView: View {
    @EnvironmentObject private var coordinator: AuthCoordinator
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = AccountSuccessViewModel()

    private var user: User? { UserDefaults.user }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                AuthHeader(title: "auth.verifyPhone".localized)
                AuthStepIndicator(completed: true)
                celebration
                VStack(spacing: 16) {
                    AuthTitle(
                        title: "auth.success.title".localized, accent: "auth.success.accent".localized,
                        message: "auth.success.message".localized)
                    profileCard
                    notificationCard
                    MainAppButton(
                        title: "auth.explore".localized, action: requestNotifications,
                        isLoading: viewModel.requestingPermission)
                    Button("auth.later".localized) {
                        coordinator.showLocation()
                    }
                    .disabled(viewModel.requestingPermission)
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.primary)
                    .frame(minHeight: 44)
                    AuthSecurityNote(text: "auth.readySecure".localized)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .task {
            await viewModel.refreshPermission()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Task {
                    await viewModel.refreshPermission()
                }
            }
        }
        .alert(
            "Error".localized,
            isPresented: Binding(
                get: {
                    viewModel.permissionError != nil
                },
                set: {
                    if !$0 {
                        viewModel.permissionError = nil
                    }
                })
        ) {
            Button("OK", role: .cancel) {
                viewModel.permissionError = nil
            }
        } message: {
            Text(viewModel.permissionError ?? "")
        }
    }

    private func requestNotifications() {
        Task {
            await viewModel.enableNotifications()
            coordinator.showLocation()
        }
    }

    private var celebration: some View {
        ZStack {
            LOHAsset.successIllustration.image
                .resizable()
                .scaledToFit()
            GeometryReader { geometry in
                let scale = geometry.size.width / 390
                ForEach(
                    Array(
                        [
                            (59.0, 16.0, 8.0), (127, 9, 8), (292, 21, 8), (331, 47, 7),
                            (49, 98, 6), (319, 114, 10), (271, 134, 8)
                        ]
                        .enumerated()), id: \.offset
                ) { index, dot in
                    Circle()
                        .fill(index == 1 || index == 4 || index == 6 ? AppColor.success : AppColor.primary)
                        .frame(width: dot.2 * scale, height: dot.2 * scale)
                        .position(x: dot.0 * scale, y: dot.1 * scale)
                }
                Image("lohAuthCelebrationCard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 59 * scale, height: 36 * scale)
                    .position(x: 241 * scale, y: 139 * scale)
            }
        }
        .aspectRatio(390 / 160, contentMode: .fit)
        .frame(maxWidth: 390)
        .accessibilityHidden(true)
    }

    private var profileCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(user?.name ?? "auth.account".localized)
                    .font(AppFont.bold(size: 16))
                Text("+\((user?.countryCode ?? "").trimmedPlus) \(user?.phone ?? "")")
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
                    .environment(\.layoutDirection, .leftToRight)
                HStack(spacing: 4) {
                    Image("lohAuthVerified")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                    Text("auth.verified".localized)
                        .font(AppFont.caption)
                        .foregroundStyle(AppColor.success)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image("lohAuthAvatar")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .frame(width: 56, height: 56)
                .background(Color(red: 249 / 255, green: 213 / 255, blue: 197 / 255), in: Circle())
        }
        .padding(16)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border.opacity(0.5)))
    }

    private var notificationCard: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("auth.notifications.title".localized)
                    .font(AppFont.bold(size: 14))
                    .foregroundStyle(AppColor.primary)
                Text("auth.notifications.message".localized)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.secondaryText)
                Button(action: requestNotifications) {
                    Text((viewModel.notificationsEnabled ? "auth.enabled" : "auth.enableNow").localized)
                        .font(AppFont.medium(size: 12))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(AppColor.primary))
                }
                .foregroundStyle(AppColor.primary)
                .disabled(viewModel.notificationsEnabled || viewModel.requestingPermission)
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image("lohAuthBell")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .frame(width: 48)
        }
        .padding(16)
        .background(Color(red: 1, green: 245 / 255, blue: 242 / 255), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.error.opacity(0.15)))
    }
}
