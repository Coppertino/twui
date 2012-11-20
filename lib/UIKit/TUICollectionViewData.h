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

@class TUICollectionView;
@class TUICollectionViewLayout;
@class TUICollectionViewLayoutAttributes;

@interface TUICollectionViewData : NSObject

@property (readonly) BOOL layoutIsPrepared;

- (id)initWithCollectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout *)layout;

// Ensure data is valid. May fetch items from dataSource and layout.
- (void)validateLayoutInRect:(CGRect)rect;

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSInteger)globalIndexForItemAtIndexPath:(NSIndexPath *)indexPath;
- (NSIndexPath *)indexPathForItemAtGlobalIndex:(NSInteger)index;

// Fetch layout attributes.
- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect;

// Make data to re-evaluate dataSources.
- (void)invalidate;

// Access cached item data.
- (NSInteger)numberOfItemsBeforeSection:(NSInteger)section;
- (NSInteger)numberOfItemsInSection:(NSInteger)section;
- (NSInteger)numberOfItems;
- (NSInteger)numberOfSections;

// Total size of the content.
- (CGRect)collectionViewContentRect;

@end
