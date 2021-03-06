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

#import "TUIScrollView.h"

extern NSUInteger const TUIExtendSelectionKey;
extern NSUInteger const TUIAddSelectionKey;

typedef NS_ENUM(NSUInteger, TUITableViewStyle) {
	TUITableViewStylePlain,              // regular table view
	TUITableViewStyleGrouped, // grouped table view—headers stick to the top of the table view and scroll with it
};

typedef NS_ENUM(NSUInteger, TUITableViewScrollPosition) {
	TUITableViewScrollPositionNone,        
	TUITableViewScrollPositionTop,    
	TUITableViewScrollPositionMiddle,   
	TUITableViewScrollPositionBottom,
	TUITableViewScrollPositionToVisible, // currently the only supported arg
};

typedef NS_ENUM(NSInteger, TUITableViewInsertionMethod) {
  TUITableViewInsertionMethodBeforeIndex  = NSOrderedAscending,
  TUITableViewInsertionMethodAtIndex      = NSOrderedSame,
  TUITableViewInsertionMethodAfterIndex   = NSOrderedDescending
};

typedef NS_ENUM(NSInteger, TUITableViewDropDestination) {
    TUITableViewDropNone = 0,
    TUITableViewDropAfter = 1,
    TUITableViewDropBefore = 2,
    TUITableViewDropOn = 3
};

@class TUITableViewCell;
@protocol TUITableViewDataSource;

@class TUITableView;

