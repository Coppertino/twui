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

#import "TUITableView.h"

@interface TUITableView (Dragging)
/**
 Override this method for dragging pointer customization
 */

- (void)drawDraggingPointerInView:(TUIView *)view;
@end

/**
 * @brief Exposes some internal table view methods to cells (primarily for drag-to-reorder support)
 */
@interface TUITableView (MultiCell)

-(void)__mouseDownInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event;
-(void)__mouseUpInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event;
-(void)__mouseDraggedCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event;

-(BOOL)__isDraggingCells;
-(void)__beginDraggingCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location;
-(void)__updateDraggingCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location;
-(void)__endDraggingCells:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location;

// Dragging pointer

- (void)_removeDraggingPointer;
- (void)_moveDraggingPointerAfterIndexPath:(NSIndexPath *)indexPath;
- (void)_moveDraggingPointerBeforeIndexPath:(NSIndexPath *)indexPath;

@end

