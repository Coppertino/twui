//
//  TUITableOulineView.m
//  Example
//
//  Created by Ivan Ablamskyi on 13.02.13.
//
//

#import "TUITableOutlineView.h"
#import "TUILayoutConstraint.h"


#define NORMAL_Z_POSITION 0.0
#define FRONT_Z_POSITION 100.0
#define BACK_Z_POSITION -100.0


CG_INLINE CGRect CGRectWithPoints(CGPoint s, CGPoint e)
{
    CGRect res = CGRectZero;
    
    res.size.width = e.x - s.x;
    res.size.height = e.y - s.y;
    res.origin = s;
    
    return res;
};

CG_INLINE CGPoint CGRectGetTopPoint(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));
}

CG_INLINE CGPoint CGRectGetBottomPoint(CGRect rect)
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
}

CG_INLINE CGFloat durationForOffset(CGFloat offset)
{
    return 0.5;
    return 1.0/100.0 * ABS(offset);
}


@interface TUITableOutlineView (Private)

- (void)_updateSectionInfo;
- (BOOL)_preLayoutCells;
- (void)_layoutSectionHeaders:(BOOL)visibleHeadersNeedRelayout;
- (void)_layoutCells:(BOOL)visibleCellsNeedRelayout;
- (void)_toggleSectionWithAnimation:(NSInteger)section;
- (void)_toggleSectionWithoutAnimation:(NSInteger)section;

@end

@implementation TUITableOutlineView
{
    CGFloat _transitionOffset;
    CGFloat _topOffset, _bottomOffset;
    
    NSInteger   _openedSection;
    NSInteger   _openningSection;
    BOOL        _openning;
    TUIView     *_oldBackgroundView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _openedSection = NSIntegerMin;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (void)toggleSection:(NSInteger)section animated:(BOOL)animated {

    if (animated) {
        [self _toggleSectionWithAnimation:section];
    } else {
        [self _toggleSectionWithoutAnimation:section];
    }
}

-(CGRect)_backgroundRectForSectionRect:(CGRect)sectionRect {
    CGRect bgViewRect;
    if (sectionRect.size.height <= sectionRect.size.width) {
        bgViewRect = sectionRect;
    } else {
        // make square rect in the top of section
        CGFloat sectionWidth = sectionRect.size.width;
        bgViewRect = CGRectMake(sectionRect.origin.x, CGRectGetMaxY(sectionRect) - sectionWidth, sectionWidth, sectionWidth);
    }
    return bgViewRect;
}

- (void)_toggleSectionWithoutAnimation:(NSInteger)section {
    
    if(!_tableFlags.layoutSubviewsReentrancyGuard) {
		_tableFlags.layoutSubviewsReentrancyGuard = 1;
    } else {
        __unsafe_unretained TUITableOutlineView *tv = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tv _toggleSectionWithoutAnimation:section];
        });
        return;
    }
    
    BOOL willOpenSection = (_openedSection == NSIntegerMin);
    BOOL willCloseSection = (_openedSection == section);
    BOOL willToggleSections = (_openedSection != section);
    
    _openning = YES;
    _openningSection = section;
    
    // Update sections info to get fill up new sections
    [self _updateSectionInfo];
    
    if (self.openedSectionBackgroundView) {
        [self.openedSectionBackgroundView removeFromSuperview];
        self.openedSectionBackgroundView = nil;
    }
    // In case not closing section - needs to create background that will appear under cells
    if (willOpenSection || willToggleSections) {
        
        CGRect sectionRect  = [self rectForSection:section];
        
        self.openedSectionBackgroundView = [[TUIView alloc] initWithFrame:[self _backgroundRectForSectionRect:sectionRect]];
        [self addSubview:self.openedSectionBackgroundView];
        [self sendSubviewToBack:self.openedSectionBackgroundView];
    }
    
    if (willOpenSection) {
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willOpenSection:)]) {
            [_delegate tableView:self willOpenSection:section];
        }
    } else if (willCloseSection) {
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willCloseSection:)]) {
            [_delegate tableView:self willCloseSection:section];
        }
    } else if (willToggleSections) {
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willCloseSection:)]) {
            [_delegate tableView:self willCloseSection:_openedSection];
        }
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willOpenSection:)]) {
            [_delegate tableView:self willOpenSection:section];
        }
    }
    
    if(!_tableFlags.layoutSubviewsReentrancyGuard) {
        _tableFlags.layoutSubviewsReentrancyGuard = 1;
    }
    
    [TUIView setAnimationsEnabled:NO block:^{
        
        _openning = NO;
        _openedSection = (willOpenSection || willToggleSections) ? section : NSIntegerMin;
        _openningSection = NSIntegerMin;
    }];
    
    
    if (willOpenSection) {
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willOpenSection:)]) {
            [_delegate tableView:self didOpenSection:section];
        }
    } else if (willCloseSection) {
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willCloseSection:)]) {
            [_delegate tableView:self didCloseSection:section];
        }
    } else if (willToggleSections) {
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willCloseSection:)]) {
            [_delegate tableView:self didCloseSection:_openedSection];
        }
        if (self.delegate && [_delegate respondsToSelector:@selector(tableView:willOpenSection:)]) {
            [_delegate tableView:self didOpenSection:section];
        }
    }
    
    _tableFlags.layoutSubviewsReentrancyGuard = 0;
    
    [self reloadData];
}

