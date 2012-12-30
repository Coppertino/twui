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

#import "TUIView.h"

@class TUIMenuItem;
@protocol TUIMenuDelegate;

extern NSString *NSMenuWillSendActionNotification;
extern NSString *NSMenuDidSendActionNotification;

// All three of these have a user info key NSMenuItemIndex with a NSNumber value.
extern NSString *NSMenuDidAddItemNotification;
extern NSString *NSMenuDidRemoveItemNotification;
extern NSString *NSMenuDidChangeItemNotification;

extern NSString *NSMenuDidBeginTrackingNotification;
extern NSString *NSMenuDidEndTrackingNotification;

@interface TUIMenu : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) TUIMenu *supermenu;

@property (nonatomic, strong) TUIMenuItem *selectedItem;
@property (nonatomic, strong) NSArray *itemArray;
@property (nonatomic, assign, readonly) NSUInteger itemCount;

@property (nonatomic, assign) BOOL autoenablesItems;
@property (nonatomic, assign) CGFloat minimumWidth;

@property (nonatomic, unsafe_unretained) id<TUIMenuDelegate> delegate;

- (id)initWithTitle:(NSString *)title;

- (BOOL)popUpMenuPositioningItem:(TUIMenuItem *)item atLocation:(NSPoint)location inView:(TUIView *)view;

- (void)addItem:(TUIMenuItem *)newItem;
- (void)insertItem:(TUIMenuItem *)newItem atIndex:(NSUInteger)index;

- (TUIMenuItem *)addItemWithTitle:(NSString *)aString action:(SEL)aSelector keyEquivalent:(NSString *)charCode;
- (TUIMenuItem *)insertItemWithTitle:(NSString *)aString action:(SEL)aSelector keyEquivalent:(NSString *)charCode atIndex:(NSUInteger)index;

- (void)removeItemAtIndex:(NSUInteger)index;
- (void)removeItem:(TUIMenuItem *)item;
- (void)removeAllItems;

- (TUIMenuItem *)itemAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfItem:(TUIMenuItem *)index;

- (NSUInteger)indexOfItemWithTitle:(NSString *)aTitle;
- (NSUInteger)indexOfItemWithTag:(NSInteger)aTag;
- (NSUInteger)indexOfItemWithRepresentedObject:(id)object;
- (NSUInteger)indexOfItemWithSubmenu:(NSMenu *)submenu;
- (NSUInteger)indexOfItemWithTarget:(id)target andAction:(SEL)actionSelector;

- (TUIMenuItem *)itemWithTitle:(NSString *)aTitle;
- (TUIMenuItem *)itemWithTag:(NSInteger)tag;

- (NSSize)size;
- (void)update;

- (void)itemChanged:(TUIMenuItem *)item;
- (void)performActionForItemAtIndex:(NSUInteger)index;
- (void)setSubmenu:(TUIMenu *)aMenu forItem:(TUIMenuItem *)anItem;

- (void)cancelTracking;
- (void)cancelTrackingWithoutAnimation;

@end

@protocol TUIMenuDelegate <NSObject>
@optional

- (void)menuNeedsUpdate:(TUIMenu *)menu;
- (NSUInteger)numberOfItemsInMenu:(TUIMenu *)menu;
- (BOOL)menu:(TUIMenu *)menu updateItem:(TUIMenuItem *)item atIndex:(NSUInteger)index shouldCancel:(BOOL)shouldCancel;
- (BOOL)menuHasKeyEquivalent:(TUIMenu *)menu forEvent:(NSEvent *)event target:(id *)target action:(SEL *)action;
- (void)menuWillOpen:(TUIMenu *)menu;
- (void)menuDidClose:(TUIMenu *)menu;
- (void)menu:(TUIMenu *)menu willHighlightItem:(TUIMenuItem *)item;
- (CGRect)confinementRectForMenu:(TUIMenu *)menu onScreen:(NSScreen *)screen;

@end
