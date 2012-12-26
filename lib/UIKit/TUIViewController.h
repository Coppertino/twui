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

#import "TUIResponder.h"

@class TUIView;
@class TUINavigationController;

// The TUIViewController class provides the fundamental view-management model.
// You rarely instantiate TUIViewController directly. Instead, you
// instantiate subclasses of the TUIViewController class based on the
// specific task each subclass performs. A view controller manages a
// set of views that make up a portion of the user interface. As part
// of the controller layer of your app, a view controller coordinates
// its efforts with model objects and other controller objects—including
// other view controllers—so your app presents a single coherent user interface.
//
// Where necessary, a view controller: resizes and lays out its views,
// adjusts the contents of the views, acts on behalf of the views when
// the user interacts with them.
//
// View controllers are tightly bound to the views they manage and take
// part in the responder chain used to handle events. View controllers
// are descendants of the TUIResponder class and are inserted into the
// responder chain between the managed root view and its superview,
// which typically belongs to a different view controller. If the view
// controller’s view does not handle an event, the view controller has
// the option of handling the event or it can pass the event to the superview.
//
// View controllers are rarely used in isolation. Instead, you use multiple
// view controllers, each of which owns a portion of the user interface.
// For example, one view controller might manage a table of items while a
// different view controller manages the display of a selected item from
// that table. Each view controller displays its own views to show the
// content it is responsible for.
@interface TUIViewController : TUIResponder <NSCopying>

// Localized title for use by a parent controller. It should be set to
// a human-readable string that represents the view to the user.
@property (nonatomic, copy) NSString *title;

// The view stored in this property represents the root view for the view
// controller’s view hierarchy. The default value of this property is nil.
// If you access this property and its value is currently nil, the view
// controller automatically calls the -loadView method and returns the resulting
// view. Each view controller object is the sole owner of its view. You must
// not associate the same view object with multiple view controller objects.
// The only exception to this rule is that a container view controller
// implementation may add this view as a subview in its own view hierarchy.
// Before adding the subview, the container must first call its addChildViewController:
// method to create a parent-child relationship between the two view controller
// objects. Because accessing this property can cause the view to be loaded
// automatically, you can use the isViewLoaded method to determine if the view
// is currently in memory. Unlike this property, the isViewLoaded property
// does not force the loading of the view if it is not currently in memory.
@property (nonatomic, strong) TUIView *view;

@property (nonatomic, readonly, getter = isViewLoaded) BOOL viewLoaded;

// If this view controller is a child of a containing view controller,
// this is the containing view controller.
@property (nonatomic, unsafe_unretained, readonly) TUIViewController *parentViewController;

// An array of children view controllers. This array does not include any presented view controllers.
@property (nonatomic, readonly) NSArray *childViewControllers;

// These four methods can be used in a view controller's appearance callbacks
// to determine if it is being presented, dismissed, or added or removed as
// a child view controller. For example, a view controller can check if it is
// disappearing because it was dismissed or popped by asking itself in its
// viewWillDisappear: method by checking the expression: [self isMovingFromParentViewController]
@property (nonatomic, readonly, getter = isMovingToParentViewController) BOOL movingToParentViewController;
@property (nonatomic, readonly, getter = isMovingFromParentViewController) BOOL movingFromParentViewController;

// This is where subclasses should create their custom view hierarchy.
// This method should never be called directly. Default implementation does nothing.
- (void)loadView;

// Called after the view has been loaded.
// This method is called after -loadView. Default implementation does nothing.
- (void)viewDidLoad;

// Called after the view controller's view is released and set to nil.
// Not invoked as a result of -dealloc. Default implementation does nothing.
- (void)viewDidUnload;

// Called when the view is about to made visible.
// Default implementation does nothing.
- (void)viewWillAppear:(BOOL)animated;

// Called when the view has been fully transitioned onto the screen.
// Default implementation does nothing.
- (void)viewDidAppear:(BOOL)animated;

// Called when the view is dismissed, covered or otherwise hidden.
// Default implementation does nothing.
- (void)viewWillDisappear:(BOOL)animated;

// Called after the view was dismissed, covered or otherwise hidden.
// Default implementation does nothing.
- (void)viewDidDisappear:(BOOL)animated;

// Called just before the view controller's view's layoutSubviews method is invoked.
// Subclasses can implement as necessary. Default implementation does nothing.
- (void)viewWillLayoutSubviews;

// Called just after the view controller's view's layoutSubviews method is invoked.
// Subclasses can implement as necessary. Default implementation does nothing.
- (void)viewDidLayoutSubviews;

// If the child controller has a different parent controller, it will first be
// removed from its current parent by calling removeFromParentViewController.
// If this method is overridden then the super implementation must be called.
- (void)addChildViewController:(TUIViewController *)childController;

// Removes the the receiver from its parent's children controllers array.
// If this method is overridden then the super implementation must be called.
- (void)removeFromParentViewController;

// These two methods are public for container subclasses to call
// when transitioning between child controllers. If they are overridden,
// the overrides should ensure to call the super. The parent argument
// in both of these methods is nil when a child is being removed from
// its parent; otherwise it is equal to the new parent view controller.
// addChildViewController: will call [child willMoveToParentViewController:self]
// before adding the child. However, it will not call didMoveToParentViewController:
// It is expected that a container view controller subclass will make
// this call after a transition to the new child has completed or, in
// the case of no transition, immediately after the call to addChildViewController:
// Similarly removeFromParentViewController: does not call
// [self willMoveToParentViewController:nil] before removing the child.
// This is also the responsibilty of the container subclass. Container
// subclasses will typically define a method that transitions to a new
// child by first calling addChildViewController:, then executing a
// transition which will add the new child's view into the view hierarchy
// of its parent, and finally will call didMoveToParentViewController:
// Similarly, subclasses will typically define a method that removes
// a child in the reverse manner by first calling willMoveToParentViewController:
- (void)willMoveToParentViewController:(TUIViewController *)parent;
- (void)didMoveToParentViewController:(TUIViewController *)parent;

// These methods can be used to transition between sibling child view controllers.
// The receiver of these methods is their common parent view controller.
// (Use [TUIViewController addChildViewController:] to create the parent/child
// relationship.) These methods will add the toViewController's view to the
// superview of the fromViewController's view and the fromViewController's view
// will be removed from its superview after the transition completes. It is
// important to allow these methods to add and remove the views. The arguments to
// these methods are the same as those defined by TUIView's block animation API.
// These methods will fail with an NSInvalidArgumentException if the parent view
// controllers are not the same as the receiver. Finally, the receiver should
// not be a subclass of an container view controller. Note also that it is possible
// to use the TUIView APIs directly. If they are used, it is important to ensure
// that the toViewController's view is added to the visible view hierarchy
// while the fromViewController's view is removed.

- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
						  animations:(void (^)(void))animations;

- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
							duration:(NSTimeInterval)duration
						  animations:(void (^)(void))animations;

- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
							duration:(NSTimeInterval)duration
						  animations:(void (^)(void))animations
						  completion:(void (^)(BOOL finished))completion;

- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
							duration:(NSTimeInterval)duration
							   delay:(NSTimeInterval)delay
						  animations:(void (^)(void))animations
						  completion:(void (^)(BOOL finished))completion;

@end
