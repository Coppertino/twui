//
//  TUICollectionView.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUICollectionView.h"
#import "TUICollectionViewData.h"
#import "TUICollectionViewCell.h"
#import "TUICollectionViewLayout.h"
#import "TUICollectionViewFlowLayout.h"
#import "TUICollectionViewItemKey.h"
#import "TUICollectionViewUpdateItem.h"

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface TUICollectionViewLayout ()

@property (nonatomic, unsafe_unretained) TUICollectionView *collectionView;

@end

@interface TUICollectionViewData ()

- (void)prepareToLoadData;

@end

@interface TUICollectionViewUpdateItem ()

- (NSIndexPath *)indexPath;
- (BOOL)isSectionOperation;

@end

@class TUICollectionViewExt;

@interface TUICollectionView () {
    TUICollectionViewLayout *_layout;
    TUIView *_backgroundView;
    NSMutableSet *_indexPathsForSelectedItems;
    NSMutableDictionary *_cellReuseQueues;
    NSMutableDictionary *_supplementaryViewReuseQueues;
    NSMutableSet *_indexPathsForHighlightedItems;
    int _reloadingSuspendedCount;
    TUICollectionReusableView *_firstResponderView;
    TUIView *_newContentView;
    int _firstResponderViewType;
    NSString *_firstResponderViewKind;
    NSIndexPath *_firstResponderIndexPath;
    NSIndexPath *_pendingSelectionIndexPath;
    NSMutableSet *_pendingDeselectionIndexPaths;
    CGRect _visibleBoundRects;
    CGRect _preRotationBounds;
    CGPoint _rotationBoundsOffset;
    int _rotationAnimationCount;
    int _updateCount;
    NSMutableArray *_insertItems;
    NSMutableArray *_deleteItems;
    NSMutableArray *_reloadItems;
    NSMutableArray *_moveItems;
    NSArray *_originalInsertItems;
    NSArray *_originalDeleteItems;
    NSEvent *_currentEvent;
    void (^_updateCompletionHandler)(BOOL);
    NSMutableDictionary *_cellClassDict;
    NSMutableDictionary *_supplementaryViewClassDict;
    struct {
        unsigned int delegateShouldHighlightItemAtIndexPath : 1;
        unsigned int delegateDidHighlightItemAtIndexPath : 1;
        unsigned int delegateDidUnhighlightItemAtIndexPath : 1;
        unsigned int delegateShouldSelectItemAtIndexPath : 1;
        unsigned int delegateShouldDeselectItemAtIndexPath : 1;
        unsigned int delegateDidSelectItemAtIndexPath : 1;
        unsigned int delegateDidDeselectItemAtIndexPath : 1;
        unsigned int delegateSupportsMenus : 1;
        unsigned int delegateDidEndDisplayingCell : 1;
        unsigned int delegateDidEndDisplayingSupplementaryView : 1;
        unsigned int dataSourceNumberOfSections : 1;
        unsigned int dataSourceViewForSupplementaryElement : 1;
        unsigned int reloadSkippedDuringSuspension : 1;
        unsigned int scheduledUpdateVisibleCells : 1;
        unsigned int scheduledUpdateVisibleCellLayoutAttributes : 1;
        unsigned int allowsSelection : 1;
        unsigned int allowsMultipleSelection : 1;
        unsigned int updating : 1;
        unsigned int fadeCellsForBoundsChange : 1;
        unsigned int updatingLayout : 1;
        unsigned int needsReload : 1;
        unsigned int reloading : 1;
        unsigned int skipLayoutDuringSnapshotting : 1;
        unsigned int layoutInvalidatedSinceLastCellUpdate : 1;
        unsigned int doneFirstLayout : 1;
    } _collectionViewFlags;
}

@property (nonatomic, strong) TUICollectionViewData *collectionViewData;
@property (nonatomic, strong) NSDictionary *currentUpdate;
@property (nonatomic, strong) NSMutableDictionary *allVisibleViewsDict;
@property (nonatomic, assign) CGRect visibleBoundRects;

@property (nonatomic, strong) NSDictionary *supplementaryViewsExternalObjects;
@property (nonatomic, strong) NSIndexPath *touchingIndexPath;

@end

@implementation TUICollectionView

@synthesize collectionViewLayout = _layout;

#pragma mark - NSObject

- (void)TUICollectionViewCommonSetup {
    self.allowsSelection = YES;
    _indexPathsForSelectedItems = [NSMutableSet new];
    _indexPathsForHighlightedItems = [NSMutableSet new];
    _cellReuseQueues = [NSMutableDictionary new];
    _supplementaryViewReuseQueues = [NSMutableDictionary new];
    _allVisibleViewsDict = [NSMutableDictionary new];
    _cellClassDict = [NSMutableDictionary new];
    _supplementaryViewClassDict = [NSMutableDictionary new];
}

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(TUICollectionViewLayout *)viewLayout {
    if ((self = [super initWithFrame:frame])) {
        [self TUICollectionViewCommonSetup];
		
        self.collectionViewLayout = viewLayout;
        _collectionViewData = [[TUICollectionViewData alloc] initWithCollectionView:self layout:viewLayout];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)inCoder {
    if ((self = [super initWithCoder:inCoder])) {
        [self TUICollectionViewCommonSetup];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ collection view layout: %@", [super description], self.collectionViewLayout];
}

#pragma mark - TUIView

- (void)layoutSubviews {
	[super layoutSubviews];
	
    // Adding alpha animation to make the relayouting smooth
    if (_collectionViewFlags.fadeCellsForBoundsChange) {
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25f;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        //[self.layer addAnimation:transition forKey:@"rotationAnimation"];
    }
	
    [_collectionViewData validateLayoutInRect:self.visibleRect];

    // update cells
    if (_collectionViewFlags.fadeCellsForBoundsChange) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
    }

    if(!_collectionViewFlags.updatingLayout)
        [self updateVisibleCellsNow:YES];

    if (_collectionViewFlags.fadeCellsForBoundsChange) {
        [CATransaction commit];
    }

    // do we need to update contentSize?
    CGSize contentSize = [_collectionViewData collectionViewContentRect].size;
    if (!CGSizeEqualToSize(self.contentSize, contentSize)) {
        self.contentSize = contentSize;

        // if contentSize is different, we need to re-evaluate layout, bounds (contentOffset) might changed
        [_collectionViewData validateLayoutInRect:self.visibleRect];
        [self updateVisibleCellsNow:YES];
    }
    
    if (_backgroundView) {
        _backgroundView.frame = (NSRect){.origin=self.contentOffset,.size=self.contentSize};
    }

    _collectionViewFlags.fadeCellsForBoundsChange = NO;
    _collectionViewFlags.doneFirstLayout = YES;
}

- (void)setFrame:(NSRect)frame {
    if (!NSEqualRects(frame, self.frame)) {
        if ([self.collectionViewLayout shouldInvalidateLayoutForBoundsChange:frame]) {
            [self invalidateLayout];
            _collectionViewFlags.fadeCellsForBoundsChange = YES;
        }
        [super setFrame:frame];
    }
}

#pragma mark - Public

- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier {
    NSParameterAssert(cellClass);
    NSParameterAssert(identifier);
    _cellClassDict[identifier] = cellClass;
}

- (void)registerClass:(Class)viewClass forSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier {
    NSParameterAssert(viewClass);
    NSParameterAssert(elementKind);
    NSParameterAssert(identifier);
	NSString *kindAndIdentifier = [NSString stringWithFormat:@"%@/%@", elementKind, identifier];
    _supplementaryViewClassDict[kindAndIdentifier] = viewClass;
}

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
    // de-queue cell (if available)
    NSMutableArray *reusableCells = _cellReuseQueues[identifier];
    TUICollectionViewCell *cell = [reusableCells lastObject];
    if (cell) {
        [reusableCells removeObjectAtIndex:[reusableCells count]-1];
    }else {
        Class cellClass = _cellClassDict[identifier];
		if (cellClass == nil) {
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Class not registered for identifier %@", identifier] userInfo:nil];
		}
		if (self.collectionViewLayout) {
			TUICollectionViewLayoutAttributes *attributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
			cell = [[cellClass alloc] initWithFrame:attributes.frame];
		} else {
			cell = [cellClass new];
		}
		
        TUICollectionViewLayout *viewLayout = [self collectionViewLayout];
        if ([viewLayout isKindOfClass:[TUICollectionViewFlowLayout class]]) {
            CGSize itemSize = ((TUICollectionViewFlowLayout *)viewLayout).itemSize;
            cell.bounds = CGRectMake(0, 0, itemSize.width, itemSize.height);
        }
        cell.collectionView = self;
        cell.reuseIdentifier = identifier;
    }
    return cell;
}

