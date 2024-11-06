/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
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

