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

@end

