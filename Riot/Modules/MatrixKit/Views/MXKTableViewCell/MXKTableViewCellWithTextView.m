/*
 Copyright 2015 OpenMarket Ltd
 
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

