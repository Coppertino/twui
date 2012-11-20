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

#import "TUICollectionViewFlowLayout.h"
#import "TUICollectionView.h"
#import "TUIGridLayoutInfo.h"
#import <objc/runtime.h>

static char *kTUICachedItemRectsKey = "___item_key_";

NSString *const TUICollectionElementKindSectionHeader = @"UICollectionElementKindSectionHeader";
NSString *const TUICollectionElementKindSectionFooter = @"UICollectionElementKindSectionFooter";

NSString *const TUIFlowLayoutCommonRowHorizontalAlignmentKey = @"UIFlowLayoutCommonRowHorizontalAlignmentKey";
NSString *const TUIFlowLayoutLastRowHorizontalAlignmentKey = @"UIFlowLayoutLastRowHorizontalAlignmentKey";
NSString *const TUIFlowLayoutRowVerticalAlignmentKey = @"UIFlowLayoutRowVerticalAlignmentKey";

@implementation TUICollectionViewFlowLayout {
    TUIGridLayoutInfo *_data;
	
    struct {
        unsigned delegateSizeForItem:1;
        unsigned delegateReferenceSizeForHeader:1;
        unsigned delegateReferenceSizeForFooter:1;
        unsigned delegateInsetForSection:1;
        unsigned delegateInteritemSpacingForSection:1;
        unsigned delegateLineSpacingForSection:1;
        unsigned delegateAlignmentOptions:1;
        unsigned keepDelegateInfoWhileInvalidating:1;
        unsigned keepAllDataWhileInvalidating:1;
        unsigned layoutDataIsValid:1;
        unsigned delegateInfoIsValid:1;
    } _gridLayoutFlags;
}

#pragma mark - Initialization

- (void)commonInit {
    _itemSize = CGSizeMake(50.f, 50.f);
    _minimumLineSpacing = 10.f;
    _minimumInteritemSpacing = 10.f;
    _sectionInset = TUIEdgeInsetsZero;
    _scrollDirection = TUICollectionViewScrollDirectionVertical;
    _headerReferenceSize = CGSizeZero;
    _footerReferenceSize = CGSizeZero;
}

