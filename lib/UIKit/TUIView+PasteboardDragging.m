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

#import "TUIView+PasteboardDragging.h"
#import "TUIView+Private.h"
#import "TUINSView+Private.h"
#import "TUIDragging+Private.h"

@implementation TUIView (Dragging)

#pragma mark - Dragging Control

@dynamic draggingTypes;

- (NSArray *)registeredDraggingTypes {
	return self.draggingTypes;
}

- (void)registerForDraggedTypes:(NSArray *)draggingTypes {
	self.draggingTypes = draggingTypes;
	[self updateRegisteredDraggingTypes];
}

- (TUIDraggingSession *)beginDraggingSessionWithItems:(NSArray *)items
												event:(NSEvent *)event
											   source:(id <TUIDraggingSource>)source {
	TUIDraggingSession *session = [[TUIDraggingSession alloc] init];
	session.draggingPasteboard = [NSPasteboard pasteboardWithName:NSDragPboard];
	session.draggingItems = items;
	
	// Convert from TUIDraggingItems back into NSPasteboardItems.
	NSMutableArray *pasteItems = @[].mutableCopy;
	for(TUIDraggingItem *item in items)
		[pasteItems addObject:item.item];
	
	// Now write all the pasteboard items to the dragging pasteboard.
	[session.draggingPasteboard clearContents];
	[session.draggingPasteboard writeObjects:pasteItems];
	
	[self.nsView beginDraggingSession:session event:event source:source];
	return session;
}

#pragma mark - TUIDraggingDestination

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return NSDragOperationNone;
}

// FIXME: Needs to use cached value instead of method call.
- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	return [self draggingEntered:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
	
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
	
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender {
	return NO;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return NO;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
	
}

#pragma mark -

- (BOOL)dragPromisedFilesOfTypes:(NSArray *)typeArray
						fromRect:(NSRect)rect source:(id)sourceObject
					   slideBack:(BOOL)aFlag event:(NSEvent *)event {
	return NO;
}

- (NSImage *)dragImageForPromisedFilesOfTypes:(NSArray *)typeArray {
	return nil;
}

@end
