import SwiftUI

struct AccountTextArea: View {
    let title: String
    @Binding var text: String
    var limit = 1000
    var placeholder = ""
    var required = false
    var showsCount = true
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AccountFlowLabel(title: title, required: required)
            VStack(spacing: 4) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(AppFont.regular(size: 13))
                            .padding(.top, 8)
                            .padding(.horizontal, 5)
                            .allowsHitTesting(false)
                    }
                    TextEditor(text: $text)
                        .font(AppFont.regular(size: 13))
                        .frame(height: 107)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel(title)
                }
                if showsCount {
                    Text("\(text.count)/\(limit)")
                        .font(.system(size: 11))
                        .foregroundStyle(AppColor.mutedText)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 14)
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(AppColor.border))
        }
        .onChange(of: text) { value in
            text = String(value.prefix(limit))
        }
    }
}
