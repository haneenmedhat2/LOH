import SwiftUI

struct SettingsIcon: View {
    let name: String
    var width: CGFloat = 18
    var height: CGFloat? = nil
    var body: some View {
        Image("lohSettings" + name)
            .resizable()
            .scaledToFit()
            .frame(width: width, height: height ?? width)
            .accessibilityHidden(true)
    }
}

struct SettingsRow: View {
    let title: String
    var subtitle = ""
    let icon: String
    var value = ""
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                SettingsIcon(name: icon)
                    .frame(width: 32, height: 32)
                    .background(AppColor.accountCanvas, in: RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.medium(size: 13))
                        .foregroundStyle(AppColor.text)
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(AppFont.regular(size: 11))
                            .foregroundStyle(AppColor.secondaryText)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if !value.isEmpty {
                    Text(value)
                        .font(AppFont.regular(size: 12))
                        .foregroundStyle(AppColor.secondaryText)
                }
                SettingsIcon(name: "Arrow", width: 16)
                    .scaleEffect(x: AppLang.isRTL ? 1 : -1, y: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SettingsPasswordField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var current = false
    @State private var visible = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.bold(size: 13))
            HStack(spacing: 8) {
                SettingsIcon(name: "FieldLock", width: 15)
                CustomTextField(
                    text: $text, placeholder: placeholder, isSecure: !visible,
                    contentType: current ? .password : .newPassword
                )
                .accessibilityLabel(title)
                Button {
                    visible.toggle()
                } label: {
                    SettingsIcon(name: "Eye", width: 15)
                        .frame(width: 32, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityLabel((visible ? "Hide password" : "Show password").localized)
            }
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .frame(minHeight: 42)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColor.border))
        }
    }
}

struct SettingsWarning: View {
    let title: String
    let message: String
    var large = false
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            SettingsIcon(name: large ? "OTPWarning" : "Warning", width: large ? 20 : 16)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.extraBold(size: large ? 14 : 12))
                Text(message)
                    .font(AppFont.regular(size: large ? 13 : 11))
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Color(red: 180 / 255, green: 83 / 255, blue: 9 / 255))
        .padding(large ? 16 : 12)
        .background(Color(red: 1, green: 248 / 255, blue: 230 / 255), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(red: 1, green: 217 / 255, blue: 125 / 255)))
    }
}

struct SettingsLanguageIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.83, blue: 0.69), AppColor.primary], startPoint: .topLeading,
                        endPoint: .bottomTrailing)
                )
                .frame(width: 56, height: 56)
            SettingsIcon(name: "LanguageGlobe", width: 28)
            languageTile("A")
                .offset(x: -28, y: -22)
            languageTile("ع")
                .offset(x: 32, y: 22)
        }
        .frame(width: 80, height: 64)
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }
    private func languageTile(_ text: String) -> some View {
        Text(text)
            .font(AppFont.bold(size: 14))
            .frame(width: 32, height: 28)
            .background(.white)
            .overlay(
                Rectangle()
                    .stroke(AppColor.border.opacity(0.5))
            )
            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
    }
}
