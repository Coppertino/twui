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

#import "TUINavigationController.h"
#import "TUIView.h"

static CGFloat const TUINavigationControllerAnimationDuration = 0.25f;

static inline CGRect TUINavigationOffscreenLeftFrame(CGRect bounds) {
	CGRect offscreenLeft = bounds;
	offscreenLeft.origin.x -= bounds.size.width;
	return offscreenLeft;
}

static inline CGRect TUINavigationOffscreenRightFrame(CGRect bounds) {
	CGRect offscreenRight = bounds;
	offscreenRight.origin.x += bounds.size.width;
	return offscreenRight;
}

@implementation TUINavigationController

- (id)initWithRootViewController:(TUIViewController *)viewController {
	if ((self = [super init])) {
		[self addChildViewController:viewController];
		self.view.clipsToBounds = YES;
	}
	return self;
}

- (void)loadView {
	self.view = [[TUIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [NSColor lightGrayColor];
	
	TUIViewController *visible = [self topViewController];
	
	[visible viewWillAppear:NO];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[self.delegate navigationController:self willShowViewController:visible animated:NO];
	
	[self.view addSubview:visible.view];
	visible.view.frame = self.view.bounds;
	visible.view.autoresizingMask = TUIViewAutoresizingFlexibleSize;
	
	[visible viewDidAppear:YES];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
		[self.delegate navigationController:self didShowViewController:visible animated:NO];

}

#pragma mark - Properties

- (NSArray *)viewControllers {
	return self.childViewControllers;
}

- (TUIViewController *)topViewController {
	return [self.childViewControllers lastObject];
}

#pragma mark - Methods

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated {
	[self setViewControllers:viewControllers animated:animated completion:nil];
}

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {	
	TUIViewController *viewController = [viewControllers lastObject];
	TUIViewController *last = [self topViewController];
	
	CGFloat duration = (animated ? TUINavigationControllerAnimationDuration : 0);
	BOOL containedAlready = ([self.childViewControllers containsObject:viewController]);
	
	for (TUIViewController *controller in self.childViewControllers)
		[controller removeFromParentViewController];
	
	for (TUIViewController *controller in viewControllers)
		[self addChildViewController:controller];
	
	[self.view addSubview:viewController.view];
	[CATransaction begin];
	viewController.view.frame = (containedAlready ?
								 TUINavigationOffscreenLeftFrame(self.view.bounds) :
								 TUINavigationOffscreenRightFrame(self.view.bounds));
	[CATransaction flush];
	[CATransaction commit];
	
	[viewController viewWillAppear:animated];
	[last viewWillDisappear:animated];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[self.delegate navigationController:self willShowViewController:viewController animated:animated];
	
	[self transitionFromViewController:last toViewController:viewController duration:duration animations:^{
		last.view.frame = (containedAlready ?
						   TUINavigationOffscreenRightFrame(self.view.bounds) :
						   TUINavigationOffscreenLeftFrame(self.view.bounds));
		
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[viewController viewDidAppear:animated];
		
		if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
			[self.delegate navigationController:self didShowViewController:viewController animated:animated];
		
		[last viewDidDisappear:animated];
		
		if(completion)
			completion(finished);
	}];
}

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated {
	[self pushViewController:viewController animated:animated completion:nil];
}

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	
	CGFloat duration = (animated ? TUINavigationControllerAnimationDuration : 0);
	TUIViewController *last = [self topViewController];
	[self addChildViewController:viewController];
	
	[last viewWillDisappear:animated];
	[viewController viewWillAppear:animated];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[self.delegate navigationController:self willShowViewController:viewController animated:animated];
	
	[self.view addSubview:viewController.view];
	[CATransaction begin];
	viewController.view.frame = TUINavigationOffscreenRightFrame(self.view.bounds);
	[CATransaction flush];
	[CATransaction commit];
	
	[self transitionFromViewController:last toViewController:viewController duration:duration animations:^{
		last.view.frame = TUINavigationOffscreenLeftFrame(self.view.bounds);
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[viewController viewDidAppear:animated];
		
		if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
			[self.delegate navigationController:self didShowViewController:viewController animated:animated];
		
		[last viewDidDisappear:animated];
		
		if (completion)
			completion(finished);
	}];
}

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated {
	return [self popViewControllerAnimated:animated completion:nil];
}

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	if (self.childViewControllers.count <= 1) {
		NSLog(@"Not enough view controllers on stack to pop!");
		return nil;
	}
	
	TUIViewController *popped = [self.childViewControllers lastObject];
	[self popToViewController:self.childViewControllers[(self.childViewControllers.count - 2)]
					 animated:animated completion:completion];
	
	return popped;
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated {
	return [self popToRootViewControllerAnimated:animated completion:nil];
}

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	if ([[self topViewController] isEqual:self.childViewControllers[0]])
		return @[];
	
	return [self popToViewController:self.childViewControllers[0] animated:animated completion:completion];
}

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated {
	return [self popToViewController:viewController animated:animated completion:nil];
}

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion {
	
	TUIViewController *last = [self.childViewControllers lastObject];
	CGFloat duration = (animated ? TUINavigationControllerAnimationDuration : 0);
	
	if ([self.childViewControllers containsObject:viewController] == NO) {
		NSLog(@"View controller %@ is not in stack!", viewController);
		return @[];
	}
	
	[self.view addSubview:viewController.view];
	[CATransaction begin];
	viewController.view.frame = TUINavigationOffscreenLeftFrame(self.view.bounds);
	[CATransaction flush];
	[CATransaction commit];
	
	[last viewWillDisappear:animated];
	[viewController viewWillAppear:animated];
	
	if ([self.delegate respondsToSelector:@selector(navigationController:willShowViewController:animated:)])
		[self.delegate navigationController:self willShowViewController:viewController animated:animated];
	
	[self transitionFromViewController:last toViewController:viewController duration:duration animations:^{
		last.view.frame = TUINavigationOffscreenRightFrame(self.view.bounds);
		viewController.view.frame = self.view.bounds;
	} completion:^(BOOL finished) {
		[viewController viewDidAppear:animated];
		
		if ([self.delegate respondsToSelector:@selector(navigationController:didShowViewController:animated:)])
			[self.delegate navigationController:self didShowViewController:viewController animated:animated];
		
		[last viewDidDisappear:animated];
		
		if (completion)
			completion(finished);
	}];
	
	NSMutableArray *popped = [@[] mutableCopy];
	while ([viewController isEqual:[self.childViewControllers lastObject]] == NO) {
		[popped addObject:[self.childViewControllers lastObject]];
		[[self.childViewControllers lastObject] removeFromParentViewController];
	}
	
	return popped;
}

@end

@implementation TUIViewController (TUINavigationController)

- (TUINavigationController *)navigationController {
	return (TUINavigationController *)self.parentViewController;
}

@end
