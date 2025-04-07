//
// Copyright 2024 beta.gouv
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

struct TchapAuthenticationLoginScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    /// A boolean that can be toggled to give focus to the password text field.
    /// This must be manually set back to `false` when the text field finishes editing.
    @State private var isPasswordFocused = false
    @State private var presentProConnectInfo = false
    @State private var presentProConnectAvailabilityFaqArticle = false

    // MARK: Public
    
    @ObservedObject var viewModel: AuthenticationLoginViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, OnboardingMetrics.topPaddingToNavigationBar)
                    .padding(.bottom, 28)
                
                if viewModel.viewState.homeserver.showLoginForm {
                    loginForm
                }
                
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(theme.colors.background.ignoresSafeArea())
        .alert(item: $viewModel.alertInfo) { $0.alert }
        .accentColor(theme.colors.accent)
        .sheet(isPresented: $presentProConnectAvailabilityFaqArticle) {
            WebSheetView(targetUrl: URL(string: BuildSettings.proConnectAvailabilityFaqArticleUrlString)!)
        }
        .sheet(isPresented: $presentProConnectInfo) {
            WebSheetView(targetUrl: URL(string: BuildSettings.proConnectInfoUrlString)!)
        }
    }
    
    /// The header containing a Welcome Back title.
    var header: some View {
        Group {
            if case .sso = viewModel.viewState.tchapAuthenticationMode {
                Spacer()
                Text(TchapL10n.authenticationSsoTitle)
            } else {
                Text(TchapL10n.authenticationPasswordTitle)
            }
        }                    
        .padding(.horizontal, 32.0)
        .padding(.bottom, 32.0)
        .font(Font.system(size: 24.0, weight: .bold))
        .multilineTextAlignment(.center)
        .foregroundColor(theme.colors.primaryContent)
        
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(spacing: 14) {
            // Tchap: Update placeholder and set keyboard type to email address
            RoundedBorderTextField(placeHolder: TchapL10n.authenticationMailPlaceholder,
                                   text: $viewModel.username,
                                   isFirstResponder: false,
                                   configuration: UIKitTextInputConfiguration(keyboardType: .emailAddress,
                                                                              returnKeyType: .next,
                                                                              autocapitalizationType: .none,
                                                                              autocorrectionType: .no),
                                   onEditingChanged: usernameEditingChanged,
                                   onCommit: { isPasswordFocused = true })
                .accessibilityIdentifier("usernameTextField")
                .padding(.bottom, 7)
            
            // Tchap: display password depending login state
            if case .password = viewModel.viewState.tchapAuthenticationMode {
                passwordLoginSection
            } else if case .sso = viewModel.viewState.tchapAuthenticationMode {
                ssoLoginSection
                Spacer(minLength: 32.0)
                ssoInformation
            }
        }
    }
    
    var passwordLoginSection: some View {
        Group {
            RoundedBorderTextField(placeHolder: VectorL10n.authPasswordPlaceholder,
                                   text: $viewModel.password,
                                   isFirstResponder: isPasswordFocused,
                                   configuration: UIKitTextInputConfiguration(returnKeyType: .done,
                                                                              isSecureTextEntry: true),
                                   onEditingChanged: passwordEditingChanged,
                                   onCommit: submit)
            .accessibilityIdentifier("passwordTextField")
            
            Button { viewModel.send(viewAction: .forgotPassword) } label: {
                Text(VectorL10n.authenticationLoginForgotPassword)
                    .font(theme.fonts.body)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 8)
            
            Button(action: submit) {
                Text(VectorL10n.next)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(!viewModel.viewState.canSubmit)
            .accessibilityIdentifier("nextButton")
        }
    }
    
    var ssoLoginSection: some View {
        Group {
            // Button ProConnect
            Button(action: submit, label: {
                HStack {
                    Spacer()
                    Image(uiImage: Asset_tchap.Images.proConnectIcon.image)
                    Text(LocalizedStringKey(TchapL10n.authenticationSsoConnectTitle)) // LocalizedStringKey is needed for markdown interpretation.
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true) // .lineLimit(Int.max) doesn't work here.
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(EdgeInsets(top: 10.0, leading: 16.0, bottom: 10.0, trailing: 16.0))
            })
            .buttonStyle(ProConnectButtonStyle(customColor: Color(UIColor(rgb: 0x000091))))
            .disabled(!viewModel.viewState.canSubmit)
            .accessibilityIdentifier("ssoButton")
            .padding(.bottom, 8.0)
                        
            // Button "What is ProConnect?"
            Button(action: { openProConnectWebsite() }, label: {
                Text(TchapL10n.welcomeProConnectInfo)
            })
        }
    }
    
    var ssoInformation: some View {
        Button(action: { openProConnectAvailabilityFaqArticle() }, label: {
            Text(TchapL10n.authenticationSsoWarning)
        })
        .padding(.horizontal, 16.0)
    }
    
    /// Parses the username for a homeserver.
    func usernameEditingChanged(isEditing: Bool) {
        guard !isEditing, !viewModel.username.isEmpty else { return }
    }
    
    /// Resets the password field focus.
    func passwordEditingChanged(isEditing: Bool) {
        guard !isEditing else { return }
        isPasswordFocused = false
    }
    
    /// Sends the `next` view action so long as the form is ready to submit.
    func submit() {
        // Tchap: try to determine the homeServer from the user's email
        // and request this homeServer about its Authentication capabilities. (Does it offer SSO?)
        
        // First, request any HomeServer to get the HomeServer of the user's email domain.
        Task {
            if let instanceDomain = try? await tchapGetInstance(for: viewModel.username) {
                if let userHomeServerViewData = try? await tchapUpdateAuthServiceForDirectAuthentication(forHomeServer: "\(BuildSettings.serverUrlPrefix)\(instanceDomain)") {
                    viewModel.viewState.homeserver = userHomeServerViewData

                    // Then, now that homeServer is known, start authentication flow.
                    if case .sso = viewModel.viewState.tchapAuthenticationMode,
                       let proConnectProvider = userHomeServerViewData.ssoIdentityProviders.first {
                        // Tchap: add `loginHint` string parameter for SSO
//                        viewModel.send(viewAction: .continueWithSSO(proConnectProvider))
                        viewModel.send(viewAction: .continueWithSSO(proConnectProvider, viewModel.username))
                    } else {
                        guard viewModel.viewState.canSubmit else { return }
                        viewModel.send(viewAction: .next)
                    }
                }
            }
        }
    }

    enum ClientError: Error {
        /// An unexpected response was received.
        case invalidURL
        case invalidResult
    }

    private func tchapGetInstance(for email: String) async throws -> String {
        struct InstanceReturnValue: Decodable {
            let hs: String
        }
        
        let homeServerAddress = AuthenticationService.shared.state.homeserver.address
        
        // MXRestClient has no global `request` method exposed.
        // So, I have to make my own and use the shared URLSession.
        guard let url = URL(string: "\(homeServerAddress)/\(kMXIdentityAPIPrefixPathV1)/info?medium=&address=\(email)") else {
            throw ClientError.invalidURL
            }
        
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let stringResult = String(data: data, encoding: .utf8) else {
            throw ClientError.invalidResult
        }
        
        guard let stringResultData = stringResult.data(using: .utf8),
              let getInstanceResult = try? JSONDecoder().decode(InstanceReturnValue.self, from: stringResultData) else {
            throw ClientError.invalidResult
        }
        
        return getInstanceResult.hs
    }
    
    // Tchap: start login flow once email is entered, to be able to determine the correct homeServer.
    // Start login flow by updating AuthenticationService
    private func tchapUpdateAuthServiceForDirectAuthentication(forHomeServer homeServerAddress: String) async throws -> AuthenticationHomeserverViewData? {
        let authService = AuthenticationService.shared
        authService.reset()
        do {
            try await authService.startFlow(.login, for: homeServerAddress)
            return authService.state.homeserver.viewData
        } catch {
            MXLog.error("[AuthenticationLoginScreen] Unable to start flow for login.")
            return nil
        }
    }

    func openProConnectWebsite() {
        presentProConnectInfo = true
    }

    func openProConnectAvailabilityFaqArticle() {
        presentProConnectAvailabilityFaqArticle = true
    }
}

struct ProConnectButtonStyle: ButtonStyle {
    @Environment(\.theme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    /// `theme.colors.accent` by default
    var customColor: Color?
    /// `theme.colors.body` by default
    var font: Font?
    
    private var fontColor: Color {
        // Always white unless disabled with a dark theme.
        .white.opacity(theme.isDark && !isEnabled ? 0.3 : 1.0)
    }
    
    private var backgroundColor: Color {
        customColor ?? theme.colors.accent
    }
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(fontColor)
            .font(font ?? theme.fonts.body)
            .background(
                backgroundColor,
                in: RoundedRectangle(cornerRadius: 12.0)
            )
            .opacity(backgroundOpacity(when: configuration.isPressed))
    }
    
    func backgroundOpacity(when isPressed: Bool) -> CGFloat {
        guard isEnabled else { return 0.5 }
        return isPressed ? 0.6 : 1.0
    }
}

// MARK: - Previews

@available(iOS 15.0, *)
struct TchapAuthenticationLogin_Previews: PreviewProvider {
    static let stateRenderer = MockAuthenticationLoginScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup(addNavigation: true)
            .navigationViewStyle(.stack)
    }
}
