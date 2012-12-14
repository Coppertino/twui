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

#import "TUINSView+Private.h"
#import "TUINSView+PasteboardDragging.h"
#import "TUIDragging+Private.h"
#import "TUIDraggingManager.h"

@implementation TUINSView (PasteboardDragging)

@dynamic draggingTypesByViews;

- (void)beginDraggingSession:(TUIDraggingSession *)session event:(NSEvent *)event source:(id<TUIDraggingSource>)source {
	session.draggingSource = source;
	session.draggingLocation = [NSEvent mouseLocation];
	self.currentSourceDraggingSession = session;
	
	[self dragImage:[[NSImage alloc] initWithSize:NSMakeSize(1, 1)]
				  at:session.draggingLocation offset:NSZeroSize
			   event:event pasteboard:session.draggingPasteboard
			 source:self slideBack:NO];
}

/*- (void)dragImage:(NSImage *)anImage at:(NSPoint)viewLocation
		   offset:(NSSize)initialOffset event:(NSEvent *)event
	   pasteboard:(NSPasteboard *)pboard source:(id)sourceObj
		slideBack:(BOOL)slideFlag {
	
	NSImage *dragImage = anImage;
	NSPoint dragLocation = viewLocation;
	if(self.promisedFileDraggingView) {
		dragImage = [self.promisedFileDraggingView dragImageForPromisedFilesOfTypes:self.promisedFileDraggingTypes];
		
		dragLocation.x -= dragImage.size.width / 2;
		dragLocation.y -= dragImage.size.height / 2;
		
		self.promisedFileDraggingView = nil;
		self.promisedFileDraggingTypes = nil;
	}
	
	[super dragImage:dragImage ?: anImage at:dragLocation offset:initialOffset
			   event:event pasteboard:pboard source:sourceObj
		   slideBack:slideFlag];
 }//*/

/*- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray fromRect:(NSRect)rect
						  source:(id)sourceObject slideBack:(BOOL)aFlag event:(NSEvent *)event {
	
	if(self.promisedFileDraggingView) {
		self.promisedFileDraggingTypes = typeArray;
		return [super dragPromisedFilesOfTypes:typeArray fromRect:rect
										source:sourceObject slideBack:aFlag event:event];
	} else {
		return NO;
	}
 }//*/

- (void)registerForDraggedTypes:(NSArray *)draggedTypes forView:(TUIView *)view {
	[self.draggingTypesByViews removeObjectForKey:@(view.hash)];
	if(draggedTypes)
		[self.draggingTypesByViews setObject:draggedTypes forKey:@(view.hash)];
	
	NSMutableArray *types = [NSMutableArray array];
	NSArray *keys = [self.draggingTypesByViews allKeys];
	
	for(NSObject *key in keys) {
		NSArray *viewTypes = [self.draggingTypesByViews objectForKey:key];
		
		for(NSObject *type in viewTypes) {
			if(![types containsObject:type])
				[types addObject:type];
		}
	}
	
	[self registerForDraggedTypes:types];
}

- (TUIView *)viewForDraggingInfo:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForLocationInWindow:sender.draggingLocation];
	
	while(view) {
		if([view conformsToProtocol:@protocol(TUIDraggingDestination)]) {
			NSArray *types = [self.draggingTypesByViews objectForKey:@(view.hash)];
			if(types && [sender.draggingPasteboard availableTypeFromArray:types])
				return view;
		}
		
		view = view.superview;
	}
	
	return nil;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(self.currentDraggingView != view) {
		[self.currentDraggingView draggingExited:sender];
		self.currentDraggingView = nil;
	}
	
	if(view) {
		if(self.currentDraggingView != view) {
			self.currentDraggingView = view;
			return [self.currentDraggingView draggingEntered:sender];
		} else
			return [view draggingUpdated:sender];
	}
	return NSDragOperationNone;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	if(self.currentDraggingView) {
		[self.currentDraggingView draggingExited:sender];
		self.currentDraggingView = nil;
	}
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	if(self.currentDraggingView) {
		[self.currentDraggingView draggingEnded:sender];
		self.currentDraggingView = nil;
	}
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		return [view prepareForDragOperation:sender];
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		return [view performDragOperation:sender];
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	TUIView *view = [self viewForDraggingInfo:sender];
	if(view)
		[view concludeDragOperation:sender];
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	return [session.draggingSource namesOfPromisedFilesInSession:session droppedAtDestination:dropDestination];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	TUIDraggingContext context = flag ? TUIDraggingContextWithinApplication : TUIDraggingContextOutsideApplication;
	NSDragOperation operation = [session.draggingSource draggingSession:session sourceOperationForContext:context];
	
	session.draggingOperation = operation;
	return operation;
}

- (BOOL)ignoreModifierKeysWhileDragging {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	
	BOOL ignore = NO;
	if([session.draggingSource respondsToSelector:@selector(ignoreModifierKeysForDraggingSession:)])
		ignore = [session.draggingSource ignoreModifierKeysForDraggingSession:session];
	
	return ignore;
}
- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	TUIDraggingImageComponent *component = [session.draggingItems[0] imageComponents][0];
	session.draggingLocation = [NSEvent mouseLocation];
	
	[[TUIDraggingManager sharedDraggingManager] startDragFromSourceScreenRect:self.window.frame
															  startingAtPoint:session.draggingLocation
																	   offset:NSZeroSize
																  insideImage:component.contents
																 outsideImage:component.contents
																	slideBack:YES];
}

- (void)draggedImage:(NSImage *)draggedImage movedTo:(NSPoint)screenPoint {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	session.draggingLocation = [NSEvent mouseLocation];
	
	[[TUIDraggingManager sharedDraggingManager] updatePosition];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	session.draggingLocation = [NSEvent mouseLocation];
	
	[[TUIDraggingManager sharedDraggingManager] endDragWithResult:operation];
	self.currentSourceDraggingSession = nil;
}

@end
