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

typedef enum TUIDraggingContext : NSUInteger {
	TUIDraggingContextOutsideApplication,
	TUIDraggingContextWithinApplication,
	TUIDraggingContextOutsideWindow,
	TUIDraggingContextWithinWindow
} TUIDraggingContext;

typedef enum TUIDraggingFormation : NSUInteger {
	TUIDraggingFormationDefault,
	TUIDraggingFormationNone,
	TUIDraggingFormationPile,
	TUIDraggingFormationList,
	TUIDraggingFormationStack
} TUIDraggingFormation;

@class TUIDraggingSession;

// Methods implemented by an object that initiates a drag session.
// The source application is sent these messages during dragging.
// The others are sent if the source responds to first method.
@protocol TUIDraggingSource <NSObject>

@optional

// Declares what types of operations the source allows to be performed.
// In the future, more specific "within" values may be specified.
// To account for this, for unrecongized localities, return the operation
// mask for the most specific context that you are concerned with.
- (NSDragOperation)draggingSession:(TUIDraggingSession *)session sourceOperationForContext:(TUIDraggingContext)context;

// Invoked when the drag will begin.
- (void)draggingSession:(TUIDraggingSession *)session beganAtPoint:(NSPoint)screenPoint;

// Invoked when the drag moves on the screen.
- (void)draggingSession:(TUIDraggingSession *)session movedToPoint:(NSPoint)screenPoint;

// Invoked when the dragging session has completed. The finalized dragging
// source mask operation can be read from the passed session object.
- (void)draggingSession:(TUIDraggingSession *)session endedAtPoint:(NSPoint)screenPoint;

// Returns whether the modifier keys will be ignored for this dragging session.
- (BOOL)ignoreModifierKeysForDraggingSession:(TUIDraggingSession *)session;

@end

// Methods implemented by an object that receives dragged images.
// The destination view is sent these messages during dragging if it responds.
@protocol TUIDraggingDestination <NSObject>

@optional

// Invoked when the dragged image enters destination bounds or frame; delegate
// returns dragging operation to perform. Returns one (and only one) of the dragging
// NSDragOperation constants. The default return value (if this method is not
// implemented by the destination) is the value returned by the previous
// draggingEntered: message. Invoked when a dragged image enters the destination
// but only if the destination has registered for the pasteboard data type involved
// in the drag operation. Specifically, this method is invoked when the mouse
// pointer enters the destination’s bounds rectangle (if it is a view object) or
// its frame rectangle (if it is a window object). This method must return a
// value that indicates which dragging operation the destination will perform
// when the image is released. In deciding which dragging operation to return,
// the method should evaluate the overlap between both the dragging operations
// allowed by the source (obtained from sender with the draggingSourceOperationMask
// method) and the dragging operations and pasteboard data types the destination
// itself supports. If none of the operations is appropriate, this method should
// return NSDragOperationNone (this is the default response if the method is not
// implemented by the destination). A destination will still receive draggingUpdated:
// and draggingExited: even if NSDragOperationNone is returned by this method.
- (NSDragOperation)draggingEntered:(TUIDraggingSession *)sender;

// Invoked periodically as the image is held within the destination area, allowing
// modification of the dragging operation or mouse-pointer position. Returns one
// (and only one) of the dragging operation constants described in NSDragOperation
// in the NSDraggingInfo reference. The default return value (if this method is not
// implemented by the destination) is the value returned by the previous draggingEntered:
// message. For this to be invoked, the destination must have registered for the
// pasteboard data type involved in the drag operation. The messages continue until
// the image is either released or dragged out of the window or view. This method
// provides the destination with an opportunity to modify the dragging operation
// depending on the position of the mouse pointer inside of the destination view
// or window object. For example, you may have several graphics or areas of text
// contained within the same view and wish to tailor the dragging operation, or
// to ignore the drag event completely, depending upon which object is underneath
// the mouse pointer at the time when the user releases the dragged image and the
// performDragOperation: method is invoked. You typically examine the contents of
// the pasteboard in the draggingEntered: method, where this examination is performed
// only once, rather than in the draggingUpdated: method, which is invoked multiple
// times. Only one destination at a time receives a sequence of draggingUpdated:
// messages. If the mouse pointer is within the bounds of two overlapping views
// that are both valid destinations, the uppermost view receives these messages
// until the image is either released or dragged out.
- (NSDragOperation)draggingUpdated:(TUIDraggingSession *)sender;

// Invoked when the dragged image exits the view's bounds rectangle.
- (void)draggingExited:(TUIDraggingSession *)sender;

// Implement this method to be notified when a drag operation ends in some other
// destination. This method might be used by a destination doing auto-expansion
// in order to collapse any auto-expands.
- (void)draggingEnded:(TUIDraggingSession *)sender;

// Invoked when the image is released, allowing the receiver to agree to or
// refuse drag operation. Returns YES if the receiver agrees to perform the drag
// operation and NO if not. This method is invoked only if the most recent
// draggingEntered: or draggingUpdated: message returned an acceptable drag-operation
// value. If you want the drag items to animate from their current location on
// screen to their final location in your view, set the sender object’s
// animatesToDestination property to YES in your implementation of this method.
- (BOOL)prepareForDragOperation:(TUIDraggingSession *)sender;

// Invoked after the released image has been removed from the screen, signaling the
// receiver to import the pasteboard data. If the destination accepts the data,
// it returns YES; otherwise it returns NO. The default is to return NO. For
// this method to be invoked, the previous prepareForDragOperation: message must
// have returned YES. The destination should implement this method to do the real
// work of importing the pasteboard data represented by the image. If the sender
// object’s animatesToDestination was set to YES in prepareForDragOperation:,
// then setup any animation to arrange space for the drag items to animate to.
- (BOOL)performDragOperation:(TUIDraggingSession *)sender;

// Invoked when the dragging operation is complete, signaling the view to perform
// any necessary clean-up. For this method to be invoked, the previous
// performDragOperation: must have returned YES. The destination implements this method
// to perform any tidying up that it needs to do, such as updating its visual
// representation now that it has incorporated the dragged data. This message is the
// last message sent from sender to the destination during a dragging session. If the
// sender object’s animatesToDestination property was set to YES in
// prepareForDragOperation:, then the drag image is still visible. At this point you
// should draw the final visual representation in the view. When this method returns,
// the drag image is removed form the screen. If your final visual representation
// matches the visual representation in the drag, this is a seamless transition.
- (void)concludeDragOperation:(TUIDraggingSession *)sender;

// The destination should return NO if it does not require periodic
// -draggingUpdated messages (eg. not autoscrolling or otherwise
// dependent on draggingUpdated: sent while mouse is stationary.
- (BOOL)wantsPeriodicDraggingUpdates;

// While a destination may change the dragging images at any time, it is
// recommended to wait until this method is called before updating the
// dragging image. This allows the system to delay changing the dragging
// images until it is likely that the user will drop on this destination.
// Otherwise, the dragging images will change too often during the drag
// which would be distracting to the user. The destination may update the
// dragging images by calling one of the -enumerateDraggingItems methods.
- (void)updateDraggingItemsForDrag:(TUIDraggingSession *)sender;

@end
