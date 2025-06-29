//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ChangePasswordScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme

    enum Field { case oldPassword, newPassword1, newPassword2 }
    @State private var focusedField: Field?
    
    // MARK: Public
    
    @ObservedObject var viewModel: ChangePasswordViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                form
            }
            .readableFrame()
            .padding(.horizontal, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }

    /// The title and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.authenticationPasswordIcon)
                .padding(.bottom, 16)

            Text(VectorL10n.settingsChangePassword)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
                .accessibilityIdentifier("titleLabel")
        }
    }

    /// The text fields and submit button.
    var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedBorderTextField(placeHolder: VectorL10n.settingsOldPassword,
                                   text: $viewModel.oldPassword,
                                   isFirstResponder: focusedField == .oldPassword,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .next,
                                                                              isSecureTextEntry: true),
                                   onCommit: { focusedField = .newPassword1 })
                .accessibilityIdentifier("oldPasswordTextField")

            RoundedBorderTextField(placeHolder: VectorL10n.settingsNewPassword,
                                   text: $viewModel.newPassword1,
                                   isFirstResponder: focusedField == .newPassword1,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .next,
                                                                              isSecureTextEntry: true),
                                   onCommit: { focusedField = .newPassword2 })
                .accessibilityIdentifier("newPasswordTextField1")

            RoundedBorderTextField(placeHolder: VectorL10n.settingsConfirmPassword,
                                   text: $viewModel.newPassword2,
                                   isFirstResponder: focusedField == .newPassword2,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                              isSecureTextEntry: true),
                                   onCommit: submit)
                .accessibilityIdentifier("newPasswordTextField2")

            HStack(alignment: .center, spacing: 8) {
                Toggle(TchapL10n.authenticationChoosePasswordSignoutAllDevices, isOn: $viewModel.signoutAllDevices)
                    .toggleStyle(AuthenticationTermsToggleStyle())
                    .accessibilityIdentifier("signoutAllDevicesToggle")
                Text(TchapL10n.authenticationChoosePasswordSignoutAllDevices)
                    .foregroundColor(theme.colors.secondaryContent)
            }
            .onTapGesture(perform: toggleSignoutAllDevices)
            .padding(.top, 8)

            Text(viewModel.viewState.passwordRequirements)
                .font(theme.fonts.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(theme.colors.secondaryContent)
                .accessibilityIdentifier("passwordRequirementsLabel")
                .padding(.top, 8)
                .padding(.bottom, 16)

            Button(action: submit) {
                Text(VectorL10n.save)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.viewState.canSubmit)
            .accessibilityIdentifier("submitButton")
        }
    }

    /// Sends the `submit` view action if viewModel.viewState.canSubmit.
    func submit() {
        guard viewModel.viewState.canSubmit else { return }
        viewModel.send(viewAction: .submit)
    }

    /// Sends the `toggleSignoutAllDevices` view action.
    func toggleSignoutAllDevices() {
        viewModel.send(viewAction: .toggleSignoutAllDevices)
    }
}

// MARK: - Previews

struct ChangePasswordScreen_Previews: PreviewProvider {
    static let stateRenderer = MockChangePasswordScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
            .theme(.dark).preferredColorScheme(.dark)
    }
}
