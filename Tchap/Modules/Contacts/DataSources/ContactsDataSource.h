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

#import <MatrixKit/MatrixKit.h>


/**
 This enum is used to filter the displayed contacts.
 */
typedef enum : NSUInteger
{
    /**
     * Display all the local contacts who have email(s).
     * The contacts with several emails are displayed several times (One item by email).
     * When an email is bound to a Tchap account, the Tchap display name is used and
     * the email is hidden. Else the name defined in the local contacts book is used with the email.
     * Note: the Tchap users for who a discussion (direct chat) exists will be considered as local contacts.
     * This means they will appear in the local contacts section.
     * The search in the Tchap users directory is available (except if the current user is external).
     */
    ContactsDataSourceTchapFilterAll,
    /**
     * Same as ALL, but the contacts related to the external Tchap server(s) are excluded.
     */
    ContactsDataSourceTchapFilterAllWithoutExternals,
    /**
     * Same as ALL, but only the contacts bound to the same host than the current user are displayed.
     */
    ContactsDataSourceTchapFilterAllWithoutFederation,
    /**
     * Display only the Tchap users.
     */
    ContactsDataSourceTchapFilterTchapUsersOnly,
    /**
     * Display only the Tchap users by excluding the external ones.
     */
    ContactsDataSourceTchapFilterTchapUsersOnlyWithoutExternals,
    /**
     * Display only the Tchap users hosted on the same host than the current user.
     */
    ContactsDataSourceTchapFilterTchapUsersOnlyWithoutFederation,
    /**
     * Display the local contacts who are not Tchap users yet.
     */
    ContactsDataSourceTchapFilterAllWithoutTchapUsers
} ContactsDataSourceTchapFilter;

/**
 The state of the users search from the homeserver user directory.
 */
typedef enum : NSUInteger
{
    ContactsDataSourceUserDirectoryStateLoading,
    ContactsDataSourceUserDirectoryStateLoadedButLimited,
    ContactsDataSourceUserDirectoryStateLoaded,
    // The search is based on local known matrix contacts
    ContactsDataSourceUserDirectoryStateOfflineLoading,
    ContactsDataSourceUserDirectoryStateOfflineLoaded
} ContactsDataSourceUserDirectoryState;


/**
 'ContactsDataSource' is a base class to handle contacts in Tchap.
 */
@interface ContactsDataSource : MXKDataSource <UITableViewDataSource, UIGestureRecognizerDelegate>
{
@protected
    // Section indexes
    NSInteger inviteToTchapButtonSection;
    NSInteger addEmailButtonSection;
    NSInteger filteredLocalContactsSection;
    NSInteger filteredMatrixContactsSection;
    
    // Tell whether the non-matrix-enabled contacts must be hidden or not. NO by default.
    BOOL hideNonMatrixEnabledContacts;
    
    // Search results
    NSString *currentSearchText;
    NSMutableArray<MXKContact*> *filteredLocalContacts;
    NSMutableArray<MXKContact*> *filteredMatrixContacts;
}

/**
 Check whether the invite button is located to the given index path.
 
 @param indexPath the index of the cell
 @return YES if the indexPath is the invite button one
 */
-(BOOL)isInviteButtonIndexPath:(NSIndexPath*)indexPath;

/**
 Check whether the add email button is located to the given index path.
 
 @param indexPath the index of the cell
 @return YES if the indexPath is the addEmail button one
 */
-(BOOL)isAddEmailButtonIndexPath:(NSIndexPath*)indexPath;

/**
 Get the contact at the given index path.
 
 @param indexPath the index of the cell
 @return the contact
 */
-(MXKContact *)contactAtIndexPath:(NSIndexPath*)indexPath;

/**
 Get the index path of the cell related to the provided contact.
 
 @param contact the contact.
 @return indexPath the index of the cell (nil if not found or if the related section is shrinked).
 */
