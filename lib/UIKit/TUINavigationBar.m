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

#import "TUINavigationBar.h"
#import "TUIStringDrawing.h"

@interface TUINavigationItem ()

@property (nonatomic, strong, readonly) TUIButton *_internalButtomItem;

- (CGSize)calculateSizeForHeight:(CGFloat)height;

@end

@interface TUINavigationBar () {
    NSMutableArray *seperatorList;
}

@property (nonatomic, retain) NSMutableArray *actionItems;

- (void)_layoutActionItems;

@end

@implementation TUINavigationBar

@synthesize iconView = _iconView;
@synthesize titleLabel = _titleLabel;

- (id)initWithFrame:(CGRect)frame {
    frame.size.height = 44.0f;
    
    if((self = [super initWithFrame:frame])) {
        [self setBackgroundColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0f]];
        _actionItems = [[NSMutableArray alloc] init];
        seperatorList = [[NSMutableArray alloc] init];
		self.userInteractionEnabled = NO;
    } return self;
}

- (void)setFrame:(CGRect)frame {
    frame.size.height = 44.0f;
    [super setFrame:frame];
}

- (void)drawRect:(CGRect)rect {
    CGFloat basePadding = 2.0f;
    CGContextRef ctx = TUIGraphicsGetCurrentContext();
    
    rect.origin.y += basePadding;
    rect.size.height -= basePadding;
    [self.backgroundColor set];
    CGContextFillRect(ctx, rect);
    
    CGRect cachedRect = rect;
    rect.origin.y = 0.0f;
    rect.size.height = basePadding;
    [[self.backgroundColor shadowWithLevel:0.8] set];
    CGContextFillRect(ctx, rect);
    
    for(int i = 0; i < seperatorList.count; i++) {
        [[[NSColor whiteColor] colorWithAlphaComponent:0.5] set];
        CGRect seperatorRect = CGRectMake([[seperatorList objectAtIndex:i] floatValue],
                                          cachedRect.origin.y + 5.0f, 1.0f, cachedRect.size.height - 10.0f);
        CGContextFillRect(ctx, seperatorRect);
    }
}

- (void)layoutSubviews {
    CGRect rect = self.bounds;
    rect.size.height -= 2.0f;
    rect.origin.y += 2.0f;
    
    CGRect iconFrame = rect;
    iconFrame.size = CGSizeMake(32.0f, 32.0f);
    iconFrame.origin.x += ((rect.size.height - iconFrame.size.height) / 2) + 16.0f;
    iconFrame.origin.y += ((rect.size.height - iconFrame.size.height) / 2);
    
    if(self.displaysIcon && self.icon) {
        [self.iconView setFrame:iconFrame];
    } else {
        [self.iconView setFrame:CGRectZero];
    }
    
    if(self.displaysTitle && self.title) {
        [self.titleLabel setFont:self.titleLabel.font];
        
        CGRect titleFrame = rect;
        titleFrame.origin.x += (self.displaysIcon ? iconFrame.origin.x + iconFrame.size.width : 0.0f) + 16.0f;
        titleFrame.size = [self.titleLabel.text ab_sizeWithFont:self.titleLabel.font
                                              constrainedToSize:CGSizeMake(rect.size.width - titleFrame.origin.x, rect.size.height)];
        titleFrame.origin.y += (rect.size.height - titleFrame.size.height) / 2;
        
        [self.titleLabel setFrame:titleFrame];
        [self.titleLabel sizeToFit];
    } else {
        [self.titleLabel setFrame:CGRectZero];
    }
    
    [self _layoutActionItems];
}

