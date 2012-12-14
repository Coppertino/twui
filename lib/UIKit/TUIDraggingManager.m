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

#import "TUIDraggingManager.h"

#define TUIDragWindowLevel (NSScreenSaverWindowLevel + 1)

@implementation TUIDraggingManager {
	BOOL _slideBack;
	NSRect _sourceRect;
	NSPoint	_startPoint;
	NSSize _offset;
	NSSize _insideImageSize;
	NSSize _outsideImageSize;
	
	NSImageView *_imageViewA;
	NSImageView *_imageViewB;
}

+ (id)sharedDraggingManager {
    static id sharedDraggingManager = nil;
    if(sharedDraggingManager == nil)
        sharedDraggingManager = [[self alloc] initWithWindow:nil];
    return sharedDraggingManager;
}

- (id)initWithWindow:(NSWindow *)window {
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 64, 64)
										 styleMask:NSBorderlessWindowMask
										   backing:NSBackingStoreBuffered
											 defer:NO];
	
	[window setReleasedWhenClosed:NO];
	[window setMovableByWindowBackground:NO];
	[window setBackgroundColor:[NSColor clearColor]];
	[window setLevel:TUIDragWindowLevel];
	[window setOpaque:NO];
	[window setHasShadow:NO];
	[window.contentView setWantsLayer:YES];
	
	if((self = [super initWithWindow:window])) {
		
		// Create and configure our NSImageViews (we retain them
		// since we'll be swapping them in and out of the window)
		_imageViewA = [[NSImageView alloc] initWithFrame:[window.contentView bounds]];
		[_imageViewA setImageScaling:NSScaleToFit];
		_imageViewB = [[NSImageView alloc] initWithFrame:[window.contentView bounds]];
		[_imageViewB setImageScaling:NSScaleToFit];
		
		// Modify the window's fade animation to set self as delegate
		// (this is done so we can order the window out and clean up)
		CABasicAnimation *alphaValueAnimation = [CABasicAnimation animation];
		[alphaValueAnimation setDelegate:self];
		[window setAnimations:[NSMutableDictionary dictionaryWithObject:alphaValueAnimation forKey:@"alphaValue"]];
	}
	return self;
}

- (void)startDragFromSourceScreenRect:(NSRect)aScreenRect
					  startingAtPoint:(NSPoint)aStartPoint
							   offset:(NSSize)anOffset
						  insideImage:(NSImage *)insideImage
						 outsideImage:(NSImage *)outsideImage
							slideBack:(BOOL)slideBackFlag {
	_sourceRect = aScreenRect;
	_startPoint = aStartPoint;
	_offset = anOffset;
	_slideBack = slideBackFlag;
	_insideImageSize = [insideImage size];
	_outsideImageSize = [outsideImage size];
	
	// Set the window's size to the larger of the two images
	NSSize largestDimensions = NSZeroSize;
	largestDimensions.width = MAX(_insideImageSize.width, _outsideImageSize.width);
	largestDimensions.height = MAX(_insideImageSize.height, _outsideImageSize.height);
	NSRect frame = [[self window] frame];
	frame.size = largestDimensions;
	[[self window] setFrame:frame display:NO];
	
	// Center imageViewA's frame within the content view bounds & set its size
	NSRect frameA = NSZeroRect;
	frameA.size = _insideImageSize;
	frameA.origin = NSMakePoint(NSWidth([[[self window] contentView] bounds]) / 2 - NSWidth(frameA) / 2, NSHeight([[[self window] contentView] bounds]) / 2 - NSHeight(frameA) / 2);
	[_imageViewA setFrame:NSIntegralRect(frameA)];
	
	// Set imageViewB's size
	NSRect frameB = NSZeroRect;
	frameB.size = _outsideImageSize;
	[_imageViewB setFrame:NSIntegralRect(frameB)];
	
	// Make sure view b isn't in the window and view b is
	if ([_imageViewB superview])
		[_imageViewB removeFromSuperview];
	if ([_imageViewA superview] != [[self window] contentView])
		[[[self window] contentView] addSubview:_imageViewA];
	
	// Set the image views' images
	[_imageViewA setImage:insideImage];
	[_imageViewB setImage:outsideImage];
	
	// Position the window's center over the start point
	// (no animation, just go straight there)
	[self _centerWindowOverPoint:_startPoint
					  withOffset:_offset
						 animate:NO];
	
	// Set the window's alpha to zero and order it in
	// (start position, ready to fade)
	[[self window] setAlphaValue:0.0];
	[[self window] orderFront:self];
	
	// Fade in quickly
	[[NSAnimationContext currentContext] setDuration:0.125];
	[[[self window] animator] setAlphaValue:1.0];
}

