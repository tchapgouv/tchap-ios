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
@protocol ContactsTableViewControllerDelegate;

/**
 'ContactsTableViewController' instance is used to display/filter a list of contacts.
 See 'ContactsTableViewController-inherited' object for example of use.
 */
@interface ContactsTableViewController : MXKViewController

/**
 The delegate for the view controller.
 */
@property (nonatomic) id<ContactsTableViewControllerDelegate> contactsTableViewControllerDelegate;

/**
 Creates and returns a new `ContactsTableViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `ContactsTableViewController` object if successful, `nil` otherwise.
 */
+ (instancetype)instantiate;

/**
 Display the contacts described in the provided data source.
 
 The provided data source will replace the current data source if any. The caller
 should dispose properly this data source if it is not used anymore.
 
 @param listDataSource the data source providing the contacts list.
 */
- (void)displayList:(ContactsDataSource*)listDataSource;

@end

/**
 `ContactsTableViewController` delegate.
 */
@protocol ContactsTableViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a contact.
 
 @param contactsTableViewController the `ContactsTableViewController` instance.
 @param contact the selected contact.
 */
- (void)contactsTableViewController:(ContactsTableViewController *)contactsTableViewController didSelectContact:(MXKContact*)contact;

@end
