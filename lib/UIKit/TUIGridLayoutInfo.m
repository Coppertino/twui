//
//  TUICollectionLayoutInfo.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUIGeometry.h"
#import "NSIndexPath+TUIExtensions.h"

#import "TUIGridLayoutInfo.h"
#import "TUIGridLayoutSection.h"
#import "TUIGridLayoutRow.h"
#import "TUIGridLayoutItem.h"
#import "TUICollectionView.h"

@interface TUIGridLayoutInfo() {
    NSMutableArray *_sections;
    CGRect _visibleBounds;
    CGSize _layoutSize;
    BOOL _isValid;
}
@property (nonatomic, strong) NSMutableArray *sections;
@end

@implementation TUIGridLayoutInfo

#pragma mark - NSObject

- (id)init {
    if((self = [super init])) {
        _sections = [NSMutableArray new];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p dimension:%.1f horizontal:%d contentSize:%@ sections:%@>", NSStringFromClass([self class]), self, self.dimension, self.horizontal, NSStringFromSize(self.contentSize), self.sections];
}

#pragma mark - Public

- (TUIGridLayoutInfo *)snapshot {
    TUIGridLayoutInfo *layoutInfo = [[self class] new];
    layoutInfo.sections = self.sections;
    layoutInfo.rowAlignmentOptions = self.rowAlignmentOptions;
    layoutInfo.usesFloatingHeaderFooter = self.usesFloatingHeaderFooter;
    layoutInfo.dimension = self.dimension;
    layoutInfo.horizontal = self.horizontal;
    layoutInfo.leftToRight = self.leftToRight;
    layoutInfo.contentSize = self.contentSize;
    return layoutInfo;
}

- (CGRect)frameForItemAtIndexPath:(NSIndexPath *)indexPath {
    TUIGridLayoutSection *section = self.sections[indexPath.section];
    CGRect itemFrame;
    if (section.fixedItemSize) {
        itemFrame = (CGRect){.size=section.itemSize};
    }else {
        itemFrame = [section.items[indexPath.item] itemFrame];
    }
    return itemFrame;
}

- (id)addSection {
    TUIGridLayoutSection *section = [TUIGridLayoutSection new];
    section.rowAlignmentOptions = self.rowAlignmentOptions;
    section.layoutInfo = self;
    [_sections addObject:section];
    [self invalidate:NO];
    return section;
}

- (void)invalidate:(BOOL)arg {
    _isValid = NO;
}

@end
