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

#import "TUITableViewMultiselection+Cell.h"
#import "TUICGAdditions.h"
#import "TUINSView.h"

// Dragged cells should be just above pinned headers
#define kTUITableViewDraggedCellZPosition 1001
#define kTUITableViewDraggedCellCascadeOffset 3
#define kTUITableViewSeparatorHeight 2

@interface TUITableView (CellPrivate)

- (BOOL)_preLayoutCells;
- (void)_layoutSectionHeaders:(BOOL)needLayout;
- (void)_layoutCells:(BOOL)needLayout;
- (void)addSelectedIndexPath:(NSIndexPath*)indexPathToAdd;
- (void)checkEventModifiers:(NSEvent *)event;

@end

@implementation TUITableView (MultiCell)

/**
 * @brief Mouse down in a cell
 */
-(void)__mouseDownInMultipleCells:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
    [self __beginDraggingMultipleCells:cell offset:offset location:[self localPointForEvent:event]];
}

/**
 * @brief Mouse up in a cell
 */
-(void)__mouseUpInMultipleCells:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
    NSIndexPath *indexPathToSelect = _indexPathToInsert;
    [self __endDraggingMultipleCells:cell offset:offset location:[self localPointForEvent:event]];
    if (!indexPathToSelect) {
        [self selectRowAtIndexPath:cell.indexPath animated:NO scrollPosition:TUITableViewScrollPositionNone];
    }
}

/**
 * @brief A cell was dragged
 *
 * If reordering is permitted by the table, this will begin a move operation.
 */
-(void)__mouseDraggedMultipleCells:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
    [self __updateDraggingMultipleCells:cell offset:offset location:[self localPointForEvent:event]];
}

/**
 * @brief Determine if we're dragging a cell or not
 */
-(BOOL)__isDraggingMultipleCells {
    return _indexPathToInsert != nil;
}

/**
 * @brief Begin dragging a cell
 */
-(void)__beginDraggingMultipleCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
    _draggedViews = [[NSMutableArray alloc] initWithCapacity:_arrayOfSelectedIndexes.count];
    
    float extendX = 0;
    float extendY = 0;
    
    for (NSIndexPath *aDisplacedIndexPath in _arrayOfSelectedIndexes)
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
-(void)__updateDraggingMultipleCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
    BOOL animate = TRUE;
    
    // return if there wasn't a proper drag
    if(![cell didDrag]) return;
    
    CGPoint pointInView = location;
    pointInView.y -= self.contentOffset.y;
    
    // determine if reordering this cell is permitted or not via our data source (this should probably be done only once somewhere)
    if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)]){
        return;
    }
    
    BOOL allowInnerDrag = [self.dataSource tableView:self
                               canMoveRowAtIndexPath:_indexPathToInsert];
    BOOL allowExternalDrag = NO;
    if (self.draggingSourceDelegate && [self.draggingSourceDelegate respondsToSelector:@selector(tableView:canMoveOutOfTableIndexPaths:)]) {
        allowExternalDrag = [self.draggingSourceDelegate tableView:self
                                       canMoveOutOfTableIndexPaths:_arrayOfSelectedIndexes];
    }
    
    if (!NSPointInRect(location, self.frame) && allowExternalDrag) {
        
        NSMutableArray *cells = [NSMutableArray array];
        for (NSIndexPath *idx in _arrayOfSelectedIndexes) {
            TUITableViewCell *cell = [self cellForRowAtIndexPath:idx];
            [cells addObject:cell];
        }
        
        NSMutableArray *dragItems = [NSMutableArray array];
        for (TUIView *view in _draggedViews) {
            NSPasteboardItem *item = [[NSPasteboardItem alloc] init];
            NSDraggingItem *dragItem = [[NSDraggingItem alloc] initWithPasteboardWriter:item];
            if ([self.draggingSourceDelegate respondsToSelector:@selector(tui_configureViewForDraggingItem:inLocation:withCellImageRep:)]) {
                [self.draggingSourceDelegate tableView:self
                                 configureDraggingItem:dragItem
                                            inLocation:location
                                      withCellImageRep:view.layer.contents
                                               andCell:[cells objectAtIndex:[_draggedViews indexOfObject:view]]];
            } else {
                [dragItem setDraggingFrame:NSMakeRect(location.x, location.y, view.frame.size.width/2, view.frame.size.height/2)
                                  contents:view.layer.contents];
            }
            [dragItems addObject:dragItem];
        }
        
        _draggingSession = [self.nsView beginDraggingSessionWithItems:[dragItems copy]
                                                                event:[NSApp currentEvent]
                                                               source:self.draggingSourceDelegate];
        NSPasteboard *pboard = _draggingSession.draggingPasteboard;
        
        [self.draggingSourceDelegate tableView:self
                   writeContentsIntoPasteBoard:pboard
                               forDraggedCells:cells];
        
        [_draggedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        [_draggedViews removeAllObjects];
        
        _indexPathToInsert = nil;
        [self _removeDraggingPointer];
        return;
    }
    
    
    
    CGRect visible = [self visibleRect];
    
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
    
    NSIndexPath *indexPathUnderMousePointer = [self indexPathForRowAtPoint:pointInView];
    TUITableViewCell *cellUnderThePointer = [self cellForRowAtIndexPath:indexPathUnderMousePointer];
    CGFloat yInCell = [cellUnderThePointer convertPoint:pointInView fromView:self].y;
    CGFloat cellHeight = cellUnderThePointer.frame.size.height;
    if (yInCell < cellHeight/2) {
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
-(void)__endDraggingMultipleCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
    BOOL animate = TRUE;
    
    // cancel our continuous scroll
    [self endContinuousScrollAnimated:TRUE];
    
    [_draggedViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_draggedViews removeAllObjects];
    
    // make sure reordering is supported by our data source (this should probably be done only once somewhere)
    if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:moveRows:toIndexPath:)]){
        _indexPathToInsert = nil;
        return; // reordering is not supported by the data source
    }
    
    if (_indexPathToInsert &&
        ![_indexPathToInsert isEqual:[cell indexPath]] &&
        ![_arrayOfSelectedIndexes containsObject:_indexPathToInsert]) {
        if(self.dataSource != nil && [self.dataSource respondsToSelector:@selector(tableView:moveRows:toIndexPath:)]){
            [self.dataSource tableView:self moveRows:_arrayOfSelectedIndexes toIndexPath:_indexPathToInsert];
            [self reloadData];
        }
    }
    
    _indexPathToInsert = nil;
    [self _removeDraggingPointer];
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

@end

