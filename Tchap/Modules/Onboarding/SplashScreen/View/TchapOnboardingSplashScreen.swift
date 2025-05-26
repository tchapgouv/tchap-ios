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

/// The splash screen shown at the beginning of the onboarding flow.
struct TchapOnboardingSplashScreen: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme
    @Environment(\.layoutDirection) private var layoutDirection
    
    // MARK: Public
    
    @ObservedObject var viewModel: OnboardingSplashScreenViewModel.Context
    
    @State var appTheme = ThemeService.shared()
    @State var presentProConnectInfo = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading) {
//                Spacer()
//                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
                                
                Spacer()
                header
                Spacer()
                buttons
                
//                Spacer()
//
//                buttons
//                    .frame(width: geometry.size.width)
//                    .padding(.bottom, OnboardingMetrics.actionButtonBottomPadding)
//                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                
                Spacer()
                    .frame(height: OnboardingMetrics.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            // Tchap: tchap background color
            .background(Color(appTheme.theme.backgroundColor))
        }
        .accentColor(theme.colors.accent)
        .navigationBarHidden(true)
        .track(screen: .welcome)
        .sheet(isPresented: $presentProConnectInfo) {
            WebSheetView(targetUrl: URL(string: BuildSettings.proConnectInfoUrlString)!)
        }

    }
    
    var header: some View {
        // Tchap: welcome title
        HStack { // HStack to center horizontally
            Spacer()
            VStack {
                // logo
                Image(uiImage: Asset.SharedImages.tchapLogo.image)
                    .resizable()
                    .frame(width: 160.0, height: 160.0) // size of logo
                    .scaledToFit()
                    .padding(.bottom, 64.0) // spacing to title below
                // title
                Text(TchapL10n.welcomeTitle)
                    .font(.system(size: 28.0, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8.0) // spacing to subtitle below
                // subtitle
                Text(TchapL10n.welcomeSubtitle)
                    .font(.system(size: 17.0, weight: .regular))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32.0)
            Spacer()
        }
    }
    
    /// The main action buttons.
    var buttons: some View {
        HStack { // HStack to center horizontally
            Spacer()
            VStack {
                // Display ProConnect option only if enabled by feature flag.
                if BuildSettings.tchapFeatureHandleSSO {
                    // Button ProConnect
                    Button(action: { viewModel.send(viewAction: .login(.sso(ssoIdentityProviders: [], providesDelegatedOIDCCompatibility: true))) }, label: {
                        HStack {
                            Image(uiImage: Asset_tchap.Images.proConnectIcon.image)
                            Text(LocalizedStringKey(TchapL10n.welcomeProConnectTitle)) // LocalizedStringKey is needed for markdown interpretation.
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true) // .lineLimit(Int.max) doesn't work here.
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 10.0, leading: 32.0, bottom: 10.0, trailing: 32.0))
                    })
                    .background(
                        Color(UIColor(rgb: 0x000091)),
                        in: RoundedRectangle(cornerRadius: 12.0)
                    )
                    .padding(.bottom, 8.0)
                
                    // Button "What is ProConnect?"
                    Button(action: { openProConnectWebsite() }, label: {
                        Text(TchapL10n.welcomeProConnectInfo)
                    })
                    .padding(.bottom, 32.0)
                }
              
                /// Button "Connect with password"
                Button(action: { viewModel.send(viewAction: .login(.password)) }, label: {
                    Text(TchapL10n.welcomePasswordTitle)
                        .padding(EdgeInsets(top: 16.0, leading: 32.0, bottom: 16.0, trailing: 32.0))
                })
                .background(
                    RoundedRectangle(cornerRadius: 12.0).stroke(.tint, lineWidth: 1.0)
                )
                .padding(.bottom, 8.0)
                
                // Button "Register/Create account"
                Button(action: { viewModel.send(viewAction: .register) }, label: {
                    Text(VectorL10n.createAccount)
                })
            }
            .padding(.bottom, 32.0)
            Spacer()
        }
        .font(.system(size: 18.0, weight: .regular))
        .readableFrame()
        
//        HStack {
//            HStack {
//                Spacer()
//                Button { viewModel.send(viewAction: .register) } label: {
//                    Text(TchapL10n.welcomeRegisterAction)
//                }
//                Spacer()
//            }
//            
//            Rectangle()
//                .foregroundColor(Color(appTheme.theme.selectedBackgroundColor))
//                .frame(width: 1.0, height: 52.0)
//            
//            HStack {
//                Spacer()
//                Button { viewModel.send(viewAction: .login) } label: {
//                    Text(TchapL10n.welcomeLoginAction)
//                }
//                Spacer()
//            }
//        }
//        .foregroundStyle(Color(appTheme.theme.tintColor))
//        .font(.system(size: 15.0))
//        .padding(.horizontal, 16)
//        .readableFrame()
    }

    func openProConnectWebsite() {
        presentProConnectInfo = true
    }
}

// MARK: - Previews

struct TchapOnboardingSplashScreen_Previews: PreviewProvider {
    static let stateRenderer = MockOnboardingSplashScreenScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
