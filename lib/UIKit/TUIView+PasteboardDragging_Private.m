//
//  TUIView+PasteboardDragging_Private.m
//  Pods
//
//  Created by Sergey Lem on 7/22/14.
//
//

#import "TUIView+PasteboardDragging_Private.h"
#import "TUINSView.h"

@implementation TUIView (PasteboardDragging_Private)

#pragma mark - Dragging Source

- (void)__beginPasteboardDraggingAsASourceWithEvent:(NSEvent *)event {
    CGPoint location = [self localPointForEvent:event];
    NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] init];
    [pbItem setDataProvider:self forTypes:[self.draggingSourceDelegate tui_draggingPasteboardTypesForView:self]];
    NSDraggingItem *draggingItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_configureDraggingItem:forView:)]) {
        [self.draggingSourceDelegate tui_configureDraggingItem:draggingItem forView:self];
        [draggingItem setDraggingFrame:NSMakeRect(location.x, location.y,
                                                  self.frame.size.width/2, self.frame.size.height/2)];
    } else {
        [draggingItem setDraggingFrame:NSMakeRect(location.x, location.y,
                                                  self.frame.size.width/2, self.frame.size.height/2)
                              contents:self.layer.contents];
    }

    [self.nsView beginDraggingSessionWithItems:@[draggingItem] event:event source:self];
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type {
    [self.draggingSourceDelegate tui_pasteboard:pasteboard item:item provideDataForType:type forView:self];
}

// Proxy

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    return [self.draggingSourceDelegate tui_draggingSession:session sourceOperationMaskForDraggingContext:context forView:self];
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
