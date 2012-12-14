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

#import "TUIDraggingItem.h"

NSString *const TUIDraggingImageComponentIconKey = @"kTUIDraggingImageComponentIconKey";
NSString *const TUIDraggingImageComponentLabelKey = @"kTUIDraggingImageComponentLabelKey";

@interface TUIDraggingImageComponent ()

@property (nonatomic, strong) TUIDraggingItem *item;

@end

@interface TUIDraggingItem ()

@property (nonatomic, strong) id<NSPasteboardWriting> pasteboardWriter;

@end

@implementation TUIDraggingItem

- (id)initWithPasteboardWriter:(id<NSPasteboardWriting>)writer {
	if((self = [super init])) {
		self.pasteboardWriter = writer;
	}
	return self;
}

- (void)setDraggingFrame:(NSRect)frame contents:(id)contents {
	self.draggingFrame = frame;
	
	self.imageComponentsProvider = ^{
		TUIDraggingImageComponent *c = [TUIDraggingImageComponent draggingImageComponentWithKey:TUIDraggingImageComponentIconKey];
		c.contents = contents;
		return @[c];
	};
}

- (NSArray *)imageComponents {
	if(self.imageComponentsProvider) {
		NSArray *components = self.imageComponentsProvider();
		for(TUIDraggingImageComponent *component in components)
			component.item = self;
		return components;
	}
	return nil;
}

- (id)item {
	return self.pasteboardWriter;
}

@end

@implementation TUIDraggingImageComponent

+ (id)draggingImageComponentWithKey:(NSString *)key {
	return [[self alloc] initWithKey:key];
}

- (id)initWithKey:(NSString *)key {
	if((self = [super init])) {
		_key = key;
	}
	return self;
}

- (CGRect)frame {
	return (CGRect){.size = self.item.draggingFrame.size};
}

@end
