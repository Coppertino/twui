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
#import "TUINSView.h"
#import "TUICGAdditions.h"

#import <objc/runtime.h>

#define kDMTabBarGradientColor_Start	[NSColor colorWithCalibratedRed:0.851f green:0.851f blue:0.851f alpha:1.0f]
#define kDMTabBarGradientColor_End		[NSColor colorWithCalibratedRed:0.700f green:0.700f blue:0.700f alpha:1.0f]
#define KDMTabBarGradient				[[NSGradient alloc] initWithStartingColor:kDMTabBarGradientColor_Start \
																	  endingColor:kDMTabBarGradientColor_End]
#define kDMTabBarBorderColor            [NSColor colorWithDeviceWhite:0.2 alpha:1.0f]
#define kDMTabBarItemWidth               32.0f
#define kDMTabBarItemGradientColor1		[NSColor colorWithCalibratedWhite:0.7f alpha:0.0f]
#define kDMTabBarItemGradientColor2		[NSColor colorWithCalibratedWhite:0.7f alpha:1.0f]
#define kDMTabBarItemGradient			[[NSGradient alloc] initWithColors:@[kDMTabBarItemGradientColor1, \
																			 kDMTabBarItemGradientColor2, \
																			 kDMTabBarItemGradientColor1] \
															   atLocations:(CGFloat []){ 0.0f, 0.5f, 1.0f } \
																colorSpace:[NSColorSpace genericGrayColorSpace]]

@interface TUISegmentedTrackedCell : NSSegmentedCell

@property (nonatomic, strong) NSMutableDictionary *trackedRects;

@end

@interface TUISegmentedControl () {
	struct {
		unsigned int segmentedControlStyle:3;
	} _segmentedControlFlags;
}

@property (nonatomic, strong) NSMutableArray *items;

@end

@interface TUISegmentedItem : TUIControl

@property (nonatomic, strong) TUISegmentedControl *segmentedControl;

@end

@implementation TUISegmentedControl

+ (TUISegmentedTrackedCell *)sharedGraphicsRenderer {
	static TUISegmentedTrackedCell *_backingCell = nil;
	if(!_backingCell) {
		_backingCell = [TUISegmentedTrackedCell new];
	}
	return _backingCell;
}

+ (instancetype)segmentedControlWithStyle:(TUISegmentedControlStyle)style {
	TUISegmentedControl *segmentedControl = [[TUISegmentedControl alloc] initWithFrame:CGRectZero];
	segmentedControl->_segmentedControlFlags.segmentedControlStyle = style;
	return segmentedControl;
}

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		_segmentedControlFlags.segmentedControlStyle = TUISegmentedControlStyleCustom;
		self.segmentAlignment = TUISegmentedControlAlignmentJustified;
		
		self.backgroundColor = [NSColor clearColor];
		self.items = @[].mutableCopy;
	}
	return self;
}

- (void)insertSegmentWithTitle:(NSString *)title atIndex:(NSUInteger)segment animated:(BOOL)animated {
	TUISegmentedItem *item = [[TUISegmentedItem alloc] initWithFrame:CGRectZero];
	item.backgroundColor = [NSColor clearColor];
	
	item.layer.borderColor = [NSColor redColor].CGColor;
	item.layer.borderWidth = 1.0f;
	
	item.segmentedControl = self;
	[self addSubview:item];
	self.items[segment] = item;
	
	if(animated) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self layoutSubviews];
		}];
	} else {
		[self setNeedsLayout];
	}
}

- (void)insertSegmentWithImage:(NSImage *)image atIndex:(NSUInteger)segment animated:(BOOL)animated {
	TUISegmentedItem *item = [[TUISegmentedItem alloc] initWithFrame:CGRectZero];
	item.backgroundColor = [NSColor clearColor];
	
	item.layer.borderColor = [NSColor redColor].CGColor;
	item.layer.borderWidth = 1.0f;
	
	item.segmentedControl = self;
	[self addSubview:item];
	self.items[segment] = item;
	
	if(animated) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self layoutSubviews];
		}];
	} else {
		[self setNeedsLayout];
	}
}

