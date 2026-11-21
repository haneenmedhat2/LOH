import SwiftUI
import Kingfisher

struct PhoneTextView<Country: CountryCodeModel>: View {
    let title: String
    let placeHolder: String
    @Binding var phone: String
    @Binding var selectedCountry: Country?
    @Binding var forceValidate: Bool
    let hasError: Bool
    let errorMessage: String
    let items: [Country]
    let leadingIcon: Image?
    let height: CGFloat
    let radius: CGFloat
    var showsCountryFlag = false
    @State private var showSheet = false
    @State private var isFocused = false
    @ScaledMetric(relativeTo: .body) private var minimumHeight = AppMetrics.fieldHeight

    init(
        title: String, placeHolder: String, phone: Binding<String>, selectedCountry: Binding<Country?>,
        forceValidate: Binding<Bool>, hasError: Bool, errorMessage: String = "",
        items: [Country], leadingIcon: Image? = nil, height: CGFloat = AppMetrics.fieldHeight,
        radius: CGFloat = AppRadius.standard
    ) {
        self.title = title
        self.placeHolder = placeHolder
        self._phone = phone
        self._selectedCountry = selectedCountry
        self._forceValidate = forceValidate
        self.hasError = hasError
        self.errorMessage = errorMessage
        self.items = items
        self.leadingIcon = leadingIcon
        self.height = height
        self.radius = radius
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Text(title.localized)
                .font(AppFont.fieldLabel)
                .foregroundStyle(AppColor.text)
            HStack(spacing: 0) {
                Button {
                    showSheet = true
                } label: {
                    HStack(spacing: AppSpacing.xxs) {
                        if showsCountryFlag {
                            KFImage(AppServices.remoteURL(selectedCountry?.image ?? ""))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 25, height: 18)
                        }
                        Text(selectedCountry?.countryCode ?? "+--")
                            .font(AppFont.regular(size: 15))
                        Image("lohChevronDown")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 14, height: 14)
                    }
                    .padding(.horizontal, AppSpacing.medium)
                    .frame(minHeight: AppMetrics.touchTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppColor.text)
                .accessibilityLabel("Country code".localized)
                Rectangle()
                    .fill(AppColor.border)
                    .frame(width: 1, height: 28)
                    .accessibilityHidden(true)
                PhoneNumberInput(
                    text: $phone, placeholder: placeHolder,
                    onFocusChange: {
                        isFocused = $0
                    }
                )
                .frame(height: max(height, minimumHeight))
                .padding(.horizontal, AppSpacing.medium)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(title.localized)
                if let leadingIcon {
                    leadingIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .padding(.trailing, AppSpacing.standard)
                        .accessibilityHidden(true)
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(height: max(height, minimumHeight))
            .background(AppColor.surface, in: RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .strokeBorder(
                        hasError ? AppColor.error : (isFocused ? AppColor.primary : AppColor.border), lineWidth: 1))
            if hasError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(AppColor.error)
            }
        }
        .sheet(isPresented: $showSheet) {
            CountryPickerSheetView(title: "Select Country".localized, items: items, selected: $selectedCountry)
                .tint(AppColor.primary)
                .presentationCornerRadius(AppRadius.sheet)
        }
        .onChange(of: selectedCountry) { country in
            if country != nil {
                forceValidate = false
            }
        }
    }
}
