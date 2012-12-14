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

#import "TUIView+PasteboardDragging.h"

@interface TUIDraggingManager : NSWindowController

+ (id)sharedDraggingManager;

- (void)startDragFromSourceScreenRect:(NSRect)aScreenRect
					  startingAtPoint:(NSPoint)aStartPoint
							   offset:(NSSize)anOffset
						  insideImage:(NSImage *)insideImage
						 outsideImage:(NSImage *)outsideImage
							slideBack:(BOOL)slideBackFlag;

- (void)updatePosition;
- (void)endDragWithResult:(NSDragOperation)dragOperation;

- (void)_centerWindowOverPoint:(NSPoint)point
					withOffset:(NSSize)offset
					   animate:(BOOL)animate;
- (void)_orderOutAndCleanUp;

@end
