/*
 Copyright 2017 Vector Creations Ltd
 
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

#import "WebViewViewController.h"

#import "RageShakeManager.h"
#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface WebViewViewController () <Stylable>

@property (nonatomic, strong) id<Style> currentStyle;

// Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
@property (nonatomic, weak) id kThemeServiceDidChangeThemeNotificationObserver;

@end

@implementation WebViewViewController

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.currentStyle = Variant1Style.shared;
    }
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
    _kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
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
    [self updateWithStyle:self.currentStyle];
}

- (void)applyVariant2Style
{
    [self updateWithStyle:Variant2Style.shared];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    // @TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = style.overlayBackgroundColor;
    
    self.view.backgroundColor = style.backgroundColor;
    webView.backgroundColor = style.backgroundColor;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}

- (void)dealloc
{
    if (_kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_kThemeServiceDidChangeThemeNotificationObserver];
    }
}

@end
