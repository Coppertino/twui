//
//  TUICollectionViewUpdateItem.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUICollectionViewUpdateItem.h"
#import "NSIndexPath+TUIExtensions.h"

@interface TUICollectionViewUpdateItem() {
    NSIndexPath *_initialIndexPath;
    NSIndexPath *_finalIndexPath;
    TUICollectionUpdateAction _updateAction;
    id _gap;
}
@end

@implementation TUICollectionViewUpdateItem

@synthesize updateAction = _updateAction;
@synthesize indexPathBeforeUpdate = _initialIndexPath;
@synthesize indexPathAfterUpdate = _finalIndexPath;

- (id)initWithInitialIndexPath:(NSIndexPath *)initialIndexPath finalIndexPath:(NSIndexPath *)finalIndexPath updateAction:(TUICollectionUpdateAction)updateAction {
    if((self = [super init])) {
        _initialIndexPath = initialIndexPath;
        _finalIndexPath = finalIndexPath;
        _updateAction = updateAction;
    }
    return self;
}

- (id)initWithAction:(TUICollectionUpdateAction)updateAction forIndexPath:(NSIndexPath*)indexPath {
    if(updateAction == TUICollectionUpdateActionInsert)
        return [self initWithInitialIndexPath:nil finalIndexPath:indexPath updateAction:updateAction];
    else if(updateAction == TUICollectionUpdateActionDelete)
        return [self initWithInitialIndexPath:indexPath finalIndexPath:nil updateAction:updateAction];
    else if(updateAction == TUICollectionUpdateActionReload)
        return [self initWithInitialIndexPath:indexPath finalIndexPath:indexPath updateAction:updateAction];

    return nil;
}

- (id)initWithOldIndexPath:(NSIndexPath *)oldIndexPath newIndexPath:(NSIndexPath *)newIndexPath {
    return [self initWithInitialIndexPath:oldIndexPath finalIndexPath:newIndexPath updateAction:TUICollectionUpdateActionMove];
}

- (NSString *)description {
    NSString *action = nil;
    switch (_updateAction) {
        case TUICollectionUpdateActionInsert: action = @"insert"; break;
        case TUICollectionUpdateActionDelete: action = @"delete"; break;
        case TUICollectionUpdateActionMove:   action = @"move";   break;
        case TUICollectionUpdateActionReload: action = @"reload"; break;
        default: break;
    }

    return [NSString stringWithFormat:@"Index path before update (%@) index path after update (%@) action (%@).",  _initialIndexPath, _finalIndexPath, action];
}

- (void)setNewIndexPath:(NSIndexPath *)indexPath {
    _finalIndexPath = indexPath;
}

- (void)setGap:(id)gap {
    _gap = gap;
}

- (BOOL)isSectionOperation {
    return (_initialIndexPath.item == NSNotFound || _finalIndexPath.item == NSNotFound);
}

- (NSIndexPath *)newIndexPath {
    return _finalIndexPath;
}

- (id)gap {
    return _gap;
}

- (TUICollectionUpdateAction)action {
    return _updateAction;
}

- (id)indexPath {
    //TODO: check this
    return _initialIndexPath;
}

- (NSComparisonResult)compareIndexPaths:(TUICollectionViewUpdateItem *)otherItem {
    NSComparisonResult result = NSOrderedSame;
    NSIndexPath *selfIndexPath = nil;
    NSIndexPath *otherIndexPath = nil;
    
    switch (_updateAction) {
        case TUICollectionUpdateActionInsert:
            selfIndexPath = _finalIndexPath;
            otherIndexPath = [otherItem newIndexPath];
            break;
        case TUICollectionUpdateActionDelete:
            selfIndexPath = _initialIndexPath;
            otherIndexPath = [otherItem indexPath];
        default: break;
    }

    if (self.isSectionOperation) result = [@(selfIndexPath.section) compare:@(otherIndexPath.section)];
    else result = [selfIndexPath compare:otherIndexPath];
    return result;
}

- (NSComparisonResult)inverseCompareIndexPaths:(TUICollectionViewUpdateItem *)otherItem {
    return (NSComparisonResult) ([self compareIndexPaths:otherItem]*-1);
}

@end
