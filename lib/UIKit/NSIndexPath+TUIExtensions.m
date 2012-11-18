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

#import "NSIndexPath+TUIExtensions.h"

@implementation NSIndexPath (TUIExtensions)

+ (NSIndexPath *)indexPathForRow:(NSInteger)row inSection:(NSInteger)section {
	NSUInteger i[] = {section, row};
	return [NSIndexPath indexPathWithIndexes:i length:2];
}

+ (NSIndexPath *)indexPathForItem:(NSInteger)item inSection:(NSInteger)section {
	NSUInteger i[] = {section, item};
	return [NSIndexPath indexPathWithIndexes:i length:2];
}

- (NSInteger)section {
	return [self indexAtPosition:0];
}

- (NSInteger)row {
	return [self indexAtPosition:1];
}

- (NSInteger)item {
    return [self indexAtPosition:1];
}

@end