- (id)init {
    if((self = [super init])) {
        [self commonInit];

        // set default values for row alignment.
        _rowAlignmentOptions = @{
        TUIFlowLayoutCommonRowHorizontalAlignmentKey : @(TUIFlowLayoutHorizontalAlignmentJustify),
        TUIFlowLayoutLastRowHorizontalAlignmentKey : @(TUIFlowLayoutHorizontalAlignmentJustify),
        // TODO: those values are some enum. find out what what is.
        TUIFlowLayoutRowVerticalAlignmentKey : @(1),
        };

        // custom ivars
        objc_setAssociatedObject(self, kTUICachedItemRectsKey, [NSMutableDictionary dictionary], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return self;
}

#pragma mark - TUICollectionViewLayout

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *layoutAttributesArray = [NSMutableArray array];
	
    for(TUIGridLayoutSection *section in _data.sections) {
        if(CGRectIntersectsRect(section.frame, rect)) {
			
            // if we have fixed size, calculate item frames only once.
            // this also uses the default TUIFlowLayoutCommonRowHorizontalAlignmentKey alignment
            // for the last row. (we want this effect!)
            NSMutableDictionary *rectCache = objc_getAssociatedObject(self, kTUICachedItemRectsKey);
            NSUInteger sectionIndex = [_data.sections indexOfObjectIdenticalTo:section];

			CGRect normalizedHeaderFrame = section.headerFrame;
			normalizedHeaderFrame.origin.x += section.frame.origin.x;
			normalizedHeaderFrame.origin.y += section.frame.origin.y;
			
			if (!CGRectIsEmpty(normalizedHeaderFrame) && CGRectIntersectsRect(normalizedHeaderFrame, rect)) {
				TUICollectionViewLayoutAttributes *layoutAttributes = [TUICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:TUICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex]];
				
				layoutAttributes.frame = normalizedHeaderFrame;
				[layoutAttributesArray addObject:layoutAttributes];
			}

            NSArray *itemRects = rectCache[@(sectionIndex)];
            if(!itemRects && section.fixedItemSize && [section.rows count]) {
                itemRects = [(section.rows)[0] itemRects];
                if(itemRects) rectCache[@(sectionIndex)] = itemRects;
            }
			
			for(TUIGridLayoutRow *row in section.rows) {
                CGRect normalizedRowFrame = row.rowFrame;
                normalizedRowFrame.origin.x += section.frame.origin.x;
                normalizedRowFrame.origin.y += section.frame.origin.y;
				
                if (CGRectIntersectsRect(normalizedRowFrame, rect)) {
                    // TODO be more fine-graind for items
					
                    for(NSInteger itemIndex = 0; itemIndex < row.itemCount; itemIndex++) {
                        TUICollectionViewLayoutAttributes *layoutAttributes;
                        NSUInteger sectionItemIndex;
                        CGRect itemFrame;
						
                        if(row.fixedItemSize) {
                            itemFrame = [itemRects[itemIndex] rectValue];
                            sectionItemIndex = row.index * section.itemsByRowCount + itemIndex;
                        } else {
                            TUIGridLayoutItem *item = row.items[itemIndex];
                            sectionItemIndex = [section.items indexOfObjectIdenticalTo:item];
                            itemFrame = item.itemFrame;
                        }
						
                        layoutAttributes = [TUICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:[NSIndexPath indexPathForItem:sectionItemIndex inSection:sectionIndex]];
                        layoutAttributes.frame = CGRectMake(normalizedRowFrame.origin.x + itemFrame.origin.x, normalizedRowFrame.origin.y + itemFrame.origin.y, itemFrame.size.width, itemFrame.size.height);
                        [layoutAttributesArray addObject:layoutAttributes];
                    }
                }
            }

			CGRect normalizedFooterFrame = section.footerFrame;
			normalizedFooterFrame.origin.x += section.frame.origin.x;
			normalizedFooterFrame.origin.y += section.frame.origin.y;
			
			if (!CGRectIsEmpty(normalizedFooterFrame) && CGRectIntersectsRect(normalizedFooterFrame, rect)) {
				TUICollectionViewLayoutAttributes *layoutAttributes = [TUICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:TUICollectionElementKindSectionFooter withIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex]];
				
				layoutAttributes.frame = normalizedFooterFrame;
				[layoutAttributesArray addObject:layoutAttributes];
			}
        }
    }
    return layoutAttributesArray;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    TUIGridLayoutSection *section = _data.sections[indexPath.section];
    TUIGridLayoutRow *row = nil;
    CGRect itemFrame = CGRectZero;

    if(section.fixedItemSize && indexPath.item / section.itemsByRowCount < (NSInteger)[section.rows count]) {
        row = section.rows[indexPath.item / section.itemsByRowCount];
        NSUInteger itemIndex = indexPath.item % section.itemsByRowCount;
        NSArray *itemRects = [row itemRects];
        itemFrame = [itemRects[itemIndex] rectValue];
    } else if (indexPath.item < (NSInteger)[section.items count]) {
        TUIGridLayoutItem *item = section.items[indexPath.item];
        row = item.rowObject;
        itemFrame = item.itemFrame;
    }

    TUICollectionViewLayoutAttributes *layoutAttributes = [TUICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

    // calculate item rect
    CGRect normalizedRowFrame = row.rowFrame;
    normalizedRowFrame.origin.x += section.frame.origin.x;
    normalizedRowFrame.origin.y += section.frame.origin.y;
    layoutAttributes.frame = CGRectMake(normalizedRowFrame.origin.x + itemFrame.origin.x, normalizedRowFrame.origin.y + itemFrame.origin.y, itemFrame.size.width, itemFrame.size.height);

    return layoutAttributes;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    NSUInteger sectionIndex = indexPath.section;

    if(sectionIndex < _data.sections.count) {
        TUIGridLayoutSection *section = _data.sections[sectionIndex];
        CGRect normalizedHeaderFrame = section.headerFrame;

        if(!CGRectIsEmpty(normalizedHeaderFrame)) {
            normalizedHeaderFrame.origin.x += section.frame.origin.x;
            normalizedHeaderFrame.origin.y += section.frame.origin.y;

            TUICollectionViewLayoutAttributes *layoutAttributes = [TUICollectionViewLayoutAttributes layoutAttributesForSupplementaryViewOfKind:TUICollectionElementKindSectionHeader withIndexPath:[NSIndexPath indexPathForItem:0 inSection:sectionIndex]];
            layoutAttributes.frame = normalizedHeaderFrame;

            return layoutAttributes;
        }
    }

    return nil;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString*)identifier atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (CGSize)collectionViewContentSize {
    return _data.contentSize;
}

#pragma mark - Invalidating Layout

- (void)invalidateLayout {
    objc_setAssociatedObject(self, kTUICachedItemRectsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    // we need to recalculate on width changes
    return ((self.collectionView.bounds.size.width != newBounds.size.width &&
			 self.scrollDirection == TUICollectionViewScrollDirectionHorizontal) ||
			(self.collectionView.bounds.size.height != newBounds.size.height &&
			 self.scrollDirection == TUICollectionViewScrollDirectionVertical));
}

// return a point at which to rest after scrolling - for layouts that want snap-to-point scrolling behavior
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    return proposedContentOffset;
}

- (void)prepareLayout {
    _data = [TUIGridLayoutInfo new]; // clear old layout data
    _data.horizontal = self.scrollDirection == TUICollectionViewScrollDirectionHorizontal;
	
    CGSize collectionViewSize = self.collectionView.bounds.size;
    _data.dimension = _data.horizontal ? collectionViewSize.height : collectionViewSize.width;
    _data.rowAlignmentOptions = _rowAlignmentOptions;
    
	[self fetchItemsInfo];
}

#pragma mark - Private

- (void)fetchItemsInfo {
    [self getSizingInfos];
    [self updateItemsLayout];
}

