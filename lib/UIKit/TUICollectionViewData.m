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

#import "NSIndexPath+TUIExtensions.h"

#import "TUICollectionViewData.h"
#import "TUICollectionView.h"
#import "TUICollectionViewLayout.h"

@interface TUICollectionViewData () {
    CGRect _validLayoutRect;
    
    NSInteger _numItems;
    NSInteger _numSections;
    NSInteger *_sectionItemCounts;
    NSArray *_globalItems;
    NSArray *_cellLayoutAttributes;
    CGSize _contentSize;
	
    struct {
        unsigned contentSizeIsValid:1;
        unsigned itemCountsAreValid:1;
        unsigned layoutIsPrepared:1;
    } _collectionViewDataFlags;
}

@property (nonatomic, unsafe_unretained) TUICollectionView *collectionView;
@property (nonatomic, unsafe_unretained) TUICollectionViewLayout *layout;

@end

@implementation TUICollectionViewData

#pragma mark - NSObject

- (id)initWithCollectionView:(TUICollectionView *)collectionView layout:(TUICollectionViewLayout *)layout {
    if((self = [super init])) {
        _globalItems = [NSArray new];
        _collectionView = collectionView;
        _layout = layout;
    }
    return self;
}

- (void)dealloc {
    if(_sectionItemCounts)
		free(_sectionItemCounts);
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p numItems:%ld numSections:%ld globalItems:%@>",
			NSStringFromClass([self class]), self, self.numberOfItems, self.numberOfSections, _globalItems];
}

#pragma mark - Public

- (void)invalidate {
    _collectionViewDataFlags.itemCountsAreValid = NO;
    _collectionViewDataFlags.layoutIsPrepared = NO;
    _validLayoutRect = CGRectZero;
}

- (CGRect)collectionViewContentRect {
    return (CGRect){.size=_contentSize};
}

// TODO: check if we need to fetch data from layout
- (void)validateLayoutInRect:(CGRect)rect {
    [self validateItemCounts];
    [self prepareToLoadData];
	
    if (!CGRectEqualToRect(_validLayoutRect, rect)) {
        _validLayoutRect = rect;
        _cellLayoutAttributes = [self.layout layoutAttributesForElementsInRect:rect];
    }
}

- (NSInteger)numberOfItems {
    [self validateItemCounts];
    return _numItems;
}

- (NSInteger)numberOfItemsBeforeSection:(NSInteger)section {
    return [self numberOfItemsInSection:section-1]; // ???
}

- (NSInteger)numberOfItemsInSection:(NSInteger)section {
    [self validateItemCounts];
	
    if(section > _numSections || section < 0) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
									   reason:[NSString stringWithFormat:@"Section %ld out of range: 0...%ld",
											   section, _numSections] userInfo:nil];
    }
    
    NSInteger numberOfItemsInSection = 0;
    if(_sectionItemCounts)
        numberOfItemsInSection = _sectionItemCounts[section];
	
    return numberOfItemsInSection;
}

- (NSInteger)numberOfSections {
    [self validateItemCounts];
    return _numSections;
}

- (CGRect)rectForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGRectZero;
}

- (NSIndexPath *)indexPathForItemAtGlobalIndex:(NSInteger)index {
    return _globalItems[index];
}

- (NSInteger)globalIndexForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [_globalItems indexOfObject:indexPath];
}

- (BOOL)layoutIsPrepared {
    return _collectionViewDataFlags.layoutIsPrepared;
}

- (void)setLayoutIsPrepared:(BOOL)layoutIsPrepared {
    _collectionViewDataFlags.layoutIsPrepared = layoutIsPrepared;
}

#pragma mark - Fetch Layout Attributes

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    [self validateLayoutInRect:rect];
    return _cellLayoutAttributes;
}

#pragma mark - Private

// Ensure item count is valid and loaded.
- (void)validateItemCounts {
    if (!_collectionViewDataFlags.itemCountsAreValid) {
        [self updateItemCounts];
    }
}

// Query dataSource for new data.
- (void)updateItemCounts {
	
    // Query how many sections there will be.
    _numSections = 1;
    if([self.collectionView.dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        _numSections = [self.collectionView.dataSource numberOfSectionsInCollectionView:self.collectionView];
    }
	
    if(_numSections <= 0) {
        _numItems = 0;
        free(_sectionItemCounts);
		_sectionItemCounts = 0;
        
		return;
    }
	
    // Allocate space.
    if (!_sectionItemCounts)
        _sectionItemCounts = malloc(_numSections * sizeof(NSInteger));
    else
        _sectionItemCounts = realloc(_sectionItemCounts, _numSections * sizeof(NSInteger));

    // Query cells per section.
    _numItems = 0;
    for (NSInteger i = 0; i < _numSections; i++) {
        NSInteger cellCount = [self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:i];
        _sectionItemCounts[i] = cellCount;
        _numItems += cellCount;
    }
    
	NSMutableArray *globalIndexPaths = [[NSMutableArray alloc] initWithCapacity:_numItems];
    for(NSInteger section = 0; section < _numSections; section++)
        for(NSInteger item = 0; item < _sectionItemCounts[section]; item++)
            [globalIndexPaths addObject:[NSIndexPath indexPathForItem:item inSection:section]];
	
    _globalItems = [NSArray arrayWithArray:globalIndexPaths];
    _collectionViewDataFlags.itemCountsAreValid = YES;
}

- (void)prepareToLoadData {
    if (!self.layoutIsPrepared) {
        [self.layout prepareLayout];
        _contentSize = self.layout.collectionViewContentSize;
        self.layoutIsPrepared = YES;
    }
}

@end
