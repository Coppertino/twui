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

@interface TUISegmentedTrackedCell : NSSegmentedCell

@property (nonatomic, strong) NSMutableDictionary *trackedRects;
@property (nonatomic, readonly) NSDictionary *positionedRects;

@end

@interface TUISegmentedControl () {
	struct {
		unsigned int segmentedControlStyle:3;
		unsigned int itemsListModified:1;
	} _segmentedControlFlags;
	CGPoint loc;
}

@property (nonatomic, strong) NSMutableArray *items;

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
		self.backgroundColor = [NSColor clearColor];
		self.items = @[].mutableCopy;
	}
	return self;
}

- (void)addSegment:(TUISegmentedItem *)item {
	if([item isKindOfClass:TUISegmentedItem.class]) {
		[self.items addObject:item];
		_segmentedControlFlags.itemsListModified = YES;
	}
}

- (void)removeSegmentAtIndex:(NSUInteger)index {
	if([[self.items objectAtIndex:index] isKindOfClass:TUISegmentedItem.class]) {
		[self.items removeObjectAtIndex:index];
		_segmentedControlFlags.itemsListModified = YES;
	}
}

- (void)replaceSegmentAtIndex:(NSUInteger)index withSegment:(TUISegmentedItem *)item {
	if([item isKindOfClass:TUISegmentedItem.class])
		[self.items replaceObjectAtIndex:index withObject:item];
}

- (TUISegmentedItem *)segmentAtIndex:(NSUInteger)index {
	return [self.items objectAtIndex:index];
}

- (void)drawRect:(CGRect)rect {
	NSSegmentedCell *renderer = [TUISegmentedControl sharedGraphicsRenderer];
	
	// Set the defaults.
	if(_segmentedControlFlags.itemsListModified) {
		[renderer setSegmentCount:self.items.count];
		//[renderer setTrackingMode:NSSegmentSwitchTrackingSelectOne];
		[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
			[renderer setLabel:[@"" stringByPaddingToLength:50 withString:@"M" startingAtIndex:0] forSegment:idx];
		}];
		_segmentedControlFlags.itemsListModified = NO;
	}
	
	// Set the enabled values.
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		[renderer setEnabled:YES forSegment:idx];
	}];
	
	// Set the selected values.
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		[renderer setSelected:item.selected forSegment:idx];
		if(item.selected)
			*stop = YES;
	}];
	
	// Set the highlighted values.
	NSDictionary *rectCache = [[TUISegmentedControl sharedGraphicsRenderer] trackedRects];
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		//[renderer highlight:item.highlighted withFrame:[rectCache[@(idx)] rectValue] inView:self.nsView];
		if(item.highlighted)
			*stop = YES;
	}];
	
	// Draw the background and each cell.
	[self drawBackground:rect];
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		[self drawSegmentContents:idx inRect:[rectCache[@(idx)] rectValue]];
	}];
}

- (void)drawBackground:(CGRect)rect {
	NSSegmentedCell *renderer = [TUISegmentedControl sharedGraphicsRenderer];
	[renderer setSegmentStyle:NSSegmentStyleRounded];
	[renderer drawWithFrame:CGRectInset(self.bounds, 2.0f, 2.0f) inView:self.nsView];
}

- (void)drawSegmentContents:(NSUInteger)segment inRect:(CGRect)rect {
	[[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.1] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];
	[[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
	[[NSBezierPath bezierPathWithRect:rect] stroke];
	
	// No image or text drawing yet.
}

- (NSUInteger)segmentForHitTestAtPoint:(CGPoint)point {
	NSDictionary *rectCache = [[TUISegmentedControl sharedGraphicsRenderer] trackedRects];
	__block NSUInteger segment = NSNotFound;
	
	[rectCache enumerateKeysAndObjectsUsingBlock:^(NSNumber *index, NSValue *rect, BOOL *stop) {
		if(CGRectContainsPoint(rect.rectValue, point))
			segment = index.unsignedIntegerValue;
	}];
	
	return segment;
}

- (BOOL)beginTrackingWithEvent:(NSEvent *)event {
	CGPoint location = [self convertPoint:event.locationInWindow fromView:nil];
	NSUInteger segment = [self segmentForHitTestAtPoint:location];
	
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		item.selected = (idx == segment);
	}];
	return YES;
}

- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	CGPoint location = [self convertPoint:event.locationInWindow fromView:nil];
	NSUInteger segment = [self segmentForHitTestAtPoint:location];
	
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		item.selected = (idx == segment);
	}];
	return YES;
}

- (void)endTrackingWithEvent:(NSEvent *)event {
	CGPoint location = [self convertPoint:event.locationInWindow fromView:nil];
	NSUInteger segment = [self segmentForHitTestAtPoint:location];
	
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		item.selected = (idx == segment);
	}];
}

@end

@implementation TUISegmentedControl (TUISegmentedItem_Subscript)

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx {
	if(obj != nil) {
		if(idx >= self.items.count) {
			NSInteger add = idx - self.items.count;
			for(int i = 0; i < add; i++)
				[self addSegment:[TUISegmentedItem new]];
			
			[self addSegment:obj];
		} else {
			[self replaceSegmentAtIndex:idx withSegment:obj];
		}
	} else {
		[self removeSegmentAtIndex:idx];
	}
}

- (id)objectAtIndexedSubscript:(NSUInteger)idx {
	return [self segmentAtIndex:idx];
}

@end

@implementation TUISegmentedItem

+ (instancetype)segmentWithTitle:(NSString *)title andImage:(NSImage *)image {
	TUISegmentedItem *item = [self.class new];
	item.title = title;
	item.image = image;
	return item;
}

@end

@implementation TUISegmentedTrackedCell

- (void)drawSegment:(NSInteger)segment inFrame:(NSRect)frame withView:(NSView *)controlView {
	if(!_trackedRects)
		_trackedRects = @{}.mutableCopy;
	_trackedRects[@(segment)] = [NSValue valueWithRect:frame];
	[self repositionRects];
	
	// Don't call super because we'll be drawing the content ourselves.
	//[super drawSegment:segment inFrame:frame withView:controlView];
}

- (NSDictionary *)positionedRects {
	if(!_trackedRects)
		return @{};
	
	NSMutableDictionary *returnDict = @{}.mutableCopy;
	for(NSUInteger idx = 0; idx < _trackedRects.count; idx++) {
		CGRect rect = [_trackedRects[@(idx)] rectValue];
		if(idx != 0) {
			CGRect previousRect = [_trackedRects[@(idx - 1)] rectValue];
			CGFloat endPosition = CGRectGetMaxX(previousRect);
			
			NSLog(@"%f to %f", endPosition, CGRectGetMinX(rect));
		} else {
			rect.origin.x = 0.0f;
		}
	}
	
	return returnDict;
}

- (void)repositionRects {
	for(NSUInteger idx = 0; idx < _trackedRects.count; idx++) {
		CGRect rect = [_trackedRects[@(idx)] rectValue];
		
		if(idx > 0) {
			CGRect previousRect = [_trackedRects[@(idx - 1)] rectValue];
			CGFloat difference = (CGRectGetMinX(rect) - CGRectGetMaxX(previousRect)) / 2.0f;
			rect.origin.x -= difference;
			
			if(idx < _trackedRects.count - 1) {
				CGRect nextRect = [_trackedRects[@(idx + 1)] rectValue];
				rect.size.width += (CGRectGetMinX(nextRect) - CGRectGetMaxX(rect)) / 2.0f;
			} else {
				rect.size.width += difference * 4;
			}
		} else {
			CGRect nextRect = [_trackedRects[@(idx + 1)] rectValue];
			rect.origin.x = 0.0f;
			rect.size.width += (CGRectGetMinX(nextRect) - CGRectGetMaxX(rect)) / 2.0f;
		}
		
		_trackedRects[@(idx)] = [NSValue valueWithRect:CGRectIntegral(rect)];
	}
}

@end
