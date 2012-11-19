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

#import "TUICollectionViewItemKey.h"
#import "TUICollectionViewLayout.h"

NSString *const TUICollectionElementKindCell = @"UICollectionElementKindCell";
NSString *const TUICollectionElementKindDecorationView = @"TUICollectionElementKindDecorationView";


@interface TUICollectionViewLayoutAttributes ()

@property (nonatomic, readonly) NSString *representedElementKind;
@property (nonatomic, readonly) TUICollectionViewItemType representedElementCategory;

- (BOOL)isDecorationView;
- (BOOL)isSupplementaryView;
- (BOOL)isCell;

@end

@implementation TUICollectionViewItemKey

#pragma mark - Factory

+ (id)collectionItemKeyForCellWithIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.type = TUICollectionViewItemTypeCell;
    key.identifier = TUICollectionElementKindCell;
    return key;
}

+ (id)collectionItemKeyForLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes {
    TUICollectionViewItemKey *key = [[self class] new];
    key.indexPath = layoutAttributes.indexPath;
    key.type = layoutAttributes.representedElementCategory;
    key.identifier = layoutAttributes.representedElementKind;
    return key;
}

+ (id)collectionItemKeyForDecorationViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.identifier = elementKind;
    key.type = TUICollectionViewItemTypeDecorationView;
    return key;
}

+ (id)collectionItemKeyForSupplementaryViewOfKind:(NSString *)elementKind andIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.identifier = elementKind;
    key.type = TUICollectionViewItemTypeSupplementaryView;
    return key;
}

NSString *TUICollectionViewItemTypeToString(TUICollectionViewItemType type) {
    switch (type) {
        case TUICollectionViewItemTypeCell: return @"Cell";
        case TUICollectionViewItemTypeDecorationView: return @"Decoration";
        case TUICollectionViewItemTypeSupplementaryView: return @"Supplementary";
        default: return @"<INVALID>";
    }
}

#pragma mark - NSObject

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p Type = %@ Identifier=%@ IndexPath = %@>", NSStringFromClass([self class]),
            self, TUICollectionViewItemTypeToString(self.type), _identifier, self.indexPath];
}

- (NSUInteger)hash {
    return (([_indexPath hash] + _type) * 31) + [_identifier hash];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[self class]]) {
        TUICollectionViewItemKey *otherKeyItem = (TUICollectionViewItemKey *)other;
		
        if (_type == otherKeyItem.type && [_indexPath isEqual:otherKeyItem.indexPath] &&
			([_identifier isEqualToString:otherKeyItem.identifier] || _identifier == otherKeyItem.identifier))
            return YES;
	}
	
    return NO;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TUICollectionViewItemKey *itemKey = [[self class] new];
    itemKey.indexPath = self.indexPath;
    itemKey.type = self.type;
    itemKey.identifier = self.identifier;
    return itemKey;
}

@end