- (void)_layoutActionItems {
    CGRect rect = self.bounds;
    rect.size.height -= 2.0f;
    rect.origin.y += 2.0f;
    
    CGFloat defaultPadding = 2.0f;
    CGFloat actionItemsWidth = 0.0f;
    [seperatorList removeAllObjects];
    for(int i = 0; i < _actionItems.count; i++) {
        TUINavigationItem *actionItem = [self actionItemAtIndex:i];
        CGSize itemSize = [actionItem calculateSizeForHeight:rect.size.height];
        actionItemsWidth += itemSize.width;
        
        CGRect itemRect = rect;
        itemRect.size = itemSize;
        itemRect.origin = CGPointMake(rect.size.width - actionItemsWidth, rect.origin.y);
        actionItem._internalButtomItem.frame = itemRect;
        
        actionItemsWidth += defaultPadding + 1.0f; /* seperator is 1px wide */
        if(i < _actionItems.count - 1)
            [seperatorList addObject:[NSNumber numberWithFloat:itemRect.origin.x - defaultPadding]];
    }
}

- (void)setIcon:(NSImage *)i {
    if([_icon isEqual:i]) return;
    
    _icon = i;
    self.iconView.image = _icon;
}

- (void)setTitle:(NSString *)t {
    if([_title isEqual:t]) return;
    
    _title = t;
    self.titleLabel.text = _title;
}

- (TUIImageView *)iconView {
    if(!_iconView) {
        _iconView = [[TUIImageView alloc] initWithFrame:CGRectZero];
        _iconView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        _iconView.userInteractionEnabled = NO;
        
        _iconView.backgroundColor = [NSColor clearColor];
        
        [self addSubview:_iconView];
    } return _iconView;
}

- (TUILabel *)titleLabel {
    if(!_titleLabel) {
        _titleLabel = [[TUILabel alloc] initWithFrame:self.bounds];
        _titleLabel.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        _titleLabel.userInteractionEnabled = NO;
        
        _titleLabel.font = [NSFont systemFontOfSize:32.0f];
        _titleLabel.backgroundColor = [NSColor clearColor];
        _titleLabel.textColor = [NSColor whiteColor];
        
        [self addSubview:_titleLabel];
    } return _titleLabel;
}

- (NSUInteger)addActionItem:(TUINavigationItem *)actionItem {
    if(!actionItem._internalButtomItem) return NSUIntegerMax;
    [_actionItems addObject:actionItem];
    [self addSubview:actionItem._internalButtomItem];
    [self _layoutActionItems];
    return [_actionItems indexOfObject:actionItem];
}

- (NSUInteger)addActionItemWithTitle:(NSString *)title andImage:(NSImage *)image {
    TUINavigationItem *actionItem = [[TUINavigationItem alloc] init];
    if(title) [actionItem setText:title];
    if(image) [actionItem setImage:image];
    
    return [self addActionItem:actionItem];
}

- (NSUInteger)addActionItemWithTitle:(NSString *)title {
    return [self addActionItemWithTitle:title andImage:nil];
}

- (NSUInteger)addActionItemWithImage:(NSImage *)image {
    return [self addActionItemWithTitle:nil andImage:image];
}

- (TUINavigationItem *)actionItemAtIndex:(NSUInteger)index {
    if(index > _actionItems.count) return nil;
    return (TUINavigationItem *)[_actionItems objectAtIndex:index];
}

- (void)removeActionItemAtIndex:(NSUInteger)index {
    if(index > _actionItems.count) return;
    TUINavigationItem *actionItem = [_actionItems objectAtIndex:index];
    
    [actionItem._internalButtomItem removeFromSuperview];
    [_actionItems removeObject:actionItem];
    [self _layoutActionItems];
}

- (BOOL)hasActionItem:(TUINavigationItem *)item {
    return [_actionItems containsObject:item];
}

- (void)removeActionItem:(TUINavigationItem *)item {
    if([_actionItems containsObject:item]) {
        [item._internalButtomItem removeFromSuperview];
        [_actionItems removeObject:item];
        [self _layoutActionItems];
    }
}

- (void)removeAllActionItems {
    [_actionItems removeAllObjects];
    [self _layoutActionItems];
}

@end
