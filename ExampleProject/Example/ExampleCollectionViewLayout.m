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

#import "ExampleCollectionViewLayout.h"

#define ITEM_SIZE 70

@implementation ExampleCollectionViewLayout

- (void)prepareLayout {
    [super prepareLayout];
    
    CGSize size = self.collectionView.frame.size;
    _cellCount = [[self collectionView] numberOfItemsInSection:0];
    _center = CGPointMake(size.width / 2.0, size.height / 2.0);
    _radius = MIN(size.width, size.height) / 2.5;
}

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems {
    [super prepareForCollectionViewUpdates:updateItems];
    _insertedIndexPaths = [[NSMutableArray alloc] init];
    
    for(TUICollectionViewUpdateItem* update in updateItems) {
        if(update.updateAction == TUICollectionUpdateActionInsert)
            [_insertedIndexPaths addObject:update.indexPathAfterUpdate];
	}
}

- (void)finalizeCollectionViewUpdates {
    [super finalizeCollectionViewUpdates];
    _insertedIndexPaths = nil;
}

- (CGSize)collectionViewContentSize {
    return self.collectionView.frame.size;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)path {
    TUICollectionViewLayoutAttributes *attributes = [TUICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:path];
    attributes.size = CGSizeMake(ITEM_SIZE, ITEM_SIZE);
    attributes.center = CGPointMake(_center.x + _radius * (1 - 0.1 * path.section) * cosf(2 * path.item * M_PI / _cellCount),
                                    _center.y + _radius * (1 - 0.1 * path.section) * sinf(2 * path.item * M_PI / _cellCount));
	
    return attributes;
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    NSMutableArray *attributes = [NSMutableArray array];
    
    for(int i = 0; i < [self.collectionView numberOfSections]; i++) {
        for(int j = 0; j < [self.collectionView numberOfItemsInSection:i]; j++) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:j inSection:i];
            [attributes addObject:[self layoutAttributesForItemAtIndexPath:indexPath]];
		}
	}
	
    return attributes;
}

- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    TUICollectionViewLayoutAttributes *attributes = (TUICollectionViewLayoutAttributes *)[super initialLayoutAttributesForAppearingItemAtIndexPath:itemIndexPath];
    
    if([_insertedIndexPaths containsObject:itemIndexPath]) {
        attributes = (TUICollectionViewLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:itemIndexPath];
        attributes.alpha = 0.0;
        attributes.center = self.center;
	}
	
    return attributes;
}

- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath {
    TUICollectionViewLayoutAttributes *attributes = (TUICollectionViewLayoutAttributes *)[self layoutAttributesForItemAtIndexPath:itemIndexPath];
	
    attributes.alpha = 0.0;
    attributes.center = self.center;
    attributes.transform3D = CATransform3DMakeScale(0.1, 0.1, 1.0);
    return attributes;
}

@end
