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
