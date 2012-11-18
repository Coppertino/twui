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
#import "TUICollectionViewFlowLayout.h"
#import "TUICollectionViewController.h"

@interface TUICollectionViewController () {
    struct {
        unsigned clearsSelectionOnViewWillAppear:1;
        unsigned appearsFirstTime:1;
    } _collectionViewControllerFlags;
}

@property (nonatomic, strong) TUICollectionViewLayout *layout;

@end

@implementation TUICollectionViewController

#pragma mark - Initializaiton

- (id)initWithCoder:(NSCoder *)coder {
    if((self = [super initWithCoder:coder])) {
		self.layout = [TUICollectionViewFlowLayout new];
		
        self.clearsSelectionOnViewWillAppear = YES;
        _collectionViewControllerFlags.appearsFirstTime = YES;
    }
	
    return self;
}

- (id)initWithCollectionViewLayout:(TUICollectionViewLayout *)layout {
    if((self = [super init])) {
        self.layout = layout;
		
        self.clearsSelectionOnViewWillAppear = YES;
        _collectionViewControllerFlags.appearsFirstTime = YES;
    }
	
    return self;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@: %p | TUICollectionView = %@>", self.class, self, self.view];
}

#pragma mark - View Loading

- (void)loadView {
	self.view = [[TUICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:self.layout];
	self.view.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
	self.view.delegate = self;
	self.view.dataSource = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
    if(_collectionViewControllerFlags.appearsFirstTime) {
        [self.view reloadData];
        _collectionViewControllerFlags.appearsFirstTime = NO;
    }
    
    if(_collectionViewControllerFlags.clearsSelectionOnViewWillAppear) {
        for(NSIndexPath *indexPath in [self.view.indexPathsForSelectedItems copy]) {
            [self.view deselectItemAtIndexPath:indexPath animated:animated];
        }
    }
}

#pragma mark - Properties

- (void)setClearsSelectionOnViewWillAppear:(BOOL)flag {
    _collectionViewControllerFlags.clearsSelectionOnViewWillAppear = flag;
}

- (BOOL)clearsSelectionOnViewWillAppear {
    return _collectionViewControllerFlags.clearsSelectionOnViewWillAppear;
}

#pragma mark - TUICollectionViewDataSource

- (NSInteger)collectionView:(TUICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 0;
}

- (TUICollectionViewCell *)collectionView:(TUICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark -

@end