- (id)dequeueReusableSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath {
	NSString *kindAndIdentifier = [NSString stringWithFormat:@"%@/%@", elementKind, identifier];
    NSMutableArray *reusableViews = _supplementaryViewReuseQueues[kindAndIdentifier];
    TUICollectionReusableView *view = [reusableViews lastObject];
    if (view) {
        [reusableViews removeObjectAtIndex:reusableViews.count - 1];
    } else {
        Class viewClass = _supplementaryViewClassDict[kindAndIdentifier];
		if (viewClass == nil) {
			@throw [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Class not registered for kind/identifier %@", kindAndIdentifier] userInfo:nil];
		}
		if (self.collectionViewLayout) {
			TUICollectionViewLayoutAttributes *attributes = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:elementKind
																													  atIndexPath:indexPath];
			view = [[viewClass alloc] initWithFrame:attributes.frame];
		} else {
			view = [viewClass new];
		}
        view.collectionView = self;
        view.reuseIdentifier = identifier;
    }
    return view;
}


- (NSArray *)allCells {
    return [[self.allVisibleViewsDict allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[TUICollectionViewCell class]];
    }]];
}

- (NSArray *)visibleCells {
    return [[self.allVisibleViewsDict allValues] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[TUICollectionViewCell class]] && CGRectIntersectsRect(self.visibleRect, [evaluatedObject frame]);
    }]];
}

- (void)reloadData {
    if (_reloadingSuspendedCount != 0) return;
    [self invalidateLayout];
    [self.allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if ([obj isKindOfClass:[TUIView class]]) {
            [obj removeFromSuperview];
        }
    }];
    [self.allVisibleViewsDict removeAllObjects];

    for(NSIndexPath *indexPath in _indexPathsForSelectedItems) {
        TUICollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
        selectedCell.selected = NO;
        selectedCell.highlighted = NO;
    }
    [_indexPathsForSelectedItems removeAllObjects];
    [_indexPathsForHighlightedItems removeAllObjects];

    [self setNeedsLayout];


    //NSAssert(sectionCount == 1, @"Sections are currently not supported.");
}


#pragma mark - Query Grid

- (NSInteger)numberOfSections {
    return [_collectionViewData numberOfSections];
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    return [_collectionViewData numberOfItemsInSection:section];
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [[self collectionViewLayout] layoutAttributesForItemAtIndexPath:indexPath];
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return [[self collectionViewLayout] layoutAttributesForSupplementaryViewOfKind:kind atIndexPath:indexPath];
}

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point {
    __block NSIndexPath *indexPath = nil;
    [self.allVisibleViewsDict enumerateKeysAndObjectsWithOptions:kNilOptions usingBlock:^(id key, id obj, BOOL *stop) {
        TUICollectionViewItemKey *itemKey = (TUICollectionViewItemKey *)key;
        if (itemKey.type == TUICollectionViewItemTypeCell) {
            TUICollectionViewCell *cell = (TUICollectionViewCell *)obj;
            if (CGRectContainsPoint(cell.frame, point)) {
                indexPath = itemKey.indexPath;
                *stop = YES;
            }
        }
    }];
    return indexPath;
}

- (NSIndexPath *)indexPathForCell:(TUICollectionViewCell *)cell {
    __block NSIndexPath *indexPath = nil;
    [self.allVisibleViewsDict enumerateKeysAndObjectsWithOptions:kNilOptions usingBlock:^(id key, id obj, BOOL *stop) {
        TUICollectionViewItemKey *itemKey = (TUICollectionViewItemKey *)key;
        if (itemKey.type == TUICollectionViewItemTypeCell) {
            TUICollectionViewCell *currentCell = (TUICollectionViewCell *)obj;
            if (currentCell == cell) {
                indexPath = itemKey.indexPath;
                *stop = YES;
            }
        }
    }];
    return indexPath;
}

- (TUICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // NSInteger index = [_collectionViewData globalIndexForItemAtIndexPath:indexPath];
    // TODO Apple uses some kind of globalIndex for this.
    __block TUICollectionViewCell *cell = nil;
    [self.allVisibleViewsDict enumerateKeysAndObjectsWithOptions:0 usingBlock:^(id key, id obj, BOOL *stop) {
        TUICollectionViewItemKey *itemKey = (TUICollectionViewItemKey *)key;
        if (itemKey.type == TUICollectionViewItemTypeCell) {
            if ([itemKey.indexPath isEqual:indexPath]) {
                cell = obj;
                *stop = YES;
            }
        }
    }];
    return cell;
}

- (NSArray *)indexPathsForVisibleItems {
	NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:[self.allVisibleViewsDict count]];

	[self.allVisibleViewsDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		TUICollectionViewItemKey *itemKey = (TUICollectionViewItemKey *)key;
        if (itemKey.type == TUICollectionViewItemTypeCell) {
			[indexPaths addObject:itemKey.indexPath];
		}
	}];

	return indexPaths;
}

// returns nil or an array of selected index paths
- (NSArray *)indexPathsForSelectedItems {
    return [_indexPathsForSelectedItems allObjects];
}

// Interacting with the collection view.
- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(TUICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated {

    // ensure grid is layouted; else we can't scroll.
    [self layout];

    TUICollectionViewLayoutAttributes *layoutAttributes = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:indexPath];
    if (layoutAttributes) {
        CGRect targetRect = layoutAttributes.frame;

        // hack to add proper margins to flowlayout.
        // TODO: how to pack this into TUICollectionViewFlowLayout?
        if ([self.collectionViewLayout isKindOfClass:[TUICollectionViewFlowLayout class]]) {
            TUICollectionViewFlowLayout *flowLayout = (TUICollectionViewFlowLayout *)self.collectionViewLayout;
            targetRect.size.height += flowLayout.scrollDirection == TUICollectionViewScrollDirectionVertical ? flowLayout.minimumLineSpacing : flowLayout.minimumInteritemSpacing;
            targetRect.size.width += flowLayout.scrollDirection == TUICollectionViewScrollDirectionVertical ? flowLayout.minimumInteritemSpacing : flowLayout.minimumLineSpacing;
        }
        [self scrollRectToVisible:targetRect animated:animated];
    }
}

#pragma mark - Mouse Event Handling

- (void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    CGPoint touchPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:touchPoint];
    if (indexPath) {
        
        if (!self.allowsMultipleSelection) {
            // temporally unhighlight background on touchesBegan (keeps selected by _indexPathsForSelectedItems)
            for (TUICollectionViewCell* visibleCell in [self allCells]) {
                visibleCell.highlighted = NO;
                visibleCell.selected = NO;
                
                // NOTE: doesn't work due to the _indexPathsForHighlightedItems validation
                //[self unhighlightItemAtIndexPath:indexPathForVisibleItem animated:YES notifyDelegate:YES];
            }
        }
        
        [self highlightItemAtIndexPath:indexPath animated:YES scrollPosition:TUICollectionViewScrollPositionNone notifyDelegate:YES];
        
        self.touchingIndexPath = indexPath;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    if (self.touchingIndexPath) {
        CGPoint touchPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSIndexPath *indexPath = [self indexPathForItemAtPoint:touchPoint];
        if ([indexPath isEqual:self.touchingIndexPath]) {
            [self highlightItemAtIndexPath:indexPath animated:YES scrollPosition:TUICollectionViewScrollPositionNone notifyDelegate:YES];
        }
        else {
            [self unhighlightItemAtIndexPath:self.touchingIndexPath animated:YES notifyDelegate:YES];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [super mouseUp:theEvent];
    CGPoint touchPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSIndexPath *indexPath = [self indexPathForItemAtPoint:touchPoint];
    if ([indexPath isEqual:self.touchingIndexPath]) {
        [self userSelectedItemAtIndexPath:indexPath];
        
        [self unhighlightAllItems];
        self.touchingIndexPath = nil;
    }
    else {
        [self cellTouchCancelled];
    }
}

- (void)cellTouchCancelled {
    // TODO: improve behavior on touchesCancelled
    if (!self.allowsMultipleSelection) {
        // highlight selected-background again
        for (TUICollectionViewCell* visibleCell in [self allCells]) {
            NSIndexPath* indexPathForVisibleItem = [self indexPathForCell:visibleCell];
            visibleCell.selected = [_indexPathsForSelectedItems containsObject:indexPathForVisibleItem];
        }
    }

    [self unhighlightAllItems];
    self.touchingIndexPath = nil;
}

- (void)userSelectedItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.allowsMultipleSelection && [_indexPathsForSelectedItems containsObject:indexPath]) {
        [self deselectItemAtIndexPath:indexPath animated:YES notifyDelegate:YES];
    }
    else {
        [self selectItemAtIndexPath:indexPath animated:YES scrollPosition:TUICollectionViewScrollPositionNone notifyDelegate:YES];
    }
}

