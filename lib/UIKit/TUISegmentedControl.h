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

#import "TUIControl.h"

typedef enum TUISegmentedControlStyle : NSUInteger {
	TUISegmentedControlStyleCustom,
	TUISegmentedControlStyleAutomatic,
    TUISegmentedControlStyleStandard,
    TUISegmentedControlStyleTextured,
    TUISegmentedControlStyleMinimal,
    TUISegmentedControlStyleBar
} TUISegmentedControlStyle;

@interface TUISegmentedItem : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSImage *image;
@property (nonatomic, strong) NSMenu *menu;

@property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;
@property (nonatomic, assign, getter = isSelected) BOOL selected;
@property (nonatomic, assign, getter = isEnabled) BOOL enabled;

+ (instancetype)segmentWithTitle:(NSString *)title andImage:(NSImage *)image;

@end

@interface TUISegmentedControl : TUIControl

@property (nonatomic, assign, readonly) TUISegmentedControlStyle segmentedControlStyle;

// Returns the first selected index, if more than one are selected.
@property (nonatomic, assign) NSUInteger selectedSegmentIndex;
@property (nonatomic, assign) NSUInteger segmentCount;

@property (nonatomic, assign, getter = isMomentary) BOOL momentary;
@property (nonatomic, assign) BOOL allowsMultipleSelection;

+ (instancetype)segmentedControlWithStyle:(TUISegmentedControlStyle)style;

- (void)addSegment:(TUISegmentedItem *)item;
- (void)removeSegmentAtIndex:(NSUInteger)index;

- (void)replaceSegmentAtIndex:(NSUInteger)index withSegment:(TUISegmentedItem *)item;
- (TUISegmentedItem *)segmentAtIndex:(NSUInteger)index;

- (void)drawBackground:(CGRect)rect;
- (void)drawSegmentContents:(NSUInteger)segment inRect:(CGRect)rect;
- (NSUInteger)segmentForHitTestAtPoint:(CGPoint)point;

@end

@interface TUISegmentedControl (TUISegmentedItem_Subscript)

- (void)setObject:(TUISegmentedItem *)item atIndexedSubscript:(NSUInteger)idx;
- (TUISegmentedItem *)objectAtIndexedSubscript:(NSUInteger)idx;

@end
