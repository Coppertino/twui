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

typedef enum TUISegmentedControlAlignment : NSUInteger {
    TUISegmentedControlAlignmentLeft,
    TUISegmentedControlAlignmentRight,
	TUISegmentedControlAlignmentCentered,
	TUISegmentedControlAlignmentJustified
} TUISegmentedControlAlignment;

@interface TUISegmentedControl : TUIControl

@property (nonatomic, assign, readonly) TUISegmentedControlStyle segmentedControlStyle;

@property (nonatomic, getter = isMomentary) BOOL momentary;
@property (nonatomic, assign, readonly) NSUInteger numberOfSegments;
@property (nonatomic, assign) NSInteger selectedSegmentIndex;

@property (nonatomic, assign) BOOL apportionsSegmentWidthsByContent;

+ (instancetype)segmentedControlWithStyle:(TUISegmentedControlStyle)style;

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated;
- (void)insertSegmentWithImage:(NSImage *)image  atIndex:(NSUInteger)segment animated:(BOOL)animated;

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated;
- (void)removeAllSegments;

- (void)setTitle:(NSString *)title forSegmentAtIndex:(NSUInteger)segment;
- (NSString *)titleForSegmentAtIndex:(NSUInteger)segment;

- (void)setImage:(NSImage *)image forSegmentAtIndex:(NSUInteger)segment;
- (NSImage *)imageForSegmentAtIndex:(NSUInteger)segment;

- (void)setWidth:(CGFloat)width forSegmentAtIndex:(NSUInteger)segment;
- (CGFloat)widthForSegmentAtIndex:(NSUInteger)segment;

- (void)setContentOffset:(CGSize)offset forSegmentAtIndex:(NSUInteger)segment;
- (CGSize)contentOffsetForSegmentAtIndex:(NSUInteger)segment;

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment;
- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segment;

- (void)setMenu:(NSMenu *)menu forSegment:(NSInteger)segment;
- (NSMenu *)menuForSegment:(NSInteger)segment;

- (void)setSelected:(BOOL)selected forSegment:(NSInteger)segment;
- (BOOL)isSelectedForSegment:(NSInteger)segment;

@end
