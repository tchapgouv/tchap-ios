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
#import "Analytics.h"
#import "ContactsDataSource.h"
#import "Contact.h"

#import "GeneratedInterface-Swift.h"

NSString *const ContactErrorDomain = @"ContactErrorDomain";

@interface ContactsViewController () <MXKDataSourceDelegate, Stylable, UISearchResultsUpdating>

@property (strong, nonatomic) ContactsDataSource *contactsDataSource;
@property (nonatomic, strong) id<Style> currentStyle;

@property (nonatomic) BOOL showSearchBar;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) BOOL enableMultipleSelection;

@property (weak, nonatomic) UIAlertController *currentAlert;

@property (nonatomic) UIActivityIndicatorView *activityIndicator;

/**
 The analytics instance screen name (Default is "ContactsTable").
 */
@property (nonatomic) NSString *screenName;

@end

@implementation ContactsViewController

#pragma mark - Setup

+ (instancetype)instantiateWithStyle:(id<Style>)style
{
    return [self instantiateWithStyle:style showSearchBar:NO enableMultipleSelection:NO];
}

+ (instancetype)instantiateWithStyle:(id<Style>)style showSearchBar:(BOOL)showSearchBar enableMultipleSelection:(BOOL)enableMultipleSelection
{
    ContactsViewController *viewController = [[UIStoryboard storyboardWithName:NSStringFromClass([ContactsViewController class]) bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    viewController.showSearchBar = showSearchBar;
    viewController.enableMultipleSelection = enableMultipleSelection;
    [viewController updateWithStyle:style];
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
    
    [self updateWithStyle:self.currentStyle];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    UISearchBar *searchBar = self.searchController.searchBar;
    if (searchBar)
    {
        if (@available(iOS 11.0, *))
        {
            // Enable to hide search bar on scrolling after first time view appear
            self.navigationItem.hidesSearchBarWhenScrolling = YES;
        }
        
        // For unknown reason, we have to force here the UISearchBar search text color again.
        // The value set by [updateWithStyle:] call is ignored.
        UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
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
    
    if (@available(iOS 11.0, *))
    {
        self.navigationItem.searchController = searchController;
        // Make the search bar visible on first view appearance
        self.navigationItem.hidesSearchBarWhenScrolling = NO;
    }
    else
    {
        self.tableView.tableHeaderView = searchController.searchBar;
    }
    
    self.definesPresentationContext = YES;
    
    self.searchController = searchController;
}

- (void)promptUserToFillAnEmailToInvite:(void (^)(NSString *email))completion
{
    MXWeakify(self);
    
    [self.currentAlert dismissViewControllerAnimated:NO completion:nil];
    self.currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"contacts_invite_by_email_title", @"Tchap", nil)
                                                            message:NSLocalizedStringFromTable(@"contacts_invite_by_email_message", @"Tchap", nil)
                                                     preferredStyle:UIAlertControllerStyleAlert];
    
    [self.currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"cancel"]
                                                     style:UIAlertActionStyleCancel
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       self.currentAlert = nil;
                                                       
                                                   }]];
    
    [self.currentAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.secureTextEntry = NO;
        textField.placeholder = nil;
        textField.keyboardType = UIKeyboardTypeEmailAddress;
    }];
    
    [self.currentAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedStringFromTable(@"action_invite", @"Tchap", nil)
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action) {
                                                       
                                                       MXStrongifyAndReturnIfNil(self);
                                                       UITextField *textField = [self.currentAlert textFields].firstObject;
                                                       // Force the filled email address in lowercase
                                                       NSString *email = [textField.text lowercaseString];
                                                       self.currentAlert = nil;
                                                       
                                                       if ([MXTools isEmailAddress:email])
                                                       {
                                                           completion(email);
                                                       }
                                                       else
                                                       {
                                                           MXWeakify(self);
                                                           [self.currentAlert dismissViewControllerAnimated:NO completion:nil];
                                                           self.currentAlert = [UIAlertController alertControllerWithTitle:NSLocalizedStringFromTable(@"authentication_error_invalid_email", @"Tchap", nil)
                                                                                                                   message:nil
                                                                                                            preferredStyle:UIAlertControllerStyleAlert];
                                                           [self.currentAlert addAction:[UIAlertAction actionWithTitle:[NSBundle mxk_localizedStringForKey:@"ok"]
                                                                                                                 style:UIAlertActionStyleDefault
                                                                                                               handler:^(UIAlertAction * action) {
                                                                                                                   
                                                                                                                   MXStrongifyAndReturnIfNil(self);
                                                                                                                   self.currentAlert = nil;
                                                                                                                   
                                                                                                               }]];
                                                           [self.currentAlert mxk_setAccessibilityIdentifier: @"ContactsVCInviteByEmailError"];
                                                           [self presentViewController:self.currentAlert animated:YES completion:nil];
                                                       }
                                                   }]];
    
    [self.currentAlert mxk_setAccessibilityIdentifier: @"ContactsVCInviteByEmailDialog"];
    [self presentViewController:self.currentAlert animated:YES completion:nil];
}

