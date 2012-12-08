//
//  UICollectionViewFlowLayout.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUICollectionViewLayout.h"
#import "TUIGeometry.h"

extern NSString *const TUICollectionElementKindSectionHeader;
extern NSString *const TUICollectionElementKindSectionFooter;

typedef enum TUICollectionViewScrollDirection : NSInteger {
    TUICollectionViewScrollDirectionVertical,
    TUICollectionViewScrollDirectionHorizontal
} TUICollectionViewScrollDirection;

@class TUIGridLayoutInfo;

@interface TUICollectionViewFlowLayout : TUICollectionViewLayout

@property (nonatomic) CGFloat minimumLineSpacing;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGSize itemSize; // for the cases the delegate method is not implemented
@property (nonatomic) TUICollectionViewScrollDirection scrollDirection; // default is TUICollectionViewScrollDirectionVertical
@property (nonatomic) CGSize headerReferenceSize;
@property (nonatomic) CGSize footerReferenceSize;

@property (nonatomic) TUIEdgeInsets sectionInset;

/*
 Row alignment options exits in the official UICollectionView, but hasn't been made public API.
 
 Here's a snippet to test this on UICollectionView:

 NSMutableDictionary *rowAlign = [[flowLayout valueForKey:@"_rowAlignmentsOptionsDictionary"] mutableCopy];
 rowAlign[@"UIFlowLayoutCommonRowHorizontalAlignmentKey"] = @(1);
 rowAlign[@"UIFlowLayoutLastRowHorizontalAlignmentKey"] = @(3);
 [flowLayout setValue:rowAlign forKey:@"_rowAlignmentsOptionsDictionary"];
 */
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;

@end

// @steipete addition, private API in UICollectionViewFlowLayout
extern NSString *const TUIFlowLayoutCommonRowHorizontalAlignmentKey;
extern NSString *const TUIFlowLayoutLastRowHorizontalAlignmentKey;
extern NSString *const TUIFlowLayoutRowVerticalAlignmentKey;

typedef NS_ENUM(NSInteger, TUIFlowLayoutHorizontalAlignment) {
    TUIFlowLayoutHorizontalAlignmentLeft,
    TUIFlowLayoutHorizontalAlignmentCentered,
    TUIFlowLayoutHorizontalAlignmentRight,
    TUIFlowLayoutHorizontalAlignmentJustify // 3; default except for the last row
};
// TODO: settings for UIFlowLayoutRowVerticalAlignmentKey

@protocol TUICollectionViewDelegate;
@class TUICollectionView;

@protocol TUICollectionViewDelegateFlowLayout <TUICollectionViewDelegate>
@optional

- (CGSize)collectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath;
- (TUIEdgeInsets)collectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section;
- (CGFloat)collectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section;
- (CGFloat)collectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section;
- (CGSize)collectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout*)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section;
- (CGSize)collectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout*)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section;

@end

/*
@interface TUICollectionViewFlowLayout (Private)

- (CGSize)synchronizeLayout;

// For items being inserted or deleted, the collection view calls some different methods, which you should override to provide the appropriate layout information.
- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForFooterInInsertedSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForHeaderInInsertedSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForInsertedItemAtIndexPath:(NSIndexPath *)indexPath;
- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForFooterInDeletedSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForHeaderInDeletedSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForDeletedItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)_updateItemsLayout;
- (void)_getSizingInfos;
- (void)_updateDelegateFlags;

- (TUICollectionViewLayoutAttributes *)layoutAttributesForFooterInSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForHeaderInSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath usingData:(id)data;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForFooterInSection:(NSInteger)section usingData:(id)data;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForHeaderInSection:(NSInteger)section usingData:(id)data;

- (id)indexesForSectionFootersInRect:(CGRect)rect;
- (id)indexesForSectionHeadersInRect:(CGRect)rect;
- (id)indexPathsForItemsInRect:(CGRect)rect usingData:(id)arg2;
- (id)indexesForSectionFootersInRect:(CGRect)rect usingData:(id)arg2;
- (id)indexesForSectionHeadersInRect:(CGRect)arg1 usingData:(id)arg2;
- (CGRect)_frameForItemAtSection:(int)arg1 andRow:(int)arg2 usingData:(id)arg3;
- (CGRect)_frameForFooterInSection:(int)arg1 usingData:(id)arg2;
- (CGRect)_frameForHeaderInSection:(int)arg1 usingData:(id)arg2;
- (void)_invalidateLayout;
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)arg1;
- (TUICollectionViewLayoutAttributes *)_layoutAttributesForItemsInRect:(CGRect)arg1;
- (CGSize)collectionViewContentSize;
- (void)finalizeCollectionViewUpdates;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath;
- (void)_invalidateButKeepDelegateInfo;
- (void)_invalidateButKeepAllInfo;
- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)arg1;
- (id)layoutAttributesForElementsInRect:(CGRect)arg1;
- (void)invalidateLayout;
- (id)layoutAttributesForItemAtIndexPath:(id)arg1;

@end
*/
