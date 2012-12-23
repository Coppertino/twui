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
#import "TUIButton.h"

// A TUINavigationItem is an abstract item context
// for a button displayed in a TUINavigationBar.
// You have limited interaction, as the item
// context serves a different purpose than a
// button, and they can only be added to
// action bars.
@interface TUINavigationItem : NSObject

// Set the inset image and text, with font
// and text color. The background color is
// the color at a normal state, and active
// is when the item is highlighted in state.
@property (nonatomic, retain) NSImage *image;
@property (nonatomic, retain) NSString *text;
@property (nonatomic, retain) NSFont *font;
@property (nonatomic, retain) NSColor *textColor;
@property (nonatomic, retain) NSColor *backgroundColor;
@property (nonatomic, retain) NSColor *activeColor;

// You can add and remove selector or block
// targets, control all the targets and events
// and send actions, like a button.
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents;
- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents;

- (void)addActionForControlEvents:(TUIControlEvents)controlEvents block:(void(^)(void))action;

- (NSSet *)allTargets;
- (TUIControlEvents)allControlEvents;
- (NSArray *)actionsForTarget:(id)target forControlEvent:(TUIControlEvents)controlEvent;

- (void)sendAction:(SEL)action to:(id)target forEvent:(NSEvent *)event;
- (void)sendActionsForControlEvents:(TUIControlEvents)controlEvents;

@end