@protocol TUITableViewDelegate<NSObject, TUIScrollViewDelegate>

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (void)tableView:(TUITableView *)tableView willDisplayCell:(TUITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath; // called after the cell's frame has been set but before it's added as a subview
- (void)tableView:(TUITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath; // happens on left/right mouse down, key up/down
- (void)tableView:(TUITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event; // happens on left/right mouse up (can look at clickCount)
- (BOOL)tableView:(TUITableView *)tableView performKeyActionWithEvent:(NSEvent *)event;

- (BOOL)tableView:(TUITableView*)tableView shouldSelectRowAtIndexPath:(NSIndexPath*)indexPath forEvent:(NSEvent*)event; // YES, if not implemented
- (NSMenu *)tableView:(TUITableView *)tableView menuForRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event;

// the following are good places to update or restore state (such as selection) when the table data reloads
- (void)tableViewWillReloadData:(TUITableView *)tableView;
- (void)tableViewDidReloadData:(TUITableView *)tableView;

// the following is optional for row reordering
- (NSIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromPath toProposedIndexPath:(NSIndexPath *)proposedPath;

@end

@interface TUITableView : TUIScrollView
{
	TUITableViewStyle             _style;
	__unsafe_unretained id <TUITableViewDataSource>	_dataSource; // weak
	NSArray                     * _sectionInfo;
	
	TUIView                     * _pullDownView;
	
	CGSize                        _lastSize;
	CGFloat                       _contentHeight;
	
	NSMutableIndexSet           * _visibleSectionHeaders;
	NSMutableDictionary         * _visibleItems;
	NSMutableDictionary         * _reusableTableCells;
	TUIView                     * _multiDragableView;
    
    // additions for multipleSelections
    NSIndexPath                 *_indexPathForLastSelectedRow;
    NSMutableArray              * _arrayOfSelectedIndexes;
    BOOL                        _multipleSelectionKeyIsPressed;
    BOOL                        _extendMultipleSelectionKeyIsPressed;
//    NSUInteger                  _iterationCount;
    
	NSIndexPath            * _baseSelectionPath;
	NSIndexPath            * _indexPathShouldBeFirstResponder;
	NSInteger                     _futureMakeFirstResponderToken;
	NSIndexPath            * _keepVisibleIndexPathForReload;
	CGFloat                       _relativeOffsetForReload;
	
    // New drag properties
    NSMutableArray      *_draggedViews;
    TUIView             *_draggingSeparatorView;
    NSIndexPath         *_indexPathToInsert;
  
    // External Drag
    NSDraggingSession   *_draggingSession;
    
	struct {
		unsigned int animateSelectionChanges:1;
		unsigned int forceSaveScrollPosition:1;
		unsigned int derepeaterEnabled:1;
		unsigned int layoutSubviewsReentrancyGuard:1;
		unsigned int didFirstLayout:1;
		unsigned int dataSourceNumberOfSectionsInTableView:1;
		unsigned int delegateTableViewWillDisplayCellForRowAtIndexPath:1;
		unsigned int maintainContentOffsetAfterReload:1;
	} _tableFlags;
	
}

- (id)initWithFrame:(CGRect)frame style:(TUITableViewStyle)style;                // must specify style at creation. -initWithFrame: calls this with UITableViewStylePlain

@property (nonatomic,unsafe_unretained) id <TUITableViewDataSource>  dataSource;
@property (nonatomic,unsafe_unretained) id <TUITableViewDelegate>    delegate;

@property (readwrite, assign) BOOL animateSelectionChanges;
@property (readwrite, assign) BOOL allowsMultipleSelection;
@property (nonatomic, assign) BOOL maintainContentOffsetAfterReload;
// Pressing up at the very first cell will select the last one and otherwise
@property (nonatomic, assign) BOOL smartIncrementalSelection;

- (void)clearData;
- (void)reloadData;

/**
 The table view itself has mechanisms for maintaining scroll position. During a live resize the table view should automatically "do the right thing".  This method may be useful during a reload if you want to stay in the same spot.  Use it instead of -reloadData.
 */
- (void)reloadDataMaintainingVisibleIndexPath:(NSIndexPath *)indexPath relativeOffset:(CGFloat)relativeOffset;

// Forces a re-calculation and re-layout of the table. This is most useful for animating the relayout. It is potentially _more_ expensive than -reloadData since it has to allow for animating.
- (void)reloadLayout;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGRect)rectForHeaderOfSection:(NSInteger)section;
- (CGRect)rectForSection:(NSInteger)section;
- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexSet *)indexesOfSectionsInRect:(CGRect)rect;
- (NSIndexSet *)indexesOfSectionHeadersInRect:(CGRect)rect;
- (NSIndexPath *)indexPathForCell:(TUITableViewCell *)cell;                      // returns nil if cell is not visible
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;                                    // returns nil if rect not valid
- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForRowAtVerticalOffset:(CGFloat)offset;
- (NSInteger)indexOfSectionWithHeaderAtPoint:(CGPoint)point;
- (NSInteger)indexOfSectionWithHeaderAtVerticalOffset:(CGFloat)offset;

- (void)enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;
- (void)enumerateIndexPathsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;
- (void)enumerateIndexPathsFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath withOptions:(NSEnumerationOptions)options usingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;

- (TUIView *)headerViewForSection:(NSInteger)section;
- (TUITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;            // returns nil if cell is not visible or index path is out of range
- (NSArray *)visibleCells; // no particular order
- (NSArray *)sortedVisibleCells; // top to bottom
- (NSArray *)indexPathsForVisibleRows;

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(TUITableViewScrollPosition)scrollPosition animated:(BOOL)animated;

@property (weak, nonatomic, readonly) NSIndexPath *indexPathForSelectedRow;
@property (strong, nonatomic, readonly) NSArray *indexPathesForSelectedRows;

- (NSIndexPath *)indexPathForFirstRow;
- (NSIndexPath *)indexPathForLastRow;

- (void)selectAll:(id)sender;
- (void)deselectAll:(id)sender;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(TUITableViewScrollPosition)scrollPosition;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

/**
 Above the top cell, only visible if you pull down (if you have scroll bouncing enabled)
 */
@property (nonatomic, strong) TUIView *pullDownView;

- (BOOL)pullDownViewIsVisible;

@property (nonatomic, strong) TUIView *headerView;
@property (nonatomic, strong) TUIView *footerView;

/**
 Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.
 */
- (TUITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

// Drag proxy

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender;
- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender;

@end

@protocol TUITableViewDataSource<NSObject>

@required

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section;

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section;

// the following are required to support row reordering
- (BOOL)tableView:(TUITableView *)tableView canMoveRows:(NSArray *)arrayOfIdexes atIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TUITableView *)tableView moveRows:(NSArray*)arrayOfIdexes toIndexPath:(NSIndexPath *)toIndexPath;

/**
 Default is 1 if not implemented
 */
- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView;

// Pasteboard destination support

- (NSDragOperation)tableView:(TUITableView *)tableView validateDrop:(id<NSDraggingInfo>)info indexPath:(NSIndexPath *)indexPath destination:(TUITableViewDropDestination)destination;
- (BOOL)tableView:(TUITableView *)tableView acceptDrop:(id<NSDraggingInfo>)info indexPath:(NSIndexPath *)indexPath dragDestination:(TUITableViewDropDestination)destination;

// Pasteboard source support

- (void)tableView:(TUITableView *)tableView pasteboard:(NSPasteboard *)pasteboard writeDataForRowsIndexPaths:(NSArray *)rows;

@end

@interface NSIndexPath (TUITableView)

+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section;

@property(nonatomic,readonly) NSUInteger section;
@property(nonatomic,readonly) NSUInteger row;

@end

#import "TUITableViewCell.h"
#import "TUITableView+Derepeater.h"
