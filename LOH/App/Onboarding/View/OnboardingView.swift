import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @ObservedObject private var language = AppLanguageManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            header
            if viewModel.isLoading {
                BrandLoaderView(size: 72)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Text(error)
                        .font(AppFont.body)
                        .multilineTextAlignment(.center)
                    Button("api.retry".localized) {
                        Task {
                            await viewModel.load(language: language.selectedLanguage)
                        }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.pages.isEmpty {
                Spacer()
                MainAppButton(title: "onboarding.start".localized, action: onFinish)
                    .padding(20)
            } else {
                TabView(selection: $viewModel.selectedPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .environment(\.layoutDirection, language.layoutDirection)
                            .scaleEffect(x: language.isRTL ? -1 : 1, y: 1)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .environment(\.layoutDirection, .leftToRight)
                .scaleEffect(x: language.isRTL ? -1 : 1, y: 1)
                .id(language.selectedLanguage)
                footer
            }
        }
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .toolbar(.hidden, for: .navigationBar)
        .task(id: language.selectedLanguage) {
            await viewModel.load(language: language.selectedLanguage)
        }
    }

    private var header: some View {
        HStack {
            Button(action: onFinish) {
                Text("onboarding.skip")
                    .font(AppFont.button)
                    .foregroundStyle(AppColor.text)
                    .frame(minWidth: AppMetrics.touchTarget, minHeight: AppMetrics.touchTarget)
            }
            .accessibilityIdentifier("onboarding.skip")
            Spacer()
            LOHAsset.logo.image
                .resizable()
                .scaledToFit()
                .frame(width: 68, height: 26)
                .accessibilityLabel("LOH")
        }
        .environment(\.layoutDirection, .leftToRight)
        .padding(.horizontal, AppSpacing.auth)
        .frame(minHeight: AppMetrics.touchTarget)
    }

    private var footer: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.small) {
                ForEach(viewModel.pages.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == viewModel.selectedPage ? AppColor.primary : AppColor.pageIndicator)
                        .frame(width: index == viewModel.selectedPage ? 20 : 8, height: 8)
                }
            }
            .environment(\.layoutDirection, language.layoutDirection)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("onboarding.progress"))
            .accessibilityValue("\(viewModel.selectedPage + 1) / \(viewModel.pages.count)")
            .padding(.bottom, AppSpacing.standard)

            MainAppButton(title: (viewModel.isLastPage ? "onboarding.start" : "onboarding.next").localized) {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
                    if viewModel.advance() {
                        onFinish()
                    }
                }
            }
            .accessibilityIdentifier("onboarding.next")

            HStack(spacing: 2) {
                Text("onboarding.haveAccount")
                    .font(AppFont.regular(size: 14))
                Button(action: onFinish) {
                    Text("onboarding.login")
                        .font(AppFont.button)
                        .foregroundStyle(AppColor.primary)
                        .frame(minHeight: AppMetrics.touchTarget)
                }
                .accessibilityIdentifier("onboarding.login")
            }
            .foregroundStyle(AppColor.text)
            .frame(minHeight: AppMetrics.touchTarget)
            .padding(.top, AppSpacing.xxs)
        }
        .padding(.horizontal, AppSpacing.auth)
        .padding(.top, AppSpacing.small)
    }
}
