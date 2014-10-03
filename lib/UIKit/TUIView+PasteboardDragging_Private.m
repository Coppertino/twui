//
//  TUIView+PasteboardDragging_Private.m
//  Pods
//
//  Created by Sergey Lem on 7/22/14.
//
//

#import "TUIView+PasteboardDragging_Private.h"
#import "TUINSView.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation TUIView (PasteboardDragging_Private)

#pragma mark - Dragging Source

- (void)__beginPasteboardDraggingAsASourceWithEvent:(NSEvent *)event {
    CGPoint location = [event locationInWindow];
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingPasteboardPromisedFileTypesForView:)]) {
        [self.nsView dragPromisedFilesOfTypes:[self.draggingSourceDelegate tui_draggingPasteboardPromisedFileTypesForView:self]
                                     fromRect:NSMakeRect(location.x, location.y, 32, 32) source:self slideBack:YES event:event];
    }
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:sourceOperationMaskForDraggingContext:forView:)]) {
        return [self.draggingSourceDelegate tui_draggingSession:session sourceOperationMaskForDraggingContext:context forView:self];
    }
    return NSDragOperationNone;
}

- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination {
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_namesOfPromisedFilesDroppedAtDestination:forView:)]) {
        return [self.draggingSourceDelegate tui_namesOfPromisedFilesDroppedAtDestination:dropDestination forView:self];
    }
    return nil;
}

// Optional proxy methods

- (void)draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint {
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:willBeginAtPoint:forView:)]) {
        [self.draggingSourceDelegate tui_draggingSession:session willBeginAtPoint:screenPoint forView:self];
    }
}

- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint {
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:movedToPoint:forView:)]) {
        [self.draggingSourceDelegate tui_draggingSession:session movedToPoint:screenPoint forView:self];
    }
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:endedAtPoint:operation:forView:)]) {
        [self.draggingSourceDelegate tui_draggingSession:session endedAtPoint:screenPoint operation:operation forView:self];
    }
}

@end
#pragma clang diagnostic pop
