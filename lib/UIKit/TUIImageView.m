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

#import "TUIImageView.h"
#import "TUINSView.h"
#import "NSImage+TUIExtensions.h"
#import "TUIStretchableImage.h"
#import "TUIDraggingFilePromiseItem.h"

@implementation TUIImageView

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.userInteractionEnabled = NO;
		self.opaque = NO;
		self.savedFiletype = NSPNGFileType;
	}
	return self;
}

- (id)initWithImage:(NSImage *)image {
	if((self = [self initWithFrame:image ? CGRectMake(0, 0, image.size.width, image.size.height) : CGRectZero])) {
		self.image = image;
	}
	return self;
}

- (id)initWithImage:(NSImage *)image highlightedImage:(NSImage *)highlightedImage {
	if((self = [self initWithImage:image])) {
		self.highlightedImage = highlightedImage;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	if(!self.image)
		return;
	
	[self.image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)startAnimating {
	NSArray *images = _highlighted ? _highlightedAnimationImages : _animationImages;
	
	NSMutableArray *CGImages = [NSMutableArray array];
	for(NSImage *image in images) {
		[CGImages addObject:(__bridge id)image.tui_CGImage];
	}
	
	CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
	animation.calculationMode = kCAAnimationDiscrete;
	animation.fillMode = kCAFillModeBoth;
	animation.removedOnCompletion = NO;
	animation.duration = self.animationDuration ?: ([images count] * (1/30.0));
	animation.repeatCount = self.animationRepeatCount ?: HUGE_VALF;
	animation.values = CGImages;
	
	[self.layer addAnimation:animation forKey:@"contents"];
}

- (void)stopAnimating {
	[self.layer removeAnimationForKey:@"contents"];
}

- (BOOL)isAnimating {
	return [self.layer animationForKey:@"contents"] != nil;
}

- (void)setImage:(NSImage *)image {
	if([_image isEqual:image])
		return;
	
	_image = image;
	if(!(self.highlighted && self.highlightedImage))
		[self setNeedsDisplay];
}

- (void)setHighlightedImage:(NSImage *)newImage {
	if([_highlightedImage isEqual:newImage])
		return;
	
	_highlightedImage = newImage;
	if(self.highlighted)
		[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)h {
	if(_highlighted == h)
		return;
	
	_highlighted = h;
	if([TUIView isInAnimationContext])
		[self redraw];
	else [self setNeedsDisplay];
	
	if([self isAnimating])
		[self startAnimating];
}

- (void)setEditable:(BOOL)editable {
	_editable = editable;
	if(editable) {
		self.draggingTypes = @[ NSPasteboardTypePDF,
								NSPasteboardTypeTIFF,
								NSPasteboardTypePNG,
								NSFilenamesPboardType,
								NSPostScriptPboardType,
								NSTIFFPboardType,
								NSFileContentsPboardType,
								NSPDFPboardType ];
	} else self.draggingTypes = nil;
}

#pragma mark - Size Calculation

- (void)displayIfSizeChangedFrom:(CGSize)oldSize to:(CGSize)newSize {
	if(!CGSizeEqualToSize(newSize, oldSize) && [self.image.class isKindOfClass:TUIStretchableImage.class]) {
		[self setNeedsDisplay];
	}
}

- (void)setFrame:(CGRect)newFrame {
	BOOL needsDisplay = !CGSizeEqualToSize(self.frame.size, newFrame.size);
	[super setFrame:newFrame];
	
	if(needsDisplay && ![self.image.class isKindOfClass:TUIStretchableImage.class]) {
		if([TUIView isInAnimationContext])
			[self redraw];
		else [self setNeedsDisplay];
	}
}

- (void)setBounds:(CGRect)newBounds {
	BOOL needsDisplay = !CGSizeEqualToSize(self.bounds.size, newBounds.size);
	[super setBounds:newBounds];
	
	if(needsDisplay && ![self.image.class isKindOfClass:TUIStretchableImage.class]) {
		if([TUIView isInAnimationContext])
			[self redraw];
		else [self setNeedsDisplay];
	}
}

- (CGSize)sizeThatFits:(CGSize)size {
	return self.image? self.image.size : CGSizeZero;
}

- (void)sizeToFit {
	CGSize fittingSize = [self sizeThatFits:CGSizeZero];
	self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y,
							fittingSize.width, fittingSize.height);
}

#pragma mark - Pasteboard Source

// Allow the activation mouse to begin dragging.
- (BOOL)acceptsFirstMouse:(NSEvent *)event {
	return YES;
}

- (void)mouseDown:(NSEvent *)event {
	[super mouseDown:event];
	if(!self.savable || !self.image)
		return;
	
	// Prepare our drag and image rectangles.
	CGRect dragRect = (CGRect) {
		.origin = event.locationInWindow,
		.size = CGSizeMake(32, 32)
	};
	
	CGRect imageRect = (CGRect) {
		.origin = CGPointZero,
		.size = self.layer.visibleRect.size
	};
	
	// Prepare the drag image.
	NSImage *dragImage = [NSImage tui_imageWithSize:imageRect.size drawing:^(CGContextRef ctx) {
		CGContextSetAlpha(ctx, 0.5);
		CGContextDrawImage(ctx, imageRect, self.image.tui_CGImage);
	}];
	
	// Determine the UTI file type of the image.
	NSString *extension = (id)kUTTypePNG;
	if(self.savedFiletype == NSTIFFFileType)
		extension = (id)kUTTypeTIFF;
	else if(self.savedFiletype == NSBMPFileType)
		extension = (id)kUTTypeBMP;
	else if(self.savedFiletype == NSGIFFileType)
		extension = (id)kUTTypeGIF;
	else if(self.savedFiletype == NSJPEGFileType)
		extension = (id)kUTTypeJPEG;
	else if(self.savedFiletype == NSJPEG2000FileType)
		extension = (id)kUTTypeJPEG2000;
	
	// Create a pasteboard item to lazy-write the content image.
	TUIDraggingFilePromiseItem *pasteItem = [[TUIDraggingFilePromiseItem alloc] init];
	[pasteItem setDataProvider:self forTypes:@[TUIPasteboardTypeFilePromiseContent]];
	[pasteItem setPropertyList:extension forType:TUIPasteboardTypeFilePromiseType];
	[pasteItem setString:(self.savedFilename ?: @"Photo") forType:TUIPasteboardTypeFilePromiseName];
	
	// Create a dragging item to display an on-screen drag with the pasteboard item.
	TUIDraggingItem *dragItem = [[TUIDraggingItem alloc] initWithPasteboardWriter:pasteItem];
	[dragItem setDraggingFrame:dragRect contents:dragImage];
	
	// Begin dragging and modify the session so it slides back and doesn't group.
	TUIDraggingSession *session = [self beginDraggingSessionWithItems:@[dragItem] event:event source:self];
	session.reanimatesToSource = YES;
	session.draggingFormation = TUIDraggingFormationNone;
}

// Modify the context so that it's only possible to copy images outside the application.
- (NSDragOperation)draggingSession:(TUIDraggingSession *)session sourceOperationForContext:(TUIDraggingContext)context {
	return NSDragOperationCopy;
}

// Return the TIFF representation of our image when the pasteboard calls for it.
- (void)pasteboard:(NSPasteboard *)sender item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
	if([type isEqualToString:TUIPasteboardTypeFilePromiseContent]) {
		
		// Convert to the specified representation type and paste it.
		NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:self.image.TIFFRepresentation];
		NSData *bitmapData = [imageRep representationUsingType:self.savedFiletype ?: NSPNGFileType properties:nil];
        [item setData:bitmapData forType:type];
	}
}

- (void)draggingSession:(TUIDraggingSession *)session movedToPoint:(NSPoint)screenPoint {
	// Update image to file icon.
}

// When the dragging session ends, call the handler.
- (void)draggingSession:(TUIDraggingSession *)session endedAtPoint:(NSPoint)screenPoint {
	if(self.imageSavedHandler)
		self.imageSavedHandler();
}

#pragma mark - Pasteboard Destination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if(![sender.draggingSource isEqual:self] && self.editable &&
	   [NSImage canInitWithPasteboard:sender.draggingPasteboard]) {
		
		self.highlighted = YES;
		return NSDragOperationCopy;
	} else {
		return NSDragOperationNone;
	}
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	self.highlighted = NO;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return (![sender.draggingSource isEqual:self] && self.editable);
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	NSImage *image = [[NSImage alloc] initWithPasteboard:sender.draggingPasteboard];
	
	if(image) {
		self.image = image;
		if(self.editingSizesToFit)
			[self sizeToFit];
		if(self.imageEditedHandler)
			self.imageEditedHandler();
	}
	
	return image == nil;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	self.highlighted = NO;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
	return NSDragOperationCopy;
}

#pragma mark -

@end
