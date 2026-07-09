/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit
import SwiftUI

@preconcurrency final class MigrateToNewTchapViewController: UIHostingController<MigrateToNewTchapView> {

    // MARK: - Properties
    
    // MARK: Private
    
    private var viewModel: MigrateToNewTchapViewModel!
    
    // MARK: Public
    
    // MARK: - Setup
    
    static func instantiate(with viewModel: MigrateToNewTchapViewModel) -> MigrateToNewTchapViewController {
        let view = MigrateToNewTchapView(viewModel: viewModel)
        let viewController = MigrateToNewTchapViewController(rootView: view)
        viewController.viewModel = viewModel
        return viewController
    }

    private func registerThemeServiceDidChangeThemeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeServiceDidChangeTheme, object: nil)
    }

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerThemeServiceDidChangeThemeNotification()
        
        // Do any additional setup after loading the view.
        
        self.setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.themeDidChange()
    }
    
    // MARK: - Private
    
    private func updateTheme() {
        self.viewModel.theme = ThemeService.shared().theme
    }
    
    @objc private func themeDidChange() {
        self.updateTheme()
    }
    
    private func setupViews() {
    }
    
    func presentHelp() {
        viewModel.shouldPresentHelp = true
    }
}
