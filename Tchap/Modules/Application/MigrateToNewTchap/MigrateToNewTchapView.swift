// 
// Copyright 2026 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct MigrateToNewTchapView: View {
    @Environment(\.openURL) private var openURL
    
    @ObservedObject var viewModel: MigrateToNewTchapViewModel

    private func openAppStoreAction() {
        openURL(viewModel.appStoreAppUrl)
    }
    
    private func presentHelpAction() {
        viewModel.shouldPresentHelp = true
    }
    
    var iconsHeader: some View {
        HStack(spacing: 0.0) {
            Image(uiImage: Asset.SharedImages.tchapLogo.image)
                .resizable()
                .scaledToFit()
                .padding(.vertical, 8.0)
            Image(systemName: "arrow.right")
                .font(.title)
                .foregroundStyle(Color(uiColor: viewModel.theme.textSecondaryColor))
                .padding(.horizontal, 16.0)
            Image(uiImage: Asset_tchap.SharedImages.nextTchapLogo.image)
                .resizable()
                .scaledToFit()
        }
    }
    
    var title: some View {
        Text(TchapL10n.migrateToNewTchapTitle)
            .font(.title2)
            .bold()
            .foregroundStyle(Color(uiColor: viewModel.theme.textPrimaryColor))
    }
    
    var message: some View {
        Text(TchapL10n.migrateToNewTchapMessage)
            .font(.callout)
            .multilineTextAlignment(.center)
            .foregroundStyle(Color(uiColor: viewModel.theme.textSecondaryColor))
    }
    
    var warning: some View {
        HStack(alignment: .top, spacing: 12.0) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color(uiColor: viewModel.theme.warningColor))
            Text(TchapL10n.migrateToNewTchapWarning)
                .font(.callout)
                .foregroundStyle(Color(uiColor: viewModel.theme.textPrimaryColor))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8.0)
                .fill(Color(uiColor: UIColor(rgb: viewModel.isCurrentThemeDark ? 0x440505 : 0xFFEFED)))
        )
    }
    
    var appStoreButton: some View {
        Button {
            openAppStoreAction()
        } label: {
            Text(TchapL10n.migrateToNewTchapActionAcceptTitle)
                .font(.callout)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: viewModel.theme.tintColor))
                .cornerRadius(4.0)
                .foregroundColor(.white)
        }
    }
    
    var helpButton: some View {
        Button {
            presentHelpAction()
        } label: {
            Text(TchapL10n.migrateToNewTchapActionHelpTitle)
                .font(.callout)
                .bold()
                .padding()
                .frame(maxWidth: .infinity)
                .foregroundColor(Color(uiColor: viewModel.theme.textSecondaryColor))
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem {
            Button {
                viewModel.actionCancel()
            } label: {
                Text(VectorL10n.skip)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                iconsHeader
                .frame(height: 96.0)
                .padding(.bottom, 32.0)
                
                title
                    .padding(.bottom, 8.0)

                message
                    .padding(.bottom, 16.0)

                warning
                    .padding(.bottom, 32.0)
                
                appStoreButton
                
                helpButton
                
            }
            .padding(32.0)
            .background(Color(uiColor:.systemBackground))
            
            .toolbar {
                toolbar
            }
        }
        .sheet(isPresented: $viewModel.shouldPresentHelp) {
            WebSheetView(targetUrl: viewModel.helpArticleUrl)
        }
    }
}

#Preview {
    MigrateToNewTchapView(viewModel: MigrateToNewTchapViewModel(appStoreAppUrl: URL(string: "https://apple.com")!, // swiftlint:disable:this force_unwrapping
                                                                helpArticleUrl: URL(string: "https://www.tchap.gouv.fr")!, // swiftlint:disable:this force_unwrapping
                                                                actionCancel: {}))
}
