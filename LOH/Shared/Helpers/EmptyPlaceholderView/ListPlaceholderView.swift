import SwiftUI

struct ListPlaceholderView: View {
    struct Action: Identifiable {
        let id = UUID()
        let title: String
        let action: () -> Void
    }
    let imageName: String?
    let title: String?
    let message: String?
    let actions: [Action]
    var imageSize: CGFloat = 160

    init(
        imageName: String? = nil, title: String? = nil, message: String? = nil,
        actions: [Action] = []
    ) {
        self.imageName = imageName
        self.title = title
        self.message = message
        self.actions = actions
    }

    var body: some View {
        VStack(spacing: AppSpacing.standard) {
            if let imageName, !imageName.isEmpty {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
                    .accessibilityHidden(true)
            }
            if let title, !title.isEmpty {
                Text(title)
                    .font(AppFont.extraBold(size: 22))
                    .foregroundStyle(AppColor.text)
                    .multilineTextAlignment(.center)
            }
            if let message, !message.isEmpty {
                Text(message)
                    .font(AppFont.body)
                    .foregroundStyle(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: AppSpacing.medium) {
                ForEach(Array(actions.enumerated()), id: \.element.id) { index, item in
                    MainAppButton(
                        title: item.title, action: item.action,
                        variant: index == 0 ? .action : .outlined)
                }
            }
            .padding(.top, AppSpacing.small)
        }
        .padding(AppSpacing.large)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
extension View {
    @ViewBuilder
    func emptyPlaceholder(
        isEmpty: Bool, style: ListPlaceholderStyle,
        onPrimaryAction: (() -> Void)? = nil
    ) -> some View {
        if isEmpty {
            ListPlaceholderView(style: style, primaryAction: onPrimaryAction)
        } else {
            self
        }
    }
}