- (NSIndexPath*)cellIndexPathWithContact:(MXKContact*)contact;

/**
 Get the height of the section header view.
 
 @param section the section  index
 @return the header height.
 */
- (CGFloat)heightForHeaderInSection:(NSInteger)section;

/**
 Get the attributed string for the header title of the specified section.
 
 @param section the section  index.
 @return the section title.
 */
- (NSAttributedString *)attributedStringForHeaderTitleInSection:(NSInteger)section;

/**
 Get the section header view.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @return the section header.
 */
- (UIView *)viewForHeaderInSection:(NSInteger)section withFrame:(CGRect)frame;

/**
 Get the sticky header view for the specified section.
 
 @param section the section  index
 @param frame the drawing area for the header of the specified section.
 @return the sticky header view.
 */
- (UIView *)viewForStickyHeaderInSection:(NSInteger)section withFrame:(CGRect)frame;

/**
 Refresh the contacts data source and notify its delegate.
 */
- (void)forceRefresh;

/**
 Select or deselect a contact for an index path.

 @param indexPath The indexpath of contact to select/deselect.
 */
- (void)selectOrDeselectContactAtIndexPath:(NSIndexPath*)indexPath;

/**
 Add an email address to the selection.
 
 @param email.
 @return the contact used to represent the email in the selection.
 */
- (MXKContact*)addSelectedEmail:(NSString*)email;

/**
 Return the identifier (Matrix id or email) related to a contact.
 
 @param contact
 */
- (NSString*)contactIdentifier:(MXKContact*)contact;

#pragma mark - Configuration
/**
 Tell whether the sections are shrinkable. NO by default.
 */
@property (nonatomic) BOOL areSectionsShrinkable;

/**
 Tell which list of contacts is expected (see ContactsDataSourceTchapFilter)
 ContactsDataSourceTchapFilterAll by default.
 */
@property (nonatomic) ContactsDataSourceTchapFilter contactsFilter;

/**
 The type of standard accessory view the contact cells should use
 Default is UITableViewCellAccessoryNone.
 */
@property (nonatomic) UITableViewCellAccessoryType contactCellAccessoryType;

/**
 An image used to create a custom accessy view on the right side of the contact cells.
 If set, use custom view. ignore accessoryType
 */
@property (nonatomic) UIImage *contactCellAccessoryImage;

/**
 The dictionary of the ignored local contacts, the keys are their email. Empty by default.
 */
@property (nonatomic) NSMutableDictionary<NSString*, MXKContact*> *ignoredContactsByEmail;

/**
 The dictionary of the ignored matrix contacts, the keys are their matrix identifier. Empty by default.
 */
@property (nonatomic) NSMutableDictionary<NSString*, MXKContact*> *ignoredContactsByMatrixId;

/**
 The dictionary of the selected contacts, the keys are their matrix identifier or their email address. Empty by default.
 */
@property (nonatomic, strong, readonly) NSMutableDictionary<NSString*, MXKContact*> *selectedContactByIdentifier;

/**
 Filter the contacts list, by keeping only the contacts who have the search pattern
 as prefix in their display name, their matrix identifiers and/or their contact methods (emails, phones).
 
 @param searchText the search pattern (nil to reset filtering).
 @param forceReset tell whether the search request must be applied by ignoring the previous search result if any (use NO by default).
 */
- (void)searchWithPattern:(NSString *)searchText forceReset:(BOOL)forceReset;

/**
 Tell whether the invite to Tchap button is displayed at the top of the contacts list (NO by default).
 */
@property (nonatomic) BOOL showInviteToTchapButton;

/**
 Tell whether the user is allowed to add some email addresses to the list (NO by default).
 */
@property (nonatomic) BOOL showAddEmailButton;

/**
 The state of the users search from the homeserver user directory.
 */
@property (nonatomic, readonly) ContactsDataSourceUserDirectoryState userDirectoryState;

@end
