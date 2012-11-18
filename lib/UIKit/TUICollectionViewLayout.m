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
#import "TUICollectionViewLayout.h"
#import "TUICollectionViewItemKey.h"
#import "TUICollectionViewData.h"
#import "TUICollectionViewUpdateItem.h"

@interface TUICollectionView()
-(id) currentUpdate;
-(NSDictionary*) visibleViewsDict;
-(TUICollectionViewData*)collectionViewData;
-(CGRect) visibleBounds;
@end

@interface TUICollectionReusableView()
-(void) setIndexPath:(NSIndexPath*)indexPath;
@end

@interface TUICollectionViewUpdateItem()
-(BOOL) isSectionOperation;
@end

@interface TUICollectionViewLayoutAttributes() {
    struct {
        unsigned int isCellKind:1;
        unsigned int isDecorationView:1;
        unsigned int isHidden:1;
    } _layoutFlags;
}
@property (nonatomic, copy) NSString *elementKind;
@property (nonatomic, copy) NSString *reuseIdentifier;
@end

@interface TUICollectionViewUpdateItem()
-(NSIndexPath*) indexPath;
@end

@implementation TUICollectionViewLayoutAttributes

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Static

+ (instancetype)layoutAttributesForCellWithIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewLayoutAttributes *attributes = [self new];
    attributes.elementKind = TUICollectionElementKindCell;
    attributes.indexPath = indexPath;
    return attributes;
}

+ (instancetype)layoutAttributesForSupplementaryViewOfKind:(NSString *)elementKind withIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewLayoutAttributes *attributes = [self new];
    attributes.elementKind = elementKind;
    attributes.indexPath = indexPath;
    return attributes;
}

+ (instancetype)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString *)reuseIdentifier withIndexPath:(NSIndexPath *)indexPath {
    TUICollectionViewLayoutAttributes *attributes = [self new];
    attributes.elementKind = TUICollectionElementKindDecorationView;
    attributes.reuseIdentifier = reuseIdentifier;
    attributes.indexPath = indexPath;
    return attributes;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _alpha = 1.f;
        _transform3D = CATransform3DIdentity;
    }
    return self;
}

- (NSUInteger)hash {
    return ([_elementKind hash] * 31) + [_indexPath hash];
}

