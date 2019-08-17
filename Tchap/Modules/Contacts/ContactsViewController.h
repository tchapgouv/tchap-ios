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

@import MatrixKit;

@class ContactsDataSource;
@protocol ContactsViewControllerDelegate, Style;

/**
 'ContactsViewController' instance is used to display/filter a list of contacts.
 */
@interface ContactsViewController : UITableViewController

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak, nullable) id<ContactsViewControllerDelegate> delegate;

/**
 Creates and returns a new `ContactsViewController` object.
  
 @param style Used to setup view style parameters.
 @return An initialized `ContactsViewController` object if successful, `nil` otherwise.
 */
+ (nonnull instancetype)instantiateWithStyle:(nonnull id<Style>)style;

/**
 Creates and returns a new `ContactsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.

 @param style Used to setup view style parameters.
 @param showSearchBar YES to indicate to show search bar.
 @param enableMultipleSelection True enable contact selection.
 @return An initialized `ContactsViewController` object if successful, `nil` otherwise.
 */
+ (nonnull instancetype)instantiateWithStyle:(nonnull id<Style>)style showSearchBar:(BOOL)showSearchBar enableMultipleSelection:(BOOL)enableMultipleSelection;

/**
 Display the contacts described in the provided data source.
 
 The provided data source will replace the current data source if any. The caller
 should dispose properly this data source if it is not used anymore.
 
 @param listDataSource the data source providing the contacts list.
 */
- (void)displayList:(nonnull ContactsDataSource*)listDataSource;

@end

/**
 `ContactsViewController` delegate.
 */
@protocol ContactsViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a contact.
 
 @param contactsViewController the `ContactsViewController` instance.
 @param contact the selected contact.
 */
- (void)contactsViewController:(nonnull ContactsViewController *)contactsViewController didSelectContact:(nonnull MXKContact*)contact;

@optional
/**
 Asks the delegate whether the email address is allowed to be selected/invited.
 By default all the email addresses are allowed, when this method is not implemented.
 
 @param contactsViewController the `ContactsViewController` instance.
 @param email the selected email.
 @param completion block called with the delegate's answer, a reason my be returned when the email is not allowed.
 */
- (void)contactsViewController:(nonnull ContactsViewController *)contactsViewController askPermissionToSelect:(nonnull NSString*)email completion:(void (^_Nonnull)(BOOL granted, NSString * _Nullable reason))completion;

/**
 Tells the delegate to send an invite to an email address.
 
 @param contactsViewController the `ContactsViewController` instance.
 @param email the selected email.
 */
- (void)contactsViewController:(nonnull ContactsViewController *)contactsViewController sendEmailInviteTo:(nonnull NSString*)email;


@end
