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

#import "TUIView.h"

typedef void (^TUIImageViewHandler)(void);

@interface TUIImageView : TUIView <TUIDraggingSource, TUIDraggingDestination, NSPasteboardItemDataProvider>

// The initial value of this property is the image passed into the
// initWithImage: method or nil if you initialized the receiver using
// a different method. Setting the image property does not change the
// size of a TUIImageView. Call sizeToFit to adjust the size of the
// view to match the image.
@property (nonatomic, strong) NSImage *image;

// The initial value of this property is the image passed into the
// initWithImage:highlightedImage: method or nil if you initialized
// the receiver using a different method.
@property (nonatomic, strong) NSImage *highlightedImage;

// This property determines whether the regular or highlighted
// images are used. When highlighted is set to YES, it will use
// the highlightedImage property. If highlighted is set to NO, it
// will use the image property.
@property (nonatomic, assign, getter = isHighlighted) BOOL highlighted;

// Set whether or not to allow a new image to be dragged into the frame.
// If YES, the user can drag a new image into the image view's frame, and
// overwrite the old image, otherwise, NO. The default value is NO.
@property (nonatomic, assign, getter = isEditable) BOOL editable;

// Set whether or not to allow drag-to-desktop saving of the image view's
// image. If YES, the user can drag the image out to the desktop, and save it
// using the specified filename as a Portable Network Graphics [PNG] file.
// If the image view is allowed to save the file, the NSImage .name property
// is used as the file name of the saved image with the savedFileType extension.
// By default, it is set to "Photo". If a file with this name already exists,
// it is not overwritten, but a count extension is added to the file.
// i.e. "Photo.png" exists, so "Photo (n).png" is used, where n is the
// number of pre-existing files with  an identical filename.
// The default value is NO.
@property (nonatomic, assign, getter = isSavable) BOOL savable;

// If the image view is allowed to save the file, the savedFiletype is
// used as the file type of the saved image. The default is NSPNGFileType.
@property (nonatomic, assign) NSBitmapImageFileType savedFiletype;

// Set whether a newly dragged image causes the image view to resize itself
// to fit. If NO, the image is scaled to fit the bounds. The default is NO.
@property (nonatomic, assign) BOOL editingSizesToFit;

// Block-based callbacks that allow you to be notified of when the image view
// has been edited, by dragging in a new image, or when it has been saved,
// by dragging it out to the desktop.
@property (nonatomic, copy) TUIImageViewHandler imageEditedHandler;
@property (nonatomic, copy) TUIImageViewHandler imageSavedHandler;

// Returns an image view initialized with the specified image. This method
// adjusts the frame of the receiver to match the size of the specified image.
// It also disables user interactions for the image view by default.
- (id)initWithImage:(NSImage *)image;

// Returns an image view initialized with the specified regular and
// highlighted images. This method adjusts the frame of the receiver to
// match the size of the specified image. It also disables user
// interactions for the image view by default.
- (id)initWithImage:(NSImage *)image highlightedImage:(NSImage *)highlightedImage;

@end