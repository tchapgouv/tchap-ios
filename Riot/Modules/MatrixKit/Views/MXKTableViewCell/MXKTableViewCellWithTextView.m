/*
Copyright 2024 New Vector Ltd.
Copyright 2015 OpenMarket Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKTableViewCellWithTextView.h"

@implementation MXKTableViewCellWithTextView

// Tchap
-(void)prepareForReuse {
    [self setIcon:nil withTint:nil];
    
    [super prepareForReuse];
}

// Tchap
-(void)resetConstraints {
    self.mxkIconWidth.constant = 24.0;
    self.mxkIconTextSpacingConstraint.constant = 4.0;
}

// Tchap
-(void)setIcon:(UIImage *)icon withTint:(UIColor *)tintColor {

    self.mxkIconView.image = icon;
    self.mxkIconView.tintColor = tintColor;
    [self resetConstraints];
    
    if( icon == nil )
    {
        self.mxkIconWidth.constant = 0.0;
        self.mxkIconTextSpacingConstraint.constant = 0.0;
    }
}

@end