// select item, notify delegate (internal)
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(TUICollectionViewScrollPosition)scrollPosition notifyDelegate:(BOOL)notifyDelegate {

    if (self.allowsMultipleSelection && [_indexPathsForSelectedItems containsObject:indexPath]) {

        BOOL shouldDeselect = YES;
        if (notifyDelegate && _collectionViewFlags.delegateShouldDeselectItemAtIndexPath) {
            shouldDeselect = [self.delegate collectionView:self shouldDeselectItemAtIndexPath:indexPath];
        }

        if (shouldDeselect) {
            [self deselectItemAtIndexPath:indexPath animated:animated];

            if (notifyDelegate && _collectionViewFlags.delegateDidDeselectItemAtIndexPath) {
                [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
            }
        }

    } else {
        // either single selection, or wasn't already selected in multiple selection mode
        
        if (!self.allowsMultipleSelection) {
            for (NSIndexPath *selectedIndexPath in [_indexPathsForSelectedItems copy]) {
                if(![indexPath isEqual:selectedIndexPath]) {
                    [self deselectItemAtIndexPath:selectedIndexPath animated:animated notifyDelegate:notifyDelegate];
                }
            }
        }

        BOOL shouldSelect = YES;
        if (notifyDelegate && _collectionViewFlags.delegateShouldSelectItemAtIndexPath) {
            shouldSelect = [self.delegate collectionView:self shouldSelectItemAtIndexPath:indexPath];
        }

        if (shouldSelect) {
            TUICollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
            selectedCell.selected = YES;
            [_indexPathsForSelectedItems addObject:indexPath];

            if (notifyDelegate && _collectionViewFlags.delegateDidSelectItemAtIndexPath) {
                [self.delegate collectionView:self didSelectItemAtIndexPath:indexPath];
            }
        }
    }

    [self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:YES];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(TUICollectionViewScrollPosition)scrollPosition {
    [self selectItemAtIndexPath:indexPath animated:animated scrollPosition:scrollPosition notifyDelegate:NO];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated
{
    [self deselectItemAtIndexPath:indexPath animated:animated notifyDelegate:NO];
}

- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated notifyDelegate:(BOOL)notify {
    if ([_indexPathsForSelectedItems containsObject:indexPath]) {
        TUICollectionViewCell *selectedCell = [self cellForItemAtIndexPath:indexPath];
        selectedCell.selected = NO;
        [_indexPathsForSelectedItems removeObject:indexPath];

        [self unhighlightItemAtIndexPath:indexPath animated:animated notifyDelegate:notify];

        if (notify && _collectionViewFlags.delegateDidDeselectItemAtIndexPath) {
            [self.delegate collectionView:self didDeselectItemAtIndexPath:indexPath];
        }
    }
}

- (BOOL)highlightItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(TUICollectionViewScrollPosition)scrollPosition notifyDelegate:(BOOL)notifyDelegate {
    BOOL shouldHighlight = YES;
    if (notifyDelegate && _collectionViewFlags.delegateShouldHighlightItemAtIndexPath) {
        shouldHighlight = [self.delegate collectionView:self shouldHighlightItemAtIndexPath:indexPath];
    }

    if (shouldHighlight) {
        TUICollectionViewCell *highlightedCell = [self cellForItemAtIndexPath:indexPath];
        highlightedCell.highlighted = YES;
        [_indexPathsForHighlightedItems addObject:indexPath];

        if (notifyDelegate && _collectionViewFlags.delegateDidHighlightItemAtIndexPath) {
            [self.delegate collectionView:self didHighlightItemAtIndexPath:indexPath];
        }
    }
    return shouldHighlight;
}

- (void)unhighlightItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated notifyDelegate:(BOOL)notifyDelegate {
    if ([_indexPathsForHighlightedItems containsObject:indexPath]) {
        TUICollectionViewCell *highlightedCell = [self cellForItemAtIndexPath:indexPath];
        highlightedCell.highlighted = NO;
        [_indexPathsForHighlightedItems removeObject:indexPath];

        if (notifyDelegate && _collectionViewFlags.delegateDidUnhighlightItemAtIndexPath) {
            [self.delegate collectionView:self didUnhighlightItemAtIndexPath:indexPath];
        }
    }
}

- (void)unhighlightAllItems {
    for (NSIndexPath *indexPath in [_indexPathsForHighlightedItems copy]) {
        [self unhighlightItemAtIndexPath:indexPath animated:NO notifyDelegate:YES];
    }
}

#pragma mark - Update Grid

- (void)insertSections:(NSIndexSet *)sections {
    [self updateSections:sections updateAction:TUICollectionUpdateActionInsert];
}

- (void)deleteSections:(NSIndexSet *)sections {
    [self updateSections:sections updateAction:TUICollectionUpdateActionInsert];
}

- (void)reloadSections:(NSIndexSet *)sections {
    [self updateSections:sections updateAction:TUICollectionUpdateActionReload];
}

- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection {
    NSMutableArray *moveUpdateItems = [self arrayForUpdateAction:TUICollectionUpdateActionMove];
    [moveUpdateItems addObject:
     [[TUICollectionViewUpdateItem alloc] initWithInitialIndexPath:[NSIndexPath indexPathForItem:NSNotFound inSection:section]
                                                    finalIndexPath:[NSIndexPath indexPathForItem:NSNotFound inSection:newSection]
                                                      updateAction:TUICollectionUpdateActionMove]];
    if(!_collectionViewFlags.updating) {
        [self setupCellAnimations];
        [self endItemAnimations];
    }
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths {
    [self updateRowsAtIndexPaths:indexPaths updateAction:TUICollectionUpdateActionInsert];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths {
    [self updateRowsAtIndexPaths:indexPaths updateAction:TUICollectionUpdateActionDelete];

}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths {
    [self updateRowsAtIndexPaths:indexPaths updateAction:TUICollectionUpdateActionReload];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    NSMutableArray* moveUpdateItems = [self arrayForUpdateAction:TUICollectionUpdateActionMove];
    [moveUpdateItems addObject:
     [[TUICollectionViewUpdateItem alloc] initWithInitialIndexPath:indexPath
                                                    finalIndexPath:newIndexPath
                                                      updateAction:TUICollectionUpdateActionMove]];
    if(!_collectionViewFlags.updating) {
        [self setupCellAnimations];
        [self endItemAnimations];
    }

}

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(BOOL finished))completion {
    if(!updates) return;
    
    [self setupCellAnimations];

    updates();
    
    if(completion) _updateCompletionHandler = completion;
        
    [self endItemAnimations];
}

#pragma mark - Properties

- (void)setBackgroundView:(TUIView *)backgroundView {
    if (backgroundView != _backgroundView) {
        [_backgroundView removeFromSuperview];
        _backgroundView = backgroundView;
        backgroundView.frame = (NSRect){.origin=self.contentOffset,.size=self.bounds.size};
        backgroundView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:backgroundView];
    }
}

- (void)setCollectionViewLayout:(TUICollectionViewLayout *)viewLayout animated:(BOOL)animated {
    if (viewLayout == _layout) return;

    // not sure it was it original code, but here this prevents crash
    // in case we switch layout before previous one was initially loaded
    if(CGRectIsEmpty(self.bounds) || !_collectionViewFlags.doneFirstLayout) {
        _layout.collectionView = nil;
        _collectionViewData = [[TUICollectionViewData alloc] initWithCollectionView:self layout:layout];
        viewLayout.collectionView = self;
        _layout = viewLayout;
        
        // originally the use method
        // _setNeedsVisibleCellsUpdate:withLayoutAttributes:
        // here with CellsUpdate set to YES and LayoutAttributes parameter set to NO
        // inside this method probably some flags are set and finally
        // setNeedsDisplay is called
        
        _collectionViewFlags.scheduledUpdateVisibleCells= YES;
        _collectionViewFlags.scheduledUpdateVisibleCellLayoutAttributes = NO;

        [self setNeedsDisplay];
    } else {
        viewLayout.collectionView = self;
        
        _collectionViewData = [[TUICollectionViewData alloc] initWithCollectionView:self layout:layout];
        [_collectionViewData prepareToLoadData];

        NSArray *previouslySelectedIndexPaths = [self indexPathsForSelectedItems];
        NSMutableSet *selectedCellKeys = [NSMutableSet setWithCapacity:[previouslySelectedIndexPaths count]];
        
        for(NSIndexPath *indexPath in previouslySelectedIndexPaths) {
            [selectedCellKeys addObject:[TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath]];
        }
        
        NSArray *previouslyVisibleItemsKeys = [self.allVisibleViewsDict allKeys];
        NSSet *previouslyVisibleItemsKeysSet = [NSSet setWithArray:previouslyVisibleItemsKeys];
        NSMutableSet *previouslyVisibleItemsKeysSetMutable = [NSMutableSet setWithArray:previouslyVisibleItemsKeys];

        if([selectedCellKeys intersectsSet:selectedCellKeys]) {
            [previouslyVisibleItemsKeysSetMutable intersectSet:previouslyVisibleItemsKeysSetMutable];
        }
        
        TUIView *previouslyVisibleView = self.allVisibleViewsDict[[previouslyVisibleItemsKeysSetMutable anyObject]];
        [previouslyVisibleView removeFromSuperview];
		[self addSubview:previouslyVisibleView];
        
        CGRect rect = [_collectionViewData collectionViewContentRect];
        NSArray *newlyVisibleLayoutAttrs = [_collectionViewData layoutAttributesForElementsInRect:rect];
        
        NSMutableDictionary *layoutInterchangeData = [NSMutableDictionary dictionaryWithCapacity:
                                                     [newlyVisibleLayoutAttrs count] + [previouslyVisibleItemsKeysSet count]];
        
        NSMutableSet *newlyVisibleItemsKeys = [NSMutableSet set];
        for(TUICollectionViewLayoutAttributes *attr in newlyVisibleLayoutAttrs) {
            TUICollectionViewItemKey *newKey = [TUICollectionViewItemKey collectionItemKeyForLayoutAttributes:attr];
            [newlyVisibleItemsKeys addObject:newKey];
            
            TUICollectionViewLayoutAttributes *prevAttr = nil;
            TUICollectionViewLayoutAttributes *newAttr = nil;
            
            if(newKey.type == TUICollectionViewItemTypeDecorationView) {
                prevAttr = [self.collectionViewLayout layoutAttributesForDecorationViewWithReuseIdentifier:attr.representedElementKind
                                                                                               atIndexPath:newKey.indexPath];
                newAttr = [layout layoutAttributesForDecorationViewWithReuseIdentifier:attr.representedElementKind
                                                                           atIndexPath:newKey.indexPath];
            }
            else if(newKey.type == TUICollectionViewItemTypeCell) {
                prevAttr = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:newKey.indexPath];
                newAttr = [layout layoutAttributesForItemAtIndexPath:newKey.indexPath];
            }
            else {
                prevAttr = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:attr.representedElementKind
                                                                                     atIndexPath:newKey.indexPath];
                newAttr = [layout layoutAttributesForSupplementaryViewOfKind:attr.representedElementKind
                                                                 atIndexPath:newKey.indexPath];
            }
            
            layoutInterchangeData[newKey] = [NSDictionary dictionaryWithObjects:@[prevAttr,newAttr]
                                                                        forKeys:@[@"previousLayoutInfos", @"newLayoutInfos"]];
        }
        
        for(TUICollectionViewItemKey *key in previouslyVisibleItemsKeysSet) {
            TUICollectionViewLayoutAttributes *prevAttr = nil;
            TUICollectionViewLayoutAttributes *newAttr = nil;
            
            if(key.type == TUICollectionViewItemTypeDecorationView) {
                TUICollectionReusableView *decorView = self.allVisibleViewsDict[key];
                prevAttr = [self.collectionViewLayout layoutAttributesForDecorationViewWithReuseIdentifier:decorView.reuseIdentifier
                                                                                               atIndexPath:key.indexPath];
                newAttr = [layout layoutAttributesForDecorationViewWithReuseIdentifier:decorView.reuseIdentifier
                                                                           atIndexPath:key.indexPath];
            }
            else if(key.type == TUICollectionViewItemTypeCell) {
                prevAttr = [self.collectionViewLayout layoutAttributesForItemAtIndexPath:key.indexPath];
                newAttr = [layout layoutAttributesForItemAtIndexPath:key.indexPath];
            }
            else {
                TUICollectionReusableView* suuplView = self.allVisibleViewsDict[key];
                prevAttr = [self.collectionViewLayout layoutAttributesForSupplementaryViewOfKind:suuplView.layoutAttributes.representedElementKind
                                                                                     atIndexPath:key.indexPath];
                newAttr = [layout layoutAttributesForSupplementaryViewOfKind:suuplView.layoutAttributes.representedElementKind
                                                                 atIndexPath:key.indexPath];
            }
            
            layoutInterchangeData[key] = [NSDictionary dictionaryWithObjects:@[prevAttr,newAttr]
                                                                     forKeys:@[@"previousLayoutInfos", @"newLayoutInfos"]];
        }

        for(TUICollectionViewItemKey *key in [layoutInterchangeData keyEnumerator]) {
            if(key.type == TUICollectionViewItemTypeCell) {
                TUICollectionViewCell* cell = self.allVisibleViewsDict[key];
                
                if (!cell) {
                    cell = [self createPreparedCellForItemAtIndexPath:key.indexPath
                                                 withLayoutAttributes:layoutInterchangeData[key][@"previousLayoutInfos"]];
                    self.allVisibleViewsDict[key] = cell;
                    [self addControlledSubview:cell];
                }
                else [cell applyLayoutAttributes:layoutInterchangeData[key][@"previousLayoutInfos"]];
            }
            else if(key.type == TUICollectionViewItemTypeSupplementaryView) {
                TUICollectionReusableView *view = self.allVisibleViewsDict[key];
                if (!view) {
                    TUICollectionViewLayoutAttributes *attrs = layoutInterchangeData[key][@"previousLayoutInfos"];
                    view = [self createPreparedSupplementaryViewForElementOfKind:attrs.representedElementKind
                                                                     atIndexPath:attrs.indexPath
                                                            withLayoutAttributes:attrs];
                }
            }
        };
        
        CGRect contentRect = [_collectionViewData collectionViewContentRect];

        [self setContentSize:contentRect.size];
        [self setContentOffset:contentRect.origin];
        
        void (^applyNewLayoutBlock)(void) = ^{
            NSEnumerator *keys = [layoutInterchangeData keyEnumerator];
            for(TUICollectionViewItemKey *key in keys) {
                [(TUICollectionViewCell *)self.allVisibleViewsDict[key] applyLayoutAttributes:layoutInterchangeData[key][@"newLayoutInfos"]];
            }
        };
        
        void (^freeUnusedViews)(void) = ^ {
            for(TUICollectionViewItemKey *key in [self.allVisibleViewsDict keyEnumerator]) {
                if(![newlyVisibleItemsKeys containsObject:key]) {
                    if(key.type == TUICollectionViewItemTypeCell) [self reuseCell:self.allVisibleViewsDict[key]];
                    else if(key.type == TUICollectionViewItemTypeSupplementaryView)
                        [self reuseSupplementaryView:self.allVisibleViewsDict[key]];
                }
            }
        };
        
        if(animated) {
            [TUIView animateWithDuration:0.25f animations:^ {
                 _collectionViewFlags.updatingLayout = YES;
                 applyNewLayoutBlock();
             } completion:^(BOOL finished) {
                 freeUnusedViews();
                 _collectionViewFlags.updatingLayout = NO;
             }];
        }
        else {
            applyNewLayoutBlock();
            freeUnusedViews();
        }
        
        _layout.collectionView = nil;
        _layout = layout;
    }
}

- (void)setCollectionViewLayout:(TUICollectionViewLayout *)viewLayout {
    [self setCollectionViewLayout:viewLayout animated:NO];
}

- (void)setDelegate:(id<TUICollectionViewDelegate>)delegate {
	//	Managing the Selected Cells
	_collectionViewFlags.delegateShouldSelectItemAtIndexPath       = [self.delegate respondsToSelector:@selector(collectionView:shouldSelectItemAtIndexPath:)];
	_collectionViewFlags.delegateDidSelectItemAtIndexPath          = [self.delegate respondsToSelector:@selector(collectionView:didSelectItemAtIndexPath:)];
	_collectionViewFlags.delegateShouldDeselectItemAtIndexPath     = [self.delegate respondsToSelector:@selector(collectionView:shouldDeselectItemAtIndexPath:)];
	_collectionViewFlags.delegateDidDeselectItemAtIndexPath        = [self.delegate respondsToSelector:@selector(collectionView:didDeselectItemAtIndexPath:)];

	//	Managing Cell Highlighting
	_collectionViewFlags.delegateShouldHighlightItemAtIndexPath    = [self.delegate respondsToSelector:@selector(collectionView:shouldHighlightItemAtIndexPath:)];
	_collectionViewFlags.delegateDidHighlightItemAtIndexPath       = [self.delegate respondsToSelector:@selector(collectionView:didHighlightItemAtIndexPath:)];
	_collectionViewFlags.delegateDidUnhighlightItemAtIndexPath     = [self.delegate respondsToSelector:@selector(collectionView:didUnhighlightItemAtIndexPath:)];

	//	Tracking the Removal of Views
	_collectionViewFlags.delegateDidEndDisplayingCell              = [self.delegate respondsToSelector:@selector(collectionView:didEndDisplayingCell:forItemAtIndexPath:)];
	_collectionViewFlags.delegateDidEndDisplayingSupplementaryView = [self.delegate respondsToSelector:@selector(collectionView:didEndDisplayingSupplementaryView:forElementOfKind:atIndexPath:)];

	//	Managing Actions for Cells
	_collectionViewFlags.delegateSupportsMenus                     = [self.delegate respondsToSelector:@selector(collectionView:shouldShowMenuForItemAtIndexPath:)];

	// These aren't present in the flags which is a little strange. Not adding them because thet will mess with byte alignment which will affect cross compatibility.
	// The flag names are guesses and are there for documentation purposes.
	//
	// _collectionViewFlags.delegateCanPerformActionForItemAtIndexPath	= [self.delegate respondsToSelector:@selector(collectionView:canPerformAction:forItemAtIndexPath:withSender:)];
	// _collectionViewFlags.delegatePerformActionForItemAtIndexPath		= [self.delegate respondsToSelector:@selector(collectionView:performAction:forItemAtIndexPath:withSender:)];
}

// Might be overkill since two are required and two are handled by TUICollectionViewData leaving only one flag we actually need to check for
- (void)setDataSource:(id<TUICollectionViewDataSource>)dataSource {
    if (dataSource != _dataSource) {
		_dataSource = dataSource;

		//	Getting Item and Section Metrics
		_collectionViewFlags.dataSourceNumberOfSections = [_dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)];

		//	Getting Views for Items
		_collectionViewFlags.dataSourceViewForSupplementaryElement = [_dataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)];
    }
}

