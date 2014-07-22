//
//  TUIView+PasteboardDragging_Private.h
//  Pods
//
//  Created by Sergey Lem on 7/22/14.
//
//

#import "TUIView.h"

@interface TUIView (PasteboardDragging_Private) <NSPasteboardItemDataProvider, NSDraggingSource>

- (void)__beginPasteboardDraggingAsASourceWithEvent:(NSEvent *)event;

@end
