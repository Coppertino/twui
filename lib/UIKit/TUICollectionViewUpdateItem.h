//
//  TUICollectionViewUpdateItem.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, TUICollectionUpdateAction) {
    TUICollectionUpdateActionInsert,
    TUICollectionUpdateActionDelete,
    TUICollectionUpdateActionReload,
    TUICollectionUpdateActionMove,
    TUICollectionUpdateActionNone
};

@interface TUICollectionViewUpdateItem : NSObject

@property (nonatomic, readonly, strong) NSIndexPath *indexPathBeforeUpdate; // nil for TUICollectionUpdateActionInsert
@property (nonatomic, readonly, strong) NSIndexPath *indexPathAfterUpdate;  // nil for TUICollectionUpdateActionDelete
@property (nonatomic, readonly, assign) TUICollectionUpdateAction updateAction;


- (id)initWithInitialIndexPath:(NSIndexPath*)arg1
                finalIndexPath:(NSIndexPath*)arg2
                  updateAction:(TUICollectionUpdateAction)arg3;

- (id)initWithAction:(TUICollectionUpdateAction)arg1
        forIndexPath:(NSIndexPath*)indexPath;

- (id)initWithOldIndexPath:(NSIndexPath*)arg1 newIndexPath:(NSIndexPath*)arg2;

- (TUICollectionUpdateAction)updateAction;

- (NSComparisonResult)compareIndexPaths:(TUICollectionViewUpdateItem*) otherItem;
- (NSComparisonResult)inverseCompareIndexPaths:(TUICollectionViewUpdateItem*) otherItem;

@end
