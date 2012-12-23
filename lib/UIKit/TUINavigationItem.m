/*
 Copyright 2011 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUINavigationItem.h"
#import "TUILabel.h"
#import "TUITextRenderer.h"
#import "TUIStringDrawing.h"

@interface TUINavigationItem ()

@property (nonatomic, readonly, retain) TUIButton *_internalButtomItem;
- (CGSize)calculateSizeForHeight:(CGFloat)height;

@end

@implementation TUINavigationItem

@synthesize _internalButtomItem;

- (id)init {
    if((self = [super init])) {
        _internalButtomItem = [TUIButton buttonWithType:TUIButtonTypeCustom];
        
        [_internalButtomItem.titleLabel setAlignment:TUITextAlignmentRight];
        [_internalButtomItem.titleLabel.renderer setVerticalAlignment:TUITextVerticalAlignmentMiddle];
        [_internalButtomItem setTitleEdgeInsets:TUIEdgeInsetsMake(0, 0 /* left */, 0, 5 /* right */)];
    } return self;
}

- (void)setText:(NSString *)text {
    [_internalButtomItem setTitle:text forState:TUIControlStateNormal];
}

- (void)setImage:(NSImage *)image {
    [_internalButtomItem setImage:image forState:TUIControlStateNormal];
}

- (void)setFont:(NSFont *)font {
    [_internalButtomItem.titleLabel setFont:font];
}

- (void)setTextColor:(NSColor *)textColor {
    [_internalButtomItem setTitleColor:textColor forState:TUIControlStateNormal];
}

- (NSString *)text {
    return [_internalButtomItem titleForState:TUIControlStateNormal];
}

- (NSImage *)image {
    return [_internalButtomItem imageForState:TUIControlStateNormal];
}

- (NSFont *)font {
    return [_internalButtomItem.titleLabel font];
}

- (NSColor *)textColor {
    return [_internalButtomItem titleColorForState:TUIControlStateNormal];
}

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents {
    [_internalButtomItem addTarget:target action:action forControlEvents:controlEvents];
}

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents {
    [_internalButtomItem removeTarget:target action:action forControlEvents:controlEvents];
}

- (void)addActionForControlEvents:(TUIControlEvents)controlEvents block:(void(^)(void))action {
    [_internalButtomItem addActionForControlEvents:controlEvents block:action];
}

- (NSSet *)allTargets {
    return [_internalButtomItem allTargets];
}

- (TUIControlEvents)allControlEvents {
    return [_internalButtomItem allControlEvents];
}

- (NSArray *)actionsForTarget:(id)target forControlEvent:(TUIControlEvents)controlEvent {
    return [_internalButtomItem actionsForTarget:target forControlEvent:controlEvent];
}

- (void)sendAction:(SEL)action to:(id)target forEvent:(NSEvent *)event {
    [_internalButtomItem sendAction:action to:target forEvent:event];
}

- (void)sendActionsForControlEvents:(TUIControlEvents)controlEvents {
    [_internalButtomItem sendActionsForControlEvents:controlEvents];
}

- (CGSize)calculateSizeForHeight:(CGFloat)height {
    CGFloat padding = 5.0f;
    NSString *string = [_internalButtomItem titleForState:TUIControlStateNormal];
    
    CGSize textSize = [string ab_sizeWithFont:_internalButtomItem.titleLabel.font];
    CGSize imageSize = [_internalButtomItem imageForState:TUIControlStateNormal].size;
    
    CGFloat edgePadding = (imageSize.width > 0 ? padding : 0.0f) + (textSize.width > 0 ? padding : 0.0f);
    CGFloat totalPadding = (edgePadding > 0 ? padding : 0.0f) + edgePadding;
    CGSize buttonSize = CGSizeMake(textSize.width + imageSize.width + totalPadding, height);
    
    return buttonSize;
}

@end