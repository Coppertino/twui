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

#import "TUITableView+Dragging.h"
#import "TUICGAdditions.h"
#import "TUINSView.h"
#import "TUIView+PasteboardDragging_Private.h"

// Dragged cells should be just above pinned headers
#define kTUITableViewDraggedCellZPosition 1001
#define kTUITableViewDraggedCellCascadeOffset 3
#define kTUITableViewSeparatorHeight 2

@interface TUITableView (CellPrivate)

- (BOOL)_preLayoutCells;
- (void)_layoutSectionHeaders:(BOOL)needLayout;
- (void)_layoutCells:(BOOL)needLayout;
- (void)checkEventModifiers:(NSEvent *)event;

- (void)_clearIndexPaths;
- (void)_addSelectedIndexPath:(NSIndexPath*)indexPathToAdd animated:(BOOL)shouldAnimate;

@end

@implementation TUITableView (MultiCell)

/**
 * @brief Mouse down in a cell
 */
-(void)__mouseDownInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
    [self __beginDraggingCells:cell offset:offset location:[self localPointForEvent:event]];
}

/**
 * @brief Mouse up in a cell
 */
-(void)__mouseUpInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
    NSIndexPath *indexPathToSelect = _indexPathToInsert;
    [self __endDraggingCells:cell offset:offset location:[self localPointForEvent:event]];
}

/**
 * @brief A cell was dragged
 *
 * If reordering is permitted by the table, this will begin a move operation.
 */
-(void)__mouseDraggedCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
    [self __updateDraggingCells:cell offset:offset location:[self localPointForEvent:event]];
}

/**
 * @brief Determine if we're dragging a cell or not
 */
-(BOOL)__isDraggingCells {
    return _indexPathToInsert != nil;
}

/**
 * @brief Begin dragging a cell
 */
-(void)__beginDraggingCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
    [self _generateDraggingViewsFromCell:cell atLocation:location];
}

- (void)_generateDraggingViewsFromCell:(TUITableViewCell *)cell atLocation:(CGPoint)location {
    if (_draggedViews && _draggedViews.count > 0) {
        [_draggedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_draggedViews removeAllObjects];
    }
    _draggedViews = [[NSMutableArray alloc] initWithCapacity:self.indexPathesForSelectedRows.count];
    
    float extendX = 0;
    float extendY = 0;
    for (NSIndexPath *aDisplacedIndexPath in self.indexPathesForSelectedRows)
    {
        TUITableViewCell *displacedCell = [self cellForRowAtIndexPath:aDisplacedIndexPath];
        
        NSImage *image = TUIGraphicsGetImageForView(displacedCell);
        
        CGRect visible = cell.frame;
        // dragged cell destination frame
        CGRect dest = CGRectMake(extendX,
                                 [self convertPoint:location fromView:self.superview].y - 5 + extendY,
                                 self.bounds.size.width,
                                 cell.frame.size.height);
        // bring to front
        //        [[displacedCell superview] bringSubviewToFront:displacedCell];
        // move the cell
        //displacedCell.frame = dest;
        
        TUIView *view = [[TUIView alloc] initWithFrame:dest];
        [view.layer setContents:image];
        [view.layer setOpacity:0.5];
        [_draggedViews addObject:view];
        
        extendX += kTUITableViewDraggedCellCascadeOffset;
        extendY += kTUITableViewDraggedCellCascadeOffset;
        
        if (extendX > kTUITableViewDraggedCellCascadeOffset * 5) {
            extendX=0;
            extendY=0;
        }
    }

}

/**
 * @brief Update cell dragging
 */
- (void)__updateDraggingCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
    BOOL animate = YES;
    
    NSIndexPath *ip = [self indexPathForRowAtPoint:location];
    if (![self.indexPathesForSelectedRows containsObject:ip] && ![self __isDraggingCells] && [self eventInside:[NSApp currentEvent]]) {
        [self _clearIndexPaths];
        [self selectRowAtIndexPath:cell.indexPath animated:NO scrollPosition:TUITableViewScrollPositionNone];
        [self _generateDraggingViewsFromCell:cell atLocation:location];
    }
    
    // return if there wasn't a proper drag
