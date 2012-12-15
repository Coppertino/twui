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

#import "TUIDraggingFilePromiseItem.h"
#import "TUIDragging+Private.h"

NSString *const TUIPasteboardTypeFilePromise = @"kTUIPasteboardTypeFilePromise";
NSString *const TUIPasteboardTypeFilePromiseType = @"pasteboard.promise.type";
NSString *const TUIPasteboardTypeFilePromiseName = @"pasteboard.promise.name";
NSString *const TUIPasteboardTypeFilePromiseContent = @"pasteboard.promise.content";

@implementation TUIDraggingFilePromiseItem

- (BOOL)setDataProvider:(id<NSPasteboardItemDataProvider>)dataProvider forTypes:(NSArray *)types {
	BOOL success;
	if((success = [super setDataProvider:dataProvider forTypes:types])) {
		if(!self.dataProviders)
			self.dataProviders = @{}.mutableCopy;
		
		for(NSString *type in types)
			self.dataProviders[type] = dataProvider;
	}
	return success;
}

- (NSString *)promisedFilename {
	NSString *name = [self stringForType:TUIPasteboardTypeFilePromiseName];
	return [NSString stringWithFormat:@"%@.%@", name, self.promisedFiletype];
}

- (NSString *)promisedFiletype {
	NSString *uti = [self propertyListForType:TUIPasteboardTypeFilePromiseType];
	NSString *extension = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)(uti),
																						kUTTagClassFilenameExtension);
	return extension;
}

@end
