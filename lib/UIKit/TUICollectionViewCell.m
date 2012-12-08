//
//  TUICollectionViewCell.m
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUICollectionView.h"
#import "TUICollectionViewCell.h"
#import "TUICollectionViewLayout.h"

@interface TUICollectionReusableView() {
    TUICollectionViewLayoutAttributes *_layoutAttributes;
    NSString *_reuseIdentifier;
    __unsafe_unretained TUICollectionView *_collectionView;
    struct {
        unsigned int inUpdateAnimation : 1;
    } _reusableViewFlags;
}
@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, unsafe_unretained) TUICollectionView *collectionView;
@property (nonatomic, strong) TUICollectionViewLayoutAttributes *layoutAttributes;
@end

@implementation TUICollectionReusableView

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (void)TUICollectionReusableViewCommonSetup
{
    self.layer.backgroundColor = [NSColor greenColor].CGColor;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self TUICollectionReusableViewCommonSetup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if((self = [super initWithCoder:aDecoder])) {
        [self TUICollectionReusableViewCommonSetup];
    }
    return self;
}

- (void)awakeFromNib {
    self.reuseIdentifier = [self valueForKeyPath:@"reuseIdentifier"];
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)prepareForReuse {
    self.layoutAttributes = nil;
}

- (void)applyLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes {
    if (layoutAttributes != _layoutAttributes) {
        _layoutAttributes = layoutAttributes;
        self.frame = layoutAttributes.frame;
        self.alpha = layoutAttributes.alpha;
        self.hidden = layoutAttributes.isHidden;
        self.layer.transform = layoutAttributes.transform3D;
        self.layer.zPosition = layoutAttributes.zIndex;
        // TODO more attributes
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
    TUIView *_contentView;
    TUIView *_backgroundView;
    TUIView *_selectedBackgroundView;
    id _selectionSegueTemplate;
    id _highlightingSupport;
    struct {
        unsigned int selected : 1;
        unsigned int highlighted : 1;
        unsigned int showingMenu : 1;
        unsigned int clearSelectionWhenMenuDisappears : 1;
        unsigned int waitingForSelectionAnimationHalfwayPoint : 1;
    } _collectionCellFlags;
    BOOL _selected;
    BOOL _highlighted;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject

- (void)TUICollectionViewCellCommonSetup
{
    self.layer.backgroundColor = [NSColor purpleColor].CGColor;
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self TUICollectionReusableViewCommonSetup];
        _backgroundView = [[TUIView alloc] initWithFrame:self.bounds];
        _backgroundView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:_backgroundView];

        _contentView = [[TUIView alloc] initWithFrame:self.bounds];
        _contentView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:_contentView];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self TUICollectionReusableViewCommonSetup];
        if ([[self subviews] count] > 0) {
            _contentView = [self subviews][0];
        } else {
            _contentView = [[TUIView alloc] initWithFrame:self.bounds];
            _contentView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
            [self addSubview:_contentView];
        }
        
        _backgroundView = [[TUIView alloc] initWithFrame:self.bounds];
        _backgroundView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
		[self insertSubview:_backgroundView belowSubview:_contentView];
    }
    return self;
}

///////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Public

- (void)prepareForReuse {
    self.layoutAttributes = nil;
    self.selected = NO;
    self.highlighted = NO;
}

- (void)setSelected:(BOOL)selected {
    if (_collectionCellFlags.selected != selected) {
        _collectionCellFlags.selected = selected;
        [self updateBackgroundView];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    if (_collectionCellFlags.highlighted != highlighted) {
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
    for (id view in subviews) {
        if ([view respondsToSelector:@selector(setHighlighted:)]) {
            [view setHighlighted:highlighted];
        }
        [self setHighlighted:highlighted forViews:[view subviews]];
    }
}

- (void)setBackgroundView:(TUIView *)backgroundView {
    if (_backgroundView != backgroundView) {
        [_backgroundView removeFromSuperview];
        _backgroundView = backgroundView;
        _backgroundView.frame = self.bounds;
        _backgroundView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:_backgroundView];
    }
}

- (void)setSelectedBackgroundView:(TUIView *)selectedBackgroundView {
    if (_selectedBackgroundView != selectedBackgroundView) {
        [_selectedBackgroundView removeFromSuperview];
        _selectedBackgroundView = selectedBackgroundView;
        _selectedBackgroundView.frame = self.bounds;
        _selectedBackgroundView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        _selectedBackgroundView.alpha = self.selected ? 1.0f : 0.0f;
        if (_backgroundView) {
			[self insertSubview:_selectedBackgroundView aboveSubview:_backgroundView];
        } else {
			[self insertSubview:_selectedBackgroundView belowSubview:_backgroundView];
        }
    }
}

- (BOOL)isSelected {
    return _collectionCellFlags.selected;
}

- (BOOL)isHighlighted {
    return _collectionCellFlags.highlighted;
}
@end
