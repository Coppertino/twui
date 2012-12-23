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

#import "TUINSView+Accessibility.h"

@implementation TUINSView (Accessibility)

- (id)accessibilityHitTest:(NSPoint)point
{
	NSPoint windowPoint = [[self window] convertScreenToBase:point];
	NSPoint localPoint = [self convertPoint:windowPoint fromView:nil];
	return [self.rootView accessibilityHitTest:localPoint];
}

- (BOOL)accessibilityIsIgnored
{
    return YES;
}

- (NSArray *)accessibilityAttributeNames
{
    static NSArray *attributes = nil;
    if(attributes == nil) {
		attributes = [[NSArray alloc] initWithObjects:NSAccessibilityChildrenAttribute, NSAccessibilityParentAttribute, NSAccessibilityWindowAttribute, NSAccessibilityTopLevelUIElementAttribute, NSAccessibilityPositionAttribute, NSAccessibilitySizeAttribute, nil];
    }
	
    return attributes;
}

- (id)accessibilityAttributeValue:(NSString *)attribute
{
    if([attribute isEqualToString:NSAccessibilityChildrenAttribute]) {
		return [NSArray arrayWithObject:self.rootView];
	} else if([attribute isEqualToString:NSAccessibilityParentAttribute]) {
		return NSAccessibilityUnignoredAncestor(self.superview);
    } else if([attribute isEqualToString:NSAccessibilityWindowAttribute]) {
		return [self.superview accessibilityAttributeValue:NSAccessibilityWindowAttribute];
    } else if([attribute isEqualToString:NSAccessibilityTopLevelUIElementAttribute]) {
		return [self.superview accessibilityAttributeValue:NSAccessibilityTopLevelUIElementAttribute];
    } else if([attribute isEqualToString:NSAccessibilityPositionAttribute]) {
		return [NSValue valueWithPoint:[[self window] convertBaseToScreen:[self convertPoint:self.bounds.origin toView:nil]]];
    } else if([attribute isEqualToString:NSAccessibilitySizeAttribute]) {
		return [NSValue valueWithSize:self.bounds.size];
    } else {
		return nil;
    }
}

- (BOOL)accessibilityIsAttributeSettable:(NSString *)attribute
{
    return NO;
}

- (NSArray *)accessibilityActionNames
{
    return [NSArray array];
}

- (id)accessibilityFocusedUIElement
{
    return NSAccessibilityUnignoredAncestor(self);
}

@end