- (void)updatePosition
{
	// We need the mouse's current location in screen coordinates
	NSPoint mouseLocation = [NSEvent mouseLocation];
	
	// Position the window's center over the current location (no animation, just go straight there)
	[self _centerWindowOverPoint:mouseLocation
					  withOffset:_offset
						 animate:NO];
	
	// Which is the source and which is the target?
	NSImageView * target = (NSPointInRect(mouseLocation, _sourceRect)) ? _imageViewA : _imageViewB;
	NSImageView * source = (target == _imageViewA) ? _imageViewB : _imageViewA;
	
	// Figure out the target frame (centered, same size as image)
	NSRect imageViewTargetFrame = NSZeroRect;
	imageViewTargetFrame.size = (target == _imageViewA) ? _insideImageSize : _outsideImageSize;
	imageViewTargetFrame.origin = NSMakePoint(NSWidth([[[self window] contentView] bounds]) / 2 - NSWidth(imageViewTargetFrame) / 2,
											  NSHeight([[[self window] contentView] bounds]) / 2 - NSHeight(imageViewTargetFrame) / 2);
	
	// If the target view is not already visible, swap it in (and animate)
	if ([target superview] != [[self window] contentView])
		{
		// Set the target view's frame to that of the existing view
		[target setFrame:[source frame]];
		
		// Animate the swap and size change (this gives the effect of
		// one object morphing into another a la Interface Builder)
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.2];
		[[[[self window] contentView] animator] replaceSubview:source with:target];
		[[target animator] setFrame:NSIntegralRect(imageViewTargetFrame)];
		[NSAnimationContext endGrouping];
		}
}

- (void)endDragWithResult:(NSDragOperation)dragOperation
{
	// If the drag operation is none and slide-back is requested, start slide-back effect
	if (dragOperation == NSDragOperationNone && _slideBack)
		[self _centerWindowOverPoint:_startPoint
						  withOffset:_offset
							 animate:YES];
	
	// Always start fade-out effect
	[[[self window] animator] setAlphaValue:0.0];
}


#pragma mark Internal Window Management

- (void)_centerWindowOverPoint:(NSPoint)point
					withOffset:(NSSize)offset
					   animate:(BOOL)animate
{
	// Determine the frame
	NSRect frame = [[self window] frame];
	frame.origin = NSMakePoint(point.x - (NSWidth(frame) / 2) + offset.width,
							   point.y - (NSHeight(frame) / 2) + offset.height);
	
	// Animate and fade out if requested, else just set the frame.
	if (animate)
		{
		[[NSAnimationContext currentContext] setDuration:0.15];
		[[[self window] animator] setFrame:frame display:YES];
		} else {
			[[self window] setFrame:frame display:YES];
		}
}

- (void)_orderOutAndCleanUp
{
	// Order our window out
	[[self window] orderOut:self];
	
	// Clean up the state
	_slideBack = NO;
	_sourceRect = NSZeroRect;
	_offset = NSZeroSize;
	_startPoint = NSZeroPoint;
	_insideImageSize = NSZeroSize;
	_outsideImageSize = NSZeroSize;
	
	// Drop the images
	[_imageViewA setImage:nil];
	[_imageViewB setImage:nil];
}


#pragma mark Animation Delegation

- (void)animationDidStop:(CAAnimation *)theAnimation
				finished:(BOOL)flag
{
	// We only care about the window's fade-out animation
	// We want to clean up if successfully faded out
	if (flag && [[self window] alphaValue] == 0.0)
		[self _orderOutAndCleanUp];
}

@end
