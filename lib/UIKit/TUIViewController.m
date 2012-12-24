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

#import "TUIViewController.h"
#import "TUIView.h"

NSString *const TUIViewControllerHierarchyInconsistencyException = @"TUIViewControllerHierarchyInconsistencyException";

@interface TUIViewController () {
	struct {
		unsigned int definesPresentationContext:1;
		unsigned int isBeingPresented:1;
		unsigned int isBeingDismissed:1;
		unsigned int isMovingToParentViewController:1;
		unsigned int isMovingFromParentViewController:1;
	} _viewControllerFlags;
}

@property (nonatomic, strong) NSMutableArray *subViewControllers;
@property (nonatomic, unsafe_unretained, readwrite) TUIViewController *parentViewController;
@property (nonatomic, unsafe_unretained, readwrite) TUIViewController *presentedViewController;
@property (nonatomic, unsafe_unretained, readwrite) TUIViewController *presentingViewController;

@end

@implementation TUIViewController

#pragma mark - Initialization

@synthesize view = _view;
@synthesize modalPresentationStyle = _modalPresentationStyle;

- (id)copyWithZone:(NSZone *)zone {
	return self.class.new;
}

#pragma mark - View Accessors

- (TUIView *)view {
	if(!_view) {
		[self loadView];
		[self viewDidLoad];
		
		[_view setNextResponder:self];
	}
	
	return _view;
}

- (void)setView:(TUIView *)view {
	_view = view;
	
	if(!_view)
		[self viewDidUnload];
}

#pragma mark - Properties

- (BOOL)isViewLoaded {
	return _view != nil;
}

- (NSArray *)childViewControllers {
	return [self.subViewControllers copy];
}

- (BOOL)isBeingPresented {
	return _viewControllerFlags.isBeingPresented;
}

- (BOOL)isBeingDismissed {
	return _viewControllerFlags.isBeingDismissed;
}

- (BOOL)isMovingFromParentViewController {
	return _viewControllerFlags.isMovingFromParentViewController;
}

- (BOOL)isMovingToParentViewController {
	return _viewControllerFlags.isMovingToParentViewController;
}

- (BOOL)definesPresentationContext {
	return _viewControllerFlags.definesPresentationContext;
}

- (void)setDefinesPresentationContext:(BOOL)flag {
	_viewControllerFlags.definesPresentationContext = flag;
}

#pragma mark - View Management

- (void)loadView {
	self.view = [[TUIView alloc] initWithFrame:CGRectZero];
	// Overriden by subclasses.
}

- (void)viewDidLoad {
	// Implemented by subclasses.
}

- (void)viewDidUnload {
	// Implemented by subclasses.
}

- (void)viewWillAppear:(BOOL)animated {
	// Implemented by subclasses.
}

- (void)viewDidAppear:(BOOL)animated {
	// Implemented by subclasses.
}

- (void)viewWillDisappear:(BOOL)animated {
	// Implemented by subclasses.
}

- (void)viewDidDisappear:(BOOL)animated {
	// Implemented by subclasses.
}

- (void)viewWillLayoutSubviews {
	// Implemented by subclasses.
}

- (void)viewDidLayoutSubviews {
	// Implemented by subclasses.
}

#pragma mark - View Controller Heirarchy

- (void)addChildViewController:(TUIViewController *)childController {
	[childController willMoveToParentViewController:self];
	[self.subViewControllers addObject:childController];
	childController.parentViewController = self;
}

- (void)removeFromParentViewController {
	[self.parentViewController.subViewControllers removeObject:self];
	self.parentViewController = nil;
	[self didMoveToParentViewController:nil];
}

- (void)willMoveToParentViewController:(TUIViewController *)parent {
	_viewControllerFlags.isMovingFromParentViewController = (parent == nil);
	_viewControllerFlags.isMovingToParentViewController = (parent != nil);
}

- (void)didMoveToParentViewController:(TUIViewController *)parent {
	_viewControllerFlags.isMovingFromParentViewController = NO;
	_viewControllerFlags.isMovingToParentViewController = NO;
}

#pragma mark - View Controller Presentation

