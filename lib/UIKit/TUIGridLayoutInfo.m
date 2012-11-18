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

#import "TUIGridLayoutInfo.h"
#import "TUICollectionView.h"
#import "TUICollectionViewFlowLayout.h"

@interface TUIGridLayoutInfo() {
    NSMutableArray *_sections;
    CGRect _visibleBounds;
    CGSize _layoutSize;
    BOOL _isValid;
}
@property (nonatomic, strong) NSMutableArray *sections;
@end

@implementation TUIGridLayoutInfo

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _sections = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p dimension:%.1f horizontal:%d contentSize:%@ sections:%@>", NSStringFromClass([self class]), self, self.dimension, self.horizontal, NSStringFromSize(self.contentSize), self.sections];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (TUIGridLayoutInfo *)snapshot {
    TUIGridLayoutInfo *layoutInfo = [[self class] new];
    layoutInfo.sections = self.sections;
    layoutInfo.rowAlignmentOptions = self.rowAlignmentOptions;
    layoutInfo.usesFloatingHeaderFooter = self.usesFloatingHeaderFooter;
    layoutInfo.dimension = self.dimension;
    layoutInfo.horizontal = self.horizontal;
    layoutInfo.leftToRight = self.leftToRight;
    layoutInfo.contentSize = self.contentSize;
    return layoutInfo;
}

- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath {
    TUIGridLayoutSection *section = self.sections[indexPath.section];
    CGRect itemFrame;
    if (section.fixedItemSize) {
        itemFrame = (CGRect){.size=section.itemSize};
    }else {
        itemFrame = [section.items[indexPath.item] itemFrame];
    }
    return itemFrame;
}

- (id)addSection {
    TUIGridLayoutSection *section = [TUIGridLayoutSection new];
    section.rowAlignmentOptions = self.rowAlignmentOptions;
    section.layoutInfo = self;
    [_sections addObject:section];
    [self invalidate:NO];
    return section;
}

- (void)invalidate:(BOOL)arg {
    _isValid = NO;
}

@end

@implementation TUIGridLayoutItem

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p itemFrame:%@>", NSStringFromClass([self class]), self, NSStringFromRect(self.itemFrame)];
}

@end

@interface TUIGridLayoutRow() {
    NSMutableArray *_items;
    BOOL _isValid;
    int _verticalAlignement;
    int _horizontalAlignement;
}
@property (nonatomic, strong) NSArray *items;
@end

@implementation TUIGridLayoutRow

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _items = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p frame:%@ index:%ld items:%@>", NSStringFromClass([self class]), self, NSStringFromRect(self.rowFrame), self.index, self.items];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)invalidate {
    _isValid = NO;
    _rowSize = CGSizeZero;
    _rowFrame = CGRectZero;
}

- (NSArray *)itemRects {
    return [self layoutRowAndGenerateRectArray:YES];
}

- (void)layoutRow {
    [self layoutRowAndGenerateRectArray:NO];
}

