//
//  TUINSView+Private.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import "TUINSView.h"

// Private functionality of TUINSView that needs to be exposed to other parts of
// the framework.
@interface TUINSView ()

// The layer-backed view which actually holds the AppKit hierarchy.
@property (nonatomic, readonly, strong) NSView *appKitHostView;

// The view that has decided to initiate a promised file drag.
@property (nonatomic, strong) TUIDraggingSession *currentSourceDraggingSession;

// The view who is currently targeted to recieve NSDragDestination method calls.
@property (nonatomic, strong) TUIView *currentDraggingView;

@property (nonatomic, strong) TUIView *trackingView;

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

- (void)beginDraggingSession:(TUIDraggingSession *)session event:(NSEvent *)event source:(id<TUIDraggingSource>)source;

@end
