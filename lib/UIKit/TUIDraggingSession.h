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

#import "TUIDragging.h"
#import "TUIDraggingItem.h"

@interface TUIDraggingSession : NSObject

// Controls the dragging formation when the drag is over the source.
// The default value is TUIDraggingFormationNone.
@property (nonatomic, assign) TUIDraggingFormation draggingFormation;

// The context carries arbitrary information from source to destination
// during a dragging session. It does nothing if out of the application.
// It is initially assigned the source of the dragging operation, but
// can be re-assigned for internal-use context passing.
@property (nonatomic, strong) id sessionContext;

@property (nonatomic, assign) BOOL animatesToDestination;

// Controls whether the dragging image animates back to its starting
// point on a cancelled or failed drag. -draggingSession:endedAtPoint:operation:
// is a good time to change this value depending on the result of the
// drag operation. The default value is YES.
@property (nonatomic, assign) BOOL reanimatesToSource;

// The index of the draggingItem under the cursor. The default is the
// TUIDraggingItem closest to the location in the event that was passed
// to -beginDraggingSessionWithItems:event:source:.
@property (nonatomic, assign, readonly) NSInteger draggingLeaderIndex;

// Returns the pasteboard object that holds the data being dragged.
@property (nonatomic, assign, readonly) NSPasteboard *draggingPasteboard;

// Returns a number that uniquely identifies the dragging session.
@property (nonatomic, assign, readonly) NSInteger draggingSequenceNumber;

// The current cursor location of the drag in screen coordinates.
@property (nonatomic, assign, readonly) NSPoint draggingLocation;

// Returns the dragging operation mask of the dragging source. The dragging
// operation mask, which is declared by the dragging source through the TUIDraggingSource
// draggingSession:sourceOperationMaskForDraggingContext: method. If the source
// does not permit any dragging operations, this method should return NSDragOperationNone.
@property (nonatomic, assign, readonly) NSDragOperation draggingOperation;

// Enumerate through each dragging item. Any changes made to the properties
// of the draggingItem are reflected in the drag when the destination is not
// overriding them. Classes in the provided array must implement the NSPasteboardReading
// protocol. Cocoa classes that implement this protocol include NSImage,
// NSString, NSURL, NSColor, NSAttributedString, and NSPasteboardItem. For
// every item on the pasteboard, each class in the provided array will be
// queried for the types it can read using -readableTypesForPasteboard:. An
// instance will be created of the first class found in the provided array
// whose readable types match a conforming type contained in that pasteboard
// item. If an Instance is created from the pasteboard item data, it is placed
// into an TUIDraggingItem along with the dragging properties of that item such
// as the drag image. The TUIDraggingItem is then passed as a parameter to the
// provided block. Additional search options, such as restricting the search to
// file URLs with particular content types, can be specified with a search options
// dictionary. Note: all coordinate properties in the TUIDraggingItem are in
// the coordinate system of view. If view is nil, the screen coordinate space is used.
- (void)enumerateDraggingItemsWithForView:(NSView *)view
								  classes:(NSArray *)classArray
							searchOptions:(NSDictionary *)searchOptions
							   usingBlock:(void (^)(TUIDraggingItem *draggingItem, NSInteger idx, BOOL *stop))block;

@end
