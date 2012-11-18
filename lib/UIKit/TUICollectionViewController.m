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
    TUICollectionViewLayout *_layout;
    TUICollectionView *_collectionView;
    struct {
        unsigned int clearsSelectionOnViewWillAppear : 1;
        unsigned int appearsFirstTime : 1; // TUI exension!
    } _collectionViewControllerFlags;
}
@property (nonatomic, strong) TUICollectionViewLayout* layout;
@end

@implementation TUICollectionViewController

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
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

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController

- (void)loadView {
    [super loadView];

    // if this is restored from IB, we don't have plain main view.
    if ([self.view isKindOfClass:[TUICollectionView class]]) {
        _collectionView = (TUICollectionView *)self.view;
    }
	
	if (_collectionView.delegate == nil) _collectionView.delegate = self;
    if (_collectionView.dataSource == nil) _collectionView.dataSource = self;

    // only create the collection view if it is not already created (by IB)
    if (!_collectionView) {
        self.collectionView = [[TUICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:self.layout];
        self.collectionView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self.view addSubview:self.collectionView];
        self.collectionView.delegate = self;
        self.collectionView.dataSource = self;
    }
    // on low memory event, just re-attach the view.
    else if (self.view != self.collectionView) {
        [self.view addSubview:self.collectionView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_collectionViewControllerFlags.appearsFirstTime) {
        [_collectionView reloadData];
        _collectionViewControllerFlags.appearsFirstTime = NO;
    }
    
    if (_collectionViewControllerFlags.clearsSelectionOnViewWillAppear) {
        for (NSIndexPath* aIndexPath in [[_collectionView indexPathsForSelectedItems] copy]) {
            [_collectionView deselectItemAtIndexPath:aIndexPath animated:animated];
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Properties

- (void)setClearsSelectionOnViewWillAppear:(BOOL)clearsSelectionOnViewWillAppear {
    _collectionViewControllerFlags.clearsSelectionOnViewWillAppear = clearsSelectionOnViewWillAppear;
}

- (BOOL)clearsSelectionOnViewWillAppear {
    return _collectionViewControllerFlags.clearsSelectionOnViewWillAppear;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - TUICollectionViewDataSource

- (NSInteger)collectionView:(TUICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 0;
}

- (TUICollectionViewCell *)collectionView:(TUICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
