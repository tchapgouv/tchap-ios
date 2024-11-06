/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MatrixKit.h"

@protocol Style;

@interface CountryPickerViewController : MXKCountryPickerViewController

/**
 Creates and returns a new `CountryPickerViewController` object.
 
 @return An initialized `CountryPickerViewController` object if successful, `nil` otherwise.
 */
+ (nonnull instancetype)instantiate;

@end
