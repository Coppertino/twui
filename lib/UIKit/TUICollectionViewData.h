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

@class TUICollectionView, TUICollectionViewLayout, TUICollectionViewLayoutAttributes;

@interface TUICollectionViewData : NSObject

/// Designated initializer.
- (id)initWithCollectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout *)layout;

// Ensure data is valid. may fetches items from dataSource and layout.
- (void)validateLayoutInRect:(CGRect)rect;

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;
/*
 - (CGRect)rectForSupplementaryElementOfKind:(id)arg1 atIndexPath:(id)arg2;
 - (CGRect)rectForDecorationElementOfKind:(id)arg1 atIndexPath:(id)arg2;
 - (CGRect)rectForGlobalItemIndex:(int)arg1;
*/

- (NSInteger)globalIndexForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItemAtGlobalIndex:(NSInteger)index;

// Fetch layout attributes
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect;
/*
- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForElementsInSection:(NSInteger)section;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForGlobalItemIndex:(NSInteger)index;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewOfKind:(id)arg1 atIndexPath:(NSIndexPath *)indexPath;
- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryElementOfKind:(id)arg1 atIndexPath:(NSIndexPath *)indexPath;
 - (id)existingSupplementaryLayoutAttributesInSection:(int)arg1;
*/

// Make data to re-evaluate dataSources.
- (void)invalidate;

// Access cached item data
- (NSInteger)numberOfItemsBeforeSection:(NSInteger)section;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (NSInteger)numberOfItems;
- (NSInteger)numberOfSections;

// Total size of the content.
- (CGRect)collectionViewContentRect;

@property (readonly) BOOL layoutIsPrepared;

/*
 - (void)_setLayoutAttributes:(id)arg1 atGlobalItemIndex:(int)arg2;
 - (void)_setupMutableIndexPath:(id*)arg1 forGlobalItemIndex:(int)arg2;
 - (id)_screenPageForPoint:(struct CGPoint { float x1; float x2; })arg1;
 - (void)_validateContentSize;
 - (void)_validateItemCounts;
 - (void)_updateItemCounts;
 - (void)_loadEverything;
 - (void)_prepareToLoadData;
 - (void)invalidate:(BOOL)arg1;
 */

@end
