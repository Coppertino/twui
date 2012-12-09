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

#import "ExampleCollectionViewCell.h"

@implementation ExampleCollectionViewCell

- (id)initWithFrame:(CGRect)frame {
    if((self = [super initWithFrame:frame])) {
		self.backgroundColor = [NSColor redColor];
        self.contentView.layer.borderWidth = 1.0f;
        self.contentView.layer.borderColor = [NSColor whiteColor].tui_CGColor;
		
        self.label = [[TUILabel alloc] initWithFrame:self.bounds];
        self.label.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        self.label.alignment = TUITextAlignmentCenter;
        self.label.font = [NSFont boldSystemFontOfSize:50.0f];
        self.label.backgroundColor = [NSColor underPageBackgroundColor];
        self.label.textColor = [NSColor whiteColor];
		self.label.backgroundColor = [NSColor clearColor];
		self.label.userInteractionEnabled = NO;
        
		[self.contentView addSubview:self.label];
    }
	
    return self;
}

@end