-(void)_toggleSectionWithAnimation:(NSInteger)section
{
    if (_openning) {
        return;
    }
    
    if(!_tableFlags.layoutSubviewsReentrancyGuard) {
		_tableFlags.layoutSubviewsReentrancyGuard = 1;
    } else {
        __unsafe_unretained TUITableOutlineView *tv = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            [tv _toggleSectionWithAnimation:section];
        });
        return;
    }

    
    CGRect curSectionRect = [self rectForSection:section];
    CGRect realVisibleRect = [self visibleRect];
    
    NSMutableIndexSet *topSections = (NSMutableIndexSet *)[self indexesOfSectionsInRect:
                                                           CGRectWithPoints(CGRectGetTopPoint(curSectionRect), CGRectGetTopPoint(realVisibleRect))];
    
    NSMutableIndexSet *bottomSections = (NSMutableIndexSet *)[self indexesOfSectionsInRect:
                                                              CGRectWithPoints(CGRectGetBottomPoint(realVisibleRect), CGRectGetBottomPoint(curSectionRect))];
    
    [topSections removeIndex:section];
    [bottomSections removeIndex:section];
    
    BOOL isOpenedSectionVisible = [topSections containsIndex:_openedSection] || [bottomSections containsIndex:_openedSection];
    
    BOOL willOpenSection = (_openedSection == NSIntegerMin || (_openedSection != section && !isOpenedSectionVisible));
    BOOL willCloseSection = (_openedSection == section);
    BOOL willToggleSections = (_openedSection != NSIntegerMin && isOpenedSectionVisible && _openedSection != section);
    
    
    CGRect openedSectionRect    = [self rectForSection:_openedSection];
    CGFloat openedSectionHeight = CGRectGetHeight(openedSectionRect);
    
    CGRect openedSectionHeader         = [self rectForHeaderOfSection:_openedSection];
    CGFloat openedSectionHeaderHeight  = CGRectGetHeight(openedSectionHeader);
    
    if (![self headerViewForSection:_openedSection]) {
        openedSectionHeader = [self rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:_openedSection]];
        openedSectionHeaderHeight = CGRectGetHeight(openedSectionHeader);
    }
    
    
    TUIScrollViewIndicatorVisibility oldScrollVisibility = self.verticalScrollIndicatorVisibility;
    self.verticalScrollIndicatorVisibility = TUIScrollViewIndicatorVisibleNever;
    
    _openning = YES;
    _openningSection = section;
    
    
    BOOL isOpenedSectionAboveCurrent = [topSections containsIndex:_openedSection];
    
    if (isOpenedSectionVisible && self.delegate && [_delegate respondsToSelector:@selector(tableView:willCloseSection:)]) {
        [_delegate tableView:self willCloseSection:_openedSection];
    }
    
    _oldBackgroundView = self.openedSectionBackgroundView;
    self.openedSectionBackgroundView = nil;
    [self sendSubviewToBack:_oldBackgroundView];
    //    [_oldBackgroundView removeFromSuperview];
    
    _topOffset = isOpenedSectionAboveCurrent ? openedSectionHeight : 0.0;
    
    // Update sections info to get fill up new section
    [self _updateSectionInfo];
    
    // Calculate section size and header size to find out fix sizes
    CGRect curSectionHeaderRect   = [self rectForHeaderOfSection:section];
    if (![self headerViewForSection:section]) {
        curSectionHeaderRect = [self rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    }
    CGRect newCurSectionRect  = [self rectForSection:section];
    
    CGFloat newCurSectionHeight   = CGRectGetHeight(newCurSectionRect);
    CGFloat curSectionHeaderHeight    = CGRectGetHeight(curSectionHeaderRect);
    CGFloat newContentHeight = (_contentHeight - openedSectionHeight) + curSectionHeaderHeight;
    
#warning This is not proper height and needs to be improved
    if (isOpenedSectionVisible && topSections) {
        _topOffset = openedSectionHeight;
        _bottomOffset = newCurSectionHeight;
    } else if (isOpenedSectionVisible) {
        _bottomOffset = openedSectionHeight;
        _topOffset = newCurSectionHeight;
    } else {
        _topOffset = newCurSectionHeight;
        _bottomOffset = newCurSectionHeight;
    }
    
    
    _transitionOffset = (newCurSectionHeight - curSectionHeaderHeight);
    //    __block CGPoint beginOffset = self.contentOffset;
    
    // In case not closing section - needs to create background that will apear under cells
    if (willOpenSection || willToggleSections) {
        
        self.openedSectionBackgroundView = [[TUIView alloc] initWithFrame:[self _backgroundRectForSectionRect:newCurSectionRect]];
        
        [self addSubview:self.openedSectionBackgroundView];
        [self sendSubviewToBack:self.openedSectionBackgroundView];
    }
    
    if ((willOpenSection || willToggleSections) && self.delegate && [_delegate respondsToSelector:@selector(tableView:willOpenSection:)]) {
        [_delegate tableView:self willOpenSection:section];
    }
    
    // Layoyt new section and return all cell to previus state
    self.contentSize = CGSizeMake(self.contentSize.width, _contentHeight);
    
    //    [self _layoutSectionHeaders:YES];
    [self _layoutCells:YES];
    
    [topSections addIndexes:[self _visibleSectionsBeforeSection:section]];
    [bottomSections addIndexes:[self _visibleSectionsAfterSection:section]];
    
    CGRect transitedNewCurSectionRect = newCurSectionRect;
    if (willOpenSection || willToggleSections) {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        
        [self _setZposition:FRONT_Z_POSITION ofSectionHeaders:topSections];
        [self _setZposition:FRONT_Z_POSITION ofSectionHeaders:bottomSections];
        
        // moves sections in position that was before opening current section
        [self _moveSections:topSections forOffset: -_transitionOffset];
        [self _moveSection:section forOffset: -_transitionOffset];
        
        [self sendSubviewToBack:self.openedSectionBackgroundView];
        
        if (willToggleSections) {
            if (isOpenedSectionAboveCurrent) {
                [self _setZposition:BACK_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:_openedSection]];
            } else {
                [self _setZposition:BACK_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
            }
        }
        
        [CATransaction flush];
        [CATransaction commit];
        
        transitedNewCurSectionRect = CGRectOffset(newCurSectionRect, 0, -_transitionOffset);
    }
    CGRect desiredCurrentSectionRect = transitedNewCurSectionRect;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [TUIView beginAnimations:NSStringFromSelector(_cmd) context:NULL];
        
        void (^compleationBlock)(BOOL) = ^(BOOL finished) {
            [TUIView setAnimationsEnabled:NO block:^{
                
                if ((willOpenSection || willToggleSections) && self.delegate && [_delegate respondsToSelector:@selector(tableView:didOpenSection:)]) {
                    [_delegate tableView:self didOpenSection:section];
                }
                
                if (isOpenedSectionVisible && self.delegate && [_delegate respondsToSelector:@selector(tableView:didCloseSection:)]) {
                    [_delegate tableView:self didCloseSection:_openedSection];
                }
                
                if (_oldBackgroundView) {
                    [_oldBackgroundView removeFromSuperview];
                    _oldBackgroundView = nil;
                }
                
                self.verticalScrollIndicatorVisibility = oldScrollVisibility;
                
                _openning = NO;
                _openedSection = willCloseSection ? NSIntegerMin : section;
                _openningSection = NSIntegerMin;
                _transitionOffset = 0;
                _topOffset = 0;
                _bottomOffset = 0;
                
                _tableFlags.layoutSubviewsReentrancyGuard = 0;
                
                // calculate offset from top for current section
                CGFloat currentSectionHeaderY = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]].frame.origin.y;
                CGFloat currentSectionHeaderTopOffset = self.contentSize.height - currentSectionHeaderY;
                
                [self reloadData];
                
                // // calculate offset from top for current section after reload
                CGFloat newCurrentSectionHeaderY = [self rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]].origin.y;
                CGFloat newCurrentSectionTopOffset = self.contentSize.height - newCurrentSectionHeaderY;
                
                // correct content offset to keep current section header top offset (avoid content "jumping")
                self.contentOffset = CGPointMake(self.contentOffset.x, self.contentOffset.y + (newCurrentSectionTopOffset - currentSectionHeaderTopOffset));
                
            }];
        };
        
        if (willToggleSections) {
            
            //                if (isOpenedSectionAboveCurrent) {
            
            // visible sections above opened section
            NSMutableIndexSet *topMovingSections = [[self _visibleSectionsBeforeSection:_openedSection] mutableCopy];
            [topMovingSections addIndex:_openedSection];
            
            NSIndexSet *bottomMovingSections = bottomSections;
            
            NSMutableIndexSet *middleMovingSectionWithCurSection = [[self _visibleSectionsAfterSection:_openedSection] mutableCopy];
            [middleMovingSectionWithCurSection removeIndexes:bottomMovingSections];
            
            CGFloat topTransition = 0;
            if (topMovingSections && [topMovingSections count] > 0) {
                NSInteger lastTopMovingSection = [topMovingSections lastIndex];
                CGRect lastTopMovingSectionHeaderRect = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:lastTopMovingSection]].frame;
                topTransition = CGRectGetMaxY(desiredCurrentSectionRect) - CGRectGetMinY(lastTopMovingSectionHeaderRect);
            }
            
            CGFloat bottomTransition = 0;
            if (bottomMovingSections && [bottomMovingSections count] > 0) {
                NSInteger firstBottomMovingSection = [bottomMovingSections firstIndex];
                CGRect firstBottomMovingSectionHeaderRect = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:firstBottomMovingSection]].frame;
                bottomTransition = CGRectGetMinY(desiredCurrentSectionRect) - CGRectGetMaxY(firstBottomMovingSectionHeaderRect);
            }
            //                }
            
            //                [self _setZposition:BACK_Z_POSITION ofSection:_openedSection];
            
            //                [TUIView animateWithDuration:durationForOffset(curSectionRect.size.height) animations:^{
            //                    [TUIView setAnimationCurve:TUIViewAnimationCurveEaseIn];
            //
            //                    [self _moveSections:topMovingSections forOffset:topTransition];
            //                    [self _moveSections:bottomMovingSections forOffset:bottomTransition];
            //
            //                } completion:^(BOOL finished) {
            //
            //                    [self _setZposition:NORMAL_Z_POSITION ofSection:_openedSection];
            //                    compleationBlock(finished);
            //                }];
            //
            //                goto finish;
            
            // !******!
            // !* In case openned section is lower - we need two step animation
            // !******!
            if (isOpenedSectionAboveCurrent && (openedSectionHeight < newCurSectionHeight || CGRectGetMaxY(curSectionHeaderRect) > CGRectGetMaxY(realVisibleRect))) {
                
                //                    NSLog(@"Opened above, op height < current");
                
                CGFloat firstOffset = MIN(openedSectionHeight - openedSectionHeaderHeight, (CGRectGetMaxY(realVisibleRect) - CGRectGetMinY(newCurSectionRect) - curSectionHeaderHeight));
                CGFloat secondOffset = _transitionOffset - firstOffset;
                
                //                    [self _setZposition:BACK_Z_POSITION ofSection:_openedSection];
                
                [TUIView animateWithDuration:durationForOffset(firstOffset) animations:^{
                    
                    [TUIView setAnimationCurve:TUIViewAnimationCurveEaseIn];
                    [topSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        if (idx > _openedSection)
                            [self _moveSection:idx forOffset:firstOffset];
                    }];
                    [self _moveSection:section forOffset:firstOffset];
                    
                } completion:^(BOOL finished) {
                    [TUIView animateWithDuration:durationForOffset(secondOffset) animations:^{
                        [TUIView setAnimationCurve:TUIViewAnimationCurveEaseOut];
                        
                        [self _moveSections:topSections forOffset:secondOffset];
                        [self _moveSection:section forOffset:secondOffset];
                        [self setContentSize:CGSizeMake(self.contentSize.width, newContentHeight)];
                        
                        // If content have fit on screen itself, then needs to help with
                        if (CGRectGetMaxY(curSectionHeaderRect) > CGRectGetMaxY(realVisibleRect)) {
                            CGPoint newOffset = CGPointMake(self.contentOffset.x, - (CGRectGetMaxY(curSectionHeaderRect) - CGRectGetHeight(realVisibleRect)));
                            [self setContentOffset: newOffset];
                        } else if (newContentHeight < CGRectGetHeight(self.bounds)) {
                            CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(self.bounds) - newContentHeight);
                            [self setContentOffset: newOffset];
                        }
                    } completion:^(BOOL finished) {
                        [self _setZposition:NORMAL_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:_openedSection]];
                        compleationBlock(finished);
                    }];
                }];
                
            } else if (isOpenedSectionAboveCurrent) {
                
                //                    NSLog(@"Opened above, op height > current");
                
                //                    NSLog(@"top sections %@, _opened %@", topSections, @(_openedSection));
                
                CGFloat firstOffset = _transitionOffset;
                CGFloat secondOffset = openedSectionHeight - _transitionOffset - openedSectionHeaderHeight;
                
                //                    [self _setZposition:BACK_Z_POSITION ofSection:_openedSection];
                
                [TUIView animateWithDuration:durationForOffset(firstOffset) animations:^{
                    
                    [TUIView setAnimationCurve:TUIViewAnimationCurveEaseIn];
                    [topSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        if (idx > _openedSection) {
                            [self _moveSection:idx forOffset:firstOffset];
                        }
                    }];
                    [self _moveSection:section forOffset:firstOffset];
                    
                    [topSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        if (idx <= _openedSection) {
                            [self _moveSection:idx forOffset:-secondOffset];
                        }
                    }];
                    [self setContentSize:CGSizeMake(self.contentSize.width, newContentHeight)];
                    
                    if (newContentHeight < CGRectGetHeight(self.bounds)) {
                        CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(self.bounds) - newContentHeight);
                        [self setContentOffset:newOffset];
                    } else if (newContentHeight < CGRectGetMaxY(realVisibleRect)) {
                        CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(realVisibleRect) - newContentHeight);
                        [self setContentOffset:newOffset];
                    }
                    
                } completion:^(BOOL finished) {
                    [self _setZposition:NORMAL_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:_openedSection]];
                    compleationBlock(finished);
                }];
            } else if ( openedSectionHeight <= newCurSectionHeight || CGRectGetMinY(newCurSectionRect) < CGRectGetMinY(realVisibleRect) ) {
                // Bottom slides;
                
                //                    NSLog(@"Opened below, op height < current");
                
                CGFloat firstOffset =  openedSectionHeight - openedSectionHeaderHeight;
                CGFloat secondOffset = _transitionOffset - openedSectionHeight + curSectionHeaderHeight;
                [self _setZposition:BACK_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
                
                [topSections addIndex:section];
                
                [TUIView animateWithDuration:durationForOffset(firstOffset) animations:^{
                    [TUIView setAnimationCurve:TUIViewAnimationCurveEaseIn];
                    [bottomSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        if (idx <= _openedSection)
                            [self _moveSection:idx forOffset:-firstOffset];
                    }];
                    
                } completion:^(BOOL finished) {
                    [TUIView animateWithDuration:durationForOffset(secondOffset) animations:^{
                        [TUIView setAnimationCurve:TUIViewAnimationCurveEaseOut];
                        
                        [self _moveSections:bottomSections forOffset:-secondOffset];
                        [self setContentSize:CGSizeMake(self.contentSize.width, newContentHeight)];
                        // If content have fit on screen itself, then needs to help with
                        if (newContentHeight < CGRectGetHeight(self.bounds)) {
                            CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(self.bounds) - newContentHeight);
                            [self setContentOffset:newOffset];
                        } else if (newContentHeight < CGRectGetMaxY(realVisibleRect)) {
                            CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(realVisibleRect) - newContentHeight);
                            [self setContentOffset:newOffset];
                        }
                    } completion:^(BOOL finished) {
                        [self _setZposition:NORMAL_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
                        compleationBlock(finished);
                    }];
                }];
            } else if (openedSectionHeight > newCurSectionHeight) {
                //                    NSLog(@"Opened below, op height > current");
                CGFloat firstOffset = newCurSectionHeight - curSectionHeaderHeight;
                CGFloat secondOffset = openedSectionHeight - newCurSectionHeight;
                
                //                    [self _setZposition:BACK_Z_POSITION ofSection:_openedSection];
                //                    [self _setZposition:BACK_Z_POSITION ofSection:section];
                
                [topSections addIndex:section];
                
                [TUIView animateWithDuration:durationForOffset(firstOffset) animations:^{
                    
                    [TUIView setAnimationCurve:TUIViewAnimationCurveEaseIn];
                    [bottomSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        if (idx <= _openedSection)
                            [self _moveSection:idx forOffset:-firstOffset];
                    }];
                    
                    [bottomSections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                        if (idx > _openedSection)
                            [self _moveSection:idx forOffset:secondOffset];
                    }];
                    
                    //                        [self setContentSize:CGSizeMake(self.contentSize.width, newContentHeight)];
                    //
                    //                        // If content have fit on screen itself, then needs to help with
                    //                        if (newContentHeight < CGRectGetHeight(self.bounds)) {
                    //                            CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(self.bounds) - newContentHeight);
                    //                            [self setContentOffset:newOffset];
                    //                        } else if (newContentHeight < CGRectGetMaxY(realVisibleRect)) {
                    //                            CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(realVisibleRect) - newContentHeight);
                    //                            [self setContentOffset:newOffset];
                    //                        }
                    
                } completion:^(BOOL finished) {
                    
                    [self _setZposition:NORMAL_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
                    compleationBlock(finished);
                }];
            }
            
            
        } else if (willCloseSection) {
            // !***
            // !** Needs to close
            // !**
            
            //                NSLog(@"Close");
            
            CGFloat offset = newCurSectionHeight - curSectionHeaderHeight;
            [self _setZposition:BACK_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
            [topSections addIndex:section];
            
            [TUIView animateWithDuration:durationForOffset(offset) animations:^{
                [self _moveSections:bottomSections forOffset:offset];
                
                //                    [self setContentSize:CGSizeMake(self.contentSize.width, newContentHeight)];
                //                    // If content have fit on screen itself, then needs to help with
                //                    if (newContentHeight < CGRectGetHeight(self.bounds)) {
                //                        CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(self.bounds) - newContentHeight);
                //                        [self setContentOffset:newOffset];
                //                    } else if (newContentHeight < CGRectGetMaxY(visibleRect)) {
                //                        CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(visibleRect) - newContentHeight);
                //                        [self setContentOffset:newOffset];
                //                    }
                
            } completion:^(BOOL finished) {
                [self _setZposition:NORMAL_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
                compleationBlock(finished);
            }];
            
        } else if (willOpenSection) {
            // !**
            // !** Needs to open section
            // !**
            [self _setZposition:BACK_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
            
            // restrict animation
            _transitionOffset = MIN(_transitionOffset, CGRectGetHeight(self.visibleRect));
            
            [topSections addIndex:section];
            //                NSLog(@"new section rect %@, visible rect %@, content offset %f", NSStringFromRect(transitedNewCurSectionRect), NSStringFromRect(realVisibleRect), self.contentOffset.y);
            [TUIView animateWithDuration:durationForOffset(_transitionOffset) animations:^{
                if (transitedNewCurSectionRect.origin.y < 0) {
                    [self _moveSections:topSections forOffset:_transitionOffset];
                } else {
                    [self _moveSections:bottomSections forOffset:-_transitionOffset];
                }
                
                // If content have fit on screen itself, then needs to help with
                //                    if (CGRectGetMaxY(curSectionHeaderRect) > CGRectGetMaxY(visibleRect)) {
                //                        CGPoint newOffset = CGPointMake(self.contentOffset.x, - (CGRectGetMaxY(curSectionHeaderRect) - CGRectGetHeight(visibleRect)));
                //                        [self setContentOffset: newOffset];
                //                        beginOffset = self.contentOffset;
                //                    } else if (newContentHeight < CGRectGetHeight(self.bounds)) {
                //                        CGPoint newOffset = CGPointMake(self.contentOffset.x, CGRectGetHeight(self.bounds) - newContentHeight);
                //                        [self setContentOffset: newOffset];
                //                        beginOffset = self.contentOffset;
                //                    }
            } completion:^(BOOL finished) {
                [self _setZposition:NORMAL_Z_POSITION ofSectionContents:[NSIndexSet indexSetWithIndex:section]];
                compleationBlock(finished);
                
            }];
        }
    finish:
        [TUIView commitAnimations];
    });

}


