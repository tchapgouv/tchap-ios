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

#import "ContactsViewController.h"

#import "RiotDesignValues.h"
#import "RageShakeManager.h"
#import "Analytics.h"
#import "LegacyAppDelegate.h"
#import "ContactTableViewCell.h"
#import "ContactsDataSource.h"

#import "GeneratedInterface-Swift.h"

@interface ContactsViewController () <UITableViewDelegate, MXKDataSourceDelegate, Stylable>

/**
 The contacts table view.
 */
@property (weak, nonatomic) IBOutlet UITableView *contactsTableView;

@property (strong, nonatomic) ContactsDataSource *contactsDataSource;
@property (nonatomic, strong) id<Style> currentStyle;

/**
 If YES, the table view will scroll at the top on the next data source refresh.
 It comes back to NO after each refresh.
 */
@property (nonatomic) BOOL shouldScrollToTopOnRefresh;

/**
 The analytics instance screen name (Default is "ContactsTable").
 */
@property (nonatomic) NSString *screenName;

/**
 Refresh the cell selection in the table.
 
 This must be done accordingly to the currently selected contact in the master tabbar of the application.
 
 @param forceVisible if YES and if the corresponding cell is not visible, scroll the table view to make it visible.
 */
- (void)refreshCurrentSelectedCell:(BOOL)forceVisible;

/**
 Refresh the contacts table display.
 */
- (void)refreshContactsTable;

@end

@implementation ContactsViewController

#pragma mark - Class methods

+ (instancetype)instantiate
{
    ContactsViewController *viewController = [[UIStoryboard storyboardWithName:NSStringFromClass([ContactsViewController class]) bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    [viewController updateWithStyle:Variant1Style.shared];
    return viewController;
}

#pragma mark -

- (void)finalizeInit
{
    [super finalizeInit];
    
    // Setup `MXKViewControllerHandling` properties
    self.enableBarTintColorStatusChange = NO;
    self.rageShakeManager = [RageShakeManager sharedManager];
    
    _screenName = @"ContactsTable";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Finalize table view configuration
    self.contactsTableView.delegate = self;
    self.contactsTableView.dataSource = self.contactsDataSource; // Note: dataSource may be nil here
    
    [self.contactsTableView registerClass:ContactTableViewCell.class forCellReuseIdentifier:ContactTableViewCell.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.contactsTableView.tableFooterView = [[UIView alloc] init];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.currentStyle.statusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Screen tracking
    [[Analytics sharedInstance] trackScreen:_screenName];

    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    
    [self refreshContactsTable];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
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

    self.activityIndicator.backgroundColor = kRiotOverlayColor;
    
    self.contactsTableView.backgroundColor = style.backgroundColor;
    self.view.backgroundColor = style.backgroundColor;
    
    if (self.contactsTableView.dataSource)
    {
        [self refreshContactsTable];
    }
}

#pragma mark -

- (void)displayList:(ContactsDataSource*)listDataSource
{
    // Cancel registration on existing dataSource if any
    if (self.contactsDataSource)
    {
        self.contactsDataSource.delegate = nil;
    }
    
    self.contactsDataSource = listDataSource;
    self.contactsDataSource.delegate = self;
    
    if (self.contactsTableView)
    {
        // Set up table data source
        self.contactsTableView.dataSource = self.contactsDataSource;
    }
}

- (void)refreshContactsTable
{
    [self.contactsTableView reloadData];
    
    if (_shouldScrollToTopOnRefresh)
    {
        [self scrollToTop:NO];
        _shouldScrollToTopOnRefresh = NO;
    }
    
    // In case of split view controller where the primary and secondary view controllers are displayed side-by-side on screen,
    // the selected room (if any) is updated and kept visible.
    if (self.splitViewController && !self.splitViewController.isCollapsed)
    {
        [self refreshCurrentSelectedCell:YES];
    }
}

- (void)refreshCurrentSelectedCell:(BOOL)forceVisible
{
    // Update here the index of the current selected cell (if any) - Useful in landscape mode with split view controller.
    NSIndexPath *currentSelectedCellIndexPath = nil;
    
    if (currentSelectedCellIndexPath)
    {
        // Select the right row
        [self.contactsTableView selectRowAtIndexPath:currentSelectedCellIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        if (forceVisible)
        {
            // Scroll table view to make the selected row appear at second position
            NSInteger topCellIndexPathRow = currentSelectedCellIndexPath.row ? currentSelectedCellIndexPath.row - 1: currentSelectedCellIndexPath.row;
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:topCellIndexPathRow inSection:currentSelectedCellIndexPath.section];
            [self.contactsTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.contactsTableView indexPathForSelectedRow];
        if (indexPath)
        {
            [self.contactsTableView deselectRowAtIndexPath:indexPath animated:NO];
        }
    }
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return ContactTableViewCell.class;
    }
    
    return nil;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    if ([cellData isKindOfClass:MXKContact.class])
    {
        return [ContactTableViewCell defaultReuseIdentifier];
    }
    
    return nil;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    [self refreshContactsTable];
}

#pragma mark - Internal methods

- (void)scrollToTop:(BOOL)animated
{
    // Scroll to the top
    [self.contactsTableView setContentOffset:CGPointMake(-self.contactsTableView.mxk_adjustedContentInset.left, -self.contactsTableView.mxk_adjustedContentInset.top) animated:animated];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = self.currentStyle.backgroundColor;
    
    if (!cell.selectedBackgroundView)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.selectedBackgroundView.backgroundColor = self.currentStyle.secondaryBackgroundColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self.contactsDataSource heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self.contactsDataSource viewForHeaderInSection:section withFrame:[tableView rectForHeaderInSection:section]];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.contactsDataSource contactAtIndexPath:indexPath])
    {
        // Return the default height of the contact cell
        return 74.0;
    }
    
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MXKContact *mxkContact = [self.contactsDataSource contactAtIndexPath:indexPath];
    
    if (self.delegate && mxkContact)
    {
        [self.delegate contactsViewController:self didSelectContact:mxkContact];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

@end
