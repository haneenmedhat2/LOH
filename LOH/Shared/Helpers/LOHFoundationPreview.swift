#if DEBUG
    import SwiftUI

    /// Review shared foundations without changing the application's navigation.
    struct LOHFoundationPreview: View {
        @State private var name = ""
        @State private var password = ""
        @State private var message = ""
        @State private var digit = ""
        @State private var selected = 0

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.large) {
                    LOHAsset.logo.image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 110, height: 44)
                    Text("آخر ساعة")
                        .font(AppFont.heading)
                    Text("كل يوم… تجربة جديدة بسعر أقل")
                        .font(AppFont.body)
                    HStack(spacing: 12) {
                        ForEach(
                            [AppColor.primary, AppColor.action, AppColor.text, AppColor.success, AppColor.error],
                            id: \.self
                        ) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 36, height: 36)
                        }
                    }
                    VStack(spacing: 12) {
                        MainAppButton(title: "تسجيل الدخول", action: {})
                        MainAppButton(title: "تأكيد الدفع", action: {}, variant: .action, icon: LOHAsset.lock.image)
                        MainAppButton(title: "التصفح كزائر", action: {}, variant: .secondary)
                        MainAppButton(title: "اختيار طريقة أخرى", action: {}, variant: .outlined)
                        MainAppButton(title: "حذف الحساب", action: {}, variant: .destructive)
                        MainAppButton(title: "إنشاء الحساب", action: {}, isEnabled: false)
                        MainAppButton(title: "جاري التحميل", action: {}, isLoading: true)
                    }
                    CardContainer {
                        VStack(spacing: 16) {
                            MainAppTextFieldView(
                                text: $name, title: "الاسم الكامل",
                                placeHolder: "اكتب اسمك الكامل", submitLabel: .next,
                                keyboardType: .default, trailingImage: LOHAsset.person.image)
                            MainAppTextFieldView(
                                text: $password, title: "كلمة المرور",
                                placeHolder: "أدخل كلمة المرور", submitLabel: .done,
                                keyboardType: .default, isSecure: true)
                            MainAppTextFieldView(
                                text: .constant(""), title: "البريد الإلكتروني",
                                placeHolder: "name@example.com", submitLabel: .done,
                                keyboardType: .emailAddress, hasError: true,
                                errorMessage: "يرجى إدخال بريد إلكتروني صحيح")
                            AppTextAreaView(text: $message, title: "تفاصيل المشكلة", placeholder: "اشرح لنا المشكلة")
                        }
                    }
                    HStack {
                        VerificationCodeDigitView(text: $digit, isFocused: true)
                        VerificationCodeDigitView(text: .constant("2"), isFocused: false)
                        VerificationCodeDigitView(text: .constant(""), isFocused: false, hasError: true)
                    }
                    .environment(\.layoutDirection, .leftToRight)
                    SegmentedPicker(
                        selection: $selected, items: [0, 1, 2],
                        titleForItem: {
                            ["الكل", "جاهزة للاستخدام", "تم استخدامها"][$0]
                        })
                    LOHAsset.onboardingDiscover.image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.standard))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 88))], spacing: 16) {
                        ForEach(LOHAsset.allCases, id: \.rawValue) { asset in
                            VStack {
                                asset.image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 70)
                                Text(asset.rawValue)
                                    .font(.caption2)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(AppSpacing.auth)
            }
            .foregroundStyle(AppColor.text)
            .background(AppColor.canvas)
            .tint(AppColor.primary)
        }
    }

    struct LOHFoundationPreview_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                LOHFoundationPreview()
                    .environment(\.layoutDirection, .rightToLeft)
                    .environment(\.locale, Locale(identifier: "ar"))
                    .previewDisplayName("LOH · Arabic")
                LOHFoundationPreview()
                    .environment(\.layoutDirection, .leftToRight)
                    .environment(\.locale, Locale(identifier: "en"))
                    .environment(\.sizeCategory, .accessibilityMedium)
                    .previewDisplayName("LOH · Larger text")
            }
        }
    }
#endif
