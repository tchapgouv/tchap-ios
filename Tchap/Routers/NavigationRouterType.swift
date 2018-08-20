/*
 Copyright 2018 New Vector Ltd
 
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

/// Protocol describing a router that wraps a UINavigationController and add convenient completion handlers. Completions are called when a Presentable is removed.
/// Routers are used to be passed between coordinators. They handles only `physical` navigation.
protocol NavigationRouterType: class, Presentable {
    
    var navigationController: UINavigationController { get }
    var rootViewController: UIViewController? { get }

    func present(_ module: Presentable, animated: Bool)
    func dismissModule(animated: Bool, completion: (() -> Void)?) // ! Here animation completion not the pop completion
    func push(_ module: Presentable, animated: Bool, popCompletion: (() -> Void)?)
    func popModule(animated: Bool)
    func setRootModule(_ module: Presentable, hideNavigationBar: Bool)
    func popToRootModule(animated: Bool)
}

extension NavigationRouterType {
    func setRootModule(_ module: Presentable) {
        setRootModule(module, hideNavigationBar: false)
    }
}
