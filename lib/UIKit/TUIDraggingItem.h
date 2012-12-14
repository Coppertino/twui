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

extern NSString *const TUIDraggingImageComponentIconKey;
extern NSString *const TUIDraggingImageComponentLabelKey;

@interface TUIDraggingImageComponent : NSObject

// key must be unique for each component in an TUIDraggingItem. You
// can create your own named components, but the following names
// have special meaning. TUIDraggingImageComponentIconKey is an
// image of the item being dragged. TUIDraggingImageComponentLabelKey
// represents a textual label associated with the item, like a file name.
@property (nonatomic, copy) NSString *key;

// An object providing the image contents of the component, typically
// you set an NSImage, but it may be anything CALayer accepts.
@property (nonatomic, assign) id contents;

// The coordinate space is the bounds of the parent TUIDraggingItem.
// Note: TUIDraggingItem does not clip its components.
@property (nonatomic, readonly) NSRect frame;

+ (id)draggingImageComponentWithKey:(NSString *)key;

// Designated initializer.
- (id)initWithKey:(NSString *)key;

@end

@interface TUIDraggingItem : NSObject

// When you create an TUIDraggingItem, item is the pasteboardWriter
// passed to initWithPasteboardWriter. However, when enumerating
// dragging items in an TUIDraggingSession or TUIDraggingInfo object,
// item is not the original pasteboardWriter. It is an instance of
// one of the classes provided to the enumeration method.
@property (nonatomic, strong, readonly) id item;

// The dragging frame that provides the spatial relationship between
// TUIDraggingItems in the TUIDraggingFormationNone. Note: The exact
// coordinate space of this rect depends on where it is used.
@property (nonatomic, assign) NSRect draggingFrame;

// The dragging image is the composite of an array of TUIDraggingImageComponents.
// The dragging image components may not be set directly. Instead, provide a
// block to generate the components and the block will be called if necessary.
// The block may be set to nil, meaning that this drag item has no image.
// Generally, only dragging destinations do this, and only if there is at
// least one valid item in the drop, and this is not it. The components are
// composited in painting order. That is, each component in the array is
// painted on top of the previous components in the array.
@property (nonatomic, copy) NSArray* (^imageComponentsProvider)(void);

// An array of TUIDraggingImageComponents that are used to create the drag
// image. Note: the array contains copies of the components. Changes made
// to these copies are not reflected in the drag. If needed, the
// imageComponentsProvider block is called to generate the image components.
@property (nonatomic, copy, readonly) NSArray *imageComponents;

// The designated initializer. When creating an TUIDraggingItem the
// pasteboardWriter must implement the NSPasteboardWriting protocol.
- (id)initWithPasteboardWriter:(id<NSPasteboardWriting>) pasteboardWriter;

// Alternate single image component setter. This method simplifies modifiying
// the components of an TUIDraggingItem when there is only one component.
// This method will set the draggingFrame and imageComponentsProvider
// properties. frame is in the same coordinate space as the draggingFrame.
- (void)setDraggingFrame:(NSRect)frame contents:(id)contents;

@end
