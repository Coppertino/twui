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

#import "TUINSView.h"

@interface TUINSView ()

@property (nonatomic, strong) TUIDraggingSession *currentSourceDraggingSession;
@property (nonatomic, strong) NSURL *currentPromisedDragDestination;
@property (nonatomic, strong) TUIView *currentDraggingView;

@property (nonatomic, strong) TUIView *trackingView;

// The layer-backed view which actually holds the AppKit hierarchy.
@property (nonatomic, readonly, strong) NSView *appKitHostView;

/*
 * Informs the receiver that the clipping of a TUIViewNSViewContainer it is hosting has
 * changed, and asks it to update clipping paths accordingly.
 */
- (void)recalculateNSViewClipping;

// Informs the receiver that the ordering of a TUIViewNSViewContainer it is hosting has
// changed, and asks it to reorder its subviews to match TwUI.
- (void)recalculateNSViewOrdering;

- (TUIView *)viewForLocalPoint:(NSPoint)p;
- (NSPoint)localPointForLocationInWindow:(NSPoint)locationInWindow;

@end

@interface TUINSView (PasteboardDragging_Private)

- (void)beginDraggingSession:(TUIDraggingSession *)session event:(NSEvent *)event source:(id<TUIDraggingSource>)source;

@end
