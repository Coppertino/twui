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
