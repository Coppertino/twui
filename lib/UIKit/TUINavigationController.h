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

@class TUINavigationController;

@protocol TUINavigationControllerDelegate  <NSObject>

- (void)navigationController:(TUINavigationController *)navigationController willShowViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (void)navigationController:(TUINavigationController *)navigationController didShowViewController:(TUIViewController *)viewController animated:(BOOL)animated;

@end

@interface TUINavigationController : TUIViewController

@property (nonatomic, readonly) TUIViewController *topViewController;
@property (nonatomic, readonly) NSArray *viewControllers;

@property (nonatomic, assign) id <TUINavigationControllerDelegate> delegate;

- (id)initWithRootViewController:(TUIViewController *)viewController;

- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated;
- (void)setViewControllers:(NSArray *)viewControllers animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (void)pushViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (TUIViewController *)popViewControllerAnimated:(BOOL)animated;
- (TUIViewController *)popViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated;
- (NSArray *)popToRootViewControllerAnimated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated;
- (NSArray *)popToViewController:(TUIViewController *)viewController animated:(BOOL)animated completion:(void (^)(BOOL finished))completion;

@end

@interface TUIViewController (TUINavigationController)

// Analogous to .presentingViewController, if the view controller
// was presented through a TUINavigationController.
@property (nonatomic, readonly) TUINavigationController *navigationController;

@end