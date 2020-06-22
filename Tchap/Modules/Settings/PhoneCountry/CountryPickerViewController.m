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

#import "CountryPickerViewController.h"

#import "RageShakeManager.h"
#import "Analytics.h"
#import "ThemeService.h"
#import "GeneratedInterface-Swift.h"

@interface CountryPickerViewController () <Stylable>
{
    /**
     The fake top view displayed in case of vertical bounce.
     */
    UIView *topview;
}

// Observe kThemeServiceDidChangeThemeNotification to handle user interface theme change.
@property (nonatomic, weak) id kThemeServiceDidChangeThemeNotificationObserver;
@property (strong, nonatomic) id<Style> currentStyle;

@end

@implementation CountryPickerViewController

+ (instancetype)instantiateWithStyle:(id<Style>)style
{
    CountryPickerViewController *countryPickerViewController = [CountryPickerViewController countryPickerViewController];
    countryPickerViewController.currentStyle = style;
    return countryPickerViewController;
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

    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Add a top view which will be displayed in case of vertical bounce.
    CGFloat height = self.tableView.frame.size.height;
    topview = [[UIView alloc] initWithFrame:CGRectMake(0,-height,self.tableView.frame.size.width,height)];
    topview.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.tableView addSubview:topview];

    // Observe user interface theme change.
    MXWeakify(self);
    _kThemeServiceDidChangeThemeNotificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kThemeServiceDidChangeThemeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notif) {
        
        MXStrongifyAndReturnIfNil(self);
        [self userInterfaceThemeDidChange];
        
    }];
}

- (void)userInterfaceThemeDidChange
{
    [self updateWithStyle:self.currentStyle];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    if (self.searchController.searchBar)
    {
        [style applyStyleOnSearchBar:self.searchController.searchBar];
    }
    
    //TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = style.overlayBackgroundColor;
    
    // Use the primary bg color for the table view in plain style.
    self.tableView.backgroundColor = style.backgroundColor;
    topview.backgroundColor = style.backgroundColor;
    
    if (self.tableView.dataSource)
    {
        [self.tableView reloadData];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:@"CountryPicker"];
    
    
    [self userInterfaceThemeDidChange];
}

- (void)dealloc
{
    [topview removeFromSuperview];
    topview = nil;
    
    if (_kThemeServiceDidChangeThemeNotificationObserver)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_kThemeServiceDidChangeThemeNotificationObserver];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.textLabel.textColor = self.currentStyle.primaryTextColor;
    cell.detailTextLabel.textColor = self.currentStyle.secondaryTextColor;
    cell.backgroundColor = self.currentStyle.backgroundColor;
    
    // Update the selected background view
    if (self.currentStyle.secondaryBackgroundColor)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
        cell.selectedBackgroundView.backgroundColor = self.currentStyle.secondaryBackgroundColor;
    }
    else
    {
        if (tableView.style == UITableViewStylePlain)
        {
            cell.selectedBackgroundView = nil;
        }
        else
        {
            cell.selectedBackgroundView.backgroundColor = nil;
        }
    }
}

@end
