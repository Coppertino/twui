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

#pragma mark - TUIDraggingSource Registration

- (void)beginDraggingSession:(TUIDraggingSession *)session event:(NSEvent *)event source:(id<TUIDraggingSource>)source {
	
	// Qualify the current dragging source and dragging session.
	session.draggingSource = source;
	session.draggingLocation = [NSEvent mouseLocation];
	self.currentSourceDraggingSession = session;
	
	// To allow return from this method, queue a fake drag right after.
	[self performSelector:@selector(beginDraggingSession:) withObject:event afterDelay:0.01f];
}

// Fake a dragged image, letting the TUIDraggingSession manage itself.
- (void)beginDraggingSession:(NSEvent *)event {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	[self dragImage:[[NSImage alloc] initWithSize:NSMakeSize(1, 1)]
				 at:session.draggingLocation offset:NSZeroSize
			  event:event pasteboard:session.draggingPasteboard
			 source:self slideBack:NO];
}

#pragma mark - TUIDraggingSource Handlers

// Using a TUIDraggingPromiseItem, proxy file promises back to the pasteboarditems.
- (void)pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type {
	if([type isEqualToString:NSFilesPromisePboardType]) {
		TUIDraggingSession *session = self.currentSourceDraggingSession;
		
		// Get all the file types from the items and return them.
		NSMutableArray *pasteTypes = @[].mutableCopy;
		for(TUIDraggingFilePromiseItem *item in session.draggingPromiseItems)
			[pasteTypes addObject:item.promisedFiletype];
		
		// Provide all the UTI-converted file extensions.
		[sender setPropertyList:pasteTypes forType:type];
	}
}

// Since we are proxying file promises, search the session for the correct file name.
- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
	
	// Save the promised drag destination because we'll need it later.
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	self.currentPromisedDragDestination = dropDestination;
	
	// Get all the file names from the promised items and return them.
	// Set the promise destination if the source needs to write promises themselves.
	NSMutableArray *pasteFiles = @[].mutableCopy;
	for(TUIDraggingFilePromiseItem *item in session.draggingPromiseItems) {
		[pasteFiles addObject:item.promisedFilename];
		item.promiseDestinationURL = dropDestination;
	}
	
	return pasteFiles;
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	
	// Set up default operations and determine the context for the dragging source.
	TUIDraggingContext context = flag ? TUIDraggingContextWithinApplication : TUIDraggingContextOutsideApplication;
	NSDragOperation operation = NSDragOperationCopy | NSDragOperationLink | NSDragOperationGeneric | NSDragOperationPrivate;
	
	// Forward source operation masking into contexts for the dragging source.
	if([session.draggingSource respondsToSelector:@selector(draggingSession:sourceOperationForContext:)])
		operation = [session.draggingSource draggingSession:session sourceOperationForContext:context];
	
	session.draggingOperation = operation;
	return operation;
}

- (BOOL)ignoreModifierKeysWhileDragging {
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	
	// Forward modifier key ignores to the dragging source.
	if([session.draggingSource respondsToSelector:@selector(ignoreModifierKeysForDraggingSession:)])
		return [session.draggingSource ignoreModifierKeysForDraggingSession:session];
	else return NO;
}
- (void)draggedImage:(NSImage *)image beganAt:(NSPoint)screenPoint {
	
	// Update the dragging session.
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	session.draggingLocation = [NSEvent mouseLocation];
	
	// Update the dragging source and the dragging session.
	[session startDrag];
	if([session.draggingSource respondsToSelector:@selector(draggingSession:beganAtPoint:)])
		[session.draggingSource draggingSession:session beganAtPoint:session.draggingLocation];
}

- (void)draggedImage:(NSImage *)draggedImage movedTo:(NSPoint)screenPoint {
	
	// Update the dragging session.
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	session.draggingLocation = [NSEvent mouseLocation];
	
	// Update the dragging source and the dragging session.
	[session updateDrag];
	if([session.draggingSource respondsToSelector:@selector(draggingSession:movedToPoint:)])
		[session.draggingSource draggingSession:session movedToPoint:session.draggingLocation];
}

- (void)draggedImage:(NSImage *)anImage endedAt:(NSPoint)aPoint operation:(NSDragOperation)operation {
	
	// Update the dragging session.
	TUIDraggingSession *session = self.currentSourceDraggingSession;
	session.draggingLocation = [NSEvent mouseLocation];
	session.draggingOperation = operation;
	
	// Clear the drag destination for future promise drags.
	NSURL *location = self.currentPromisedDragDestination;
	self.currentPromisedDragDestination = nil;
	
	// If there is no existing location for file promises, ignore them.
	// The !! is a NOT-NOT: It qualifies the existance of the object.
	if(!!location) {
		
		// Iterate all the files to save and either take care of the saving for
		// the data providers or alert them to save the files themselves.
		// Do this on an asynchronous dispatch queue to prevent UI blocking.
		for(TUIDraggingFilePromiseItem *item in session.draggingPromiseItems) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
				
				// Retrieve all the file information to paste, if it's available.
				NSString *filename = [item stringForType:TUIPasteboardTypeFilePromiseName];
				NSString *extension = item.promisedFiletype;
				NSData *data = [item dataForType:TUIPasteboardTypeFilePromiseContent];
				
				// If we don't have any of the above, assume the promise is invalid,
				// and don't process it. If the data is the only missing content,
				// assume the dragging source wishes to write the promised file.
				if(!!data && !!filename && !!extension) {
					NSURL *path = [location URLByAppendingPathComponent:filename];
					
					// Determine the number of pre-existing files with the same name.
					NSUInteger existingFileCount = 0;
					NSString *checkPath = path.path;
					while([[NSFileManager defaultManager] fileExistsAtPath:[checkPath stringByAppendingPathExtension:extension]]) {
						existingFileCount++;
						checkPath = [path.path stringByAppendingFormat:@" (%lu)", existingFileCount];
					}
					
					// Write the data to the file after appending a file copy badge.
					[data writeToFile:[checkPath stringByAppendingPathExtension:extension] atomically:YES];
				}
			});
		}
	}
	
	// End the dragging and disqualify the dragging session.
	[session endDrag];
	self.currentSourceDraggingSession = nil;
	
	if([session.draggingSource respondsToSelector:@selector(draggingSession:endedAtPoint:)])
		[session.draggingSource draggingSession:session endedAtPoint:session.draggingLocation];
	
	// Relinquish the item promise destination URLs when done dragging.
	for(TUIDraggingFilePromiseItem *item in session.draggingPromiseItems)
		item.promiseDestinationURL = nil;
}

#pragma mark - TUIDraggingDestination Registration

@dynamic draggingTypesByViews;

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

#pragma mark - TUIDraggingDestination Handlers

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

#pragma mark - 

@end
