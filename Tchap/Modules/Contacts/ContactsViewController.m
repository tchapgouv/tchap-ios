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

#import "RageShakeManager.h"
#import "ContactsDataSource.h"
#import "Contact.h"

#import "GeneratedInterface-Swift.h"

NSString *const ContactErrorDomain = @"ContactErrorDomain";

@interface ContactsViewController () <MXKDataSourceDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) ContactsDataSource *contactsDataSource;

@property (nonatomic) BOOL showSearchBar;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) BOOL enableMultipleSelection;

@property (weak, nonatomic) UIAlertController *currentAlert;

@property (nonatomic) UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) DiscussionFinder* discussionFinder;

/**
 The analytics instance screen name (Default is "ContactsTable").
 */
@property (nonatomic) NSString *screenName;

@end

@implementation ContactsViewController

#pragma mark - Setup

+ (instancetype)instantiate
{
    return [self instantiateWithShowSearchBar:NO enableMultipleSelection:NO];
}

+ (instancetype)instantiateWithShowSearchBar:(BOOL)showSearchBar
                     enableMultipleSelection:(BOOL)enableMultipleSelection
{
    ContactsViewController *viewController = [[UIStoryboard storyboardWithName:NSStringFromClass([ContactsViewController class]) bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    viewController.showSearchBar = showSearchBar;
    viewController.enableMultipleSelection = enableMultipleSelection;
    [viewController updateTheme];
    viewController.screenName = @"ContactsTable";
    return viewController;
}

#pragma mark - Life cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Finalize table view configuration
    self.tableView.dataSource = self.contactsDataSource; // Note: dataSource may be nil here
    
    if (self.enableMultipleSelection)
    {
        [self.tableView registerNib:SelectableContactCell.nib forCellReuseIdentifier:SelectableContactCell.defaultReuseIdentifier];
    }
    else
    {
        [self.tableView registerNib:ContactCell.nib forCellReuseIdentifier:ContactCell.defaultReuseIdentifier];
    }
    [self.tableView registerNib:ContactButtonView.nib forCellReuseIdentifier:ContactButtonView.defaultReuseIdentifier];
    
    // Hide line separators of empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    
    // Enable self-sizing cells.
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 60;
    self.tableView.allowsMultipleSelection = self.enableMultipleSelection;
    
    // Add activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    CGRect frame = self.activityIndicator.frame;
    frame.size.width += 30;
    frame.size.height += 30;
    self.activityIndicator.bounds = frame;
    [self.activityIndicator.layer setCornerRadius:5];
    self.activityIndicator.center = self.view.center;
    [self.view addSubview:self.activityIndicator];
    
    if (self.showSearchBar)
    {
        [self setupSearchController];
    }
    
    self.discussionFinder = [[DiscussionFinder alloc] initWithSession:self.contactsDataSource.mxSession];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return ThemeService.shared.theme.statusBarStyle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Check whether the access to the local contacts has not been already asked.
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        // Allow by default the local contacts sync in order to discover matrix users.
        // This setting change will trigger the loading of the local contacts, which will automatically
        // ask user permission to access their local contacts.
        [MXKAppSettings standardAppSettings].syncLocalContacts = YES;
    }
    
    [self updateTheme];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UISearchBar *searchBar = self.searchController.searchBar;
    if (searchBar)
    {
        if (@available(iOS 13.0, *))
        {
            // iOS 13 issue: When the search bar is shown, the navigation bar color is replaced with the background color of the TableView
            // Patch: Always show the search bar on iOS 13
            self.navigationItem.hidesSearchBarWhenScrolling = NO;
        }
        else
        {
            // Enable to hide search bar on scrolling after first time view appear
            self.navigationItem.hidesSearchBarWhenScrolling = YES;
        }
        
        // For unknown reason, we have to force here the UISearchBar search text color again.
        // The value set by [updateWithStyle:] call is ignored.
        UITextField *searchBarTextField = searchBar.vc_searchTextField;
        searchBarTextField.textColor = searchBar.tintColor;
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchController.searchBar resignFirstResponder];
    
    if (self.currentAlert)
    {
        [self.currentAlert dismissViewControllerAnimated:NO completion:nil];
        self.currentAlert = nil;
    }
}

#pragma mark - Activity indicator

