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

#import "TUISegmentedControl.h"

#define kDMTabBarGradientColor_Start	[NSColor colorWithCalibratedRed:0.851f green:0.851f blue:0.851f alpha:1.0f]
#define kDMTabBarGradientColor_End		[NSColor colorWithCalibratedRed:0.700f green:0.700f blue:0.700f alpha:1.0f]
#define KDMTabBarGradient				[[NSGradient alloc] initWithStartingColor:kDMTabBarGradientColor_Start \
																	  endingColor:kDMTabBarGradientColor_End]
#define kDMTabBarBorderColor            [NSColor colorWithDeviceWhite:0.2 alpha:1.0f]
#define kDMTabBarItemWidth               32.0f

@interface TUISegmentedControl ()

@property (nonatomic, strong) NSMutableArray *items;

@end

@implementation TUISegmentedControl


- (void)dealloc {
    [self removeAllTabBarItems];
}

- (void)drawRect:(NSRect)dirtyRect {
    [KDMTabBarGradient drawInRect:self.bounds angle:90.0];
    [kDMTabBarBorderColor setStroke];
	
    [NSBezierPath setDefaultLineWidth:0.0f];
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(self.bounds), NSMaxY(self.bounds))
                              toPoint:NSMakePoint(NSMaxX(self.bounds), NSMaxY(self.bounds))];
}

- (void)layoutSubviews {
    NSUInteger buttonsNumber = [self.tabBarItems count];
    CGFloat totalWidth = (buttonsNumber*kDMTabBarItemWidth);
    __block CGFloat offset_x = floorf((NSWidth(self.bounds)-totalWidth)/2.0f);
    [self.tabBarItems enumerateObjectsUsingBlock:^(DMTabBarItem* tabBarItem, NSUInteger idx, BOOL *stop) {
        tabBarItem.tabBarItemButton.frame = NSMakeRect(offset_x, NSMinY(self.bounds), kDMTabBarItemWidth, NSHeight(self.bounds));
        offset_x += kDMTabBarItemWidth;
    }];
}

- (void)removeAllTabBarItems {
    [self.tabBarItems enumerateObjectsUsingBlock:^(DMTabBarItem* tabBarItem, NSUInteger idx, BOOL *stop) {
        [tabBarItem.tabBarItemButton removeFromSuperview];
    }];
    tabBarItems = nil;
}

- (void) handleTabBarItemSelection:(DMTabBarEventsHandler) newSelectionHandler {
    selectionHandler = newSelectionHandler;
}

- (void)selectTabBarItem:(id)sender {
    __block NSUInteger itemIndex = NSNotFound;
    [self.tabBarItems enumerateObjectsUsingBlock:^(DMTabBarItem* tabBarItem, NSUInteger idx, BOOL *stop) {
        if (sender == tabBarItem.tabBarItemButton) {
            itemIndex = idx;
            *stop = YES;
        }
    }];
    if (itemIndex == NSNotFound) return;
    DMTabBarItem *tabBarItem = [self.tabBarItems objectAtIndex:itemIndex];
    selectionHandler(DMTabBarItemSelectionType_WillSelect,tabBarItem,itemIndex);
    
    self.selectedTabBarItem = tabBarItem;
    selectionHandler(DMTabBarItemSelectionType_DidSelect,tabBarItem,itemIndex);
}

#pragma mark - Layout Subviews

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize {
    [super resizeSubviewsWithOldSize:oldSize];
    [self layoutSubviews];
}

- (void) setTabBarItems:(NSArray *)newTabBarItems {
    if (newTabBarItems != tabBarItems) {
        [self removeAllTabBarItems];
        tabBarItems = newTabBarItems;
        
        NSUInteger selectedItemIndex = [self.tabBarItems indexOfObject:self.selectedTabBarItem];
        NSUInteger itemIndex = 0;
        [self.tabBarItems enumerateObjectsUsingBlock:^(DMTabBarItem * tabBarItem, NSUInteger idx, BOOL *stop) {
            NSButton *itemButton = tabBarItem.tabBarItemButton;
            itemButton.frame = NSMakeRect(0.0f, 0.0f, kDMTabBarItemWidth, NSHeight(self.bounds));
            itemButton.state = (itemIndex == selectedItemIndex ? NSOnState : NSOffState);
            itemButton.action = @selector(selectTabBarItem:);
            itemButton.target = self;
            [self addSubview:itemButton];
        }];
        
        [self layoutSubviews];
        
        if (![self.tabBarItems containsObject:self.selectedTabBarItem])
            self.selectedTabBarItem = ([self.tabBarItems count] > 0 ? [self.tabBarItems objectAtIndex:0] : nil);
    }
}

- (DMTabBarItem *) selectedTabBarItem {
    return selectedTabBarItem_;
}

- (void) setSelectedTabBarItem:(DMTabBarItem *)newSelectedTabBarItem {
    if ([self.tabBarItems containsObject:newSelectedTabBarItem] == NO) return;
    NSUInteger selectedItemIndex = [self.tabBarItems indexOfObject:newSelectedTabBarItem];
    selectedTabBarItem_ = newSelectedTabBarItem;
    
    __block NSUInteger buttonIndex = 0;
    [self.tabBarItems enumerateObjectsUsingBlock:^(DMTabBarItem* tabBarItem, NSUInteger idx, BOOL *stop) {
        tabBarItem.state = (buttonIndex == selectedItemIndex ? NSOnState : NSOffState);
        ++buttonIndex;
    }];
}

- (NSUInteger) selectedIndex {
    return [self.tabBarItems indexOfObject:self.selectedTabBarItem];
}

- (void) setSelectedIndex:(NSUInteger)newSelectedIndex {
    if (newSelectedIndex != self.selectedIndex && newSelectedIndex < [self.tabBarItems count]) {
        self.selectedTabBarItem = [self.tabBarItems objectAtIndex:newSelectedIndex];
    }
}

@end