- (NSArray *)layoutRowAndGenerateRectArray:(BOOL)generateRectArray {
    NSMutableArray *rects = generateRectArray ? [NSMutableArray array] : nil;
    if (!_isValid || generateRectArray) {
        // properties for aligning
        BOOL isHorizontal = self.section.layoutInfo.horizontal;
        BOOL isLastRow = self.section.indexOfIncompleteRow == self.index;
        TUIFlowLayoutHorizontalAlignment horizontalAlignment = [self.section.rowAlignmentOptions[isLastRow ? TUIFlowLayoutLastRowHorizontalAlignmentKey : TUIFlowLayoutCommonRowHorizontalAlignmentKey] intValue];
		
        // calculate space that's left over if we would align it from left to right.
        CGFloat leftOverSpace = self.section.layoutInfo.dimension;
        if (isHorizontal) {
            leftOverSpace -= self.section.sectionMargins.top + self.section.sectionMargins.bottom;
        }else {
            leftOverSpace -= self.section.sectionMargins.left + self.section.sectionMargins.right;
        }
		
        // calculate the space that we have left after counting all items.
        // UICollectionView is smart and lays out items like they would have been placed on a full row
        // So we need to calculate the "usedItemCount" with using the last item as a reference size.
        // This allows us to correctly justify-place the items in the grid.
        NSUInteger usedItemCount = 0;
        NSInteger itemIndex = 0;
        BOOL canFitMoreItems = itemIndex < self.itemCount;
        while (itemIndex < self.itemCount || canFitMoreItems) {
            if (!self.fixedItemSize) {
                TUIGridLayoutItem *item = self.items[MIN(itemIndex, self.itemCount-1)];
                leftOverSpace -= isHorizontal ? item.itemFrame.size.height : item.itemFrame.size.width;
                canFitMoreItems = isHorizontal ? leftOverSpace > item.itemFrame.size.height : leftOverSpace > item.itemFrame.size.width;
            }else {
                leftOverSpace -= isHorizontal ? self.section.itemSize.height : self.section.itemSize.width;
                canFitMoreItems = isHorizontal ? leftOverSpace > self.section.itemSize.height : leftOverSpace > self.section.itemSize.width;
            }
            // separator starts after first item
            if (itemIndex > 0) {
                leftOverSpace -= isHorizontal ? self.section.verticalInterstice : self.section.horizontalInterstice;
            }
            itemIndex++;
            usedItemCount = itemIndex;
        }
		
        CGPoint itemOffset = CGPointZero;
        if (horizontalAlignment == TUIFlowLayoutHorizontalAlignmentRight) {
            itemOffset.x += leftOverSpace;
        }else if(horizontalAlignment == TUIFlowLayoutHorizontalAlignmentCentered) {
            itemOffset.x += leftOverSpace/2;
        }
		
        // calculate row frame as union of all items
        CGRect frame = CGRectZero;
        CGRect itemFrame = (CGRect){.size=self.section.itemSize};
        for (itemIndex = 0; itemIndex < self.itemCount; itemIndex++) {
            TUIGridLayoutItem *item = nil;
            if (!self.fixedItemSize) {
                item = self.items[itemIndex];
                itemFrame = [item itemFrame];
            }
            if (isHorizontal) {
                itemFrame.origin.y = itemOffset.y;
                itemOffset.y += itemFrame.size.height + self.section.verticalInterstice;
                if (horizontalAlignment == TUIFlowLayoutHorizontalAlignmentJustify) {
                    itemOffset.y += leftOverSpace/(CGFloat)(usedItemCount-1);
                }
            }else {
                itemFrame.origin.x = itemOffset.x;
                itemOffset.x += itemFrame.size.width + self.section.horizontalInterstice;
                if (horizontalAlignment == TUIFlowLayoutHorizontalAlignmentJustify) {
                    itemOffset.x += leftOverSpace/(CGFloat)(usedItemCount-1);
                }
            }
            item.itemFrame = CGRectIntegral(itemFrame); // might call nil; don't care
            [rects addObject:[NSValue valueWithRect:CGRectIntegral(itemFrame)]];
            frame = CGRectUnion(frame, itemFrame);
        }
        _rowSize = frame.size;
        //        _rowFrame = frame; // set externally
        _isValid = YES;
    }
    return rects;
}

- (void)addItem:(TUIGridLayoutItem *)item {
    [_items addObject:item];
    item.rowObject = self;
    [self invalidate];
}

- (TUIGridLayoutRow *)snapshot {
    TUIGridLayoutRow *snapshotRow = [[self class] new];
    snapshotRow.section = self.section;
    snapshotRow.items = self.items;
    snapshotRow.rowSize = self.rowSize;
    snapshotRow.rowFrame = self.rowFrame;
    snapshotRow.index = self.index;
    snapshotRow.complete = self.complete;
    snapshotRow.fixedItemSize = self.fixedItemSize;
    snapshotRow.itemCount = self.itemCount;
    return snapshotRow;
}

- (TUIGridLayoutRow *)copyFromSection:(TUIGridLayoutSection *)section {
    return nil; // ???
}

- (NSInteger)itemCount {
    if(self.fixedItemSize) {
        return _itemCount;
    }else {
        return [self.items count];
    }
}

@end