- (void)presentViewController:(TUIViewController *)viewControllerToPresent animated:(BOOL)flag {
	[self presentViewController:viewControllerToPresent animated:flag completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag {
	[self dismissViewControllerAnimated:flag completion:nil];
}

- (void)presentViewController:(TUIViewController *)viewControllerToPresent
					 animated:(BOOL)flag
				   completion:(void (^)(void))completion {
	
	// Link view controller presentation.
	self.presentedViewController = viewControllerToPresent;
	viewControllerToPresent.presentingViewController = self;
	
	// Tell ourselves that we'll appear because of presentation.
	viewControllerToPresent->_viewControllerFlags.isBeingPresented = YES;
	[self viewWillAppear:flag];
	
	// TODO: Animate presentation
	// TODO: Take into account the context of the controller.
	// TODO: Actually present the controller.
	
	// Tell ourselves that we've appeared because of presentation.
	viewControllerToPresent->_viewControllerFlags.isBeingPresented = NO;
	[self viewDidAppear:flag];
	
	// Fire completion block.
	_viewControllerFlags.isBeingPresented = NO;
	if(completion)
		completion();
}

- (void)dismissViewControllerAnimated:(BOOL)flag
						   completion:(void (^)(void))completion {
	
	// Unlink view controller presentation.
	self.presentedViewController.presentingViewController = nil;
	self.presentingViewController = nil;
	
	// Tell ourselves that we'll disappear because of dismissal.
	_viewControllerFlags.isBeingDismissed = YES;
	[self viewWillDisappear:flag];
	
	// TODO: Animate dismissal
	// TODO: Actually dismiss the controller.
	
	// Tell ourselves we've disappeared because of dismissal.
	_viewControllerFlags.isBeingDismissed = NO;
	[self viewDidDisappear:flag];
	
	// Fire completion block.
	if(completion)
		completion();
}

#pragma mark - View Controller Transitions

// Forwarded to the complex version of the method.
- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
						  animations:(void (^)(void))animations {
	[self transitionFromViewController:fromViewController
					  toViewController:toViewController
							  duration:0.25f
							animations:animations
							completion:nil];
}

// Forwarded to the complex version of the method.
- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
							duration:(NSTimeInterval)duration
						  animations:(void (^)(void))animations {
	[self transitionFromViewController:fromViewController
					  toViewController:toViewController
							  duration:duration
							animations:animations
							completion:nil];
}

// Forwarded to the complex version of the method.
- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
							duration:(NSTimeInterval)duration
						  animations:(void (^)(void))animations
						  completion:(void (^)(BOOL finished))completion {
	[self transitionFromViewController:fromViewController
					  toViewController:toViewController
							  duration:duration
								 delay:0.0f
							animations:animations
							completion:completion];
}

- (void)transitionFromViewController:(TUIViewController *)fromViewController
					toViewController:(TUIViewController *)toViewController
							duration:(NSTimeInterval)duration
							   delay:(NSTimeInterval)delay
						  animations:(void (^)(void))animations
						  completion:(void (^)(BOOL finished))completion {
	
	// If our view is not loaded, we have no way to transition views.
	if(![self isViewLoaded])
		return;
	
	// If the controllers are not on our controller heirarchy, don't transition.
	if(![fromViewController.parentViewController isEqual:self] || ![toViewController.parentViewController isEqual:self]) {
		[NSException raise:NSInvalidArgumentException format:@"The view controllers parents' must be the receiver."];
		return;
	}
	
	// Remove the fromViewController if its view is attached to our view.
	// Then attach the toViewController to our view.
	if([fromViewController isViewLoaded] && [fromViewController.view.superview isEqual:self.view])
		[fromViewController.view removeFromSuperview];
	[self.view addSubview:toViewController.view];
	
	// Finally, call the animation block to animate them into place.
	[TUIView animateWithDuration:duration delay:delay animations:animations completion:completion];
}

#pragma mark - Modal Presentation

- (TUIModalPresentationStyle)modalPresentationStyle {
	TUIModalPresentationStyle currentStyle = _modalPresentationStyle;
	
	if(currentStyle == TUIModalPresentationContext) {
		if(self.view.window.isSheet)
			currentStyle = TUIModalPresentationSheet;
		else if([self.view.window isKindOfClass:NSPanel.class])
			currentStyle = TUIModalPresentationPanel;
		else if(self.view.window.styleMask & NSFullScreenWindowMask)
			currentStyle = TUIModalPresentationFullScreen;
		else
			currentStyle = TUIModalPresentationView;
	}
	
	return currentStyle;
}

- (void)setModalPresentationStyle:(TUIModalPresentationStyle)style {
	_modalPresentationStyle = style;
}

#pragma mark - Responder Chain

- (BOOL)performKeyEquivalent:(NSEvent *)event {
	return NO;
}

- (TUIResponder *)initialFirstResponder {
	return _view.initialFirstResponder;
}

@end
