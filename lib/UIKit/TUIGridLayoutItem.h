//
//  TUIGridLayoutItem.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TUIGridLayoutSection, TUIGridLayoutRow;

// Represents a single grid item; only created for non-uniform-sized grids.
@interface TUIGridLayoutItem : NSObject

@property (nonatomic, unsafe_unretained) TUIGridLayoutSection *section;
@property (nonatomic, unsafe_unretained) TUIGridLayoutRow *rowObject;
@property (nonatomic, assign) CGRect itemFrame;

@end