//    if(![cell didDrag]) return;
    
    if (!NSPointInRect(location, self.frame) && [self canActAsDraggingSource]) {
        [self __beginPasteboardDraggingAsASourceWithEvent:[NSApp currentEvent]];
        [_draggedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        _draggedViews = nil;
        _indexPathToInsert = nil;
        
        return;
    }
    
    // determine if reordering this cell is permitted or not via our data source (this should probably be done only once somewhere)
    if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:canMoveRows:atIndexPath:)]){
        return;
    }
    
    
    BOOL allowInnerDrag = [self.dataSource tableView:self
                                         canMoveRows:self.indexPathesForSelectedRows
                                         atIndexPath:_indexPathToInsert];
    
    CGRect visible = [self visibleRect];
    
    CGPoint pointInView = location;
    pointInView.y -= self.contentOffset.y;
    
    [TUIView animateWithDuration:0.05
                      animations:^{
                          float extendX = 0;
                          float extendY = 0;
                          
                          for (TUIView *view in _draggedViews) {
                              // dragged cell destination frame
                              
                              CGRect dest = CGRectMake(extendX,
                                                       pointInView.y - 5 + extendY,
                                                       self.bounds.size.width,
                                                       cell.frame.size.height);
                              [view setFrame:dest];
                              extendX += kTUITableViewDraggedCellCascadeOffset;
                              extendY += kTUITableViewDraggedCellCascadeOffset;
                              if (extendX > kTUITableViewDraggedCellCascadeOffset * 5) {
                                  extendX=0;
                                  extendY=0;
                              }
                          }
                    }];
    
    [_draggedViews enumerateObjectsWithOptions:NSEnumerationReverse
                                    usingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                                        [self addSubview:obj];
                                    }];

    if (!allowInnerDrag) {
        return;
    }
    
    CGPoint point = location;
    NSIndexPath *indexPathUnderMousePointer = [self indexPathForRowAtPoint:point];
    TUITableViewCell *cellUnderThePointer = [self cellForRowAtIndexPath:[self indexPathForRowAtPoint:point]];
    
    CGFloat relativeOffset = [cell convertFromWindowPoint:location].y / cellUnderThePointer.bounds.size.height;
    
    CGFloat yInCell = [cellUnderThePointer convertFromWindowPoint:location].y;
    CGFloat cellHeight = cellUnderThePointer.frame.size.height;
    if (relativeOffset < 0.5) {
        [self _moveDraggingPointerAfterIndexPath:indexPathUnderMousePointer];
    } else {
        [self _moveDraggingPointerBeforeIndexPath:indexPathUnderMousePointer];
    }
    // constraint the location to the viewport
    location = CGPointMake(location.x, MAX(0, MIN(visible.size.height, location.y)));
    // scroll content if necessary (scroll view figures out whether it's necessary or not)
    [self beginContinuousScrollForDragAtPoint:location animated:TRUE];
}

/**
 * @brief Finish dragging a cell
 */
-(void)__endDraggingCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
    BOOL animate = TRUE;
    
    if (_draggedViews && _draggedViews.count > 0) {
        [_draggedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_draggedViews removeAllObjects];
    }
    
    // cancel our continuous scroll
    [self endContinuousScrollAnimated:TRUE];
    
    // make sure reordering is supported by our data source (this should probably be done only once somewhere)
    if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:moveRows:toIndexPath:)]){
        [self _removeDraggingPointer];
        _indexPathToInsert = nil;
        return; // reordering is not supported by the data source
    }
    
    if (_indexPathToInsert &&
        ![_indexPathToInsert isEqual:[cell indexPath]] &&
        ![self.indexPathesForSelectedRows containsObject:_indexPathToInsert]) {
        if(self.dataSource != nil && [self.dataSource respondsToSelector:@selector(tableView:moveRows:toIndexPath:)]){
            [self.dataSource tableView:self moveRows:self.indexPathesForSelectedRows toIndexPath:_indexPathToInsert];
            [self reloadData];
            
            NSInteger dropSection = _indexPathToInsert.section;
            NSInteger dropRow = _indexPathToInsert.row;
            
            NSInteger correctedDropSection = dropSection;
            __block NSInteger correctedDropRow = dropRow;

            [self.indexPathesForSelectedRows enumerateObjectsUsingBlock:^(NSIndexPath *idxPath, NSUInteger idx, BOOL *stop) {
                if (idxPath.section <= dropSection && idxPath.row <= dropRow) {
                    correctedDropRow--;
                }
            }];
            NSInteger count = self.indexPathesForSelectedRows.count;
            [self _clearIndexPaths];
            for (NSInteger i = 0; i < count; i++) {
                [self _addSelectedIndexPath:[NSIndexPath indexPathForRow:correctedDropRow+i inSection:correctedDropSection] animated:NO];
            }
        }
    }
    
    [self _removeDraggingPointer];
    _indexPathToInsert = nil;
}

