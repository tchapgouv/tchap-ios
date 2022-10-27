//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
//            }
            
            // Tchap: Add password management
            RoundedBorderTextField(title: nil,
                                   placeHolder: VectorL10n.authPasswordPlaceholder,
                                   text: $viewModel.password,
                                           footerText: VectorL10n.authenticationRegistrationPasswordFooter,
                                   isError: viewModel.viewState.hasEditedPassword && viewModel.viewState.isPasswordInvalid,
                                   isFirstResponder: isEditingTextField,//isPasswordFocused,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                              isSecureTextEntry: true),
                                   onEditingChanged: nil,//passwordEditingChanged,
                                   onCommit: submit)
            .accessibilityIdentifier("passwordTextField")
            
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
    
    // Tchap: Add password management
    /// Enables password validation the first time the user finishes editing.
    /// Additionally resets the password field focus.
    func passwordEditingChanged(isEditing: Bool) {
        guard !isEditing else { return }
        isPasswordFocused = false
        
        guard !viewModel.viewState.hasEditedPassword else { return }
        viewModel.send(viewAction: .sendPassword)
    }
    
    /// Sends the `send` view action so long as a valid email address has been input.
    func submit() {
        guard !viewModel.viewState.hasInvalidAddress else { return }
        viewModel.send(viewAction: .sendPassword)
    }
}
