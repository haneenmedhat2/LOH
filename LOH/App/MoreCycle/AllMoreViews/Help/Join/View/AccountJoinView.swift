import SwiftUI

struct AccountJoinView: View {
    @EnvironmentObject private var coordinator: MoreCoordinator
    @EnvironmentObject private var requests: AccountRequestController
    @StateObject var viewModel: AccountJoinViewModel
    @EnvironmentObject private var appCoordinator: AppCoordinator
    var body: some View {
        Group {
            if viewModel.submitted {
                AccountFlowSuccess(
                    title: "accountFlow.Join success".localized, subtitle: "accountFlow.Join thanks".localized
                ) {
                    CardContainer {
                        VStack(spacing: 0) {
                            AccountFlowSummaryRow(
                                title: "more.Business name".localized, value: viewModel.form.business, icon: "Business")
                            Divider()
                                .opacity(0.4)
                            AccountFlowSummaryRow(
                                title: "accountFlow.Contact phone".localized, value: viewModel.form.normalizedPhone,
                                icon: "Phone")
                            Divider()
                                .opacity(0.4)
                            AccountFlowSummaryRow(
                                title: "more.Email".localized, value: viewModel.form.email, icon: "Person")
                        }
                    }
                    CardContainer(background: AccountFlowColor.iconSurface) {
                        HStack(spacing: 16) {
                            AccountFlowIcon(name: "NextStep", size: 24)
                                .frame(width: 48, height: 48)
                                .background(AccountFlowColor.supportSurface, in: RoundedRectangle(cornerRadius: 16))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("accountFlow.Next step".localized)
                                    .font(AppFont.bold(size: 14))
                                Text("accountFlow.Partnership next step".localized)
                                    .font(AppFont.regular(size: 13))
                                    .foregroundStyle(AppColor.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    MainAppButton(
                        title: "more.Back to my account".localized,
                        action: {
                            coordinator.popToRoot()
                        }, variant: .action, height: 56)
                    MainAppButton(
                        title: "accountFlow.Browse offers".localized,
                        action: {
                            coordinator.popToRoot()
                            appCoordinator.tabsCoordinator.select(.offers)
                        }, variant: .outlined, height: 58)
                }
            } else {
                AccountPage(title: "more.Join us".localized, hidesTabBar: true, headerHeight: 60) {
                    AccountFlowIntro(
                        title: "accountFlow.Reach customers".localized,
                        subtitle: "accountFlow.Join intro".localized, icon: "JoinHero"
                    )
                    .padding(.bottom, 4)
                    CardContainer {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("more.Contact details".localized)
                                .font(AppFont.bold(size: 14))
                            AccountFlowField(
                                title: "more.Business name".localized, text: $viewModel.form.business,
                                placeholder: "accountFlow.Business placeholder".localized, icon: "BusinessField",
                                error: viewModel.validationMessage(for: .business))
                            AccountFlowField(
                                title: "more.Contact name".localized, text: $viewModel.form.name,
                                placeholder: "accountFlow.Contact placeholder".localized, icon: "PersonField",
                                error: viewModel.validationMessage(for: .name))
                            AccountFlowField(
                                title: "more.Phone number".localized,
                                text: Binding(
                                    get: {
                                        viewModel.form.phone
                                    }, set: viewModel.updatePhone),
                                placeholder: "5X XXX XXXX", icon: "PhoneField", keyboard: .phonePad,
                                error: viewModel.validationMessage(for: .phone))
                            AccountFlowField(
                                title: "more.Email".localized, text: $viewModel.form.email,
                                placeholder: "name@example.com", keyboard: .emailAddress,
                                error: viewModel.validationMessage(for: .email))
                            AccountTextArea(
                                title: "more.About the business (optional)".localized, text: $viewModel.form.details,
                                limit: 255,
                                placeholder: "accountFlow.Business description".localized, showsCount: false)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    VStack(spacing: 8) {
                        MainAppButton(
                            title: "more.Submit request".localized,
                            action: {
                                Task {
                                    await viewModel.submit()
                                }
                            }, variant: .action, isEnabled: viewModel.canSubmit && !requests.busy, height: 56)
                        Text("accountFlow.Partnership contact soon".localized)
                            .font(AppFont.regular(size: 11))
                            .foregroundStyle(AppColor.mutedText)
                    }
                    .padding(16)
                    .background(AppColor.surface)
                }
            }
        }
    }
}