- (void)_moveDraggingPointerAfterIndexPath:(NSIndexPath *)indexPath {
    CGFloat edgeCellError = 0;
    if ([indexPath isEqual:[self indexPathForLastRow]]) {
        edgeCellError = kTUITableViewSeparatorHeight/2;
        _indexPathToInsert = indexPath;
    } else {
        _indexPathToInsert = [NSIndexPath indexPathForRow:indexPath.row+1
                                                   inSection:indexPath.section];
    }
    TUITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    [self _drawSeparatorWithFrame:NSMakeRect(cell.frame.origin.x,
                                             cell.frame.origin.y - 1 + edgeCellError,
                                             cell.frame.size.width,
                                             kTUITableViewSeparatorHeight)];
}

- (void)_moveDraggingPointerBeforeIndexPath:(NSIndexPath *)indexPath {
    _indexPathToInsert = indexPath;
    CGFloat edgeCellError = 0;
    if ([indexPath isEqual:[self indexPathForFirstRow]]) {
        edgeCellError = -kTUITableViewSeparatorHeight/2;
    }
    TUITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
    [self _drawSeparatorWithFrame:NSMakeRect(cell.frame.origin.x,
                                             cell.frame.origin.y + cell.frame.size.height - 1 + edgeCellError,
                                             cell.frame.size.width,
                                             kTUITableViewSeparatorHeight)];
}

- (void)_removeDraggingPointer {
    [_draggingSeparatorView removeFromSuperview];
    _draggingSeparatorView = nil;
}


- (void)_drawSeparatorWithFrame:(CGRect)frame {
    [self _removeDraggingPointer];
    _draggingSeparatorView = [[TUIView alloc] init];
    [_draggingSeparatorView.layer setZPosition:kTUITableViewDraggedCellZPosition+1];
    [_draggingSeparatorView setFrame:frame];
    [self drawDraggingPointerInView:_draggingSeparatorView];
    [self addSubview:_draggingSeparatorView];
}
- (void)drawDraggingPointerInView:(TUIView *)view {
    [view setBackgroundColor:[NSColor whiteColor]];
}

// Overriding pasteboard dragging for TUITableView

- (void)__beginPasteboardDraggingAsASourceWithEvent:(NSEvent *)event {
    CGPoint location = [event locationInWindow];

    NSMutableArray *draggingItems = [NSMutableArray arrayWithCapacity:self.indexPathesForSelectedRows.count];
    [self.indexPathesForSelectedRows enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSPasteboardItem *pbItem = [[NSPasteboardItem alloc] init];
        [pbItem setDataProvider:self forTypes:nil];
        NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:pbItem];
        
        if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_configureDraggingItem:forView:)]) {
            [self.draggingSourceDelegate tui_configureDraggingItem:dragItem forView:self];
            [dragItem setDraggingFrame:NSMakeRect(location.x, location.y,
                                                  32, 32)];
        } else {
            [dragItem setDraggingFrame:NSMakeRect(location.x, location.y,
                                                  32, 32)
                              contents:nil];
        }
        [draggingItems addObject:dragItem];
    }];
    
    _draggingSession = [self.nsView beginDraggingSessionWithItems:draggingItems event:event source:self];
    _draggingSession.animatesToStartingPositionsOnCancelOrFail = YES;
    
    if ([self.dataSource respondsToSelector:@selector(tableView:pasteboard:writeDataForRowsIndexPaths:)]) {
        [self.dataSource tableView:self pasteboard:_draggingSession.draggingPasteboard writeDataForRowsIndexPaths:self.indexPathesForSelectedRows];
    }
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context {
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:sourceOperationMaskForDraggingContext:forView:)]) {
        return [self.draggingSourceDelegate tui_draggingSession:session sourceOperationMaskForDraggingContext:context forView:self];
    }
    return NSDragOperationNone;
}

- (void)draggingSession:(NSDraggingSession *)session movedToPoint:(NSPoint)screenPoint {
    NSPoint p = [self convertFromWindowPoint:[(NSWindow *)self.nsWindow convertScreenToBase:screenPoint]];
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:movedToPoint:forView:)]) {
        [self.draggingSourceDelegate tui_draggingSession:session movedToPoint:screenPoint forView:self];
    }
}

- (void)draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation {
    NSPoint p = [self convertFromWindowPoint:[(NSWindow *)self.nsWindow convertScreenToBase:screenPoint]];
    if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_draggingSession:endedAtPoint:operation:forView:)]) {
        [self.draggingSourceDelegate tui_draggingSession:session endedAtPoint:screenPoint operation:operation forView:self];
    }
    [self _removeDraggingPointer];
}

@end