- (CGRect)proposedScrollRectForSection:(NSInteger)section;
{
    CGFloat padding = 10;
    CGRect scrollRect = CGRectOffset([self rectForSection:section], 0, padding);
    CGRect visibleRect = [self visibleRect];
    
    // If section not fit in visible rect, will place it on screen by header to top
    // or if section is above
    if (    CGRectGetHeight(scrollRect) > CGRectGetHeight(visibleRect)
        ||  CGRectGetMaxY(scrollRect) > CGRectGetMaxY(visibleRect))
    {
        scrollRect = [self rectForHeaderOfSection:section];
        scrollRect.origin.y -= CGRectGetHeight(visibleRect) - CGRectGetHeight(scrollRect);
        scrollRect.size.height = CGRectGetHeight(visibleRect);
    }
    
    return scrollRect;
}

- (void)scrollToSection:(NSInteger)section;
{
    BOOL animated = [TUIView isInAnimationContext];
    if (section == 0)
        return [self scrollToTopAnimated:animated];
    
    [self scrollRectToVisible:[self proposedScrollRectForSection:section] animated:animated];
}

- (BOOL)sectionIsOpened:(NSInteger)section;
{
    return (_openning && _openningSection == section) || (section == _openedSection);
}



#pragma mark - Helpers

-(void)_setZposition:(CGFloat)newZposition ofSectionHeaders:(NSIndexSet *)sections {
    [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        //        TUIView *header = [self headerViewForSection:section];
        //        header.layer.zPosition = newZposition;
        
        TUIView *header = [self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
        header.layer.zPosition = newZposition;
    }];
    
}

