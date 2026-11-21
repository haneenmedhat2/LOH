import SwiftUI

enum AccountFlowColor {
    static let iconSurface = Color(red: 1, green: 245 / 255, blue: 242 / 255)
    static let supportSurface = Color(red: 232 / 255, green: 65 / 255, blue: 33 / 255).opacity(0.1)
}

/// Components shared by the notification, support and partnership Figma flows.
struct AccountFlowIcon: View {
    let name: String
    var size: CGFloat = 18
    var body: some View {
        Image("lohFlow" + name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

struct AccountFlowIntro: View {
    let title: String
    let subtitle: String
    let icon: String
    var compact = false
    var body: some View {
        HStack(spacing: 12) {
            AccountFlowIcon(name: icon, size: compact ? 18 : icon == "SupportHero" ? 30 : 28)
                .frame(width: compact ? 36 : 56, height: compact ? 36 : 56)
                .background(AppColor.primary, in: RoundedRectangle(cornerRadius: compact ? 12 : 16))
            VStack(alignment: .leading, spacing: compact ? 2 : 6) {
                Text(title)
                    .font(AppFont.bold(size: compact ? 14 : 16))
                Text(subtitle)
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, compact ? 12 : 16)
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct AccountFlowLabel: View {
    let title: String
    var required = false
    var body: some View {
        HStack(spacing: 3) {
            Text(title)
                .foregroundStyle(AppColor.text)
            if required {
                Text("*")
                    .foregroundStyle(AppColor.primary)
            }
        }
        .font(AppFont.medium(size: 13))
    }
}

struct AccountFlowField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var icon: String? = nil
    var required = true
    var height: CGFloat = 46
    var keyboard: UIKeyboardType = .default
    var error: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AccountFlowLabel(title: title, required: required)
            HStack(spacing: 12) {
                if let icon {
                    AccountFlowIcon(name: icon, size: 16)
                }
                if keyboard == .phonePad {
                    AccountPhoneTextInput(text: $text, placeholder: placeholder, title: title)
                        .frame(maxWidth: .infinity, minHeight: 24)
                } else {
                    TextField(placeholder, text: $text)
                        .font(AppFont.regular(size: 13))
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                        .autocorrectionDisabled()
                        .environment(
                            \.layoutDirection,
                            keyboard == .emailAddress ? .leftToRight : AppLanguageManager.shared.layoutDirection
                        )
                        .accessibilityLabel(title)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: height)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(error == nil ? AppColor.border : AppColor.error))
            if let error {
                Text(error)
                    .font(AppFont.regular(size: 11))
                    .foregroundStyle(AppColor.error)
            }
        }
    }
}

struct AccountFlowSelect: View {
    let title: String
    let placeholder: String
    @Binding var selection: String
    let options: [(String, String)]
    var icon: String? = nil
    var required = false
    var height: CGFloat = 66
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AccountFlowLabel(title: title, required: required)
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    if let icon {
                        AccountFlowIcon(name: icon)
                            .frame(width: 36, height: 36)
                            .background(AccountFlowColor.iconSurface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    Text(selection.isEmpty ? placeholder : options.first(where: { $0.0 == selection })?.1 ?? placeholder)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(selection.isEmpty ? AppColor.mutedText : AppColor.text)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    AccountFlowIcon(name: "Down", size: 18)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .frame(minHeight: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColor.border))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(title)
            .accessibilityValue(selection.isEmpty ? placeholder : selection)
            .overlay(alignment: .top) {
                if expanded {
                    optionsList
                        .offset(y: height + 8)
                }
            }
        }
        .zIndex(expanded ? 10 : 0)
    }
    private var optionsList: some View {
        VStack(spacing: 0) {
            if options.isEmpty {
                Text("accountFlow.No orders available".localized)
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
                    .padding(16)
            }
            ForEach(options, id: \.0) { option in
                Button {
                    selection = option.0
                    expanded = false
                } label: {
                    Text(option.1)
                        .font(AppFont.regular(size: 13))
                        .foregroundStyle(AppColor.text)
                        .frame(maxWidth: .infinity, minHeight: 49, alignment: .leading)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(.plain)
                if option.0 != options.last?.0 {
                    Divider()
                }
            }
        }
        .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(AppColor.border)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, y: 3)
    }
}

struct AccountFlowSummaryRow: View {
    let title: String
    let value: String
    let icon: String
    var body: some View {
        HStack(spacing: 12) {
            AccountFlowIcon(name: icon)
                .frame(width: 40, height: 40)
                .background(AccountFlowColor.iconSurface, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.regular(size: 12))
                    .foregroundStyle(AppColor.secondaryText)
                Text(value)
                    .font(AppFont.bold(size: 14))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
    }
}

struct AccountFlowReference: View {
    let title: String
    let reference: String
    var centered = false
    @State private var copied = false
    var body: some View {
        VStack(alignment: centered ? .center : .leading, spacing: 8) {
            Text(title)
                .font(AppFont.regular(size: 13))
                .foregroundStyle(AppColor.secondaryText)
            Button {
                UIPasteboard.general.string = reference
                copied = true
            } label: {
                HStack(spacing: 8) {
                    Text(reference)
                        .font(.system(size: centered ? 20 : 18, weight: .bold))
                    AccountFlowIcon(name: centered ? "SuccessCopy" : "Copy", size: centered ? 16 : 14)
                }
                .foregroundStyle(AppColor.text)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("accountFlow.Copy reference".localized)
            .accessibilityValue(copied ? "accountFlow.Copied".localized : reference)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
        .padding(.bottom, 16)
    }
}

struct AccountFlowSuccess<Content: View>: View {
    let title: String
    let subtitle: String
    var ticket = false
    @ViewBuilder var content: Content
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                AccountFlowCelebration(ticket: ticket)
                Text(title)
                    .font(AppFont.black(size: 26))
                    .multilineTextAlignment(.center)
                Text(subtitle)
                    .font(AppFont.regular(size: 15))
                    .foregroundStyle(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 12)
                content
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(
            AppColor.canvas
                .ignoresSafeArea()
        )
        .font(AppFont.regular(size: 14))
        .foregroundStyle(AppColor.text)
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
    }
}

struct AccountFlowCelebration: View {
    var ticket = false
    var body: some View {
        ZStack {
            if ticket {
                LOHAsset.ticketSuccess.image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 208, height: 128)
                    .overlay(alignment: .leading) {
                        Circle()
                            .fill(AppColor.canvas)
                            .frame(width: 24, height: 24)
                            .offset(x: -12, y: -12)
                    }
                    .overlay(alignment: .trailing) {
                        Circle()
                            .fill(AppColor.canvas)
                            .frame(width: 24, height: 24)
                            .offset(x: 12, y: -12)
                    }
                    .overlay(alignment: .bottom) {
                        AccountFlowIcon(name: "SuccessCheck", size: 22)
                            .frame(width: 40, height: 40)
                            .background(AppColor.success, in: Circle())
                            .padding(4)
                            .background(AppColor.canvas, in: Circle())
                            .offset(y: 20)
                    }
                ForEach(0..<3) { index in
                    AccountFlowIcon(name: "Sparkle", size: 12)
                        .offset(x: [111.0, -119.0, 151.0][index], y: [-30.0, 25.0, 95.0][index])
                }
            } else {
                // The current join-success frame contains this flat store placeholder.
                Rectangle()
                    .fill(Color(red: 240 / 255, green: 224 / 255, blue: 200 / 255))
                    .frame(width: 144, height: 96)
                    .offset(y: 24)
            }
            ForEach(0..<(ticket ? 8 : 3), id: \.self) { index in
                Circle()
                    .fill([AppColor.primary, AppColor.success, Color(red: 1, green: 0.83, blue: 0.76)][index % 3])
                    .frame(width: [10.0, 8, 8, 10, 7, 7, 6, 6][index], height: [10.0, 8, 8, 10, 7, 7, 6, 6][index])
                    .offset(
                        x: ticket ? [-156.0, -111, 149, 170, -141, 179, -92, 128][index] : [-80.0, -40, -85][index],
                        y: ticket ? [-31.0, -72, -52, 8, 58, 68, 107, 117][index] : [-44.0, -70, 46][index])
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: ticket ? 200 : 164)
        .accessibilityHidden(true)
    }
}
