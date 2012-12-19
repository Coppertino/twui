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

#import "TUIDraggingSession.h"
#import "TUIDragging+Private.h"
#import "CAAnimation+TUIExtensions.h"

@implementation TUIDraggingSession

- (id)init {
	if((self = [super init])) {
		self.draggingFormation = TUIDraggingFormationDefault;
		
		self.compositedWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 64, 64)
											 styleMask:NSBorderlessWindowMask
											   backing:NSBackingStoreBuffered
												 defer:NO];
		
		[self.compositedWindow setReleasedWhenClosed:NO];
		[self.compositedWindow setMovableByWindowBackground:NO];
		[self.compositedWindow setBackgroundColor:[NSColor clearColor]];
		[self.compositedWindow setLevel:CGShieldingWindowLevel()];
		[self.compositedWindow setOpaque:NO];
		[self.compositedWindow.contentView setWantsLayer:YES];
		
		[self.compositedWindow setCollectionBehavior:NSWindowCollectionBehaviorIgnoresCycle |
		 NSWindowCollectionBehaviorFullScreenAuxiliary |
		 NSWindowCollectionBehaviorCanJoinAllSpaces |
		 NSWindowCollectionBehaviorTransient |
		 NSWindowCollectionBehaviorStationary];
		
		self.compositeView = [[NSImageView alloc] initWithFrame:[self.compositedWindow.contentView bounds]];
		[self.compositeView setImageScaling:NSScaleToFit];
		
		CABasicAnimation *alpha = [CABasicAnimation animation];
		alpha.tui_completionBlock = ^{
			if([self.compositedWindow alphaValue] == 0.0) {
				[self.compositedWindow orderOut:self];
				[self.compositeView setImage:nil];
			}
		};
		self.compositedWindow.animations = @{@"alphaValue" : alpha};
	}
	return self;
}

- (void)startDrag {
	TUIDraggingImageComponent *component = [self.draggingItems[0] imageComponents][0];
	
	_startPoint = self.draggingLocation;
	_imageSize = [component.contents size];
	
	NSRect frame = self.compositedWindow.frame;
	frame.size = _imageSize;
	[self.compositedWindow setFrame:frame display:NO];
	
	NSRect frameA = NSZeroRect;
	frameA.size = _imageSize;
	frameA.origin = NSMakePoint(NSWidth([[self.compositedWindow contentView] bounds]) / 2 - NSWidth(frameA) / 2,
								NSHeight([[self.compositedWindow contentView] bounds]) / 2 - NSHeight(frameA) / 2);
	[self.compositeView setFrame:NSIntegralRect(frameA)];
	
	if(self.compositeView.superview != self.compositedWindow.contentView)
		[self.compositedWindow.contentView addSubview:self.compositeView];
	[self.compositeView setImage:component.contents];
	
	[self _centerWindowOverPoint:_startPoint animate:NO];
	[self.compositedWindow setAlphaValue:0.0];
	[self.compositedWindow orderFront:self];
	
	[[NSAnimationContext currentContext] setDuration:0.125f];
	[self.compositedWindow.animator setAlphaValue:1.0f];
}

- (void)updateDrag {
	NSPoint mouseLocation = [NSEvent mouseLocation];
	[self _centerWindowOverPoint:mouseLocation  animate:NO];
	
	NSRect imageViewTargetFrame = NSZeroRect;
	imageViewTargetFrame.size = _imageSize;
	imageViewTargetFrame.origin = NSMakePoint(NSWidth([[self.compositedWindow contentView] bounds]) / 2 - NSWidth(imageViewTargetFrame) / 2, NSHeight([[self.compositedWindow contentView] bounds]) / 2 - NSHeight(imageViewTargetFrame) / 2);
}

- (void)endDrag {
	if(self.draggingOperation == NSDragOperationNone && self.reanimatesToSource)
		[self _centerWindowOverPoint:_startPoint animate:YES];
	[self.compositedWindow.animator setAlphaValue:0.0];
}

- (void)_centerWindowOverPoint:(NSPoint)point animate:(BOOL)animate {
	NSRect frame = self.compositedWindow.frame;
	frame.origin = NSMakePoint(point.x - (NSWidth(frame) / 2), point.y - (NSHeight(frame) / 2));
	
	if(animate) {
		[[NSAnimationContext currentContext] setDuration:0.15f];
		[[self.compositedWindow animator] setFrame:frame display:YES];
	} else {
		[self.compositedWindow setFrame:frame display:YES];
	}
}

- (void)enumerateDraggingItemsWithForView:(NSView *)view
								  classes:(NSArray *)classArray
							searchOptions:(NSDictionary *)searchOptions
							   usingBlock:(void (^)(TUIDraggingItem *draggingItem, NSInteger idx, BOOL *stop))block {
	NSLog(@"Class %@ method %@ is unimplemented.", NSStringFromClass(self.class), NSStringFromSelector(_cmd));
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p> {\n\tDragging Formation: %lu\n\tSession Context: %@\n\tAnimates to Destination: %@\n\tReanimates to Source: %@\n\tNumber of Valid Items for Drop: %@\n\tDragging Leader Index: %lu\n\tDragging Pasteboard: %@\n\tDragging Sequence Number: %@\n\tDragging Location: %@\n\tDragging Source: %@\n\tDragging Operation: %lu\n}",
			NSStringFromClass(self.class), self, self.draggingFormation, self.sessionContext,
			self.animatesToDestination ? @"YES" : @"NO", self.reanimatesToSource ? @"YES" : @"NO",
			(self.numberOfValidItemsForDrop != NSNotFound ? @(self.numberOfValidItemsForDrop): @"Unavailable"),
			self.draggingLeaderIndex, self.draggingPasteboard,
			(self.draggingSequenceNumber != NSNotFound ? @(self.draggingSequenceNumber): @"Unavailable"),
			NSStringFromPoint(self.draggingLocation), self.draggingSource, self.draggingOperation];
}

@end
