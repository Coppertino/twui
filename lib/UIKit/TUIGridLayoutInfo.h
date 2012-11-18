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

#import <Foundation/Foundation.h>
#import "TUIGeometry.h"

@class TUIGridLayoutItem;
@class TUIGridLayoutRow;
@class TUIGridLayoutSection;

/*
 Every TUICollectionViewLayout has a TUIGridLayoutInfo attached.
 Is used extensively in TUICollectionViewFlowLayout.
 */
@interface TUIGridLayoutInfo : NSObject

@property (nonatomic, strong, readonly) NSArray *sections;
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;
@property (nonatomic, assign) BOOL usesFloatingHeaderFooter;

// Vertical/horizontal dimension (depending on horizontal)
// Used to create row objects
@property (nonatomic, assign) CGFloat dimension;

@property (nonatomic, assign) BOOL horizontal;
@property (nonatomic, assign) BOOL leftToRight;
@property (nonatomic, assign) CGSize contentSize;

// Frame for specific TUIGridLayoutItem.
- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath;

// Add new section. Invalidates layout.
- (TUIGridLayoutSection *)addSection;

// forces the layout to recompute on next access
// TODO; what's the parameter for?
- (void)invalidate:(BOOL)arg;

// Make a copy of the current state.
- (TUIGridLayoutInfo *)snapshot;

@end

// Represents a single grid item; only created for non-uniform-sized grids.
@interface TUIGridLayoutItem : NSObject

@property (nonatomic, unsafe_unretained) TUIGridLayoutSection *section;
@property (nonatomic, unsafe_unretained) TUIGridLayoutRow *rowObject;
@property (nonatomic, assign) CGRect itemFrame;

@end

@interface TUIGridLayoutRow : NSObject

@property (nonatomic, unsafe_unretained) TUIGridLayoutSection *section;
@property (nonatomic, strong, readonly) NSArray *items;
@property (nonatomic, assign) CGSize rowSize;
@property (nonatomic, assign) CGRect rowFrame;
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, assign) BOOL complete;
@property (nonatomic, assign) BOOL fixedItemSize;

// @steipete addition for row-fastPath
@property (nonatomic, assign) NSInteger itemCount;

//- (TUIGridLayoutRow *)copyFromSection:(TUIGridLayoutSection *)section; // ???

// Add new item to items array.
- (void)addItem:(TUIGridLayoutItem *)item;

// Layout current row (if invalid)
- (void)layoutRow;

// @steipete: Helper to save code in TUICollectionViewFlowLayout.
// Returns the item rects when fixedItemSize is enabled.
- (NSArray *)itemRects;

//  Set current row frame invalid.
- (void)invalidate;

// Copy a snapshot of the current row data
- (TUIGridLayoutRow *)snapshot;

@end

@interface TUIGridLayoutSection : NSObject

@property (nonatomic, strong, readonly) NSArray *items;
@property (nonatomic, strong, readonly) NSArray *rows;

// fast path for equal-size items
@property (nonatomic, assign) BOOL fixedItemSize;
@property (nonatomic, assign) CGSize itemSize;
// depending on fixedItemSize, this either is a _ivar or queries items.
@property (nonatomic, assign) NSInteger itemsCount;

@property (nonatomic, assign) CGFloat verticalInterstice;
@property (nonatomic, assign) CGFloat horizontalInterstice;
@property (nonatomic, assign) TUIEdgeInsets sectionMargins;

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, assign) CGRect headerFrame;
@property (nonatomic, assign) CGRect footerFrame;
@property (nonatomic, assign) CGFloat headerDimension;
@property (nonatomic, assign) CGFloat footerDimension;
@property (nonatomic, unsafe_unretained) TUIGridLayoutInfo *layoutInfo;
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;

@property (nonatomic, assign, readonly) CGFloat otherMargin;
@property (nonatomic, assign, readonly) CGFloat beginMargin;
@property (nonatomic, assign, readonly) CGFloat endMargin;
@property (nonatomic, assign, readonly) CGFloat actualGap;
@property (nonatomic, assign, readonly) CGFloat lastRowBeginMargin;
@property (nonatomic, assign, readonly) CGFloat lastRowEndMargin;
@property (nonatomic, assign, readonly) CGFloat lastRowActualGap;
@property (nonatomic, assign, readonly) BOOL lastRowIncomplete;
@property (nonatomic, assign, readonly) NSInteger itemsByRowCount;
@property (nonatomic, assign, readonly) NSInteger indexOfIncompleteRow; // typo as of iOS6B3

//- (TUIGridLayoutSection *)copyFromLayoutInfo:(TUIGridLayoutInfo *)layoutInfo;

// Faster variant of invalidate/compute
- (void)recomputeFromIndex:(NSInteger)index;

// Invalidate layout. Destroys rows.
- (void)invalidate;

// Compute layout. Creates rows.
- (void)computeLayout;

- (TUIGridLayoutItem *)addItem;
- (TUIGridLayoutRow *)addRow;

// Copy snapshot of current object
- (TUIGridLayoutSection *)snapshot;

@end
