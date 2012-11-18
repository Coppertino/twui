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

@class TUIGridLayoutSection;

/*
 Every TUICollectionViewLayout has a TUIGridLayoutInfo attached.
 Is used extensively in TUICollectionViewFlowLayout.
 */
@interface TUIGridLayoutInfo : NSObject

@property (nonatomic, strong, readonly) NSArray *sections;
@property (nonatomic, strong) NSDictionary *rowAlignmentOptions;
@property (nonatomic, assign) BOOL usesFloatingHeaderFooter;

// Vertical/horizontal dimension (depending on horizontal)
// Used to create row objects
@property (nonatomic, assign) CGFloat dimension;

@property (nonatomic, assign) BOOL horizontal;
@property (nonatomic, assign) BOOL leftToRight;
@property (nonatomic, assign) CGSize contentSize;

// Frame for specific TUIGridLayoutItem.
- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath;

// Add new section. Invalidates layout.
- (TUIGridLayoutSection *)addSection;

// forces the layout to recompute on next access
// TODO; what's the parameter for?
- (void)invalidate:(BOOL)arg;

// Make a copy of the current state.
- (TUIGridLayoutInfo *)snapshot;

@end