- (BOOL)allowsSelection {
    return _collectionViewFlags.allowsSelection;
}

- (void)setAllowsSelection:(BOOL)allowsSelection {
    _collectionViewFlags.allowsSelection = allowsSelection;
}

- (BOOL)allowsMultipleSelection {
    return _collectionViewFlags.allowsMultipleSelection;
}

- (void)setAllowsMultipleSelection:(BOOL)allowsMultipleSelection {
    _collectionViewFlags.allowsMultipleSelection = allowsMultipleSelection;

    // Deselect all objects if allows multiple selection is false
    if (!allowsMultipleSelection && _indexPathsForSelectedItems.count) {

        // Note: Apple's implementation leaves a mostly random item selected. Presumably they
        //       have a good reason for this, but I guess it's just skipping the last or first index.
        for (NSIndexPath *selectedIndexPath in [_indexPathsForSelectedItems copy]) {
            if (_indexPathsForSelectedItems.count == 1) continue;
            [self deselectItemAtIndexPath:selectedIndexPath animated:YES notifyDelegate:YES];
        }
    }
}

#pragma mark - Private

- (void)invalidateLayout {
    [self.collectionViewLayout invalidateLayout];
    [self.collectionViewData invalidate]; // invalidate layout cache
}

// update currently visible cells, fetches new cells if needed
// TODO: use now parameter.
- (void)updateVisibleCellsNow:(BOOL)now {
    NSArray *layoutAttributesArray = [_collectionViewData layoutAttributesForElementsInRect:self.visibleRect];

    // create ItemKey/Attributes dictionary
    NSMutableDictionary *itemKeysToAddDict = [NSMutableDictionary dictionary];
    for (TUICollectionViewLayoutAttributes *layoutAttributes in layoutAttributesArray) {
        TUICollectionViewItemKey *itemKey = [TUICollectionViewItemKey collectionItemKeyForLayoutAttributes:layoutAttributes];
        itemKeysToAddDict[itemKey] = layoutAttributes;
    }

    // detect what items should be removed and queued back.
    NSMutableSet *allVisibleItemKeys = [NSMutableSet setWithArray:[self.allVisibleViewsDict allKeys]];
    [allVisibleItemKeys minusSet:[NSSet setWithArray:[itemKeysToAddDict allKeys]]];

    // remove views that have not been processed and prepare them for re-use.
    for (TUICollectionViewItemKey *itemKey in allVisibleItemKeys) {
        TUICollectionReusableView *reusableView = self.allVisibleViewsDict[itemKey];
        if (reusableView) {
            [reusableView removeFromSuperview];
            [self.allVisibleViewsDict removeObjectForKey:itemKey];
            if (itemKey.type == TUICollectionViewItemTypeCell) {
                if (_collectionViewFlags.delegateDidEndDisplayingCell) {
                    [self.delegate collectionView:self didEndDisplayingCell:(TUICollectionViewCell *)reusableView forItemAtIndexPath:itemKey.indexPath];
                }
                [self reuseCell:(TUICollectionViewCell *)reusableView];
            }else if(itemKey.type == TUICollectionViewItemTypeSupplementaryView) {
                if (_collectionViewFlags.delegateDidEndDisplayingSupplementaryView) {
                    [self.delegate collectionView:self didEndDisplayingSupplementaryView:reusableView forElementOfKind:itemKey.identifier atIndexPath:itemKey.indexPath];
                }
                [self reuseSupplementaryView:reusableView];
            }
            // TODO: decoration views etc?
        }
    }

    // finally add new cells.
    [itemKeysToAddDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        TUICollectionViewItemKey *itemKey = key;
        TUICollectionViewLayoutAttributes *layoutAttributes = obj;

        // check if cell is in visible dict; add it if not.
        TUICollectionReusableView *view = self.allVisibleViewsDict[itemKey];
        if (!view) {
            if (itemKey.type == TUICollectionViewItemTypeCell) {
                view = [self createPreparedCellForItemAtIndexPath:itemKey.indexPath withLayoutAttributes:layoutAttributes];

            } else if (itemKey.type == TUICollectionViewItemTypeSupplementaryView) {
                view = [self createPreparedSupplementaryViewForElementOfKind:layoutAttributes.representedElementKind
																 atIndexPath:layoutAttributes.indexPath
														withLayoutAttributes:layoutAttributes];
            }

			//Supplementary views are optional
			if (view) {
				self.allVisibleViewsDict[itemKey] = view;
				[self addControlledSubview:view];
			}
        }else {
            // just update cell
            [view applyLayoutAttributes:layoutAttributes];
        }
    }];
}

