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

UIColor *kVariant1PrimaryBgColor;
UIColor *kVariant1PrimaryTextColor;
UIColor *kVariant1PrimarySubTextColor;
UIColor *kVariant1PlaceholderTextColor;
UIColor *kVariant1ActionColor;
UIColor *kVariant1SecondaryBgColor;
UIColor *kVariant1SecondaryTextColor;

UIColor *kVariant2PrimaryBgColor;
UIColor *kVariant2PrimaryTextColor;
UIColor *kVariant2PrimarySubTextColor;
UIColor *kVariant2PlaceholderTextColor;
UIColor *kVariant2ActionColor;
UIColor *kVariant2SecondaryBgColor;
UIColor *kVariant2SecondaryTextColor;

UIStatusBarStyle kVariant1StatusBarStyle;
UIBarStyle kVariant1SearchBarStyle;
UIColor *kVariant1SearchBarTintColor;

UIStatusBarStyle kVariant2StatusBarStyle;
UIBarStyle kVariant2SearchBarStyle;
UIColor *kVariant2SearchBarTintColor;

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
        kVariant1PrimaryBgColor = [UIColor whiteColor];
        kVariant1PrimaryTextColor = [UIColor whiteColor];
        kVariant1PrimarySubTextColor = [UIColor whiteColor];
        kVariant1PlaceholderTextColor = kColorWarmGrey;
        kVariant1ActionColor = [UIColor whiteColor];
        kVariant1SecondaryBgColor = kColorDarkBlue;
        kVariant1SecondaryTextColor = [UIColor whiteColor];
        
        kVariant1StatusBarStyle = UIStatusBarStyleLightContent;
        kVariant1SearchBarStyle = UIBarStyleDefault;
        kVariant1SearchBarTintColor = nil; // Default tint color.
        
        kVariant2PrimaryBgColor = [UIColor whiteColor];
        kVariant2PrimaryTextColor = [UIColor blackColor];
        kVariant2PrimarySubTextColor = kColorDarkBlue;
        kVariant2PlaceholderTextColor = kColorWarmGrey;
        kVariant2ActionColor = kColorLightNavy;
        kVariant2SecondaryBgColor = kColorLightGrey;
        kVariant2SecondaryTextColor = kColorWarmGrey;
        
        kVariant2StatusBarStyle = UIStatusBarStyleDefault;
        kVariant2SearchBarStyle = UIBarStyleDefault;
        kVariant2SearchBarTintColor = nil; // Default tint color.
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDesignValuesDidChangeThemeNotification object:nil];
}

@end
