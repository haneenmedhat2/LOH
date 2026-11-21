import SwiftUI

struct AuthHeader: View {
    var title: String? = nil
    var showsLanguage = false

    var body: some View {
        HStack {
            if let title {
                Text(title)
                    .font(AppFont.navigationTitle)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer()
                if showsLanguage {
                    AuthLanguageButton()
                }
            }
        }
        .foregroundStyle(AppColor.text)
        .padding(.horizontal, AppSpacing.auth)
        .frame(minHeight: 44)
    }
}

struct AuthLanguageButton: View {
    @EnvironmentObject private var coordinator: AuthCoordinator
    @ObservedObject private var language = AppLanguageManager.shared
    var body: some View {
        Button {
            coordinator.present(.language)
        } label: {
            HStack(spacing: 6) {
                LOHAsset.globe.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(language.isRTL ? "العربية" : "English")
                    .font(AppFont.regular(size: 14))
                LOHAsset.chevronDown.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppColor.surface, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(AppColor.border)
            )
            .frame(minHeight: 44)
        }
        .foregroundStyle(AppColor.text)
    }
}

struct AuthTitle: View {
    let title: String
    let accent: String
    let message: String
    var accentFirst = false
    var body: some View {
        VStack(spacing: 8) {
            (accentFirst
                ? Text(accent)
                    .foregroundColor(AppColor.primary) + Text(" ")
                    + Text(title)
                    .foregroundColor(AppColor.text)
                : Text(title)
                    .foregroundColor(AppColor.text) + Text(" ")
                    + Text(accent)
                    .foregroundColor(AppColor.primary))
                .font(AppFont.heading)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            Text(message)
                .font(AppFont.regular(size: 14))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AuthSecurityNote: View {
    let text: String
    var body: some View {
        HStack(spacing: 8) {
            LOHAsset.shieldCheck.image
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .accessibilityHidden(true)
            Text(text)
                .font(AppFont.regular(size: 13))
        }
        .foregroundStyle(AppColor.mutedText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

struct AuthStepIndicator: View {
    let completed: Bool
    var body: some View {
        HStack(alignment: .top) {
            ForEach(0..<3) { index in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(index < 2 || completed ? AppColor.primary : AppColor.surface)
                        if index == 0 || completed {
                            Image("lohAuthStepCheck")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                        } else {
                            Text("\(index + 1)")
                                .font(AppFont.bold(size: 14))
                                .foregroundStyle(index == 1 ? AppColor.surface : AppColor.mutedText)
                        }
                    }
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .strokeBorder(index == 2 && !completed ? AppColor.border : .clear, lineWidth: 2))
                    Text(["auth.step.account", "auth.step.verify", "auth.step.done"][index].localized)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(index == (completed ? 2 : 1) ? AppColor.primary : AppColor.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 16)
    }
}

/// One backing field preserves paste, SMS AutoFill and backspace across all four cells.
struct AuthCodeInput: View {
    @Binding var code: String
    var hasError = false
    var cellSize: CGFloat = 68
    @FocusState private var focused: Bool
    var body: some View {
        ZStack {
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accessibilityLabel("auth.code".localized)
                .onChange(of: code) { value in
                    let normalized = AuthInput.normalizedDigits(value, limit: 4)
                    if normalized != value {
                        code = normalized
                    }
                }
            HStack(spacing: 12) {
                ForEach(0..<4) { index in
                    Text(index < code.count ? String(Array(code)[index]) : "")
                        .font(AppFont.semiBold(size: 24))
                        .foregroundStyle(AppColor.text)
                        .frame(maxWidth: cellSize)
                        .frame(height: cellSize)
                        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    hasError
                                        ? AppColor.error
                                        : (focused && index == min(code.count, 3) ? AppColor.primary : AppColor.border),
                                    lineWidth: 2))
                }
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
        .frame(height: cellSize)
        .contentShape(Rectangle())
        .onTapGesture {
            focused = true
        }
        .environment(\.layoutDirection, .leftToRight)
    }
}