-(void)_setZposition:(CGFloat)newZposition ofSectionContents:(NSIndexSet *)sections {
    [sections enumerateIndexesUsingBlock:^(NSUInteger section, BOOL *stop) {
        
        NSIndexPath *from = [NSIndexPath indexPathForRow:0 inSection:section];
        NSIndexPath *to = [NSIndexPath indexPathForRow:[self numberOfRowsInSection:section] - 1 inSection:section];
        
        [self enumerateIndexPathsFromIndexPath:from toIndexPath:to withOptions:0 usingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
            TUITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
            cell.layer.zPosition = newZposition;
            [cell.layer setNeedsDisplay];
        }];
        
        if (_openning && _openningSection == section && self.openedSectionBackgroundView) {
            self.openedSectionBackgroundView.layer.zPosition = newZposition - 1.0;
        }
        if (_openning && _openedSection == section && _oldBackgroundView) {
            _oldBackgroundView.layer.zPosition = newZposition - 50.0;
        }
        
    }];
}


//-(void)_setZposition:(CGFloat)newZposition ofSection:(NSInteger)section {
//    TUIView *header = [self headerViewForSection:section];
//    header.layer.zPosition = newZposition;
//
//    if (_openning && _openningSection == section && self.openedSectionBackgroundView) {
//        self.openedSectionBackgroundView.layer.zPosition = newZposition - 1.0;
//    }
//    if (_openning && _openedSection == section && _oldBackgroundView) {
//        _oldBackgroundView.layer.zPosition = newZposition - 1.0;
//    }
//
//    NSIndexPath *from = [NSIndexPath indexPathForRow:0 inSection:section];
//    NSIndexPath *to = [NSIndexPath indexPathForRow:[self numberOfRowsInSection:section] - 1 inSection:section];
//
//    [self enumerateIndexPathsFromIndexPath:from toIndexPath:to withOptions:0 usingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
//        TUITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
//        cell.layer.zPosition = newZposition;
//    }];
//}
//
//-(void)_setZposition:(CGFloat)newZposition ofSections:(NSIndexSet *)sections {
//    [sections enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
//        [self _setZposition:newZposition ofSection: idx];
//    }];
//}


