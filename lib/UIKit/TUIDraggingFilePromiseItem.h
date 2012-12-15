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

// This is a key used to cache any file promise information, provided
// as a convinience for property list encoding and decoding.
extern NSString *const TUIPasteboardTypeFilePromise;

// As part of a promised file collection, you must specify a
// uniform type identifier (UTI) for the promised file.
// This should be set as a property list. Usage:
// 
// [promiseItem setPropertyList:(id)kUTTypePNG
//						forType:TUIPasteboardTypeFilePromiseType];
extern NSString *const TUIPasteboardTypeFilePromiseType;

// As part of a promised file collection, you must specify a
// string name for the promised file to be saved as.
// This should be set as a string. Usage:
//
// [promiseItem setString:@"My Image Name"
//				  forType:TUIPasteboardTypeFilePromiseName];
extern NSString *const TUIPasteboardTypeFilePromiseName;

// As part of a promised file collection, you must specify the
// actual data for the promised file's contents.
// This should be set as data. Usage:
//
// [promiseItem setData:[self myImageData]
//				forType:TUIPasteboardTypeFilePromiseContent];
extern NSString *const TUIPasteboardTypeFilePromiseContent;

// A TUIDraggingFilePromiseItem is used the exact same way as an
// NSPasteboardItem, its superclass, but with the exception of
// TUIKit's built in hybrid file collection, using the above
// UTI keys. For example, where one would use an NSPasteboardItem
// to set the sender as a data provider for an image pasteboard
// type, one would use the TUIDraggingFilePromiseItem and set
// the sender as the data provider for the aforementioned UTI keys,
// or simply declare the data before-hand, to avoid lazy-loading.
// 
// If the TUIPasteboardTypeFilePromiseContent is not provided,
// you are expected to provide such the promise file collection
// facility yourself, preferrably by overriding the TUIDraggingSource
// method -draggingSession:endedAtPoint: and writing the file.
// The promiseDestinationURL property should be used as the file path.
@interface TUIDraggingFilePromiseItem : NSPasteboardItem

@property (nonatomic, strong, readonly) NSURL *promiseDestinationURL;

@end