@interface TUIGridLayoutSection() {
    NSMutableArray *_items;
    NSMutableArray *_rows;
    BOOL _isValid;
}
@property (nonatomic, strong) NSArray *items;
@property (nonatomic, strong) NSArray *rows;
@property (nonatomic, assign) CGFloat otherMargin;
@property (nonatomic, assign) CGFloat beginMargin;
@property (nonatomic, assign) CGFloat endMargin;
@property (nonatomic, assign) CGFloat actualGap;
@property (nonatomic, assign) CGFloat lastRowBeginMargin;
@property (nonatomic, assign) CGFloat lastRowEndMargin;
@property (nonatomic, assign) CGFloat lastRowActualGap;
@property (nonatomic, assign) BOOL lastRowIncomplete;
@property (nonatomic, assign) NSInteger itemsByRowCount;
@property (nonatomic, assign) NSInteger indexOfIncompleteRow;
@end

@implementation TUIGridLayoutSection

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _items = [NSMutableArray new];
        _rows = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p itemCount:%ld frame:%@ rows:%@>", NSStringFromClass([self class]), self, self.itemsCount, NSStringFromRect(self.frame), self.rows];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)invalidate {
    _isValid = NO;
    self.rows = [NSMutableArray array];
}

- (void)computeLayout {
    if (!_isValid) {
        NSAssert([self.rows count] == 0, @"No rows shall be at this point.");
		
        // iterate over all items, turning them into rows.
        CGSize sectionSize = CGSizeZero;
        NSInteger rowIndex = 0;
        NSInteger itemIndex = 0;
        NSInteger itemsByRowCount = 0;
        CGFloat dimensionLeft = 0;
        TUIGridLayoutRow *row = nil;
        // get dimension and compensate for section margin
		CGFloat headerFooterDimension = self.layoutInfo.dimension;
        CGFloat dimension = headerFooterDimension;
		
        if (self.layoutInfo.horizontal) {
            dimension -= self.sectionMargins.top + self.sectionMargins.bottom;
			self.headerFrame = CGRectMake(sectionSize.width, 0, self.headerDimension, headerFooterDimension);
			sectionSize.width += self.headerDimension + self.sectionMargins.left;
        }else {
            dimension -= self.sectionMargins.left + self.sectionMargins.right;
			self.headerFrame = CGRectMake(0, sectionSize.height, headerFooterDimension, self.headerDimension);
			sectionSize.height += self.headerDimension + self.sectionMargins.top;
        }
		
        float spacing = self.layoutInfo.horizontal ? self.verticalInterstice : self.horizontalInterstice;
        
        do {
            BOOL finishCycle = itemIndex >= self.itemsCount;
            // TODO: fast path could even remove row creation and just calculate on the fly
            TUIGridLayoutItem *item = nil;
            if (!finishCycle) item = self.fixedItemSize ? nil : self.items[itemIndex];
			
            CGSize itemSize = self.fixedItemSize ? self.itemSize : item.itemFrame.size;
            CGFloat itemDimension = self.layoutInfo.horizontal ? itemSize.height : itemSize.width;
            // first item of each row does not add spacing
            if (itemsByRowCount > 0) itemDimension += spacing;
            if (dimensionLeft < itemDimension || finishCycle) {
                // finish current row
                if (row) {
                    // compensate last row
                    self.itemsByRowCount = fmaxf(itemsByRowCount, self.itemsByRowCount);
                    row.itemCount = itemsByRowCount;
					
                    // if current row is done but there are still items left, increase the incomplete row counter
                    if (!finishCycle) self.indexOfIncompleteRow = rowIndex;
					
                    [row layoutRow];
					
                    if (self.layoutInfo.horizontal) {
                        row.rowFrame = CGRectMake(sectionSize.width, self.sectionMargins.top, row.rowSize.width, row.rowSize.height);
                        sectionSize.height = fmaxf(row.rowSize.height, sectionSize.height);
                        sectionSize.width += row.rowSize.width + (finishCycle ? 0 : self.horizontalInterstice);
                    }else {
                        row.rowFrame = CGRectMake(self.sectionMargins.left, sectionSize.height, row.rowSize.width, row.rowSize.height);
                        sectionSize.height += row.rowSize.height + (finishCycle ? 0 : self.verticalInterstice);
                        sectionSize.width = fmaxf(row.rowSize.width, sectionSize.width);
                    }
                }
                // add new rows until the section is fully layouted
                if (!finishCycle) {
                    // create new row
                    row.complete = YES; // finish up current row
                    row = [self addRow];
                    row.fixedItemSize = self.fixedItemSize;
                    row.index = rowIndex;
                    self.indexOfIncompleteRow = rowIndex;
                    rowIndex++;
                    // convert an item from previous row to current, remove spacing for first item
                    if (itemsByRowCount > 0) itemDimension -= spacing;
                    dimensionLeft = dimension - itemDimension;
                    itemsByRowCount = 0;
                }
            } else {
                dimensionLeft -= itemDimension;
            }
			
            // add item on slow path
            if (item) [row addItem:item];
			
            itemIndex++;
            itemsByRowCount++;
        }while (itemIndex <= self.itemsCount); // cycle once more to finish last row
		
        if (self.layoutInfo.horizontal) {
			sectionSize.width += self.sectionMargins.right;
			self.footerFrame = CGRectMake(sectionSize.width, 0, self.footerDimension, headerFooterDimension);
			sectionSize.width += self.footerDimension;
        }else {
			sectionSize.height += self.sectionMargins.bottom;
			self.footerFrame = CGRectMake(0, sectionSize.height, headerFooterDimension, self.footerDimension);
			sectionSize.height += self.footerDimension;
        }
		
        _frame = CGRectMake(0, 0, sectionSize.width, sectionSize.height);
        _isValid = YES;
    }
}

