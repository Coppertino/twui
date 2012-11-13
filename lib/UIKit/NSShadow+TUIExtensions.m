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

#import "NSShadow+TUIExtensions.h"

@implementation NSShadow (TUIExtensions)

+ (NSShadow *)shadow {
	return [[self.class alloc] init];
}

+ (NSShadow *)shadowWithRadius:(CGFloat)radius offset:(CGSize)offset color:(NSColor *)color {
	return [[self.class alloc] initWithRadius:radius offset:offset color:color];
}

- (id)initWithRadius:(CGFloat)radius offset:(CGSize)offset color:(NSColor *)color {
	if((self = [super init])) {
		self.shadowBlurRadius = radius;
		self.shadowOffset = offset;
		self.shadowColor = color;
	}
	
	return self;
}

@end