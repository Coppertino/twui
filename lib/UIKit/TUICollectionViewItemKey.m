//
//  TUICollectionViewItemKey.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUICollectionViewItemKey.h"
#import "TUICollectionViewLayout.h"

NSString *const TUICollectionElementKTUICell = @"TUICollectionElementKTUICell";
NSString *const TUICollectionElementKindDecorationView = @"TUICollectionElementKindDecorationView";

@implementation TUICollectionViewItemKey

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static

+ (id)collectionItemKeyForCellWithIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewItemKey *key = [[self class] new];
    key.indexPath = indexPath;
    key.type = TUICollectionViewItemTypeCell;
    key.identifier = TUICollectionElementKTUICell;
    return key;
}

+ (id)collectionItemKeyForLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes {
    TUICollectionViewItemKey *key = [[self class] new];
    key.indexPath = layoutAttributes.indexPath;
    key.type = layoutAttributes.representedElementCategory;
    key.identifier = layoutAttributes.representedElementKind;
    return key;
}

// elementKind or reuseIdentifier?
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

///////////////////////////////////////////////////////////////////////////////////////////
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
        // identifier might be nil?
        if (_type == otherKeyItem.type && [_indexPath isEqual:otherKeyItem.indexPath] && ([_identifier isEqualToString:otherKeyItem.identifier] || _identifier == otherKeyItem.identifier)) {
            return YES;
            }
        }
    return NO;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TUICollectionViewItemKey *itemKey = [[self class] new];
    itemKey.indexPath = self.indexPath;
    itemKey.type = self.type;
    itemKey.identifier = self.identifier;
    return itemKey;
}

@end