- (void)startActivityIndicator
{
    [self.view bringSubviewToFront:self.activityIndicator];
    [self.activityIndicator startAnimating];
    
    // Show the loading wheel after a delay so that if the caller calls stopActivityIndicator
    // in a short future, the loading wheel will not be displayed to the end user.
    self.activityIndicator.alpha = 0;
    [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.activityIndicator.alpha = 1;
    } completion:^(BOOL finished) {}];
}

- (void)stopActivityIndicator
{
    [self.activityIndicator stopAnimating];
}

#pragma mark - Public

- (void)displayList:(ContactsDataSource*)listDataSource
{
    // Cancel registration on existing dataSource if any
    if (self.contactsDataSource)
    {
        self.contactsDataSource.delegate = nil;
    }
    
    self.contactsDataSource = listDataSource;
    self.contactsDataSource.delegate = self;
    
    if (self.tableView)
    {
        // Set up table data source
        self.tableView.dataSource = self.contactsDataSource;
    }
}

#pragma mark - Private

/**
 Refresh the contacts table display.
 */
- (void)refreshContactsTable
{
    [self.tableView reloadData];
}

- (void)setupSearchController
{
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.searchResultsUpdater = self;
    searchController.searchBar.placeholder = NSLocalizedStringFromTable(@"contacts_search_bar_placeholder", @"Tchap", nil);
    searchController.hidesNavigationBarDuringPresentation = NO;
    
    self.navigationItem.searchController = searchController;
    // Make the search bar visible on first view appearance
    self.navigationItem.hidesSearchBarWhenScrolling = NO;
    
    self.definesPresentationContext = YES;
    
    self.searchController = searchController;
}

#pragma mark - Theme

- (void)updateTheme
{
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [ThemeService.shared.theme applyStyleOnNavigationBar:navigationBar];
    }
    
    self.tableView.backgroundColor = ThemeService.shared.theme.backgroundColor;
    self.view.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    //TODO Design the activity indicator for Tchap
    self.activityIndicator.backgroundColor = ThemeService.shared.theme.overlayBackgroundColor;
    
    UISearchBar *searchBar = self.searchController.searchBar;
    
    if (searchBar)
    {
        [ThemeService.shared.theme applyStyleOnSearchBar:searchBar];
    }
    
    if (self.tableView.dataSource)
    {
        [self refreshContactsTable];
    }
    
    [self setNeedsStatusBarAppearanceUpdate];
}

#pragma mark - MXKDataSourceDelegate

- (Class<MXKCellRendering>)cellViewClassForCellData:(MXKCellData*)cellData
{
    Class<MXKCellRendering> tableViewCellClass;
    
    if ([cellData isKindOfClass:MXKContact.class])
    {
        if (self.enableMultipleSelection)
        {
            tableViewCellClass = SelectableContactCell.class;
        }
        else
        {
            tableViewCellClass = ContactCell.class;
        }
    }
    
    return tableViewCellClass;
}

- (NSString *)cellReuseIdentifierForCellData:(MXKCellData*)cellData
{
    NSString *reuseIdentifier;
    
    if ([cellData isKindOfClass:MXKContact.class])
    {
        if (self.enableMultipleSelection)
        {
            reuseIdentifier =  [SelectableContactCell defaultReuseIdentifier];
        }
        else
        {
            reuseIdentifier =  [ContactCell defaultReuseIdentifier];
        }
    }
    
    return reuseIdentifier;
}

- (void)dataSource:(MXKDataSource *)dataSource didCellChange:(id)changes
{
    [self refreshContactsTable];
}

