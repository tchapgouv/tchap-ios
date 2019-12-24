/*
 Copyright 2018 Vector Creations Ltd

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

#import "DesignValues.h"

#import "GeneratedInterface-Swift.h"

NSString *const kDesignValuesDidChangeThemeNotification = @"kDesignValuesDidChangeThemeNotification";

// Tchap Colors
UIColor *kColorDarkBlue;
UIColor *kColorDarkGreyBlue;
UIColor *kColorLightNavy;
UIColor *kColorGreyishPurple;
UIColor *kColorWarmGrey;
UIColor *kColorLightGrey;
UIColor *kColorDarkGrey;

#pragma mark Variant 1

// Status bar

UIStatusBarStyle kVariant1StatusBarStyle;

// Bar

UIColor *kVariant1BarBgColor;
UIColor *kVariant1BarTitleColor;
UIColor *kVariant1BarSubTitleColor;
UIColor *kVariant1BarActionColor;

// Button

UIColor *kVariant1ButtonBorderedTitleColor;
UIColor *kVariant1ButtonBorderedBgColor;
UIColor *kVariant1ButtonPlainTitleColor;
UIColor *kVariant1ButtonPlainBgColor;

// Body

UIColor *kVariant1PrimaryBgColor;
UIColor *kVariant1PrimaryTextColor;
UIColor *kVariant1PrimarySubTextColor;
UIColor *kVariant1PlaceholderTextColor;
UIColor *kVariant1SeparatorColor;
UIColor *kVariant1SecondaryBgColor;
UIColor *kVariant1SecondaryTextColor;
UIColor *kVariant1WarnTextColor;
UIColor *kVariant1PresenceIndicatorOnlineColor;

#pragma mark Variant 2

// Status bar

UIStatusBarStyle kVariant2StatusBarStyle;

// Bar

UIColor *kVariant2BarBgColor;
UIColor *kVariant2BarTitleColor;
UIColor *kVariant2BarSubTitleColor;
UIColor *kVariant2BarActionColor;

// Button

UIColor *kVariant2ButtonBorderedTitleColor;
UIColor *kVariant2ButtonBorderedBgColor;
UIColor *kVariant2ButtonPlainTitleColor;
UIColor *kVariant2ButtonPlainBgColor;

// Body

UIColor *kVariant2PrimaryBgColor;
UIColor *kVariant2PrimaryTextColor;
UIColor *kVariant2PrimarySubTextColor;
UIColor *kVariant2SecondaryTextColor;
UIColor *kVariant2PlaceholderTextColor;
UIColor *kVariant2SeparatorColor;
UIColor *kVariant2SecondaryBgColor;
UIColor *kVariant2SecondaryTextColor;
UIColor *kVariant2WarnTextColor;
UIColor *kVariant2PresenceIndicatorOnlineColor;

@implementation DesignValues

+ (DesignValues *)sharedInstance
{
    static DesignValues *sharedOnceInstance;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedOnceInstance = [[DesignValues alloc] init];
    });
    
    return sharedOnceInstance;
}

+ (void)load
{
    [super load];

    // Load colors at the app load time for the life of the app
    kColorDarkBlue = UIColorFromRGB(0x162d58);
    kColorDarkGreyBlue = UIColorFromRGB(0x374c72);
    kColorLightNavy = UIColorFromRGB(0x124a9d);
    kColorGreyishPurple = UIColorFromRGB(0x8b8999);
    kColorWarmGrey = UIColorFromRGB(0x858585);
    kColorLightGrey = UIColorFromRGB(0xf0f0f0);
    kColorDarkGrey = UIColorFromRGB(0xcccccc);
    
    // Observe user interface theme change.
    [[NSUserDefaults standardUserDefaults] addObserver:[DesignValues sharedInstance] forKeyPath:@"userInterfaceTheme" options:0 context:nil];
    [[DesignValues sharedInstance] userInterfaceThemeDidChange];
    
    // Observe "Invert Colours" settings changes (available since iOS 11)
    [[NSNotificationCenter defaultCenter] addObserver:[DesignValues sharedInstance] selector:@selector(accessibilityInvertColorsStatusDidChange) name:UIAccessibilityInvertColorsStatusDidChangeNotification object:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([@"userInterfaceTheme" isEqualToString:keyPath])
    {
        [self userInterfaceThemeDidChange];
    }
}

- (void)accessibilityInvertColorsStatusDidChange
{
    // Refresh the theme only for "auto"
    NSString *theme = RiotSettings.shared.userInterfaceTheme;
    if (!theme || [theme isEqualToString:@"auto"])
    {
        [self userInterfaceThemeDidChange];
    }
}

- (void)setupVariant1Colors {
    
    // Status bar
    
    kVariant1StatusBarStyle = UIStatusBarStyleLightContent;
    
    // Bar
    
    kVariant1BarBgColor = kColorDarkBlue;
    kVariant1BarTitleColor = [UIColor whiteColor];
    kVariant1BarSubTitleColor = [UIColor whiteColor];
    kVariant1BarActionColor = [UIColor whiteColor];
    
    // Button
    
    kVariant1ButtonBorderedTitleColor = [UIColor whiteColor];
    kVariant1ButtonBorderedBgColor = kColorLightNavy;
    kVariant1ButtonPlainTitleColor = kColorLightNavy;
    kVariant1ButtonPlainBgColor = [UIColor clearColor];
    
    // Body
    
    kVariant1PrimaryBgColor = [UIColor whiteColor];
    kVariant1PrimaryTextColor = [UIColor blackColor];
    kVariant1PrimarySubTextColor = kColorDarkBlue;
    kVariant1PlaceholderTextColor = kColorWarmGrey;
    kVariant1SeparatorColor = kColorLightNavy;
    kVariant1SecondaryBgColor = kColorLightGrey;
    kVariant1SecondaryTextColor = kColorWarmGrey;
    kVariant1WarnTextColor = [UIColor redColor];
    
    kVariant1PresenceIndicatorOnlineColor = UIColorFromRGB(0x60ad0d);
    kVariant1OverlayBackgroundColor = [UIColor colorWithWhite:0.7 alpha:0.5];
}

- (void)setupVariant2Colors {
    
    // Satus bar
    
    kVariant2StatusBarStyle = UIStatusBarStyleDefault;
    
    // Bar
    
    kVariant2BarBgColor = [UIColor whiteColor];
    kVariant2BarTitleColor = [UIColor blackColor];
    kVariant2BarSubTitleColor = kColorDarkBlue;
    kVariant2BarActionColor = kColorLightNavy;
    
    // Button
    
    kVariant2ButtonBorderedTitleColor = [UIColor whiteColor];
    kVariant2ButtonBorderedBgColor = kColorDarkBlue;
    kVariant2ButtonPlainTitleColor = kColorLightNavy;
    kVariant2ButtonPlainBgColor = [UIColor clearColor];
    
    // Body
    
    kVariant2PrimaryBgColor = [UIColor whiteColor];
    kVariant2PrimaryTextColor = [UIColor blackColor];
    kVariant2PrimarySubTextColor = kColorDarkBlue;
    kVariant2PlaceholderTextColor = kColorWarmGrey;
    kVariant2SeparatorColor = kColorLightNavy;
    kVariant2SecondaryBgColor = kColorLightGrey;
    kVariant2SecondaryTextColor = kColorWarmGrey;
    kVariant2WarnTextColor = [UIColor redColor];
    
    kVariant2PresenceIndicatorOnlineColor = UIColorFromRGB(0x60ad0d);
    kVariant2OverlayBackgroundColor = [UIColor colorWithWhite:0.7 alpha:0.5];
}

- (void)userInterfaceThemeDidChange
{
    // Tchap: Only one theme is supported for the moment
//    // Retrieve the current selected theme ("light" if none. "auto" is used as default from iOS 11).
//    NSString *theme = RiotSettings.shared.userInterfaceTheme;
//
//    if (!theme || [theme isEqualToString:@"auto"])
//    {
//        theme = UIAccessibilityIsInvertColorsEnabled() ? @"dark" : @"light";
//    }
//
//    if ([theme isEqualToString:@"dark"])
//    {
//        // TODO
//    }
//    else
    {
        // Set light theme colors by default.
        [self setupVariant1Colors];
        
        [self setupVariant2Colors];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDesignValuesDidChangeThemeNotification object:nil];
}

@end
