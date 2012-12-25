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
	NSMutableArray *_childViewControllers;
	
	struct {
		unsigned int isMovingToParentViewController:1;
		unsigned int isMovingFromParentViewController:1;
	} _viewControllerFlags;
}

@property (nonatomic, unsafe_unretained, readwrite) TUIViewController *parentViewController;
@property (nonatomic, unsafe_unretained, readwrite) TUIViewController *presentedViewController;
@property (nonatomic, unsafe_unretained, readwrite) TUIViewController *presentingViewController;

@end

@implementation TUIViewController

#pragma mark - Initialization

@synthesize view = _view;
@synthesize childViewControllers = _childViewControllers;

- (id)init {
	if((self = [super init])) {
		_childViewControllers = @[].mutableCopy;
	}
	return self;
}

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
	return [_childViewControllers copy];
}

- (BOOL)isMovingFromParentViewController {
	return _viewControllerFlags.isMovingFromParentViewController;
}

- (BOOL)isMovingToParentViewController {
	return _viewControllerFlags.isMovingToParentViewController;
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
    [self beginAppearanceTransition:YES animated:animated];
	// Implemented by subclasses.
}

- (void)viewDidAppear:(BOOL)animated {
    [self endAppearanceTransition];
	// Implemented by subclasses.
}

- (void)viewWillDisappear:(BOOL)animated {
    [self beginAppearanceTransition:NO animated:animated];
	// Implemented by subclasses.
}

- (void)viewDidDisappear:(BOOL)animated {
    [self endAppearanceTransition];
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
	
	if(childController.parentViewController) {
		[childController.parentViewController->_childViewControllers removeObject:self];
		childController.parentViewController = nil;
	}
	
	[_childViewControllers addObject:childController];
	childController.parentViewController = self;
}

- (void)removeFromParentViewController {
	if(self.parentViewController) {
		[self.parentViewController->_childViewControllers removeObject:self];
		self.parentViewController = nil;
	}
	
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
	
	// Keep the toViewController attached while we animate.
	// Then call the animation block to animate them into place.
	// Finally, remove the fromViewController if its view is attached to our view.
	[self.view addSubview:toViewController.view];
	[TUIView animateWithDuration:duration delay:delay animations:animations completion:^(BOOL finished) {
		if([fromViewController.view.superview isEqual:self.view])
			[fromViewController.view removeFromSuperview];
		
		if(completion)
			completion(finished);
	}];
}

#pragma mark - View Appearance

- (BOOL)shouldAutomaticallyForwardAppearanceMethods {
	return YES;
}

- (void)beginAppearanceTransition:(BOOL)isAppearing animated:(BOOL)animated {
	
}

- (void)endAppearanceTransition {
	
}

#pragma mark - Responder Chain

- (BOOL)performKeyEquivalent:(NSEvent *)event {
	return NO;
}

- (TUIResponder *)initialFirstResponder {
	return _view.initialFirstResponder;
}

@end