- (void)recomputeFromIndex:(NSInteger)index {
    // TODO: use index.
    [self invalidate];
    [self computeLayout];
}

- (TUIGridLayoutItem *)addItem {
    TUIGridLayoutItem *item = [TUIGridLayoutItem new];
    item.section = self;
    [_items addObject:item];
    return item;
}

- (TUIGridLayoutRow *)addRow {
    TUIGridLayoutRow *row = [TUIGridLayoutRow new];
    row.section = self;
    [_rows addObject:row];
    return row;
}

- (TUIGridLayoutSection *)snapshot {
    TUIGridLayoutSection *snapshotSection = [TUIGridLayoutSection new];
    snapshotSection.items = [self.items copy];
    snapshotSection.rows = [self.items copy];
    snapshotSection.verticalInterstice = self.verticalInterstice;
    snapshotSection.horizontalInterstice = self.horizontalInterstice;
    snapshotSection.sectionMargins = self.sectionMargins;
    snapshotSection.frame = self.frame;
    snapshotSection.headerFrame = self.headerFrame;
    snapshotSection.footerFrame = self.footerFrame;
    snapshotSection.headerDimension = self.headerDimension;
    snapshotSection.footerDimension = self.footerDimension;
    snapshotSection.layoutInfo = self.layoutInfo;
    snapshotSection.rowAlignmentOptions = self.rowAlignmentOptions;
    snapshotSection.fixedItemSize = self.fixedItemSize;
    snapshotSection.itemSize = self.itemSize;
    snapshotSection.itemsCount = self.itemsCount;
    snapshotSection.otherMargin = self.otherMargin;
    snapshotSection.beginMargin = self.beginMargin;
    snapshotSection.endMargin = self.endMargin;
    snapshotSection.actualGap = self.actualGap;
    snapshotSection.lastRowBeginMargin = self.lastRowBeginMargin;
    snapshotSection.lastRowEndMargin = self.lastRowEndMargin;
    snapshotSection.lastRowActualGap = self.lastRowActualGap;
    snapshotSection.lastRowIncomplete = self.lastRowIncomplete;
    snapshotSection.itemsByRowCount = self.itemsByRowCount;
    snapshotSection.indexOfIncompleteRow = self.indexOfIncompleteRow;
    return snapshotSection;
}

- (NSInteger)itemsCount {
    return self.fixedItemSize ? _itemsCount : [self.items count];
}

@end
