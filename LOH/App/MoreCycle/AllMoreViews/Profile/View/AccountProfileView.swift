import SwiftUI
import PhotosUI

struct AccountProfileView: View {
    @EnvironmentObject private var requests: AccountRequestController
    @EnvironmentObject private var account: AccountProfileViewModel
    @EnvironmentObject private var coordinator: MoreCoordinator
    @Environment(\.locale) private var locale
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var draft = AccountProfile()
    @State private var photo: PhotosPickerItem?
    @State private var avatar: UIImage?
    @State private var initialized = false
    @State private var photoError = false
    @State private var dialog: ProfileDialog?
    @State private var editingText = ""
    @State private var editingDate = Date()

    private var valid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && draft.name.count <= 191
            && draft.email.count <= 50 && AccountValidation.validEmail(draft.email)
            && (account.profile.email.isEmpty || !draft.email.isEmpty)
    }

    var body: some View {
        ZStack {
            AccountPage(title: "more.Edit profile".localized, hidesTabBar: true, headerHeight: 60) {
                if !initialized && !requests.busy {
                    Button("accountAPI.retry".localized) {
                        Task {
                            await loadProfile()
                        }
                    }
                }
                photoCard
                CardContainer(padding: 0) {
                    VStack(spacing: 0) {
                        sectionTitle("more.Personal information")
                        editRow("more.Full name", value: draft.name, icon: .profilePerson, dialog: .name)
                        profileDivider
                        editRow("more.Date of birth", value: birthdayText, icon: .profileCalendar, dialog: .birthday)
                        profileDivider
                        Menu {
                            Button("more.Male".localized) {
                                draft.gender = "male"
                            }
                            Button("more.Female".localized) {
                                draft.gender = "female"
                            }
                        } label: {
                            ProfileDetailRow(
                                title: "more.Gender".localized,
                                value: draft.gender.isEmpty
                                    ? "—" : (draft.gender == "male" ? "more.Male" : "more.Female").localized,
                                icon: .profilePerson, accessory: .profileDown)
                        }
                        .buttonStyle(.plain)
                        profileDivider
                        Menu {
                            ForEach(account.cities) { city in
                                Button(city.name) {
                                    draft.city = city.name
                                    draft.cityID = city.id
                                }
                            }
                        } label: {
                            ProfileDetailRow(
                                title: "more.City".localized, value: draft.city,
                                icon: .profilePin, accessory: .profileDown)
                        }
                        .buttonStyle(.plain)
                    }
                }
                CardContainer(padding: 0) {
                    VStack(spacing: 0) {
                        sectionTitle("more.Contact information")
                        editRow("more.Email", value: draft.email, icon: .profileMail, dialog: .email)
                        profileDivider
                        ProfileDetailRow(
                            title: "more.Phone number".localized, value: draft.phone,
                            icon: .profilePhone, isPhone: true)
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AccountFooter(title: "more.Save changes".localized, enabled: valid && initialized && !requests.busy) {
                    draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    draft.email = draft.email.trimmingCharacters(in: .whitespacesAndNewlines)
                    Task {
                        if await account.saveProfile(draft, image: photo == nil ? nil : avatar) {
                            draft = account.profile
                            photo = nil
                            showSuccess(true)
                        }
                    }
                }
                .overlay(alignment: .top) {
                    profileDivider
                }
            }
            .allowsHitTesting(dialog == nil)
            .accessibilityHidden(dialog != nil)

            if let dialog, dialog != .success {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                dialogContent(dialog)
                    .padding(24)
                    .frame(maxWidth: 342)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.25), radius: 25, y: 25)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .accessibilityAddTraits(.isModal)
                    .logScreen(dialog.screenName)
            }
        }
        .fullScreenCover(
            isPresented: Binding(
                get: { dialog == .success },
                set: { if !$0 { dialog = nil } }
            ),
            onDismiss: { coordinator.popToRoot() }
        ) {
            ZStack {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                dialogContent(.success)
                    .padding(24)
                    .frame(maxWidth: 326)
                    .background(AppColor.surface, in: RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.25), radius: 25, y: 25)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .accessibilityAddTraits(.isModal)
            }
            .presentationBackground(.clear)
            .interactiveDismissDisabled()
            .logScreen(ProfileDialog.success.screenName)
        }
        .task {
            await loadProfile()
        }
        .task(id: photo) {
            guard let photo else {
                return
            }
            do {
                guard let data = try await photo.loadTransferable(type: Data.self), let image = UIImage(data: data)
                else {
                    photoError = true
                    return
                }
                guard !Task.isCancelled else {
                    return
                }
                avatar = image
            } catch {
                if !Task.isCancelled {
                    photoError = true
                }
            }
        }
        .alert("more.Could not load photo".localized, isPresented: $photoError) {
            Button("more.Done".localized, role: .cancel) {}
        }
    }

    @MainActor private func loadProfile() async {
        initialized = false
        guard await account.loadProfile(), !Task.isCancelled else {
            return
        }
        draft = account.profile
        avatar = account.avatar
        photo = nil
        initialized = true
        await account.loadProfileCities()
    }

    private var photoCard: some View {
        CardContainer(padding: 20) {
            PhotosPicker(selection: $photo, matching: .images) {
                HStack(spacing: 16) {
                    AccountAvatar(
                        image: avatar, url: draft.imageURL,
                        revision: account.profileImageRevision, showsBorder: true)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("more.Profile photo".localized)
                            .font(AppFont.bold(size: 17))
                            .foregroundStyle(AppColor.text)
                        Text("more.Change photo".localized)
                            .font(AppFont.mediumButton)
                            .foregroundStyle(AppColor.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var birthdayText: String {
        guard draft.hasBirthday else {
            return "—"
        }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter.string(from: draft.birthday)
    }

    private func sectionTitle(_ key: String) -> some View {
        Text(key.localized)
            .font(AppFont.bold(size: 13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 4)
    }

    private func editRow(_ key: String, value: String, icon: LOHAsset, dialog: ProfileDialog) -> some View {
        Button {
            editingText = dialog == .name ? draft.name : draft.email
            editingDate = draft.birthday
            self.dialog = dialog
        } label: {
            ProfileDetailRow(title: key.localized, value: value, icon: icon, accessory: .profileEdit)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func dialogContent(_ dialog: ProfileDialog) -> some View {
        if dialog == .success {
            VStack(spacing: 0) {
                profileIcon(.profileSuccess, size: 30)
                    .frame(width: 64, height: 64)
                    .background(AppColor.success, in: Circle())
                    .padding(.bottom, 16)
                Text("more.Profile saved title".localized)
                    .font(AppFont.extraBold(size: 20))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
                Text("more.Profile saved message".localized)
                    .font(AppFont.regular(size: 14))
                    .foregroundStyle(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                MainAppButton(
                    title: "more.Excellent".localized,
                    action: {
                        showSuccess(false)
                    }, variant: .action, height: 56)
            }
            .foregroundStyle(AppColor.text)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(dialog.title)
                    .font(AppFont.bold(size: 17))
                    .foregroundStyle(AppColor.text)
                    .padding(.bottom, 16)
                Group {
                    if dialog == .birthday {
                        DatePicker(
                            "more.Date of birth".localized, selection: $editingDate, in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .environment(\.calendar, Calendar(identifier: .gregorian))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        TextField(
                            dialog == .name ? "more.Enter full name".localized : "name@example.com", text: $editingText
                        )
                        .keyboardType(dialog == .email ? .emailAddress : .default)
                        .textInputAutocapitalization(dialog == .email ? .never : .words)
                        .autocorrectionDisabled(dialog == .email)
                        .textContentType(dialog == .email ? .emailAddress : .name)
                        .environment(\.layoutDirection, dialog == .email ? .leftToRight : layoutDirection)
                        .submitLabel(.done)
                        .onSubmit {
                            if canSave(dialog) {
                                saveField(dialog)
                            }
                        }
                    }
                }
                .font(AppFont.regular(size: 15))
                .foregroundStyle(AppColor.text)
                .tint(AppColor.primary)
                .padding(.horizontal, 16)
                .frame(height: 55)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColor.primary, lineWidth: 2)
                )
                .padding(.bottom, 20)
                HStack(spacing: 12) {
                    MainAppButton(
                        title: "more.Cancel".localized,
                        action: {
                            self.dialog = nil
                        }, variant: .secondary, height: 54)
                    MainAppButton(
                        title: "more.Save".localized,
                        action: {
                            saveField(dialog)
                        }, variant: .action,
                        isEnabled: canSave(dialog), height: 54)
                }
            }
        }
    }

    private func showSuccess(_ isPresented: Bool) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            dialog = isPresented ? .success : nil
        }
    }

    private func canSave(_ dialog: ProfileDialog) -> Bool {
        let text = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        switch dialog {
        case .name: return !text.isEmpty
        case .email: return !text.isEmpty && AccountValidation.validEmail(text)
        case .birthday: return editingDate <= Date()
        case .success: return true
        }
    }

    private func saveField(_ dialog: ProfileDialog) {
        guard canSave(dialog) else {
            return
        }
        switch dialog {
        case .name: draft.name = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        case .email: draft.email = editingText.trimmingCharacters(in: .whitespacesAndNewlines)
        case .birthday:
            draft.birthday = editingDate
            draft.hasBirthday = true
        case .success: break
        }
        self.dialog = nil
    }
}
