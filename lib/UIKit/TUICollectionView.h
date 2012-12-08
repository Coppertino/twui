//
//  TUICollectionView.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUIScrollView.h"
#import "NSIndexPath+TUIExtensions.h"

#import "TUICollectionViewLayout.h"
#import "TUICollectionViewFlowLayout.h"
#import "TUICollectionViewCell.h"
#import "TUICollectionViewUpdateItem.h"


typedef NS_OPTIONS(NSUInteger, TUICollectionViewScrollPosition) {
    TUICollectionViewScrollPositionNone                 = 0,

    // The vertical positions are mutually exclusive to each other, but are bitwise or-able with the horizontal scroll positions.
    // Combining positions from the same grouping (horizontal or vertical) will result in an NSInvalidArgumentException.
    TUICollectionViewScrollPositionTop                  = 1 << 0,
    TUICollectionViewScrollPositionCenteredVertically   = 1 << 1,
    TUICollectionViewScrollPositionBottom               = 1 << 2,

    // Likewise, the horizontal positions are mutually exclusive to each other.
    TUICollectionViewScrollPositionLeft                 = 1 << 3,
    TUICollectionViewScrollPositionCenteredHorizontally = 1 << 4,
    TUICollectionViewScrollPositionRight                = 1 << 5
};

// Port of Peter Steinberger's PSTCollectionView to AppKit

@interface TUICollectionView : TUIScrollView

- (id)initWithFrame:(CGRect)frame collectionViewLayout:(TUICollectionViewLayout *)layout; // the designated initializer

@property (nonatomic, strong) TUICollectionViewLayout *collectionViewLayout;
@property (nonatomic, assign) IBOutlet id <TUICollectionViewDelegate> delegate;
@property (nonatomic, assign) IBOutlet id <TUICollectionViewDataSource> dataSource;
@property (nonatomic, strong) TUIView *backgroundView; // will be automatically resized to track the size of the collection view and placed behind all cells and supplementary views.

// For each reuse identifier that the collection view will use, register either a class or a nib from which to instantiate a cell.
// If a nib is registered, it must contain exactly 1 top level object which is a TUICollectionViewCell.
// If a class is registered, it will be instantiated via alloc/initWithFrame:
- (void)registerClass:(Class)cellClass forCellWithReuseIdentifier:(NSString *)identifier;
- (void)registerClass:(Class)viewClass forSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier;
- (void)registerNib:(NSNib *)nib forCellWithReuseIdentifier:(NSString *)identifier;

// TODO: implement!
- (void)registerNib:(NSNib *)nib forSupplementaryViewOfKind:(NSString *)kind withReuseIdentifier:(NSString *)identifier;

- (id)dequeueReusableCellWithReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;
- (id)dequeueReusableSupplementaryViewOfKind:(NSString *)elementKind withReuseIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath;

// These properties control whether items can be selected, and if so, whether multiple items can be simultaneously selected.
@property (nonatomic) BOOL allowsSelection; // default is YES
@property (nonatomic) BOOL allowsMultipleSelection; // default is NO

- (NSArray *)indexPathsForSelectedItems; // returns nil or an array of selected index paths
- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(TUICollectionViewScrollPosition)scrollPosition;
- (void)deselectItemAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

- (void)reloadData; // discard the dataSource and delegate data and requery as necessary

- (void)setCollectionViewLayout:(TUICollectionViewLayout *)layout animated:(BOOL)animated; // transition from one layout to another

// Information about the current state of the collection view.

- (NSInteger)numberOfSections;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;

- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;

- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForCell:(TUICollectionViewCell *)cell;

- (TUICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)visibleCells;
- (NSArray *)indexPathsForVisibleItems;

// Interacting with the collection view.

- (void)scrollToItemAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(TUICollectionViewScrollPosition)scrollPosition animated:(BOOL)animated;

// These methods allow dynamic modification of the current set of items in the collection view
- (void)insertSections:(NSIndexSet *)sections;
- (void)deleteSections:(NSIndexSet *)sections;
- (void)reloadSections:(NSIndexSet *)sections;
- (void)moveSection:(NSInteger)section toSection:(NSInteger)newSection;

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths;
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;

- (void)performBatchUpdates:(void (^)(void))updates completion:(void (^)(void))completion; // allows multiple insert/delete/reload/move calls to be animated simultaneously. Nestable.

@end