- (void)_moveSections:(NSIndexSet *)indexes forOffset:(CGFloat)offset;
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [self _moveSection:idx forOffset:offset];
    }];
}

- (void)_moveSection:(NSInteger)section forOffset:(CGFloat)offset
{
    
    TUIView *header = [self headerViewForSection:section];
    header.frame = CGRectOffset(header.frame, 0, offset);
    
    if (_openning && _openningSection == section && self.openedSectionBackgroundView) {
        self.openedSectionBackgroundView.frame = CGRectOffset(self.openedSectionBackgroundView.frame, 0, offset);
        //        self.openedSectionBackgroundView.hidden = YES;
    }
    if (_openning && _openedSection == section && _oldBackgroundView) {
        _oldBackgroundView.frame = CGRectOffset(_oldBackgroundView.frame, 0, offset);
        //        _oldBackgroundView.hidden = YES;
    }
    
    NSIndexPath *from = [NSIndexPath indexPathForRow:0 inSection:section];
    NSIndexPath *to = [NSIndexPath indexPathForRow:[self numberOfRowsInSection:section] - 1 inSection:section];
    
    [self enumerateIndexPathsFromIndexPath:from toIndexPath:to withOptions:0 usingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
        TUITableViewCell *cell = [self cellForRowAtIndexPath:indexPath];
        //        if (!cell) NSLog(@"no cell: %@", indexPath);
        
        cell.frame = CGRectOffset(cell.frame, 0, offset);
        //        cell.layer.borderColor = [[NSColor redColor] CGColor];
        //        cell.layer.borderWidth = 1.0;
    }];
}