- (void)sendInviteToTchapByEmail:(NSString *)email
{
    // Sanity check
    if ([self.delegate respondsToSelector:@selector(contactsViewController:sendInviteToTchapByEmail:)])
    {
        [self.delegate contactsViewController:self sendInviteToTchapByEmail:email];
    }
}

- (void)selectEmail:(NSString *)email
{
    // Check whether the delegate allows this email to be invited
    if ([self.delegate respondsToSelector:@selector(contactsViewController:askPermissionToSelect:completion:)])
    {
        [self startActivityIndicator];
        MXWeakify(self);
        [self.delegate contactsViewController:self
                        askPermissionToSelect:email
                                   completion:^(BOOL granted, NSString * _Nullable reason) {
                                       MXStrongifyAndReturnIfNil(self);
                                       [self stopActivityIndicator];
                                       if (granted)
                                       {
                                           MXKContact *contact = [self.contactsDataSource addSelectedEmail:email];
                                           if (self.delegate)
                                           {
                                               [self.delegate contactsViewController:self didSelectContact:contact];
                                           }
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
                                       }
                                   }];
    }
    else
    {
        // By default all email is allowed
        MXKContact *contact = [self.contactsDataSource addSelectedEmail:email];
        if (self.delegate)
        {
            [self.delegate contactsViewController:self didSelectContact:contact];
        }
    }
}

#pragma mark - Stylable

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    
    if (navigationBar)
    {
        [style applyStyleOnNavigationBar:navigationBar];
    }
    
    self.tableView.backgroundColor = style.backgroundColor;
    self.view.backgroundColor = style.backgroundColor;
    
    //TODO Design the activvity indicator for Tchap
    self.activityIndicator.backgroundColor = style.overlayBackgroundColor;
    
    UISearchBar *searchBar = self.searchController.searchBar;
    
    if (searchBar)
    {
        if (@available(iOS 11.0, *))
        {
            searchBar.tintColor = style.barActionColor;
        }
        else
        {
            searchBar.tintColor = style.primarySubTextColor;
        }
        
        UITextField *searchBarTextField = [searchBar valueForKey:@"_searchField"];
        searchBarTextField.textColor = searchBar.tintColor;
    }
    
    if (self.tableView.dataSource)
    {
        [self refreshContactsTable];
    }
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Check first the potential invite button
    if ([self.contactsDataSource isInviteButtonIndexPath:indexPath])
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self promptUserToFillAnEmailToInvite:^(NSString *email) {
            [self sendInviteToTchapByEmail:email];
        }];
        return;
    }
    
    // Check whether the user wants to add manually some email into the list
    if ([self.contactsDataSource isAddEmailButtonIndexPath:indexPath])
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self promptUserToFillAnEmailToInvite:^(NSString *email) {
            [self selectEmail:email];
        }];
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
        [self.delegate contactsViewController:self didSelectContact:contact];
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