- (BOOL)isEqual:(id)other {
    if ([other isKindOfClass:[self class]]) {
        TUICollectionViewLayoutAttributes *otherLayoutAttributes = (TUICollectionViewLayoutAttributes *)other;
        if ([_elementKind isEqual:otherLayoutAttributes.elementKind] && [_indexPath isEqual:otherLayoutAttributes.indexPath]) {
            return YES;
        }
    }
    return NO;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p frame:%@ indexPath:%@ elementKind:%@>", NSStringFromClass([self class]), self, NSStringFromRect(self.frame), self.indexPath, self.elementKind];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (TUICollectionViewItemType)representedElementCategory {
    if ([self.elementKind isEqualToString:TUICollectionElementKindCell]) {
        return TUICollectionViewItemTypeCell;
    }else if([self.elementKind isEqualToString:TUICollectionElementKindDecorationView]) {
        return TUICollectionViewItemTypeDecorationView;
    }else {
        return TUICollectionViewItemTypeSupplementaryView;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (NSString *)representedElementKind {
    return self.elementKind;
}

- (BOOL)isDecorationView {
    return self.representedElementCategory == TUICollectionViewItemTypeDecorationView;
}

- (BOOL)isSupplementaryView {
    return self.representedElementCategory == TUICollectionViewItemTypeSupplementaryView;
}

- (BOOL)isCell {
    return self.representedElementCategory == TUICollectionViewItemTypeCell;
}

- (void)setSize:(CGSize)size {
    _size = size;
    _frame = (CGRect){_frame.origin, _size};
}

- (void)setCenter:(CGPoint)center {
    _center = center;
    _frame = (CGRect){{_center.x - _frame.size.width / 2, _center.y - _frame.size.height / 2}, _frame.size};
}

- (void)setFrame:(CGRect)frame {
    _frame = frame;
    _size = _frame.size;
    _center = (CGPoint){CGRectGetMidX(_frame), CGRectGetMidY(_frame)};
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone {
    TUICollectionViewLayoutAttributes *layoutAttributes = [[self class] new];
    layoutAttributes.indexPath = self.indexPath;
    layoutAttributes.elementKind = self.elementKind;
    layoutAttributes.reuseIdentifier = self.reuseIdentifier;
    layoutAttributes.frame = self.frame;
    layoutAttributes.center = self.center;
    layoutAttributes.size = self.size;
    layoutAttributes.transform3D = self.transform3D;
    layoutAttributes.alpha = self.alpha;
    layoutAttributes.zIndex = self.zIndex;
    layoutAttributes.hidden = self.isHidden;
    return layoutAttributes;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - TUICollection/UICollection interoperability

#import <objc/runtime.h>
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if(!signature) {
        NSString *selString = NSStringFromSelector(selector);
        if ([selString hasPrefix:@"_"]) {
            SEL cleanedSelector = NSSelectorFromString([selString substringFromIndex:1]);
            signature = [super methodSignatureForSelector:cleanedSelector];
        }
    }
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *selString = NSStringFromSelector([invocation selector]);
    if ([selString hasPrefix:@"_"]) {
        SEL cleanedSelector = NSSelectorFromString([selString substringFromIndex:1]);
        if ([self respondsToSelector:cleanedSelector]) {
            invocation.selector = cleanedSelector;
            [invocation invokeWithTarget:self];
        }
    }else {
        [super forwardInvocation:invocation];
    }
}

@end


@interface TUICollectionViewLayout() {
    __unsafe_unretained TUICollectionView *_collectionView;
    CGSize _collectionViewBoundsSize;
    NSMutableDictionary *_initialAnimationLayoutAttributesDict;
    NSMutableDictionary *_finalAnimationLayoutAttributesDict;
    NSMutableIndexSet *_deletedSectionsSet;
    NSMutableIndexSet *_insertedSectionsSet;
    NSMutableDictionary *_decorationViewClassDict;
    NSMutableDictionary *_decorationViewNibDict;
    NSMutableDictionary *_decorationViewExternalObjectsTables;
}
@property (nonatomic, unsafe_unretained) TUICollectionView *collectionView;
@end

NSString *const TUICollectionViewLayoutAwokeFromNib = @"TUICollectionViewLayoutAwokeFromNib";

@implementation TUICollectionViewLayout

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _decorationViewClassDict = [NSMutableDictionary new];
        _decorationViewNibDict = [NSMutableDictionary new];
        _decorationViewExternalObjectsTables = [NSMutableDictionary new];
        _initialAnimationLayoutAttributesDict = [NSMutableDictionary new];
        _finalAnimationLayoutAttributesDict = [NSMutableDictionary new];
        _insertedSectionsSet = [NSMutableIndexSet new];
        _deletedSectionsSet = [NSMutableIndexSet new];

        [[NSNotificationCenter defaultCenter] postNotificationName:TUICollectionViewLayoutAwokeFromNib object:self];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setCollectionView:(TUICollectionView *)collectionView {
    if (collectionView != _collectionView) {
        _collectionView = collectionView;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Invalidating the Layout

- (void)invalidateLayout {
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds {
    return NO; // return YES to requery the layout for geometry information
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Providing Layout Attributes

- (void)prepareLayout {
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect {
    return nil;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForSupplementaryViewOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

- (TUICollectionViewLayoutAttributes *)layoutAttributesForDecorationViewWithReuseIdentifier:(NSString*)identifier atIndexPath:(NSIndexPath *)indexPath {
    return nil;
}

// return a point at which to rest after scrolling - for layouts that want snap-to-point scrolling behavior
- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity {
    return proposedContentOffset;
}

- (CGSize)collectionViewContentSize {
    return CGSizeZero;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Responding to Collection View Updates

- (void)prepareForCollectionViewUpdates:(NSArray *)updateItems
{
    NSDictionary* update = [_collectionView currentUpdate];


    for (TUICollectionReusableView* view in [[_collectionView visibleViewsDict] objectEnumerator])
    {

        TUICollectionViewLayoutAttributes* attr = [view.layoutAttributes copy];


        TUICollectionViewData* oldModel = update[@"oldModel"];


        NSInteger index = [oldModel globalIndexForItemAtIndexPath:[attr indexPath]];

        if(index != NSNotFound)
        {
            index = [update[@"oldToNewIndexMap"][index] intValue];

            if(index != NSNotFound)
            {

                [attr setIndexPath:[update[@"newModel"] indexPathForItemAtGlobalIndex:index]];

                [_initialAnimationLayoutAttributesDict setObject:attr
                                                          forKey:[TUICollectionViewItemKey collectionItemKeyForLayoutAttributes:attr]];
            }
        }


    }


    TUICollectionViewData* collectionViewData = [_collectionView collectionViewData];



    CGRect bounds = [_collectionView visibleBounds];


    for (TUICollectionViewLayoutAttributes* attr in [collectionViewData layoutAttributesForElementsInRect:bounds])
    {

        NSInteger index = [collectionViewData globalIndexForItemAtIndexPath:attr.indexPath];

        index = [update[@"newToOldIndexMap"][index] intValue];
        if(index != NSNotFound)
        {
            TUICollectionViewLayoutAttributes* finalAttrs = [attr copy];

            [finalAttrs setIndexPath:[update[@"oldModel"] indexPathForItemAtGlobalIndex:index]];
            [finalAttrs setAlpha:0];
            [_finalAnimationLayoutAttributesDict setObject:finalAttrs
                                                    forKey:[TUICollectionViewItemKey collectionItemKeyForLayoutAttributes:finalAttrs]];

        }
    }

    for(TUICollectionViewUpdateItem* updateItem in updateItems)
    {

        TUICollectionUpdateAction action = updateItem.updateAction;


        if([updateItem isSectionOperation])
        {


            if(action == TUICollectionUpdateActionReload)
            {
                [_deletedSectionsSet addIndex:[[updateItem indexPathBeforeUpdate] section]];
                [_insertedSectionsSet addIndex:[updateItem indexPathAfterUpdate].section];
            }
            else
            {
                NSMutableIndexSet* indexSet =
                (action == TUICollectionUpdateActionInsert)?_insertedSectionsSet:_deletedSectionsSet;

                [indexSet addIndex: [updateItem indexPath].section];
            }
        }
        else
        {
            if(action == TUICollectionUpdateActionDelete)
            {

                TUICollectionViewItemKey* key = [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:
                                                 [updateItem indexPathBeforeUpdate]];

                TUICollectionViewLayoutAttributes* attrs = [[_finalAnimationLayoutAttributesDict objectForKey:key]copy];

                if(attrs)
                {
                    [attrs setAlpha:0];
                    [_finalAnimationLayoutAttributesDict setObject:attrs
                                                            forKey:key];
                }
            }
            else if(action == TUICollectionUpdateActionReload ||
                    action == TUICollectionUpdateActionInsert)
            {

                TUICollectionViewItemKey* key = [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:
                                                 [updateItem indexPathAfterUpdate]];
                TUICollectionViewLayoutAttributes* attrs = [[_initialAnimationLayoutAttributesDict objectForKey:key] copy];

                if(attrs)
                {
                    [attrs setAlpha:0];
                    [_initialAnimationLayoutAttributesDict setObject: attrs
                                                              forKey:key];
                }
            }
        }
    }
}

- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForAppearingItemAtIndexPath:(NSIndexPath*)itemIndexPath
{
    TUICollectionViewLayoutAttributes* attrs = [_initialAnimationLayoutAttributesDict objectForKey:
                                                [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:itemIndexPath]];

    if([_insertedSectionsSet containsIndex:[itemIndexPath section]])
    {
        attrs = [attrs copy];
        [attrs setAlpha:0];
    }
    return attrs;
}

- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForDisappearingItemAtIndexPath:(NSIndexPath *)itemIndexPath
{
    TUICollectionViewLayoutAttributes* attrs = [_finalAnimationLayoutAttributesDict objectForKey:
                                                [TUICollectionViewItemKey collectionItemKeyForCellWithIndexPath:itemIndexPath]];

    if([_deletedSectionsSet containsIndex:[itemIndexPath section]])
    {
        attrs = [attrs copy];
        [attrs setAlpha:0];
    }
    return attrs;

}

- (TUICollectionViewLayoutAttributes *)initialLayoutAttributesForInsertedSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath {
    return nil;
}

- (TUICollectionViewLayoutAttributes *)finalLayoutAttributesForDeletedSupplementaryElementOfKind:(NSString *)elementKind atIndexPath:(NSIndexPath *)elementIndexPath {
    return nil;
}

- (void)finalizeCollectionViewUpdates
{
    [_initialAnimationLayoutAttributesDict removeAllObjects];
    [_finalAnimationLayoutAttributesDict removeAllObjects];
    [_deletedSectionsSet removeAllIndexes];
    [_insertedSectionsSet removeAllIndexes];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Registering Decoration Views

- (void)registerClass:(Class)viewClass forDecorationViewWithReuseIdentifier:(NSString *)identifier {

}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Private

- (void)setCollectionViewBoundsSize:(CGSize)size {
    _collectionViewBoundsSize = size;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)coder {
    if((self = [self init])) {
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - TUICollection/UICollection interoperability

#import <objc/runtime.h>
#import <objc/message.h>
- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *sig = [super methodSignatureForSelector:selector];
    if(!sig) {
        NSString *selString = NSStringFromSelector(selector);
        if ([selString hasPrefix:@"_"]) {
            SEL cleanedSelector = NSSelectorFromString([selString substringFromIndex:1]);
            sig = [super methodSignatureForSelector:cleanedSelector];
        }
    }
    return sig;
}

- (void)forwardInvocation:(NSInvocation *)inv {
    NSString *selString = NSStringFromSelector([inv selector]);
    if ([selString hasPrefix:@"_"]) {
        SEL cleanedSelector = NSSelectorFromString([selString substringFromIndex:1]);
        if ([self respondsToSelector:cleanedSelector]) {
            // dynamically add method for faster resolving
            Method newMethod = class_getInstanceMethod([self class], [inv selector]);
            IMP underscoreIMP = imp_implementationWithBlock((^(id _self) {
                return objc_msgSend(_self, cleanedSelector);
            }));
            class_addMethod([self class], [inv selector], underscoreIMP, method_getTypeEncoding(newMethod));
            // invoke now
            inv.selector = cleanedSelector;
            [inv invokeWithTarget:self];
        }
    }else {
        [super forwardInvocation:inv];
    }
}

@end
