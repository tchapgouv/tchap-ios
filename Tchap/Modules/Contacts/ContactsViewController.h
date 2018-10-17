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
@protocol ContactsViewControllerDelegate;

/**
 'ContactsViewController' instance is used to display/filter a list of contacts.
 See 'ContactsViewController-inherited' object for example of use.
 */
@interface ContactsViewController : MXKViewController

/**
 The delegate for the view controller.
 */
@property (nonatomic, weak) id<ContactsViewControllerDelegate> delegate;

/**
 Creates and returns a new `ContactsViewController` object.
 
 @discussion This is the designated initializer for programmatic instantiation.
 @return An initialized `ContactsViewController` object if successful, `nil` otherwise.
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
 `ContactsViewController` delegate.
 */
@protocol ContactsViewControllerDelegate <NSObject>

/**
 Tells the delegate that the user selected a contact.
 
 @param contactsViewController the `ContactsViewController` instance.
 @param contact the selected contact.
 */
- (void)contactsViewController:(ContactsViewController *)contactsViewController didSelectContact:(MXKContact*)contact;

@end
