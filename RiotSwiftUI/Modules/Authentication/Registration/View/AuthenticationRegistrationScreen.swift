//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct AuthenticationRegistrationScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @State private var isPasswordFocused = false
    
    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationRegistrationViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    .padding(.bottom, 28)
                
                // Tchap: Hide server selection
//                serverInfo
//                    .padding(.leading, 12)
//                    .padding(.bottom, 16)
//                
//                Rectangle()
//                    .fill(theme.colors.quinaryContent)
//                    .frame(height: 1)
//                    .padding(.bottom, 22)
                
                if viewModel.viewState.homeserver.showRegistrationForm {
                    registrationForm
                }
                
                if viewModel.viewState.homeserver.showRegistrationForm, viewModel.viewState.showSSOButtons {
                    Text(VectorL10n.or)
                        .foregroundColor(theme.colors.secondaryContent)
                        .padding(.top, 16)
                }
                
                if viewModel.viewState.showSSOButtons {
                    ssoButtons
                        .padding(.top, 16)
                }
                
                sunsetBanners

                if !viewModel.viewState.homeserver.showRegistrationForm, !viewModel.viewState.showSSOButtons {
                    fallbackButton
                        .disabled(viewModel.viewState.showReplacementAppBanner) // This button conveniently shows in the EX banner state, so use it as the disabled button.
                }
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
    }
    
    /// The header containing the icon, title and message.
    var header: some View {
        VStack(spacing: 8) {
            OnboardingIconImage(image: Asset.Images.onboardingCongratulationsIcon)
                .padding(.bottom, 8)
            
            Text(VectorL10n.authenticationRegistrationTitle)
                .font(theme.fonts.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(theme.colors.primaryContent)
        }
    }
    
    /// The sever information section that includes a button to select a different server.
    var serverInfo: some View {
        AuthenticationServerInfoSection(address: viewModel.viewState.homeserver.address,
                                        flow: .register) {
            viewModel.send(viewAction: .selectServer)
        }
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var registrationForm: some View {
        VStack(spacing: 21) {
            // Tchap: Update placeholder
            RoundedBorderTextField(title: nil,
                                   placeHolder: VectorL10n.authenticationVerifyEmailTextFieldPlaceholder,
                                   text: $viewModel.username,
                                   footerText: viewModel.viewState.usernameFooterMessage,
                                   isError: viewModel.viewState.hasEditedUsername && viewModel.viewState.isUsernameInvalid,
                                   isFirstResponder: false,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .next,
                                                                              autocapitalizationType: .none,
                                                                              autocorrectionType: .no),
                                   onEditingChanged: usernameEditingChanged,
                                   onCommit: { isPasswordFocused = true })
                .onChange(of: viewModel.username) { _ in viewModel.send(viewAction: .resetUsernameAvailability) }
                .accessibilityIdentifier("usernameTextField")
            
            RoundedBorderTextField(title: nil,
                                   placeHolder: VectorL10n.authPasswordPlaceholder,
                                   text: $viewModel.password,
                                   footerText: VectorL10n.authenticationRegistrationPasswordFooter,
                                   isError: viewModel.viewState.hasEditedPassword && viewModel.viewState.isPasswordInvalid,
                                   isFirstResponder: isPasswordFocused,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                              isSecureTextEntry: true),
                                   onEditingChanged: passwordEditingChanged,
                                   onCommit: submit)
                .accessibilityIdentifier("passwordTextField")
            
            Button(action: submit) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.viewState.canSubmit)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    /// A list of SSO buttons that can be used for login.
    var ssoButtons: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.viewState.homeserver.ssoIdentityProviders) { provider in
                AuthenticationSSOButton(provider: provider) {
                    viewModel.send(viewAction: .continueWithSSO(provider))
                }
                .accessibilityIdentifier("ssoButton")
            }
        }
    }
    
    @ViewBuilder
    var sunsetBanners: some View {
        if viewModel.viewState.showReplacementAppBanner, let replacementApp = BuildSettings.replacementApp {
            VStack(spacing: 20) {
                SunsetOIDCRegistrationBanner(homeserverAddress: viewModel.viewState.homeserver.address, 
                                             replacementApp: replacementApp)
                
                SunsetDownloadBanner(replacementApp: replacementApp) {
                    viewModel.send(viewAction: .downloadReplacementApp(replacementApp))
                }
            }
            .padding(.bottom, 20)
            .accessibilityIdentifier("sunsetBanners")
        }
    }

    /// A fallback button that can be used for login.
    var fallbackButton: some View {
        Button(action: fallback) {
            Text(VectorL10n.authRegister)
        }
        .buttonStyle(PrimaryActionButtonStyle())
        .accessibilityIdentifier("fallbackButton")
    }
    
    /// Validates the username when the text field ends editing.
    func usernameEditingChanged(isEditing: Bool) {
        guard !isEditing, !viewModel.username.isEmpty else { return }
        viewModel.send(viewAction: .validateUsername)
    }
    
    /// Enables password validation the first time the user finishes editing.
    /// Additionally resets the password field focus.
    func passwordEditingChanged(isEditing: Bool) {
        guard !isEditing else { return }
        isPasswordFocused = false
        
        guard !viewModel.viewState.hasEditedPassword else { return }
        viewModel.send(viewAction: .enablePasswordValidation)
    }
    
    /// Sends the `next` view action so long as valid credentials have been input.
    func submit() {
        guard viewModel.viewState.canSubmit else { return }
        viewModel.send(viewAction: .next)
    }

    /// Sends the `fallback` view action.
    func fallback() {
        viewModel.send(viewAction: .fallback)
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct AuthenticationRegistration_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationRegistrationScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
    }
}
