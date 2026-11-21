import SwiftUI

struct AddPaymentCardView: View {
    @EnvironmentObject private var requests: AccountRequestController
    @EnvironmentObject private var account: PaymentCardViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AddPaymentCardViewModel
    @State private var focusedField: AddPaymentCardField?
    private var defaultCard: AccountCard? { viewModel.defaultCard }

    init(defaultCard: AccountCard? = nil) {
        _viewModel = StateObject(wrappedValue: AddPaymentCardViewModel(defaultCard: defaultCard))
    }

    var body: some View {
        AccountPage(
            title: (defaultCard == nil ? "more.Add a new card" : "more.Set as default card").localized, headerHeight: 56
        ) {
            CardContainer(padding: 12) {
                HStack(spacing: 12) {
                    profileIcon(.paymentFormShield, size: 16)
                        .frame(width: 32, height: 32)
                        .background(AppColor.primary, in: RoundedRectangle(cornerRadius: 12))
                    Text(
                        defaultCard.map { String(format: "payments.confirmDefaultHint".localized, $0.lastFour) }
                            ?? "accountAPI.cardFormHint".localized
                    )
                    .font(AppFont.regular(size: 13))
                    .foregroundStyle(AppColor.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            CardContainer {
                VStack(spacing: 12) {
                    PaymentCardField(
                        title: "more.Cardholder name".localized, text: $viewModel.form.name,
                        placeholder: "more.Name as shown on card".localized, icon: .paymentFormPerson,
                        field: .name, focus: $focusedField, error: viewModel.validationMessage(for: .name))
                    VStack(spacing: 0) {
                        PaymentCardField(
                            title: "more.Card number".localized,
                            text: Binding(
                                get: {
                                    viewModel.form.number
                                }, set: viewModel.updateNumber),
                            placeholder: "0000 0000 0000 0000", icon: .paymentFormCard, numeric: true,
                            field: .number, focus: $focusedField, error: viewModel.validationMessage(for: .number))
                        HStack(spacing: 8) {
                            PaymentBrandLogo(brand: "mada", size: .compact)
                            PaymentBrandLogo(brand: "mastercard", size: .compact)
                            PaymentBrandLogo(brand: "visa", size: .compact)
                        }
                        .padding(.top, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityHidden(true)
                    }
                    PaymentCardField(
                        title: "more.Expiry date".localized,
                        text: Binding(
                            get: {
                                viewModel.form.expiry
                            }, set: viewModel.updateExpiry), placeholder: "MM/YY",
                        icon: .paymentFormCalendar, iconSize: 14, numeric: true,
                        field: .expiry, focus: $focusedField, error: viewModel.validationMessage(for: .expiry))
                    PaymentCardField(
                        title: "more.Security code (CVV)".localized,
                        text: Binding(
                            get: {
                                viewModel.form.cvv
                            }, set: viewModel.updateCVV), placeholder: "CVV",
                        icon: .paymentFormLock, iconSize: 14, numeric: true, secure: true,
                        field: .cvv, focus: $focusedField, error: viewModel.validationMessage(for: .cvv))
                    HStack(spacing: 8) {
                        profileIcon(.paymentFormDefault, size: 16)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("more.Set as default card".localized)
                                .font(AppFont.bold(size: 13))
                            Text("payments.defaultHint".localized)
                                .font(AppFont.regular(size: 11))
                                .foregroundStyle(AppColor.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Toggle("more.Set as default card".localized, isOn: $viewModel.form.isDefault)
                            .labelsHidden()
                            .tint(AppColor.primary)
                            .disabled(defaultCard != nil)
                            .scaleEffect(0.85)
                            .frame(width: 44, height: 26)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(AppColor.border))
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 4) {
                Button {
                    focusedField = nil
                    Task {
                        if await viewModel.submit(using: account) {
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        profileIcon(.paymentSaveLock, size: 16)
                        Text((defaultCard == nil ? "more.Save card" : "more.Set as default card").localized)
                    }
                }
                .buttonStyle(MainButtonStyle(variant: .action, height: 51))
                .disabled(!viewModel.canSubmit || requests.busy)
                HStack(spacing: 4) {
                    profileIcon(.paymentFooterLock, size: 11)
                    Text("accountAPI.cardPrivacy".localized)
                        .font(AppFont.regular(size: 11))
                        .foregroundStyle(AppColor.mutedText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppColor.surface)
            .overlay(alignment: .top) {
                profileDivider
            }
        }
        .onDisappear {
            viewModel.clearSensitiveData()
        }
    }
}