// fetches a cell from the dataSource and sets the layoutAttributes
- (TUICollectionViewCell *)createPreparedCellForItemAtIndexPath:(NSIndexPath *)indexPath withLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes {

    TUICollectionViewCell *cell = [self.dataSource collectionView:self cellForItemAtIndexPath:indexPath];

    // reset selected/highlight state
    [cell setHighlighted:[_indexPathsForHighlightedItems containsObject:indexPath]];
    [cell setSelected:[_indexPathsForSelectedItems containsObject:indexPath]];

    [cell applyLayoutAttributes:layoutAttributes];
    return cell;
}

- (TUICollectionReusableView *)createPreparedSupplementaryViewForElementOfKind:(NSString *)kind
																   atIndexPath:(NSIndexPath *)indexPath
														  withLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes {
	if (_collectionViewFlags.dataSourceViewForSupplementaryElement) {
		TUICollectionReusableView *view = [self.dataSource collectionView:self
										viewForSupplementaryElementOfKind:kind
															  atIndexPath:indexPath];
		[view applyLayoutAttributes:layoutAttributes];
		return view;
	}
	return nil;
}

// @steipete optimization
- (void)queueReusableView:(TUICollectionReusableView *)reusableView inQueue:(NSMutableDictionary *)queue {
    NSString *cellIdentifier = reusableView.reuseIdentifier;
    NSParameterAssert([cellIdentifier length]);

    [reusableView removeFromSuperview];
    [reusableView prepareForReuse];

    // enqueue cell
    NSMutableArray *reuseableViews = queue[cellIdentifier];
    if (!reuseableViews) {
        reuseableViews = [NSMutableArray array];
        queue[cellIdentifier] = reuseableViews;
    }
    [reuseableViews addObject:reusableView];
}

// enqueue cell for reuse
- (void)reuseCell:(TUICollectionViewCell *)cell {
    [self queueReusableView:cell inQueue:_cellReuseQueues];
}

// enqueue supplementary view for reuse
- (void)reuseSupplementaryView:(TUICollectionReusableView *)supplementaryView {
    [self queueReusableView:supplementaryView inQueue:_supplementaryViewReuseQueues];
}

- (void)addControlledSubview:(TUICollectionReusableView *)subview {
	// avoids placing views above the scroll indicator
    [self addSubview:subview];
}

#pragma mark - Updating grid internal functionality

- (void)suspendReloads {
    _reloadingSuspendedCount++;
}

- (void)resumeReloads {
    _reloadingSuspendedCount--;
}

-(NSMutableArray *)arrayForUpdateAction:(TUICollectionUpdateAction)updateAction {
    NSMutableArray *ret = nil;

    switch (updateAction) {
        case TUICollectionUpdateActionInsert:
            if(!_insertItems) _insertItems = [[NSMutableArray alloc] init];
            ret = _insertItems;
            break;
        case TUICollectionUpdateActionDelete:
            if(!_deleteItems) _deleteItems = [[NSMutableArray alloc] init];
            ret = _deleteItems;
            break;
        case TUICollectionUpdateActionMove:
            if(_moveItems) _moveItems = [[NSMutableArray alloc] init];
            ret = _moveItems;
            break;
        case TUICollectionUpdateActionReload:
            if(!_reloadItems) _reloadItems = [[NSMutableArray alloc] init];
            ret = _reloadItems;
            break;
        default: break;
    }
    return ret;
}


