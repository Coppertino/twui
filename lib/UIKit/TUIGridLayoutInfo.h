//
//  TUICollectionLayoutInfo.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

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