- (void)removeSegmentAtIndex:(NSUInteger)segment animated:(BOOL)animated {
	[self.items[segment] removeFromSuperview];
	[self.items removeObjectAtIndex:segment];
	
	if(animated) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self layoutSubviews];
		}];
	} else {
		[self setNeedsLayout];
	}
}

- (void)removeAllSegmentsAnimated:(BOOL)animated {
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
        [self removeSegmentAtIndex:idx animated:animated];
    }];
	
    self.items = nil;
}

- (void)setEnabled:(BOOL)enabled forSegmentAtIndex:(NSUInteger)segment {
	[self.items[segment] setEnabled:enabled];
	
	if(self.animateStateChange) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self redraw];
		}];
	} else {
		[self setNeedsDisplay];
	}
}

- (BOOL)isEnabledForSegmentAtIndex:(NSUInteger)segment {
	return [self.items[segment] isEnabled];
}

- (void)setSelected:(BOOL)selected forSegment:(NSUInteger)segment {
	[self.items[segment] setSelected:selected];
	
	if(self.animateStateChange) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self redraw];
		}];
	} else {
		[self setNeedsDisplay];
	}
}

- (BOOL)isSelectedForSegment:(NSUInteger)segment {
	return [self.items[segment] state] & TUIControlStateSelected;
}

- (void)setHighlighted:(BOOL)selected forSegment:(NSUInteger)segment {
	[self.items[segment] setHighlighted:selected];
	
	if(self.animateStateChange) {
		[TUIView animateWithDuration:0.25f animations:^{
			[self redraw];
		}];
	} else {
		[self setNeedsDisplay];
	}
}

- (BOOL)isHighlightedForSegment:(NSUInteger)segment {
	return [self.items[segment] state] & TUIControlStateHighlighted;
}

- (void)drawRect:(CGRect)rect {
	NSSegmentedCell *renderer = [TUISegmentedControl sharedGraphicsRenderer];
	
	[renderer setSegmentStyle:NSSegmentStyleRounded];
	[renderer setSegmentCount:self.items.count];
	
	[renderer calcDrawInfo:rect];
	[renderer drawWithFrame:self.bounds inView:self.nsView];
}

- (void)drawSegmentContents:(NSUInteger)segment inRect:(CGRect)rect {
	
}

- (void)layoutSubviews {
	if(self.segmentAlignment == TUISegmentedControlAlignmentCustom) {
		__block CGFloat totalWidth = 0.0f;
		[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
			totalWidth += [self widthForSegmentAtIndex:idx];
		}];
		
		__block CGFloat currentOffset = roundf((self.bounds.size.width - totalWidth) / 2);
		[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
			CGRect itemRect = CGRectMake(currentOffset, 0, [self widthForSegmentAtIndex:idx], self.bounds.size.height);
			item.frame = itemRect;
		}];
	} else if(self.segmentAlignment == TUISegmentedControlAlignmentJustified) {
		[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
			CGFloat width = roundf(self.bounds.size.width / self.items.count);
			CGRect itemRect = CGRectMake(idx * width, 0, width, self.bounds.size.height);
			item.frame = itemRect;
		}];
	} else {
		
	}
}

@end

@implementation TUISegmentedItem

- (void)drawRect:(CGRect)rect {
	NSUInteger segmentIndex = [self.segmentedControl.items indexOfObject:self];
	CGRect segmentRect = [[TUISegmentedControl sharedGraphicsRenderer].trackedRects[@(segmentIndex)] rectValue];
	
	[self.segmentedControl drawSegmentContents:segmentIndex inRect:segmentRect];
}

@end

@implementation TUISegmentedTrackedCell

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView {
	if(!_trackedRects)
		_trackedRects = @{}.mutableCopy;
	
	_trackedRects[@(segment)] = [NSValue valueWithRect:frame];
	[super drawSegment:segment inFrame:frame withView:controlView];
}

@end
