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

#import "TUICGAdditions.h"
#import "TUIButton.h"
#import "TUIImageView.h"
#import "TUILabel.h"
#import "TUINavigationItem.h"

@class TUILabel;
@class TUINavigationItem;

// A navigation bar + toolbar combo which can be customized
// by the toolbar buttons it holds, as well as its title,
// icon, and navigation stack.
// Currently there is a restriction size of 44.0f in height.
@interface TUINavigationBar : TUIView

// If you'd like to have an icon or title displayed in the
// action bar, set this to true, and set the icon or text
// to a non-nil value to have it display.
@property (nonatomic, assign) BOOL displaysIcon;
@property (nonatomic, assign) BOOL displaysTitle;

// If the icon or title is set to a non-nil value, but
// the boolean flags are set to false, then they will not display.
@property (nonatomic, strong) NSImage *icon;
@property (nonatomic, strong) NSString *title;

// Readonly access to the internal view heirarchy for further
// component-based customization.
@property (nonatomic, readonly) TUIImageView *iconView;
@property (nonatomic, readonly) TUILabel *titleLabel;

// Adds an action item to the action bar, either by custom
// action item, or by creating a new one from given title and image.
// Returns the index of the action item added.
- (NSUInteger)addActionItem:(TUINavigationItem *)actionItem;
- (NSUInteger)addActionItemWithTitle:(NSString *)title andImage:(NSImage *)image;
- (NSUInteger)addActionItemWithTitle:(NSString *)title;
- (NSUInteger)addActionItemWithImage:(NSImage *)image;

// Returns the action item at the given index.
- (TUINavigationItem *)actionItemAtIndex:(NSUInteger)index;

// Removes the action item at the given index.
- (void)removeActionItemAtIndex:(NSUInteger)index;

- (BOOL)hasActionItem:(TUINavigationItem *)item;
- (void)removeActionItem:(TUINavigationItem *)item;

// Removes all action items for the action bar.
- (void)removeAllActionItems;

@end