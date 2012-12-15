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

#import "TUIView.h"

#import "TUIDragging.h"
#import "TUIDraggingItem.h"
#import "TUIDraggingSession.h"

@interface TUIView (Dragging) <TUIDraggingDestination>

// Returns or sets the types registered for a view. Each element of the array
// is a uniform type identifier. The returned elements are in no particular
// order, but the array is guaranteed not to contain duplicate entries.
// Registering an TUIView object for dragged types automatically makes it a
// candidate destination object for a dragging session. As such, it must
// properly implement some or all of the NSDraggingDestination protocol
// methods. As a convenience, TUIView provides default implementations of
// these methods. See the NSDraggingDestination protocol for details.
// To unregister all dragging types, set this property's value to nil.
@property (nonatomic, copy, getter = registeredDraggingTypes, setter = registerForDraggedTypes:) NSArray *draggingTypes;

// Initiates a dragging session with a group of dragging items. The passed NSArray
// must contain TUIDraggingItems whose frames must be in the view's coordinate
// system. The NSEvent is used to determine the mouse location for the offset
// of the dragged icons. The source serves as the controller of the dragging
// operation. The returned dragging session allows you to further modify its
// properties. When the drag actually starts, the source's dragging methods
// are called in order. Once the drag is ended or cancelled, the drag is complete.
- (TUIDraggingSession *)beginDraggingSessionWithItems:(NSArray *)items
												event:(NSEvent *)event
											   source:(id <TUIDraggingSource>)source;

@end