// get size of all items (if delegate is implemented)
- (void)getSizingInfos {
    NSAssert([_data.sections count] == 0, @"Grid layout is already populated?");

    id <TUICollectionViewDelegateFlowLayout> flowDataSource = (id <TUICollectionViewDelegateFlowLayout>)self.collectionView.delegate;

    BOOL implementsSizeDelegate = [flowDataSource respondsToSelector:@selector(collectionView:layout:sizeForItemAtIndexPath:)];
	BOOL implementsHeaderReferenceDelegate = [flowDataSource respondsToSelector:@selector(collectionView:layout:referenceSizeForHeaderInSection:)];
	BOOL implementsFooterReferenceDelegate = [flowDataSource respondsToSelector:@selector(collectionView:layout:referenceSizeForFooterInSection:)];

    NSUInteger numberOfSections = [self.collectionView numberOfSections];
    for (NSUInteger section = 0; section < numberOfSections; section++) {
        TUIGridLayoutSection *layoutSection = [_data addSection];
        layoutSection.verticalInterstice = _data.horizontal ? self.minimumInteritemSpacing : self.minimumLineSpacing;
        layoutSection.horizontalInterstice = !_data.horizontal ? self.minimumInteritemSpacing : self.minimumLineSpacing;

        if ([flowDataSource respondsToSelector:@selector(collectionView:layout:insetForSectionAtIndex:)]) {
            layoutSection.sectionMargins = [flowDataSource collectionView:self.collectionView layout:self insetForSectionAtIndex:section];
        } else {
            layoutSection.sectionMargins = self.sectionInset;
        }

        if ([flowDataSource respondsToSelector:@selector(collectionView:layout:minimumLineSpacingForSectionAtIndex:)]) {
            CGFloat minimumLineSpacing = [flowDataSource collectionView:self.collectionView layout:self minimumLineSpacingForSectionAtIndex:section];
            if (_data.horizontal) {
                layoutSection.horizontalInterstice = minimumLineSpacing;
            }else {
                layoutSection.verticalInterstice = minimumLineSpacing;
            }
        }

        if ([flowDataSource respondsToSelector:@selector(collectionView:layout:minimumInteritemSpacingForSectionAtIndex:)]) {
            CGFloat minimumInterimSpacing = [flowDataSource collectionView:self.collectionView layout:self minimumInteritemSpacingForSectionAtIndex:section];
            if (_data.horizontal) {
                layoutSection.verticalInterstice = minimumInterimSpacing;
            }else {
                layoutSection.horizontalInterstice = minimumInterimSpacing;
            }
        }

		CGSize headerReferenceSize;
		if (implementsHeaderReferenceDelegate) {
			headerReferenceSize = [flowDataSource collectionView:self.collectionView layout:self referenceSizeForHeaderInSection:section];
		} else {
			headerReferenceSize = self.headerReferenceSize;
		}
		layoutSection.headerDimension = _data.horizontal ? headerReferenceSize.width : headerReferenceSize.height;

		CGSize footerReferenceSize;
		if (implementsFooterReferenceDelegate) {
			footerReferenceSize = [flowDataSource collectionView:self.collectionView layout:self referenceSizeForFooterInSection:section];
		} else {
			footerReferenceSize = self.footerReferenceSize;
		}
		layoutSection.footerDimension = _data.horizontal ? footerReferenceSize.width : footerReferenceSize.height;

        NSUInteger numberOfItems = [self.collectionView numberOfItemsInSection:section];

        // if delegate implements size delegate, query it for all items
        if (implementsSizeDelegate) {
            for (NSUInteger item = 0; item < numberOfItems; item++) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForItem:item inSection:section];
                CGSize itemSize = implementsSizeDelegate ? [flowDataSource collectionView:self.collectionView layout:self sizeForItemAtIndexPath:indexPath] : self.itemSize;

                TUIGridLayoutItem *layoutItem = [layoutSection addItem];
                layoutItem.itemFrame = (CGRect){.size=itemSize};
            }
            // if not, go the fast path
        }else {
            layoutSection.fixedItemSize = YES;
            layoutSection.itemSize = self.itemSize;
            layoutSection.itemsCount = numberOfItems;
        }
    }
}

- (void)updateItemsLayout {
    CGSize contentSize = CGSizeZero;
    for (TUIGridLayoutSection *section in _data.sections) {
        [section computeLayout];

        // update section offset to make frame absolute (section only calculates relative)
        CGRect sectionFrame = section.frame;
        if (_data.horizontal) {
            sectionFrame.origin.x += contentSize.width;
            contentSize.width += section.frame.size.width + section.frame.origin.x;
            contentSize.height = fmaxf(contentSize.height, sectionFrame.size.height + section.frame.origin.y);
        } else {
            sectionFrame.origin.y += contentSize.height;
            contentSize.height += sectionFrame.size.height + section.frame.origin.y;
            contentSize.width = fmaxf(contentSize.width, sectionFrame.size.width + section.frame.origin.x);
        }
        section.frame = sectionFrame;
    }
    _data.contentSize = contentSize;
}

@end