- (void)prepareLayoutForUpdates {
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    [arr addObjectsFromArray: [_originalDeleteItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)]];
    [arr addObjectsFromArray:[_originalInsertItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    [arr addObjectsFromArray:[_reloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    [arr addObjectsFromArray: [_moveItems sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    [_layout prepareForCollectionViewUpdates:arr];
}

- (void)updateWithItems:(NSArray *) items {
    [self prepareLayoutForUpdates];
    
    NSMutableArray *animations = [[NSMutableArray alloc] init];
    NSMutableDictionary *newAllVisibleView = [[NSMutableDictionary alloc] init];

    for (TUICollectionViewUpdateItem *updateItem in items) {
        if (updateItem.isSectionOperation) continue;
        
        if (updateItem.updateAction == TUICollectionUpdateActionDelete) {
            NSIndexPath *indexPath = updateItem.indexPathBeforeUpdate;
            
            TUICollectionViewLayoutAttributes *finalAttrs = [_layout finalLayoutAttributesForDisappearingItemAtIndexPath:indexPath];
            TUICollectionViewItemKey *key = [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath];
            TUICollectionReusableView *view = self.allVisibleViewsDict[key];
            if (view) {
                TUICollectionViewLayoutAttributes *startAttrs = view.layoutAttributes;
                
                if (!finalAttrs) {
                    finalAttrs = [startAttrs copy];
                    finalAttrs.alpha = 0;
                }
                [animations addObject:@{@"view": view, @"previousLayoutInfos": startAttrs, @"newLayoutInfos": finalAttrs}];
                [self.allVisibleViewsDict removeObjectForKey:key];
            }
        }
        else if(updateItem.updateAction == TUICollectionUpdateActionInsert) {
            NSIndexPath *indexPath = updateItem.indexPathAfterUpdate;
            TUICollectionViewItemKey *key = [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPath];
            TUICollectionViewLayoutAttributes *startAttrs = [_layout initialLayoutAttributesForAppearingItemAtIndexPath:indexPath];
            TUICollectionViewLayoutAttributes *finalAttrs = [_layout layoutAttributesForItemAtIndexPath:indexPath];
            
            CGRect startRect = CGRectMake(CGRectGetMidX(startAttrs.frame)-startAttrs.center.x,
                                          CGRectGetMidY(startAttrs.frame)-startAttrs.center.y,
                                          startAttrs.frame.size.width,
                                          startAttrs.frame.size.height);
            CGRect finalRect = CGRectMake(CGRectGetMidX(finalAttrs.frame)-finalAttrs.center.x,
                                         CGRectGetMidY(finalAttrs.frame)-finalAttrs.center.y,
                                         finalAttrs.frame.size.width,
                                         finalAttrs.frame.size.height);
            
            if(CGRectIntersectsRect(_visibleBoundRects, startRect) || CGRectIntersectsRect(_visibleBoundRects, finalRect)) {
                TUICollectionReusableView *view = [self createPreparedCellForItemAtIndexPath:indexPath
                                                                        withLayoutAttributes:startAttrs];
                [self addControlledSubview:view];
                
                newAllVisibleView[key] = view;
                [animations addObject:@{@"view": view, @"previousLayoutInfos": startAttrs?startAttrs:finalAttrs, @"newLayoutInfos": finalAttrs}];
            }
        }
        else if(updateItem.updateAction == TUICollectionUpdateActionMove) {
            NSIndexPath *indexPathBefore = updateItem.indexPathBeforeUpdate;
            NSIndexPath *indexPathAfter = updateItem.indexPathAfterUpdate;
            
            TUICollectionViewItemKey *keyBefore = [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPathBefore];
            TUICollectionViewItemKey *keyAfter = [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:indexPathAfter];
            TUICollectionReusableView *view = self.allVisibleViewsDict[keyBefore];
            
            TUICollectionViewLayoutAttributes *startAttrs = nil;
            TUICollectionViewLayoutAttributes *finalAttrs = [_layout layoutAttributesForItemAtIndexPath:indexPathAfter];
            
            if(view) {
                startAttrs = view.layoutAttributes;
                [self.allVisibleViewsDict removeObjectForKey:keyBefore];
                newAllVisibleView[keyAfter] = view;
            }
            else {
                startAttrs = [finalAttrs copy];
                startAttrs.alpha = 0;
                view = [self createPreparedCellForItemAtIndexPath:indexPathAfter withLayoutAttributes:startAttrs];
                [self addControlledSubview:view];
                newAllVisibleView[keyAfter] = view;
            }
            
            [animations addObject:@{@"view": view, @"previousLayoutInfos": startAttrs, @"newLayoutInfos": finalAttrs}];
        }
    }
    
    for (TUICollectionViewItemKey *key in [self.allVisibleViewsDict keyEnumerator]) {
        TUICollectionReusableView *view = self.allVisibleViewsDict[key];
        NSInteger oldGlobalIndex = [self.currentUpdate[@"oldModel"] globalIndexForItemAtIndexPath:key.indexPath];
        NSInteger newGlobalIndex = [self.currentUpdate[@"oldToNewIndexMap"][oldGlobalIndex] intValue];
        NSIndexPath *newIndexPath = [self.currentUpdate[@"newModel"] indexPathForItemAtGlobalIndex:newGlobalIndex];
        
        TUICollectionViewLayoutAttributes* startAttrs =
        [_layout initialLayoutAttributesForAppearingItemAtIndexPath:newIndexPath];
        
        TUICollectionViewLayoutAttributes* finalAttrs =
        [_layout layoutAttributesForItemAtIndexPath:newIndexPath];
        
        [animations addObject:@{@"view":view, @"previousLayoutInfos": startAttrs, @"newLayoutInfos": finalAttrs}];
        TUICollectionViewItemKey* newKey = [key copy];
        [newKey setIndexPath:newIndexPath];
        newAllVisibleView[newKey] = view;
    }

    NSArray *allNewlyVisibleItems = [_layout layoutAttributesForElementsInRect:_visibleBoundRects];
    for (TUICollectionViewLayoutAttributes *attrs in allNewlyVisibleItems) {
        TUICollectionViewItemKey *key = [TUICollectionViewItemKey collectionItemKeyForLayoutAttributes:attrs];
        
        if (![[newAllVisibleView allKeys] containsObject:key]) {
            TUICollectionViewLayoutAttributes* startAttrs =
            [_layout initialLayoutAttributesForAppearingItemAtIndexPath:attrs.indexPath];
            
            TUICollectionReusableView *view = [self createPreparedCellForItemAtIndexPath:attrs.indexPath
                                                                    withLayoutAttributes:startAttrs];
            [self addControlledSubview:view];
            newAllVisibleView[key] = view;
            
            [animations addObject:@{@"view":view, @"previousLayoutInfos": startAttrs?startAttrs:attrs, @"newLayoutInfos": attrs}];
        }
    }
    
    self.allVisibleViewsDict = newAllVisibleView;

    for(NSDictionary *animation in animations) {
        TUICollectionReusableView *view = animation[@"view"];
        TUICollectionViewLayoutAttributes *attr = animation[@"previousLayoutInfos"];
        [view applyLayoutAttributes:attr];
    };

    [TUIView animateWithDuration:0.25f animations:^{
         _collectionViewFlags.updatingLayout = YES;
         for(NSDictionary *animation in animations) {
             TUICollectionReusableView* view = animation[@"view"];
             TUICollectionViewLayoutAttributes* attrs = animation[@"newLayoutInfos"];
             [view applyLayoutAttributes:attrs];
         }
     } completion:^(BOOL finished) {
         NSMutableSet *set = [NSMutableSet set];
         NSArray *visibleItems = [_layout layoutAttributesForElementsInRect:_visibleBoundRects];
         for(TUICollectionViewLayoutAttributes *attrs in visibleItems)
             [set addObject: [TUICollectionViewItemKey collectionItemKeyForLayoutAttributes:attrs]];

         NSMutableSet *toRemove =  [NSMutableSet set];
         for(TUICollectionViewItemKey *key in [self.allVisibleViewsDict keyEnumerator]) {
             if(![set containsObject:key]) {
                 [self reuseCell:self.allVisibleViewsDict[key]];
                 [toRemove addObject:key];
             }
         }
         for(id key in toRemove)
             [self.allVisibleViewsDict removeObjectForKey:key];
         
         _collectionViewFlags.updatingLayout = NO;
         
         if(_updateCompletionHandler) {
             _updateCompletionHandler(finished);
             _updateCompletionHandler = nil;
         }
     }];

    [_layout finalizeCollectionViewUpdates];
}

- (void)setupCellAnimations {
    [self updateVisibleCellsNow:YES];
    [self suspendReloads];
    _collectionViewFlags.updating = YES;
}

- (void)endItemAnimations {
    _updateCount++;
    TUICollectionViewData *oldCollectionViewData = _collectionViewData;
    _collectionViewData = [[TUICollectionViewData alloc] initWithCollectionView:self layout:_layout];
    
    [_layout invalidateLayout];
    [_collectionViewData prepareToLoadData];

    NSMutableArray *someMutableArr1 = [[NSMutableArray alloc] init];

    NSArray *removeUpdateItems = [[self arrayForUpdateAction:TUICollectionUpdateActionDelete]
                                  sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)];
    
    NSArray *insertUpdateItems = [[self arrayForUpdateAction:TUICollectionUpdateActionInsert]
                                  sortedArrayUsingSelector:@selector(compareIndexPaths:)];

    NSMutableArray *sortedMutableReloadItems = [[_reloadItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
    NSMutableArray *sortedMutableMoveItems = [[_moveItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
    
    _originalDeleteItems = [removeUpdateItems copy];
    _originalInsertItems = [insertUpdateItems copy];

    NSMutableArray *someMutableArr2 = [[NSMutableArray alloc] init];
    NSMutableArray *someMutableArr3 =[[NSMutableArray alloc] init];
    NSMutableDictionary *operations = [[NSMutableDictionary alloc] init];
    
    for(TUICollectionViewUpdateItem *updateItem in sortedMutableReloadItems) {
        NSAssert(updateItem.indexPathBeforeUpdate.section< [oldCollectionViewData numberOfSections],
                 @"attempt to reload item (%@) that doesn't exist (there are only %ld sections before update)",
                 updateItem.indexPathBeforeUpdate, [oldCollectionViewData numberOfSections]);
        NSAssert(updateItem.indexPathBeforeUpdate.item<[oldCollectionViewData numberOfItemsInSection:updateItem.indexPathBeforeUpdate.section],
                 @"attempt to reload item (%@) that doesn't exist (there are only %ld items in section %ld before udpate)",
                 updateItem.indexPathBeforeUpdate,
                 [oldCollectionViewData numberOfItemsInSection:updateItem.indexPathBeforeUpdate.section],
                 updateItem.indexPathBeforeUpdate.section);
        
        [someMutableArr2 addObject:[[TUICollectionViewUpdateItem alloc] initWithAction:TUICollectionUpdateActionDelete
                                                                          forIndexPath:updateItem.indexPathBeforeUpdate]];
        [someMutableArr3 addObject:[[TUICollectionViewUpdateItem alloc] initWithAction:TUICollectionUpdateActionInsert
                                                                          forIndexPath:updateItem.indexPathAfterUpdate]];
    }
    
    NSMutableArray *sortedDeletedMutableItems = [[_deleteItems sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)] mutableCopy];
    NSMutableArray *sortedInsertMutableItems = [[_insertItems sortedArrayUsingSelector:@selector(compareIndexPaths:)] mutableCopy];
    
    for(TUICollectionViewUpdateItem *deleteItem in sortedDeletedMutableItems) {
        if([deleteItem isSectionOperation]) {
            NSAssert(deleteItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to delete section (%ld) that doesn't exist (there are only %ld sections before update)",
                     deleteItem.indexPathBeforeUpdate.section,
                     [oldCollectionViewData numberOfSections]);
            
            for(TUICollectionViewUpdateItem *moveItem in sortedMutableMoveItems) {
                if(moveItem.indexPathBeforeUpdate.section == deleteItem.indexPathBeforeUpdate.section) {
                    if(moveItem.isSectionOperation)
                        NSAssert(NO, @"attempt to delete and move from the same section %ld", deleteItem.indexPathBeforeUpdate.section);
                    else
                        NSAssert(NO, @"attempt to delete and move from the same section (%@)", moveItem.indexPathBeforeUpdate);
                }
            }
        } else {
            NSAssert(deleteItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to delete item (%@) that doesn't exist (there are only %ld sections before update)",
                     deleteItem.indexPathBeforeUpdate,
                     [oldCollectionViewData numberOfSections]);
            NSAssert(deleteItem.indexPathBeforeUpdate.item<[oldCollectionViewData numberOfItemsInSection:deleteItem.indexPathBeforeUpdate.section],
                     @"attempt to delete item (%@) that doesn't exist (there are only %ld items in section %ld before update)",
                     deleteItem.indexPathBeforeUpdate,
                     [oldCollectionViewData numberOfItemsInSection:deleteItem.indexPathBeforeUpdate.section],
                     deleteItem.indexPathBeforeUpdate.section);
            
            for(TUICollectionViewUpdateItem *moveItem in sortedMutableMoveItems) {
                NSAssert([deleteItem.indexPathBeforeUpdate isEqual:moveItem.indexPathBeforeUpdate],
                         @"attempt to delete and move the same item (%@)", deleteItem.indexPathBeforeUpdate);
            }
            
            if(!operations[@(deleteItem.indexPathBeforeUpdate.section)])
                operations[@(deleteItem.indexPathBeforeUpdate.section)] = [NSMutableDictionary dictionary];
            
            operations[@(deleteItem.indexPathBeforeUpdate.section)][@"deleted"] =
            @([operations[@(deleteItem.indexPathBeforeUpdate.section)][@"deleted"] intValue]+1);
        }
    }
                      
    for(NSInteger i=0; i<[sortedInsertMutableItems count]; i++) {
        TUICollectionViewUpdateItem *insertItem = sortedInsertMutableItems[i];
        NSIndexPath *indexPath = insertItem.indexPathAfterUpdate;

        BOOL sectionOperation = [insertItem isSectionOperation];
        if(sectionOperation) {
            NSAssert([indexPath section]<[_collectionViewData numberOfSections],
                     @"attempt to insert %ld but there are only %ld sections after update",
                     [indexPath section], [_collectionViewData numberOfSections]);
            
            for(TUICollectionViewUpdateItem *moveItem in sortedMutableMoveItems) {
                if([moveItem.indexPathAfterUpdate isEqual:indexPath]) {
                    if(moveItem.isSectionOperation)
                        NSAssert(NO, @"attempt to perform an insert and a move to the same section (%ld)",indexPath.section);
//                    else
//                        NSAssert(NO, @"attempt to perform an insert and a move to the same index path (%@)",indexPath);
                }
            }
            
            NSInteger j=i+1;
            while(j<[sortedInsertMutableItems count]) {
                TUICollectionViewUpdateItem *nextInsertItem = sortedInsertMutableItems[j];
                
                if(nextInsertItem.indexPathAfterUpdate.section == indexPath.section) {
                    NSAssert(nextInsertItem.indexPathAfterUpdate.item<[_collectionViewData numberOfItemsInSection:indexPath.section],
                             @"attempt to insert item %ld into section %ld, but there are only %ld items in section %ld after the update",
                             nextInsertItem.indexPathAfterUpdate.item,
                             indexPath.section,
                             [_collectionViewData numberOfItemsInSection:indexPath.section],
                             indexPath.section);
                    [sortedInsertMutableItems removeObjectAtIndex:j];
                }
                else break;
            }
        } else {
            NSAssert(indexPath.item< [_collectionViewData numberOfItemsInSection:indexPath.section],
                     @"attempt to insert item to (%@) but there are only %ld items in section %ld after update",
                     indexPath,
                     [_collectionViewData numberOfItemsInSection:indexPath.section],
                     indexPath.section);
            
            if(!operations[@(indexPath.section)])
                operations[@(indexPath.section)] = [NSMutableDictionary dictionary];

            operations[@(indexPath.section)][@"inserted"] =
            @([operations[@(indexPath.section)][@"inserted"] intValue]+1);
        }
    }

    for(TUICollectionViewUpdateItem * sortedItem in sortedMutableMoveItems) {
        if(sortedItem.isSectionOperation) {
            NSAssert(sortedItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to move section (%ld) that doesn't exist (%ld sections before update)",
                     sortedItem.indexPathBeforeUpdate.section,
                     [oldCollectionViewData numberOfSections]);
            NSAssert(sortedItem.indexPathAfterUpdate.section<[_collectionViewData numberOfSections],
                     @"attempt to move section to %ld but there are only %ld sections after update",
                     sortedItem.indexPathAfterUpdate.section,
                     [_collectionViewData numberOfSections]);
        } else {
            NSAssert(sortedItem.indexPathBeforeUpdate.section<[oldCollectionViewData numberOfSections],
                     @"attempt to move item (%@) that doesn't exist (%ld sections before update)",
                     sortedItem, [oldCollectionViewData numberOfSections]);
            NSAssert(sortedItem.indexPathBeforeUpdate.item<[oldCollectionViewData numberOfItemsInSection:sortedItem.indexPathBeforeUpdate.section],
                     @"attempt to move item (%@) that doesn't exist (%ld items in section %ld before update)",
                     sortedItem,
                     [oldCollectionViewData numberOfItemsInSection:sortedItem.indexPathBeforeUpdate.section],
                     sortedItem.indexPathBeforeUpdate.section);
            
            NSAssert(sortedItem.indexPathAfterUpdate.section<[_collectionViewData numberOfSections],
                     @"attempt to move item to (%@) but there are only %ld sections after update",
                     sortedItem.indexPathAfterUpdate,
                     [_collectionViewData numberOfSections]);
            NSAssert(sortedItem.indexPathAfterUpdate.item<[_collectionViewData numberOfItemsInSection:sortedItem.indexPathAfterUpdate.section],
                     @"attempt to move item to (%@) but there are only %ld items in section %ld after update",
                     sortedItem,
                     [_collectionViewData numberOfItemsInSection:sortedItem.indexPathAfterUpdate.section],
                     sortedItem.indexPathAfterUpdate.section);
        }
        
        if(!operations[@(sortedItem.indexPathBeforeUpdate.section)])
            operations[@(sortedItem.indexPathBeforeUpdate.section)] = [NSMutableDictionary dictionary];
        if(!operations[@(sortedItem.indexPathAfterUpdate.section)])
            operations[@(sortedItem.indexPathAfterUpdate.section)] = [NSMutableDictionary dictionary];
        
        operations[@(sortedItem.indexPathBeforeUpdate.section)][@"movedOut"] =
        @([operations[@(sortedItem.indexPathBeforeUpdate.section)][@"movedOut"] intValue]+1);

        operations[@(sortedItem.indexPathAfterUpdate.section)][@"movedIn"] =
        @([operations[@(sortedItem.indexPathAfterUpdate.section)][@"movedIn"] intValue]+1);
    }

#if !defined  NS_BLOCK_ASSERTIONS
    for(NSNumber *sectionKey in [operations keyEnumerator]) {
        NSInteger section = [sectionKey intValue];
        
        NSInteger insertedCount = [operations[sectionKey][@"inserted"] intValue];
        NSInteger deletedCount = [operations[sectionKey][@"deleted"] intValue];
        NSInteger movedInCount = [operations[sectionKey][@"movedIn"] intValue];
        NSInteger movedOutCount = [operations[sectionKey][@"movedOut"] intValue];
        
        NSAssert([oldCollectionViewData numberOfItemsInSection:section]+insertedCount-deletedCount+movedInCount-movedOutCount ==
                 [_collectionViewData numberOfItemsInSection:section],
                 @"invalide update in section %ld: number of items after update (%ld) should be equal to the number of items before update (%ld) "\
                 "plus count of inserted items (%ld), minus count of deleted items (%ld), plus count of items moved in (%ld), minus count of items moved out (%ld)",
                 section,
                  [_collectionViewData numberOfItemsInSection:section],
                 [oldCollectionViewData numberOfItemsInSection:section],
                 insertedCount,deletedCount,movedInCount, movedOutCount);
    }
#endif

    [someMutableArr2 addObjectsFromArray:sortedDeletedMutableItems];
    [someMutableArr3 addObjectsFromArray:sortedInsertMutableItems];
    [someMutableArr1 addObjectsFromArray:[someMutableArr2 sortedArrayUsingSelector:@selector(inverseCompareIndexPaths:)]];
    [someMutableArr1 addObjectsFromArray:sortedMutableMoveItems];
    [someMutableArr1 addObjectsFromArray:[someMutableArr3 sortedArrayUsingSelector:@selector(compareIndexPaths:)]];
    
    NSMutableArray *layoutUpdateItems = [[NSMutableArray alloc] init];

    [layoutUpdateItems addObjectsFromArray:sortedDeletedMutableItems];
    [layoutUpdateItems addObjectsFromArray:sortedMutableMoveItems];
    [layoutUpdateItems addObjectsFromArray:sortedInsertMutableItems];
    
    
    NSMutableArray* newModel = [NSMutableArray array];
    for(NSInteger i=0;i<[oldCollectionViewData numberOfSections];i++) {
        NSMutableArray * sectionArr = [NSMutableArray array];
        for(NSInteger j=0;j< [oldCollectionViewData numberOfItemsInSection:i];j++)
            [sectionArr addObject: @([oldCollectionViewData globalIndexForItemAtIndexPath:[NSIndexPath indexPathForItem:j inSection:i]])];
        [newModel addObject:sectionArr];
    }
    
    for(TUICollectionViewUpdateItem *updateItem in layoutUpdateItems) {
        switch (updateItem.updateAction) {
            case TUICollectionUpdateActionDelete: {
                if(updateItem.isSectionOperation) {
                    [newModel removeObjectAtIndex:updateItem.indexPathBeforeUpdate.section];
                } else {
                    [(NSMutableArray*)newModel[updateItem.indexPathBeforeUpdate.section]
                     removeObjectAtIndex:updateItem.indexPathBeforeUpdate.item];
                }
            }break;
            case TUICollectionUpdateActionInsert: {
                if(updateItem.isSectionOperation) {
                    [newModel insertObject:[[NSMutableArray alloc] init]
                                   atIndex:updateItem.indexPathAfterUpdate.section];
                } else {
                    [(NSMutableArray *)newModel[updateItem.indexPathAfterUpdate.section]
                     insertObject:@(NSNotFound)
                     atIndex:updateItem.indexPathAfterUpdate.item];
                }
            }break;
                
            case TUICollectionUpdateActionMove: {
                if(updateItem.isSectionOperation) {
                    id section = newModel[updateItem.indexPathBeforeUpdate.section];
                    [newModel insertObject:section atIndex:updateItem.indexPathAfterUpdate.section];
                }
                else {
                    id object = newModel[updateItem.indexPathBeforeUpdate.section][updateItem.indexPathBeforeUpdate.item];
                    [newModel[updateItem.indexPathBeforeUpdate.section] removeObjectAtIndex:updateItem.indexPathBeforeUpdate.item];
                    [newModel[updateItem.indexPathAfterUpdate.section] insertObject:object
                                                                            atIndex:updateItem.indexPathAfterUpdate.item];
                }
            }break;
            default: break;
        }
    }
    
    NSMutableArray *oldToNewMap = [NSMutableArray arrayWithCapacity:[oldCollectionViewData numberOfItems]];
    NSMutableArray *newToOldMap = [NSMutableArray arrayWithCapacity:[_collectionViewData numberOfItems]];

    for(NSInteger i=0; i < [oldCollectionViewData numberOfItems]; i++)
        [oldToNewMap addObject:@(NSNotFound)];

    for(NSInteger i=0; i < [_collectionViewData numberOfItems]; i++)
        [newToOldMap addObject:@(NSNotFound)];
    
    for(NSInteger i=0; i < [newModel count]; i++) {
        NSMutableArray* section = newModel[i];
        for(NSInteger j=0; j<[section count];j++) {
            NSInteger newGlobalIndex = [_collectionViewData globalIndexForItemAtIndexPath:[NSIndexPath indexPathForItem:j inSection:i]];
            if([section[j] intValue] != NSNotFound)
                oldToNewMap[[section[j] intValue]] = @(newGlobalIndex);
            if(newGlobalIndex != NSNotFound)
                newToOldMap[newGlobalIndex] = section[j];
        }
    }

    self.currentUpdate = @{@"oldModel":oldCollectionViewData, @"newModel":_collectionViewData, @"oldToNewIndexMap":oldToNewMap, @"newToOldIndexMap":newToOldMap};

    [self updateWithItems:someMutableArr1];
    
    _originalInsertItems = nil;
    _originalDeleteItems = nil;
    _insertItems = nil;
    _deleteItems = nil;
    _moveItems = nil;
    _reloadItems = nil;
    self.currentUpdate = nil;
    _updateCount--;
    _collectionViewFlags.updating = NO;
    [self resumeReloads];
}


- (void)updateRowsAtIndexPaths:(NSArray *)indexPaths updateAction:(TUICollectionUpdateAction)updateAction {
    BOOL updating = _collectionViewFlags.updating;
    if(!updating) {
        [self setupCellAnimations];
    }
    
    NSMutableArray *array = [self arrayForUpdateAction:updateAction]; //returns appropriate empty array if not exists
    
    for(NSIndexPath *indexPath in indexPaths) {
        TUICollectionViewUpdateItem *updateItem = [[TUICollectionViewUpdateItem alloc] initWithAction:updateAction
                                                                                         forIndexPath:indexPath];
        [array addObject:updateItem];
    }
    
    if(!updating) [self endItemAnimations];
}


- (void)updateSections:(NSIndexSet *)sections updateAction:(TUICollectionUpdateAction)updateAction {
    BOOL updating = _collectionViewFlags.updating;
    if(updating) {
        [self setupCellAnimations];
    }
    
    NSMutableArray *updateActions = [self arrayForUpdateAction:updateAction];
    NSInteger section = [sections firstIndex];
    
    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        TUICollectionViewUpdateItem *updateItem =
        [[TUICollectionViewUpdateItem alloc] initWithAction:updateAction
                                               forIndexPath:[NSIndexPath indexPathForItem:NSNotFound
                                                                                inSection:section]];
        [updateActions addObject:updateItem];
    }];
    
    if (!updating) {
        [self endItemAnimations];
    }
}
@end