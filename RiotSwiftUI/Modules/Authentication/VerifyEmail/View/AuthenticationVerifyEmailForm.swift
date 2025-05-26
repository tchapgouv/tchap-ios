//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The form shown to enter an email address.
struct AuthenticationVerifyEmailForm: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    
    @State private var isEditingTextField = false
    @State private var isPasswordFocused = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationVerifyEmailViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                .padding(.bottom, 36)
            
            mainContent
        }
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            // Tchap: Replace onboarding icon
            OnboardingIconImage(image: Asset.Images.onboardingCongratulationsIcon)
                .padding(.bottom, 8)
            
            // Tchap: Add registration title
            Text(VectorL10n.authenticationRegistrationTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)

            // Tchap: Hide other header fields
//            Text(VectorL10n.authenticationVerifyEmailInputTitle)
//                .font(theme.fonts.title2B)
//                .multilineTextAlignment(.center)
//                .foregroundColor(theme.colors.primaryContent)
//                .accessibilityIdentifier("titleLabel")
//
//            Text(viewModel.viewState.formHeaderMessage)
//                .font(theme.fonts.body)
//                .multilineTextAlignment(.center)
//                .foregroundColor(theme.colors.secondaryContent)
//                .accessibilityIdentifier("messageLabel")
        }
    }
    
    /// The text field and submit button where the user enters an email address.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tchap: Remove the ability to submit just with the e-mail field content
//            if #available(iOS 15.0, *) {
//                textField
//                    .onSubmit(submit)
//            } else {

            textField
                .introspectTextField {
                    $0.becomeFirstResponder()
                }
                

//            }
            
            // Tchap: Add password management
            passwordField
            
            // Tchap: Add Terms and Conditions buttons
            HStack(alignment: .center, spacing: 8) {
                Toggle(TchapL10n.registrationTermsLabelFormat(TchapL10n.registrationTermsLabelLink), isOn: $viewModel.userAgreeWithTermsAndConditions)
                    .toggleStyle(AuthenticationTermsToggleStyle())
                    .accessibilityIdentifier("termsAndConditionsToggle")
                
                TACText
                    .foregroundColor(theme.colors.secondaryContent)
                    .onTapGesture {
                        viewModel.send(viewAction: .showTermsAndConditions)
                    }
            }
            .padding(.bottom, 16)
            .onTapGesture(perform: toggleTermsAndConditions)
            
            // Tchap: Update condition for activation
            Button(action: submit) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.viewState.canSubmit)
//            .disabled(viewModel.viewState.hasInvalidAddress)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// The text field, extracted for iOS 15 modifiers to be applied.
    var textField: some View {
        TextField(VectorL10n.authenticationVerifyEmailTextFieldPlaceholder, text: $viewModel.emailAddress) {
            isEditingTextField = $0
        }
        .textFieldStyle(BorderedInputFieldStyle(isEditing: isEditingTextField, isError: false))
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
        .disableAutocorrection(true)
        .accessibilityIdentifier("addressTextField")
    }
    
    var passwordField: some View {
        RoundedBorderTextField(title: nil,
                               placeHolder: VectorL10n.authPasswordPlaceholder,
                               text: $viewModel.password,
                               footerText: VectorL10n.authenticationRegistrationPasswordFooter,
                               isError: viewModel.viewState.hasEditedPassword && viewModel.viewState.isPasswordInvalid,
                               isFirstResponder: isEditingTextField,//isPasswordFocused,
                               configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                          isSecureTextEntry: true),
                               onEditingChanged: nil,//passwordEditingChanged,
                               onCommit: nil)
        .accessibilityIdentifier("passwordTextField")
    }

    // Tchap: Prepare the account creation when email and pwd are ready
    func submit() {
        guard !viewModel.viewState.hasInvalidAddress else { return }
        viewModel.send(viewAction: .prepareAccountCreation)
    }
    
    // Tchap: Add the Terms and Conditions button.
    /// Sends the `toggleTermsAndConditions` view action.
    func toggleTermsAndConditions() {
        viewModel.send(viewAction: .toggleTermsAndConditions)
    }
    
    // Tchap: Build Terms and Conditions text.
    var TACText: some View {
        return Text(TchapL10n.registrationTermsLabelFormat("")) + Text(TchapL10n.registrationTermsLabelLink).underline(true)
    }
}