-(NSIndexSet *)_visibleSectionsInRange:(NSRange)range {
    
    return [[NSIndexSet indexSetWithIndexesInRange:range] indexesPassingTest:^BOOL(NSUInteger idx, BOOL *stop) {
        return ([self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:idx]] != nil);
    }];
}

-(NSIndexSet *)_visibleSectionsBeforeSection:(NSInteger)section {
    if (section > 0) {
        return [self _visibleSectionsInRange:NSMakeRange(0, section)];
    } else {
        return nil;
    }
}
-(NSIndexSet *)_visibleSectionsAfterSection:(NSInteger)section {
    if (section < ([self numberOfSections] - 1)) {
        return [self _visibleSectionsInRange:NSMakeRange(section + 1, [self numberOfSections] - section)];
    } else {
        return nil;
    }
}

#pragma mark - Overload
// This method is used in inner method -_layoutCells to define visible cells;
// so we extend it to provide creating some aaditional cells for animation purpose
-(NSArray *)indexPathsForRowsInRect:(CGRect)rect {
    
    if (!_openning) {
        return [super indexPathsForRowsInRect:rect];
    } else {
        // to provide needed cells for opening/closing animation we extend visible rect
        // and add new cella to visible cells array restricting number of rows in opened and
        // opening sections
        
        NSMutableArray *originalIndexPaths = [NSMutableArray arrayWithCapacity:50];
        [originalIndexPaths addObjectsFromArray:[super indexPathsForRowsInRect:rect]];
        
        NSRect visibleRect = [self visibleRect];
        NSRect extendedVisibleRect = NSInsetRect(visibleRect, 0, -visibleRect.size.height);
        
        // define a number of rows that can be viewed in visible rect
        NSInteger testSection = (_openedSection != NSIntegerMin) ? _openedSection : _openningSection;
        CGFloat rowHeight = [self rectForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:testSection]].size.height;
        NSInteger maxRowCount = ceil(visibleRect.size.height / rowHeight);
        
        // go up from first visible cell to top of table
        NSMutableArray *topIndexPaths = [NSMutableArray arrayWithCapacity:50];
        for(NSInteger sectionIndex = [originalIndexPaths[0] section]; sectionIndex >= 0; sectionIndex--) {
            NSInteger numberOfRows = [self numberOfRowsInSection:sectionIndex];
            NSInteger numberOfAddedRows = 0;
            for(NSInteger row = numberOfRows; row >= 0; row--) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:sectionIndex];
                CGRect cellRect = [self rectForRowAtIndexPath:indexPath];
                if(CGRectIntersectsRect(cellRect, extendedVisibleRect)) {
                    if (![originalIndexPaths containsObject:indexPath]) {
                        [topIndexPaths addObject:indexPath];
                    }
                } else {
                    // not visible
                }
                numberOfAddedRows++;
                if (numberOfAddedRows >= maxRowCount) {
                    break;
                }
            }
        }
        
        // go down from last visible cell to bottom of table
        NSMutableArray *bottomIndexPaths = [NSMutableArray arrayWithCapacity:50];
        for(NSInteger sectionIndex = [[originalIndexPaths lastObject] section]; sectionIndex < [self numberOfSections]; sectionIndex++) {
            NSInteger numberOfRows = [self numberOfRowsInSection:sectionIndex];
            NSInteger numberOfAddedRows = 0;
            for(NSInteger row = 0; row < numberOfRows; ++row) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:sectionIndex];
                CGRect cellRect = [self rectForRowAtIndexPath:indexPath];
                if(CGRectIntersectsRect(cellRect, extendedVisibleRect)) {
                    if (![originalIndexPaths containsObject:indexPath]) {
                        [bottomIndexPaths addObject:indexPath];
                    }
                } else {
                    // not visible
                }
                numberOfAddedRows++;
                if (numberOfAddedRows >= maxRowCount) {
                    break;
                }
            }
        }
        NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:50];
        [resultArray addObjectsFromArray:topIndexPaths];
        [resultArray addObjectsFromArray:originalIndexPaths];
        [resultArray addObjectsFromArray:bottomIndexPaths];
        
        return resultArray;
    }
    
    
}

//- (CGRect)visibleRect
//{
//    CGRect vr = [super visibleRect];
//    if (_openning) {
//        vr.size.height += 2*(_topOffset + _transitionOffset + _bottomOffset);
//        vr.origin.y -= (_bottomOffset  + _transitionOffset + _topOffset);
//    }
//
//    return vr;
//}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!_openning && self.openedSectionBackgroundView)
    {
        self.openedSectionBackgroundView.frame = [self _backgroundRectForSectionRect:[self rectForSection:_openedSection]];
    }
    
    if (_openning && _oldBackgroundView)
    {
        CGRect sectionRect = [self rectForSection:_openedSection];
        CGRect currentRect = [[self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:_openedSection]] frame];
        sectionRect = CGRectOffset(sectionRect, 0, -(CGRectGetMaxY(sectionRect) - CGRectGetMaxY(currentRect)));
        _oldBackgroundView.frame = [self _backgroundRectForSectionRect:sectionRect];
    }
}

@end