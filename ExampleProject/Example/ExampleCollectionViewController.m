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

#import "ExampleCollectionViewController.h"

#define CELL_ID @"__ExampleCollectionViewCell__"

@implementation ExampleCollectionViewController

- (void)viewDidLoad {
    [self.view registerClass:[ExampleCollectionViewCell class] forCellWithReuseIdentifier:CELL_ID];
}

- (NSInteger)collectionView:(TUICollectionView *)view numberOfItemsInSection:(NSInteger)section {
    return 60;
}

- (TUICollectionViewCell *)collectionView:(TUICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ExampleCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CELL_ID forIndexPath:indexPath];
	
	cell.label.text = [NSString stringWithFormat:@"%ld", indexPath.item];
    return cell;
}

- (BOOL)collectionView:(TUICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)collectionView:(TUICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	if([self.view.collectionViewLayout isKindOfClass:[ExampleCollectionViewLayout class]])
		[self.view setCollectionViewLayout:[TUICollectionViewFlowLayout new] animated:YES];
    else
        [self.view setCollectionViewLayout:[ExampleCollectionViewLayout new] animated:YES];
}

/* 
 - (void)cellClicked:(Cell *)cell {
 NSIndexPath *tappedCellPath = [self.collectionView indexPathForCell:cell];
 NSLog(@"%@",self.sections[tappedCellPath.section][tappedCellPath.item]);
 if (tappedCellPath != nil)
 {
 [self.sections[tappedCellPath.section] removeObjectAtIndex:tappedCellPath.item];
 [self.collectionView performBatchUpdates:^{
 [self.collectionView deleteItemsAtIndexPaths:@[tappedCellPath]];
 } completion:^
 {
 NSLog(@"delete finished");
 }];
 }
 else
 {
 NSInteger insertElements = 10;
 NSInteger deleteElements = 10;
 NSMutableSet* insertedIndexPaths = [NSMutableSet set];
 NSMutableSet* deletedIndexPaths = [NSMutableSet set];
 for(NSInteger i=0;i<deleteElements;i++)
 {
 NSInteger index = rand()%[self.sections[0] count];
 NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
 if([deletedIndexPaths containsObject:indexPath])
 {
 i--;
 continue;
 }
 [self.sections[0] removeObjectAtIndex:index];
 [deletedIndexPaths addObject:indexPath];
 }
 for(NSInteger i=0;i<insertElements;i++)
 {
 NSInteger index = rand()%[self.sections[0] count];
 NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
 if([insertedIndexPaths containsObject:indexPath])
 {
 i--;
 continue;
 }
 [self.sections[0] insertObject:@(count++)
 atIndex:index];
 [insertedIndexPaths addObject:indexPath];
 }
 [self.collectionView performBatchUpdates:^{
 [self.collectionView insertItemsAtIndexPaths:[insertedIndexPaths allObjects]];
 [self.collectionView deleteItemsAtIndexPaths:[deletedIndexPaths allObjects]];
 } completion:^
 {
 NSLog(@"insert finished");
 }];
 }
}
*/

@end

