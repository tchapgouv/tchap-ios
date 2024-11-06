/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "WebViewViewController.h"
#import "GeneratedInterface-Swift.h"

@interface WebViewViewController ()
{
    // Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
    id kThemeServiceDidChangeThemeNotificationObserver;
}

@end

@implementation WebViewViewController

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Observe user interface theme change.
    MXWeakify(self);
    kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self userInterfaceThemeDidChange];
        
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self userInterfaceThemeDidChange];
}

- (void)userInterfaceThemeDidChange
{
    [self updateTheme];
}

- (void)applyVariant2Style
{
    [self updateTheme];
}

- (void)updateTheme
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [ThemeService.shared.theme applyStyleOnNavigationBar:navigationBar];
    }
    
    // @TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    webView.backgroundColor = ThemeService.shared.theme.backgroundColor;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)dealloc
{
    if (kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver: kThemeServiceDidChangeThemeNotificationObserver];
    }
}

@end
