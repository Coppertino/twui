//
//  TUINSView+Accessibility.m
//  TwUI
//
//  Created by Josh Abernathy on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TUINSView+Accessibility.h"


@implementation TUINSView (Accessibility)

- (id)accessibilityHitTest:(NSPoint)point
{
	NSPoint windowPoint = [[self window] convertRectFromScreen:NSMakeRect(point.x, point.y, 1, 1)].origin;
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
		return [NSValue valueWithPoint:[[self window] convertRectToScreen:[self convertRect:self.bounds toView:nil]].origin];
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
