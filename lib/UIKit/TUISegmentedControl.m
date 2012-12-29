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

+ (NSSegmentedCell *)sharedGraphicsRenderer {
	static NSSegmentedCell *_backingCell = nil;
	if(!_backingCell) {
		_backingCell = [NSSegmentedCell new];
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
	
	[self drawBackground:rect];
	// Set the highlighted values.
	/*NSDictionary *rectCache = [[TUISegmentedControl sharedGraphicsRenderer] trackedRects];
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
	//*/
}

- (void)drawBackground:(CGRect)rect {
	NSSegmentedCell *renderer = [TUISegmentedControl sharedGraphicsRenderer];
	[renderer setSegmentStyle:NSSegmentStyleRounded];
	[renderer drawWithFrame:rect inView:self.nsView];
}

- (void)drawSegmentContents:(NSUInteger)segment inRect:(CGRect)rect {
	// No image or text drawing yet.
}

- (NSUInteger)segmentForHitTestAtPoint:(CGPoint)point {
	point = [self.nsView convertPoint:point fromView:nil];
	NSSegmentedCell *renderer = [TUISegmentedControl sharedGraphicsRenderer];
	NSLog(@"%ld", renderer.segmentCount);
	
	[renderer startTrackingAt:point inView:self.nsView];
	[renderer stopTracking:point at:point inView:self.nsView mouseIsUp:YES];
	
	return renderer.selectedSegment;
}

- (BOOL)beginTrackingWithEvent:(NSEvent *)event {
	NSUInteger segment = [self segmentForHitTestAtPoint:event.locationInWindow];
	
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		item.selected = (idx == segment);
	}];
	return YES;
}

- (BOOL)continueTrackingWithEvent:(NSEvent *)event {
	NSUInteger segment = [self segmentForHitTestAtPoint:event.locationInWindow];
	
	[self.items enumerateObjectsUsingBlock:^(TUISegmentedItem *item, NSUInteger idx, BOOL *stop) {
		item.selected = (idx == segment);
	}];
	return YES;
}

- (void)endTrackingWithEvent:(NSEvent *)event {
	NSUInteger segment = [self segmentForHitTestAtPoint:event.locationInWindow];
	
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
