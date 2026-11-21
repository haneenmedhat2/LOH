import SwiftUI

struct ProfileDetailRow: View {
    let title: String
    let value: String
    let icon: LOHAsset
    var accessory: LOHAsset? = nil
    var isPhone = false
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                profileIcon(icon, size: 14)
                if let accessory {
                    profileIcon(accessory, size: accessory == .profileEdit ? 15 : 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(AppFont.medium(size: 13))
                .foregroundStyle(AppColor.text)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .environment(\.layoutDirection, isPhone ? .leftToRight : layoutDirection)
            Text(title)
                .font(AppFont.regular(size: 12))
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 40)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
    @Environment(\.layoutDirection) private var layoutDirection
}

@ViewBuilder
func cityPicker(selection: Binding<String>) -> some View {
    Picker("more.City".localized, selection: selection) {
        Text("more.Riyadh".localized)
            .tag("Riyadh")
        Text("more.Jeddah".localized)
            .tag("Jeddah")
        Text("more.Dammam".localized)
            .tag("Dammam")
        Text("more.Makkah".localized)
            .tag("Makkah")
        Text("more.Madinah".localized)
            .tag("Madinah")
    }
    .tint(AppColor.primary)
}
