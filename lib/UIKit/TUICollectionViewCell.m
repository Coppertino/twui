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
#import "TUICollectionViewCell.h"
#import "TUICollectionViewLayout.h"

@interface TUICollectionReusableView () {
    struct {
        unsigned inUpdateAnimation:1;
    } _reusableViewFlags;
}

@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, unsafe_unretained) TUICollectionView *collectionView;
@property (nonatomic, strong) TUICollectionViewLayoutAttributes *layoutAttributes;

@end

@implementation TUICollectionReusableView

#pragma mark - Public

- (void)prepareForReuse {
    self.layoutAttributes = nil;
}

- (void)applyLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes {
    if (layoutAttributes != _layoutAttributes) {
        _layoutAttributes = layoutAttributes;

        self.layer.frame = layoutAttributes.frame;
        self.layer.position = layoutAttributes.center;

        self.hidden = layoutAttributes.isHidden;
        self.layer.transform = layoutAttributes.transform3D;
        self.layer.zPosition = layoutAttributes.zIndex;
        self.layer.opacity = layoutAttributes.alpha;
    }
}

- (void)willTransitionFromLayout:(TUICollectionViewLayout *)oldLayout toLayout:(TUICollectionViewLayout *)newLayout {
    _reusableViewFlags.inUpdateAnimation = YES;
}

- (void)didTransitionFromLayout:(TUICollectionViewLayout *)oldLayout toLayout:(TUICollectionViewLayout *)newLayout {
    _reusableViewFlags.inUpdateAnimation = NO;
}

- (BOOL)isInUpdateAnimation {
    return _reusableViewFlags.inUpdateAnimation;
}

- (void)setInUpdateAnimation:(BOOL)inUpdateAnimation {
    _reusableViewFlags.inUpdateAnimation = inUpdateAnimation;
}

@end

@implementation TUICollectionViewCell {
    struct {
        unsigned selected:1;
        unsigned highlighted:1;
        unsigned showingMenu:1;
        unsigned clearSelectionWhenMenuDisappears:1;
        unsigned waitingForSelectionAnimationHalfwayPoint:1;
    } _collectionCellFlags;
}

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
        _backgroundView = [[TUIView alloc] initWithFrame:self.bounds];
        _backgroundView.autoresizingMask = TUIViewAutoresizingFlexibleWidth | TUIViewAutoresizingFlexibleHeight;
        [self addSubview:_backgroundView];

        _contentView = [[TUIView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = TUIViewAutoresizingFlexibleWidth | TUIViewAutoresizingFlexibleHeight;
        [self addSubview:_contentView];
    }
	
    return self;
}

#pragma mark - Public

- (void)prepareForReuse {
    self.layoutAttributes = nil;
    self.selected = NO;
    self.highlighted = NO;
}

- (void)setSelected:(BOOL)selected {
    if(_collectionCellFlags.selected != selected) {
        _collectionCellFlags.selected = selected;
		
        [self updateBackgroundView];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if(_collectionCellFlags.highlighted != highlighted) {
        _collectionCellFlags.highlighted = highlighted;
		
        [self updateBackgroundView];
    }
}

- (void)updateBackgroundView {
    BOOL shouldHighlight = (self.highlighted || self.selected);
    _selectedBackgroundView.alpha = shouldHighlight ? 1.0f : 0.0f;
    [self setHighlighted:shouldHighlight forViews:self.contentView.subviews];
}

- (void)setHighlighted:(BOOL)highlighted forViews:(id)subviews {
    for(id view in subviews) {
        if([view respondsToSelector:@selector(setHighlighted:)]) {
            [view setHighlighted:highlighted];
        }
		
        [self setHighlighted:highlighted forViews:[view subviews]];
    }
}

- (void)setBackgroundView:(TUIView *)backgroundView {
    if(_backgroundView != backgroundView) {
        _backgroundView = backgroundView;
        [self insertSubview:_backgroundView atIndex:0];
    }
}

- (void)setSelectedBackgroundView:(TUIView *)selectedBackgroundView {
    if(_selectedBackgroundView != selectedBackgroundView) {
        _selectedBackgroundView = selectedBackgroundView;
        _selectedBackgroundView.frame = self.bounds;
		
        _selectedBackgroundView.autoresizingMask = TUIViewAutoresizingFlexibleWidth | TUIViewAutoresizingFlexibleHeight;
        _selectedBackgroundView.alpha = self.selected ? 1.0f : 0.0f;
        
		if(_backgroundView)
            [self insertSubview:_selectedBackgroundView aboveSubview:_backgroundView];
        else
            [self insertSubview:_selectedBackgroundView atIndex:0];
    }
}

- (BOOL)isSelected {
    return _collectionCellFlags.selected;
}

- (BOOL)isHighlighted {
    return _collectionCellFlags.highlighted;
}

@end
