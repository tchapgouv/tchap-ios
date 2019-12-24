/*
 Copyright 2018 New Vector Ltd
 
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

#import "DisabledRoomInputToolbarView.h"

#import "ThemeService.h"

#import "GeneratedInterface-Swift.h"

@interface DisabledRoomInputToolbarView() <Stylable>
@property (nonatomic, strong) id<Style> currentStyle;
@end

@implementation DisabledRoomInputToolbarView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([DisabledRoomInputToolbarView class])
                          bundle:[NSBundle bundleForClass:[DisabledRoomInputToolbarView class]]];
}

+ (instancetype)roomInputToolbarView
{
    DisabledRoomInputToolbarView *inputToolbarView;
    
    if ([[self class] nib])
    {
        inputToolbarView = [[[self class] nib] instantiateWithOwner:nil options:nil].firstObject;
    }
    else
    {
        inputToolbarView = [[self alloc] init];
    }
    

    [inputToolbarView updateWithStyle:Variant2Style.shared];
    return inputToolbarView;
}

#pragma mark - Override MXKView

-(void)customizeViewRendering
{
    [super customizeViewRendering];
    [self updateWithStyle:self.currentStyle];
}

- (void)updateWithStyle:(id<Style>)style
{
    self.currentStyle = style;
    
    // Remove default toolbar background color
    self.backgroundColor = [UIColor clearColor];
    
    self.separatorView.backgroundColor = style.separatorColor;
    
    self.disabledReasonTextView.font = [UIFont systemFontOfSize:15];
    self.disabledReasonTextView.textColor = style.primaryTextColor;
    self.disabledReasonTextView.tintColor = style.secondaryTextColor;
    self.disabledReasonTextView.editable = NO;
    self.disabledReasonTextView.scrollEnabled = NO;
}

#pragma mark -

- (void)setDisabledReason:(NSString *)reason
{
    self.disabledReasonTextView.text = reason;
}

@end
