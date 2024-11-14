/*
Copyright 2019-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXKMessageTextView.h"
#import "GeneratedInterface-Swift.h"

@interface MXKMessageTextView()

@property (nonatomic, readwrite) CGPoint lastHitTestLocation;
@property (nonatomic) NSHashTable *pillViews;

@end


@implementation MXKMessageTextView

// Tchap: automatically adjust message font size dynamically when user change the setting.
- (id)initWithFrame:(CGRect)frame textContainer:(NSTextContainer *)textContainer
{
    self = [super initWithFrame:frame textContainer:textContainer];
    
    if (self) {
        [self setAdjustsFontForContentSizeCategory:YES];
    }
    
    return self;
}

// Tchap: automatically adjust message font size dynamically when user change the setting.
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    
    if (self) {
        [self setAdjustsFontForContentSizeCategory:YES];
    }
    
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return NO;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    self.lastHitTestLocation = point;
    return [super hitTest:point withEvent:event];
}

// Indicate to receive a touch event only if a link is hitted.
// Otherwise it means that the touch event will pass through and could be received by a view below.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (![super pointInside:point withEvent:event])
    {
        return NO;
    }
    
    return [self isThereALinkNearLocation:point];
}

#pragma mark - Pills Flushing

- (void)setText:(NSString *)text
{
    if (@available(iOS 15.0, *)) {
        [self flushPills];
    }
    [super setText:text];
}

- (void)setAttributedText:(NSAttributedString *)attributedText
{
    self.linkTextAttributes = @{};
    if (@available(iOS 15.0, *)) {
        [self flushPills];
    }

    // Tchap: set text type to prefered font to respect user text size, but only if timeline style is set to bubble.
    if (RiotSettings.shared.roomTimelineStyleIdentifier == RoomTimelineStyleIdentifierBubble ) {
        attributedText = [self respectPreferredFontForAttributedString:attributedText];
    }

    [super setAttributedText:attributedText];

    if (@available(iOS 15.0, *)) {
        // Fixes an iOS 16 issue where attachment are not drawn properly by
        // forcing the layoutManager to redraw the glyphs at all NSAttachment positions.
        [self vc_invalidateTextAttachmentsDisplay];
    }
}

// Tchap: Update font size using preferred font settings but keeping other attributes
- (NSAttributedString *)respectPreferredFontForAttributedString:(NSAttributedString *)sourceString
{
    UIFont *preferredFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    NSMutableAttributedString *workString = [sourceString mutableCopy];
    
    [workString beginEditing];
    [workString enumerateAttribute:NSFontAttributeName
                           inRange:NSMakeRange(0, workString.length)
                           options:0
                        usingBlock:^(id  _Nullable value, NSRange range, BOOL * _Nonnull stop) {
        if ([value isKindOfClass:UIFont.class])
        {
            [workString removeAttribute:NSFontAttributeName range:range];
            [workString addAttribute:NSFontAttributeName value:[(UIFont *)value fontWithSize:preferredFont.pointSize] range:range];
        }
    }];
    [workString endEditing];
    
    return workString;
}

- (void)registerPillView:(UIView *)pillView
{
    [self.pillViews addObject:pillView];
}

/// Flushes all previously registered Pills from their hierarchy.
- (void)flushPills API_AVAILABLE(ios(15))
{
    for (UIView* view in self.pillViews)
    {
        view.alpha = 0.0;
        [view removeFromSuperview];
    }
    self.pillViews = [NSHashTable weakObjectsHashTable];
}

@end