#pragma mark - UITableView delegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath;
{
    cell.backgroundColor = ThemeService.shared.theme.backgroundColor;
    
    if (!cell.selectedBackgroundView)
    {
        cell.selectedBackgroundView = [[UIView alloc] init];
    }
    
    cell.selectedBackgroundView.backgroundColor = ThemeService.shared.theme.selectedBackgroundColor;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self.contactsDataSource heightForHeaderInSection:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self.contactsDataSource viewForHeaderInSection:section withFrame:[tableView rectForHeaderInSection:section]];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check whether the user wants to invite people by sharing a link to the room
    if ([self.contactsDataSource isInviteByLinkButtonIndexPath:indexPath])
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        RoomAccessByLinkViewController *roomAccessByLinkViewController = [RoomAccessByLinkViewController instantiateWithSession:self.contactsDataSource.mxSession roomId:self.contactsDataSource.inviteByLinkRoomId];
        [self.navigationController pushViewController:roomAccessByLinkViewController animated:YES];
        return;
    }
    
    MXKContact *mxkContact = [self.contactsDataSource contactAtIndexPath:indexPath];
    if (mxkContact)
    {
        NSString *identifier = [self.contactsDataSource contactIdentifier:mxkContact];
        // Before selecting a new email, we ask the delegate whether the email is allowed.
        if ([MXTools isEmailAddress:identifier]
            && !self.contactsDataSource.selectedContactByIdentifier[identifier]
            && [self.delegate respondsToSelector:@selector(contactsViewController:askPermissionToSelect:completion:)])
        {
            [self startActivityIndicator];
            MXWeakify(self);
            [self.delegate contactsViewController:self
                            askPermissionToSelect:identifier
                                       completion:^(BOOL granted, NSString * _Nullable reason) {
                                           MXStrongifyAndReturnIfNil(self);
                                           [self stopActivityIndicator];
                                           if (granted)
                                           {
                                               [self selectContact:mxkContact atIndexPath:indexPath];
                                           }
                                           else
                                           {
                                               MXWeakify(self);
                                               [self.currentAlert dismissViewControllerAnimated:NO completion:nil];
                                               self.currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"contacts_picker_unauthorized_email_title", @"Tchap", nil)
                                                                                                       message:reason
                                                                                                preferredStyle:UIAlertControllerStyleAlert];
                                               [self.currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                                                     style:UIAlertActionStyleDefault
                                                                                                   handler:^(UIAlertAction * action) {
                                                                                                       
                                                                                                       MXStrongifyAndReturnIfNil(self);
                                                                                                       self.currentAlert = nil;
                                                                                                       
                                                                                                   }]];
                                               [self.currentAlert mxk_setAccessibilityIdentifier: @"ContactsVCInviteByEmailError"];
                                               [self presentViewController:self.currentAlert animated:YES completion:nil];
                                               [tableView deselectRowAtIndexPath:indexPath animated:YES];
                                           }
                                       }];
        }
        else
        {
            [self selectContact:mxkContact atIndexPath:indexPath];
        }
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (void)selectContact:(MXKContact*)contact atIndexPath:(NSIndexPath *)indexPath
{
    // Store into the session the user info if any (This allows to display correctly this contact in other screens)
    if ([contact isKindOfClass:Contact.class]) {
        MXUser *user = ((Contact*)contact).mxUser;
        if (user)
        {
            [self.contactsDataSource.mxSession.store storeUser:user];
        }
    }
    
    if (self.enableMultipleSelection)
    {
        [self.contactsDataSource selectOrDeselectContactAtIndexPath:indexPath];
    }
    
    if (self.delegate)
    {
        // Tchap: Check if there is already a discussion with the contact or not.
        [self.discussionFinder hasDiscussionFor:contact.contactID completion:^(BOOL hasDiscussion) {
            if (hasDiscussion) {
                [self.delegate contactsViewController:self didSelectContact:contact];
            } else {
                // Show alert to prevent unwanted discussion creation.
                UIAlertController* alert = [UIAlertController alertControllerWithTitle: nil
                                                                               message: [NSString stringWithFormat:NSLocalizedStringFromTable(@"tchap_dialog_prompt_new_direct_chat", @"Tchap", nil), contact.displayName]
                                               preferredStyle:UIAlertControllerStyleAlert];
                
                MXWeakify(self);
                UIAlertAction* defaultAction = [UIAlertAction actionWithTitle: NSLocalizedStringFromTable(@"action_proceed", @"Tchap", nil) style:UIAlertActionStyleDefault
                   handler:^(UIAlertAction * action) {
                    MXStrongifyAndReturnIfNil(self);
                    [self.delegate contactsViewController:self didSelectContact:contact];
                }];
                
                UIAlertAction* cancelAction = [UIAlertAction actionWithTitle: NSLocalizedStringFromTable(@"action_cancel", @"Tchap", nil) style:UIAlertActionStyleDefault
                   handler:nil];
                
                [alert addAction:cancelAction];
                [alert addAction:defaultAction];
                [self presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    
    if (self.enableMultipleSelection)
    {
        [self.tableView reloadData];
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    NSString *searchText = searchController.searchBar.text;
    [self.contactsDataSource searchWithPattern:searchText forceReset:NO];
}

@end
