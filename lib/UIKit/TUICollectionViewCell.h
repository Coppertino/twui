//
//  TUICollectionViewCell.h
//
//  Original Source: Copyright (c) 2012 Peter Steinberger. All rights reserved.
//  AppKit Port: Copyright (c) 2012 Indragie Karunaratne. All rights reserved.
//

#import "TUICollectionViewCommon.h"

@class TUICollectionViewLayout, TUICollectionView, TUICollectionViewLayoutAttributes;

@interface TUICollectionReusableView : TUIView

@property (nonatomic, readonly, copy) NSString *reuseIdentifier;

// Override in subclasses. Called before instance is returned to the reuse queue.
- (void)prepareForReuse;

// Apply layout attributes on cell.
- (void)applyLayoutAttributes:(TUICollectionViewLayoutAttributes *)layoutAttributes;

- (void)willTransitionFromLayout:(TUICollectionViewLayout *)oldLayout toLayout:(TUICollectionViewLayout *)newLayout;
- (void)didTransitionFromLayout:(TUICollectionViewLayout *)oldLayout toLayout:(TUICollectionViewLayout *)newLayout;

@end

@interface TUICollectionReusableView (Internal)
@property (nonatomic, unsafe_unretained) TUICollectionView *collectionView;
@property (nonatomic, copy) NSString *reuseIdentifier;
@property (nonatomic, strong, readonly) TUICollectionViewLayoutAttributes *layoutAttributes;
@end


@interface TUICollectionViewCell : TUICollectionReusableView

@property (nonatomic, readonly) TUIView *contentView; // add custom subviews to the cell's contentView

// Cells become highlighted when the user touches them.
// The selected state is toggled when the user lifts up from a highlighted cell.
// Override these methods to provide custom PS for a selected or highlighted state.
// The collection view may call the setters inside an animation block.
@property (nonatomic, getter=isSelected) BOOL selected;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;

// The background view is a subview behind all other views.
// If selectedBackgroundView is different than backgroundView, it will be placed above the background view and animated in on selection.
@property (nonatomic, strong) TUIView *backgroundView;
@property (nonatomic, strong) TUIView *selectedBackgroundView;

@end
