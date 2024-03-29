/*
 Copyright 2015 OpenMarket Ltd
 
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

#import "MatrixKit.h"

@class SettingsViewController;

/**
 `SettingsViewController` delegate.
 */
@protocol SettingsViewControllerDelegate <NSObject>

/**
 Tells the delegate to reload all the running matrix sessions by eventually clearing the cache.
 
 @param settingsViewController the `SettingsViewController` instance.
 @param clearCache tell whether all store data must be cleared.
 */
- (void)settingsViewController:(SettingsViewController *)settingsViewController reloadMatrixSessionsByClearingCache:(BOOL)clearCache;

@end

@interface SettingsViewController : MXKTableViewController

+ (instancetype)instantiate;

- (void)showUserSessionsFlow;

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<SettingsViewControllerDelegate> delegate;

@end

