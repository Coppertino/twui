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

#import "TUICollectionView.h"

typedef enum {
    TUICollectionViewItemTypeCell,
    TUICollectionViewItemTypeSupplementaryView,
    TUICollectionViewItemTypeDecorationView
} TUICollectionViewItemType;

// The TUICollectionViewLayout class is provided as an abstract class for subclassing to define custom collection layouts.
// Defining a custom layout is an advanced operation intended for applications with complex needs.
@class TUICollectionViewLayoutAttributes, TUICollectionView;

@interface TUICollectionViewLayoutAttributes : NSObject <NSCopying>

@property (nonatomic) CGRect frame;
@property (nonatomic) CGPoint center;
@property (nonatomic) CGSize size;
@property (nonatomic) CATransform3D transform3D;
@property (nonatomic) CGFloat alpha;
@property (nonatomic) NSInteger zIndex; // default is 0
@property (nonatomic, getter=isHidden) BOOL hidden; // As an optimization, TUICollectionView might not create a view for items whose hidden attribute is YES
@property (nonatomic, strong) NSIndexPath *indexPath;

+ (instancetype)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind withIndexPath:(NSIndexPath *)indexPath;
+ (instancetype)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString *)reuseIdentifier withIndexPath:(NSIndexPath*)indexPath;

/*
 + (id)layoutAttributesForDecorationViewOfKind:(id)arg1 withIndexPath:(id)arg2;
 - (id)initialLayoutAttributesForInsertedDecorationElementOfKind:(id)arg1 atIndexPath:(id)arg2;
 - (BOOL)_isEquivalentTo:(id)arg1;
 */
@end

@interface TUICollectionViewLayout : NSObject <NSCoding>

// Methods in this class are meant to be overridden and will be called by its collection view to gather layout information.
// To get the truth on the current state of the collection view, call methods on TUICollectionView rather than these.
@property (nonatomic, unsafe_unretained, readonly) TUICollectionView *collectionView;

// Call -invalidateLayout to indicate that the collection view needs to requery the layout information.
// Subclasses must always call super if they override.
- (void)invalidateLayout;

/// @name Registering Decoration Views
- (void)registerClass:(Class)viewClass forDecorationViewWithReuseIdentifier:(NSString *)identifier;

@end


@interface TUICollectionViewLayout (SubclassingHooks)

// The collection view calls -prepareLayout once at its first layout as the first message to the layout instance.
// The collection view calls -prepareLayout again after layout is invalidated and before requerying the layout information.
// Subclasses should always call super if they override.
- (void)prepareLayout;

// TUICollectionView calls these four methods to determine the layout information.
// Implement -layoutAttributesForElementsInRect: to return layout attributes for for supplementary or decoration views, or to perform layout in an as-needed-on-screen fashion.
// Additionally, all layout subclasses should implement -layoutAttributesForItemAtIndexPath: to return layout attributes instances on demand for specific index paths.
// If the layout supports any supplementary or decoration view types, it should also implement the respective atIndexPath: methods for those types.
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect; // return an array layout attributes instances for all the views in the given rect
- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString*)identifier atIndexPath:(NSIndexPath *)indexPath;

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds; // return YES to cause the collection view to requery the layout for geometry information
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity; // return a point at which to rest after scrolling - for layouts that want snap-to-point scrolling behavior

- (CGSize)collectionViewContentSize; // the collection view calls this to update its content size any time it queries new layout information - at least one of the width and height fields must match the respective field of the collection view's bounds

@end

@interface TUICollectionViewLayout (UpdateSupportHooks)

// This method is called when there is an update with deletes/inserts to the collection view.
// It will be called prior to calling the initial/final layout attribute methods below to give the layout an opportunity to do batch computations for the insertion and deletion layout attributes.
// The updateItems parameter is an array of TUICollectionViewUpdateItem instances for each element that is moving to a new index path.
- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems;

// This method is called inside an animation block after all items have been laid out for a collection view update.
// Subclasses can use this opportunity to layout their 'layout-owned' decoration views in response to the update.
- (void)finalizeCollectionViewUpdates;

// Collection view calls these methods to determine the starting layout for animating in newly inserted views, or the ending layout for animating out deleted views
- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath*)itemIndexPath;
- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath;
- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForInsertedSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath;
- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForDeletedSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath;

@end

@interface TUICollectionViewLayout (Private)
- (void)setCollectionViewBoundsSize:(CGSize)size;
@end
