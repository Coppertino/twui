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

#import "TUITextView.h"
#import "TUITextEditor.h"

#import "TUINSView.h"
#import "TUINSWindow.h"

#import "TUICGAdditions.h"
#import "NSColor+TUIExtensions.h"

#define TUITextCursorColor [NSColor colorWithCalibratedRed:0.05f green:0.55f blue:0.91f alpha:1.00f]

static CAAnimation* TUICursorThrobAnimation() {
	CAKeyframeAnimation *throb = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
	throb.values = @[ @1.0, @1.0, @1.0, @1.0, @1.0, @0.5, @0.0, @0.0, @0.0, @1.0 ];
	throb.repeatCount = HUGE_VALF;
	throb.duration = 1.0f;
	return throb;
}

// A specialized subclass of TUITextEditor for use in text fields.
@interface TUITextViewEditor : TUITextEditor

@end

@interface TUITextView () <TUITextRendererDelegate> {
	@package struct {
		unsigned delegateDoCommandBySelector:1;
		unsigned delegateTextViewDidChange:1;
		unsigned delegateWillBeginEditing:1;
		unsigned delegateDidBeginEditing:1;
		unsigned delegateWillEndEditing:1;
		unsigned delegateDidEndEditing:1;
		unsigned delegateTextViewShouldReturn:1;
		unsigned delegateTextViewShouldClear:1;
		unsigned delegateTextViewShouldTabToNext:1;
	} _textViewFlags;
}

@property (nonatomic, assign) CGRect lastTextRect;
@property (nonatomic, assign) NSInteger lastCheckToken;
@property (nonatomic, strong) NSArray *lastCheckResults;

@property (nonatomic, strong) NSTextCheckingResult *selectedTextCheckingResult;
@property (nonatomic, strong) NSMutableDictionary *autocorrectedResults;

@property (nonatomic, strong) TUIView *cursor;
@property (nonatomic, strong) TUITextViewEditor *editor;
@property (nonatomic, strong, readwrite) TUITextRenderer *placeholderRenderer;

@end

@implementation TUITextView

@dynamic delegate;

#pragma mark -
#pragma mark Object Lifecycle

- (id)initWithFrame:(CGRect)frame {
	if((self = [super initWithFrame:frame])) {
		self.needsDisplayWhenWindowsKeyednessChanges = YES;
		self.userInteractionEnabled = YES;
		self.backgroundColor = [NSColor clearColor];
		self.alwaysBounceVertical = YES;
		self.clipsToBounds = YES;
		
		self.editor = [[TUITextViewEditor alloc] init];
		self.placeholderRenderer = [[TUITextRenderer alloc] init];
		self.editor.delegate = self;
		self.editable = YES;
		
		self.cursor = [[TUIView alloc] initWithFrame:CGRectZero];
		self.cursor.backgroundColor = TUITextCursorColor;
		self.cursor.userInteractionEnabled = NO;
		self.cursorWidth = 2.0f;
		
		self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
		self.textColor = [NSColor textColor];
		self.drawFrame = TUITextFrameBezelStyle();
		
		self.autocorrectedResults = [NSMutableDictionary dictionary];
		self.textRenderers = @[self.editor];
		[self _updateDefaultAttributes];
	}
	return self;
}

- (void)dealloc {
	self.editor.delegate = nil;
}

#pragma mark -
#pragma mark Cursor Management

// The text field doesn't have a window when -init is called,
// so the cursor can only be added or removed when the text
// view is moved to a window or removed from a window.
- (void)willMoveToWindow:(TUINSWindow *)newWindow {
	[super willMoveToWindow:newWindow];
	
	if([newWindow isKeyWindow])
		[self addSubview:self.cursor];
	else
		[self.cursor removeFromSuperview];
	
	[self setNeedsDisplay];
}

// Only keep the cursor displayed if the window is key.
- (void)windowDidBecomeKey {
	[self addSubview:self.cursor];
	[super windowDidBecomeKey];
}

- (void)windowDidResignKey {
	[self.cursor removeFromSuperview];
	[super windowDidResignKey];
}

// When the mouse enters a text field, use the I-beam cursor,
// to indicate possible allowed text entry.
- (void)mouseEntered:(NSEvent *)event {
	[super mouseEntered:event];
	[[NSCursor IBeamCursor] push];
}

- (void)mouseExited:(NSEvent *)event {
	[super mouseExited:event];
	[NSCursor pop];
}

- (void)setEditable:(BOOL)editable {
	_editable = editable;
	self.editor.editable = editable;
}

#pragma mark -
#pragma mark Renderer and Delegate Forwarding

- (void)setDelegate:(id <TUITextViewDelegate>)d {
	_delegate = d;
	
	_textViewFlags.delegateTextViewDidChange = [_delegate respondsToSelector:@selector(textViewDidChange:)];
	_textViewFlags.delegateDoCommandBySelector = [_delegate respondsToSelector:@selector(textView:doCommandBySelector:)];
	_textViewFlags.delegateWillBeginEditing = [_delegate respondsToSelector:@selector(textViewWillBeginEditing:)];
	_textViewFlags.delegateDidBeginEditing = [_delegate respondsToSelector:@selector(textViewDidBeginEditing:)];
	_textViewFlags.delegateWillEndEditing = [_delegate respondsToSelector:@selector(textViewWillEndEditing:)];
	_textViewFlags.delegateDidEndEditing = [_delegate respondsToSelector:@selector(textViewDidEndEditing:)];
	_textViewFlags.delegateTextViewShouldReturn = [_delegate respondsToSelector:@selector(textViewShouldReturn:)];
	_textViewFlags.delegateTextViewShouldClear = [_delegate respondsToSelector:@selector(textViewShouldClear:)];
	_textViewFlags.delegateTextViewShouldTabToNext = [_delegate respondsToSelector:@selector(textViewShouldTabToNext:)];
}

// If the text renderer can handle an event for us, let it do so.
- (id)forwardingTargetForSelector:(SEL)selector {
	if([self.editor respondsToSelector:selector])
		return self.editor;
	return nil;
}

- (TUIResponder *)initialFirstResponder {
	return self.editor.initialFirstResponder;
}

- (BOOL)acceptsFirstResponder {
	return self.editable;
}

- (TUITextRenderer *)renderer {
	return self.editor;
}

#pragma mark -
#pragma mark Text Storage Properties

- (NSRange)selectedRange {
	return [self.editor selectedRange];
}

- (void)setSelectedRange:(NSRange)range {
	self.editor.selectedRange = range;
}

- (NSString *)text {
	return self.editor.text;
}

- (void)setText:(NSString *)text {
	self.editor.text = text;
}

- (void)setFont:(NSFont *)font {
	_font = font ?: [NSFont systemFontOfSize:[NSFont systemFontSize]];
	[self _updateDefaultAttributes];
}

- (void)setTextColor:(NSColor *)color {
	_textColor = color;
	[self _updateDefaultAttributes];
}

- (void)setCursorColor:(NSColor *)color {
	self.cursor.backgroundColor = ![color isEqualTo:[NSColor clearColor]] ? color : TUITextCursorColor;
	[self.cursor setNeedsDisplay];
}

- (NSColor *)cursorColor {
	return self.cursor.backgroundColor;
}

- (void)setCursorWidth:(CGFloat)width {
	if(width <= 0.0f)
		return;
	
	_cursorWidth = width;
	[self setNeedsDisplay];
}

- (void)setTextAlignment:(TUITextAlignment)alignment {
	_textAlignment = alignment;
	[self _updateDefaultAttributes];
}

// Update the text renderer default and marked attributes.
- (void)_updateDefaultAttributes {
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	if(self.textColor)
		[attributes setObject:(__bridge id)self.textColor.tui_CGColor forKey:(__bridge id)kCTForegroundColorAttributeName];
	
	NSParagraphStyle *style = NSSParagraphStyleForTUITextAlignment(self.textAlignment);
	if(style)
		[attributes setObject:style forKey:NSParagraphStyleAttributeName];
	
	[attributes setObject:self.font forKey:(__bridge id)kCTFontAttributeName];
	
	self.editor.defaultAttributes = attributes;
	self.editor.markedAttributes = attributes;
}

#pragma mark -
#pragma mark Cursor and Text Drawing

// The responder should be on the renderer.
- (BOOL)_isKey {
	NSResponder *firstResponder = [self.nsWindow firstResponder];
	if(firstResponder == self) {
		[self.nsWindow tui_makeFirstResponder:self.editor];
		firstResponder = self.editor;
	}
	
	return (firstResponder == self.editor && self.editable);
}

- (CGRect)_cursorRect {
	BOOL fakeMetrics = (self.editor.backingStore.length == 0);
	NSRange selection = self.editor.selectedRange;
	
	// We have no text so fake it to get proper cursor metrics.
	if(fakeMetrics) {
		TUITextStorage *fake = [TUITextStorage storageWithString:@"M"];
		fake.font = self.font;
		self.editor.textStorage = fake;
		selection = NSMakeRange(0, 0);
	}
	
	// Approximate the cursor height by pulling a character rect and modifying that.
	CGPoint charactersStart = CGRectIntegral([self.editor firstRectForCharacterRange:ABCFRangeFromNSRange(selection)]).origin;
	CGRect fontBoundingBox = CTFontGetBoundingBox((__bridge CTFontRef)self.font);
	
	CGRect cursorRect = {
		.origin.x = charactersStart.x,
		.origin.y = charactersStart.y + floor(self.font.leading),
		.size.width = self.cursorWidth,
		.size.height = round(fontBoundingBox.origin.y + fontBoundingBox.size.height)
	};
	
	// If the string ends with a return, CTFrameGetLines doesn't consider that a new line.
	if(self.text.length > 0) {
		unichar lastCharacter = [self.text characterAtIndex:MAX(selection.location - 1, 0)];
		if(lastCharacter == '\n') {
			CGRect firstCharacterRect = [self.editor firstRectForCharacterRange:CFRangeMake(0, 0)];
			cursorRect.origin.y -= firstCharacterRect.size.height;
			cursorRect.origin.x = firstCharacterRect.origin.x;
		}
	}
	
	// If we used fake metrics, restore the original ones.
	if(fakeMetrics)
		self.editor.textStorage = (TUITextStorage *)self.editor.backingStore;
	
	return cursorRect;
}

- (void)drawRect:(CGRect)rect {
	
	// Draw the text field background first.
	if(self.drawFrame)
		self.drawFrame(self, rect);
	
	// Show the cursor only if we're key and we haven't selected any text.
	BOOL showCursor = [self _isKey] && [self.editor selectedRange].length == 0;
	self.cursor.hidden = !showCursor;
	
	// Make the cursor flash if it's displayed.
	if(showCursor) {
		[self.cursor.layer removeAnimationForKey:@"opacity"];
		[self.cursor.layer addAnimation:TUICursorThrobAnimation() forKey:@"opacity"];
	}
	
	// Get the text metrics set up.
	self.contentSize = [self.editor sizeConstrainedToWidth:self.frame.size.width];
	CGRect rendererFrame = TUIEdgeInsetsInsetRect(self.contentRect, self.contentInset);
	self.editor.frame = rendererFrame;
	
	// If the cursor is displayed, position it without animations.
	if(showCursor) {
		[TUIView setAnimationsEnabled:NO block:^{
			self.cursor.frame = [self _cursorRect];
		}];
	}
	
	// If the user has not entered any text, and we have a placeholder string,
	// configure a quick text storage for the placeholder.
	BOOL placeholderRequired = (self.editor.textStorage.length < 1 && self.placeholder.length > 0);
	if(placeholderRequired) {
		TUITextStorage *storage = [TUITextStorage storageWithString:self.placeholder];
		storage.font = self.font;
		storage.color = [self.textColor colorWithAlphaComponent:0.5f];
		
		self.placeholderRenderer.textStorage = storage;
		self.placeholderRenderer.frame = self.editor.frame;
	}
	
	// We can only draw one renderer at a time, so determine if it's the
	// placeholder renderer or the actual text editor and draw it.
	// Note that to allow editing, we set the editor's frame as well.
	[(placeholderRequired ? self.placeholderRenderer : self.editor) draw];
}

#pragma mark -
#pragma mark Autocorrection and Spellcheck + Menu

- (void)_textDidChange {
	if(_textViewFlags.delegateTextViewDidChange)
		[_delegate textViewDidChange:self];
	
	if(self.spellCheckingEnabled)
		[self _checkSpelling];
}

- (void)_checkSpelling {
	NSRange wholeLineRange = NSMakeRange(0, self.text.length);
	NSTextCheckingType checkingTypes = NSTextCheckingTypeSpelling;
	if(self.autocorrectionEnabled)
		checkingTypes |= NSTextCheckingTypeCorrection | NSTextCheckingTypeReplacement;
	
	NSSpellChecker *s = [NSSpellChecker sharedSpellChecker];
	self.lastCheckToken = [s requestCheckingOfString:self.text
											   range:wholeLineRange types:checkingTypes
											 options:nil inSpellDocumentWithTag:0
								   completionHandler:^(NSInteger sequenceNumber, NSArray *results,
													   NSOrthography *orthography, NSInteger wordCount) {
		NSRange selectionRange = [self selectedRange];
		__block NSRange activeWordSubstringRange = NSMakeRange(0, 0);
		
		NSStringEnumerationOptions options = NSStringEnumerationByWords | NSStringEnumerationSubstringNotRequired |
		NSStringEnumerationReverse | NSStringEnumerationLocalized;
		[self.text enumerateSubstringsInRange:wholeLineRange options:options
													  usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
			if(selectionRange.location >= substringRange.location &&
			   selectionRange.location <= substringRange.location + substringRange.length) {
				
				activeWordSubstringRange = substringRange;
				*stop = YES;
			}
		}];
		
		// This needs to happen on the main thread so that the user doesn't enter
		// more text while we're changing the text storage contents.
		dispatch_async(dispatch_get_main_queue(), ^{
			
			// We only care about the most recent results, ignore anything older.
			if(sequenceNumber != self.lastCheckToken)
				return;
			if([self.lastCheckResults isEqualToArray:results])
				return;
			
			[[self.editor backingStore] beginEditing];
			
			NSRange wholeStringRange = NSMakeRange(0, [self.text length]);
			[[self.editor backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:wholeStringRange];
			[[self.editor backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:wholeStringRange];
			
			NSMutableArray *autocorrectedResultsThisRound = [NSMutableArray array];
			for(NSTextCheckingResult *result in results) {
				
				// Don't check the word they're typing.
				BOOL isActiveWord = NSEqualRanges(result.range, activeWordSubstringRange);
				if(selectionRange.length == 0) {
					if(isActiveWord)
						continue;
					
					// Don't correct if it looks like they might be typing a contraction.
					unichar lastCharacter = [[[self.editor backingStore] string] characterAtIndex:self.selectedRange.location - 1];
					if(lastCharacter == '\'')
						continue;
				}
				
				if(result.resultType == NSTextCheckingTypeCorrection || result.resultType == NSTextCheckingTypeReplacement) {
					NSString *backingString = self.editor.backingStore.string;
					
					if(NSMaxRange(result.range) <= backingString.length) {
						NSString *oldString = [backingString substringWithRange:result.range];
						
						TUITextStorageAutocorrectedPair *correctionPair = [[TUITextStorageAutocorrectedPair alloc] init];
						correctionPair.correctionResult = result;
						correctionPair.originalString = oldString;
						
						// Don't redo corrections that the user undid.
						if(self.autocorrectedResults[correctionPair])
							continue;
						
						[[self.editor backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:result.range];
						[[self.editor backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:result.range];
						
						[self.autocorrectedResults setObject:oldString forKey:correctionPair];
						[[self.editor backingStore] replaceCharactersInRange:result.range withString:result.replacementString];
						[autocorrectedResultsThisRound addObject:result];
						
						// The replacement could have changed the length of the string,
						// so adjust the selection to account for this change.
						NSInteger lengthChange = result.replacementString.length - oldString.length;
						[self setSelectedRange:NSMakeRange(self.selectedRange.location + lengthChange, self.selectedRange.length)];
						
					} else NSLog(@"%@: Auto-correction result out of range: %@", self, result);
					
				} else if(result.resultType == NSTextCheckingTypeSpelling) {
					[[self.editor backingStore] addAttribute:NSUnderlineColorAttributeName
																		  value:[NSColor redColor] range:result.range];
					[[self.editor backingStore] addAttribute:(id)kCTUnderlineStyleAttributeName
																		  value:@(kCTUnderlineStyleThick | kCTUnderlinePatternDot)
																		  range:result.range];
				}
			}
			
			[[self.editor backingStore] endEditing];
			
			// Make sure we reset so that the self.editor uses our new attributes.
			[self.editor reset];
			[self setNeedsDisplay];
			self.lastCheckResults = results;
		});
	}];
}

- (NSMenu *)menuForEvent:(NSEvent *)event {
	CFIndex stringIndex = [self.editor stringIndexForEvent:event];
	
	// Scan through to find the spellcheck result for the selected text.
	for(NSTextCheckingResult *result in self.lastCheckResults) {
		if(stringIndex >= result.range.location && stringIndex <= result.range.location + result.range.length) {
			self.selectedTextCheckingResult = result;
			break;
		}
	}
	
	// Scan through to find the autocorrect word pair for the selected text.
	TUITextStorageAutocorrectedPair *matchingAutocorrectPair = nil;
	if(self.selectedTextCheckingResult == nil) {
		for(TUITextStorageAutocorrectedPair *correctionPair in self.autocorrectedResults) {
			NSTextCheckingResult *result = correctionPair.correctionResult;
			
			if(stringIndex >= result.range.location && stringIndex <= result.range.location + result.range.length) {
				self.selectedTextCheckingResult = result;
				matchingAutocorrectPair = correctionPair;
				break;
			}
		}
	}
	
	// If we couldn't find a spellcheck or autocorrection set, return the editor's menu.
	if(self.selectedTextCheckingResult == nil)
		return [self.editor menuForEvent:event];
	
	// If we had an autocorrect word pair, allow changing it back with a menu item.
	NSMenu *menu = [[NSMenu alloc] initWithTitle:@""];
	if(self.selectedTextCheckingResult.resultType == NSTextCheckingTypeCorrection && matchingAutocorrectPair != nil) {
		NSString *menuText = [NSString stringWithFormat:NSLocalizedString(@"Change Back to \"%@\"", @""),
							  matchingAutocorrectPair.originalString];
		
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:menuText
														  action:@selector(_replaceAutocorrectedWord:)
												   keyEquivalent:@""];
		
		[menuItem setTarget:self];
		[menuItem setRepresentedObject:matchingAutocorrectPair.originalString];
		[menu addItem:menuItem];
		
		[menu addItem:[NSMenuItem separatorItem]];
	}
	
	// Allow the spell checker to guess for replacement words.
	NSArray *guesses = [[NSSpellChecker sharedSpellChecker] guessesForWordRange:self.selectedTextCheckingResult.range
																	   inString:[self text] language:nil
														 inSpellDocumentWithTag:0];
	
	// If there are suitable guesses, add a menu item for each.
	// If not, explicity state that there were no guesses.
	if(guesses.count > 0) {
		for(NSString *guess in guesses) {
			NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:guess
															  action:@selector(_replaceMisspelledWord:)
													   keyEquivalent:@""];
			
			[menuItem setTarget:self];
			[menuItem setRepresentedObject:guess];
			[menu addItem:menuItem];
		}
	} else {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"No guesses", @"")
														  action:NULL keyEquivalent:@""];
		[menu addItem:menuItem];
	}
	
	// Ask the editor to patch its standard text editing menu items.
	[menu addItem:[NSMenuItem separatorItem]];
	[self.editor patchMenuWithStandardEditingMenuItems:menu];
	[menu addItem:[NSMenuItem separatorItem]];
	
	// Add a spelling and grammar submenu.
	NSMenuItem *spellingAndGrammarItem = [menu addItemWithTitle:NSLocalizedString(@"Spelling and Grammar", @"")
														 action:NULL keyEquivalent:@""];
	NSMenu *spellingAndGrammarMenu = [[NSMenu alloc] initWithTitle:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Show Spelling and Grammar", @"")
									  action:@selector(showGuessPanel:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Check Document Now", @"")
									  action:@selector(checkSpelling:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItem:[NSMenuItem separatorItem]];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Check Spelling While Typing", @"")
									  action:@selector(toggleContinuousSpellChecking:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Check Grammar With Spelling", @"")
									  action:@selector(toggleGrammarChecking:) keyEquivalent:@""];
	[spellingAndGrammarMenu addItemWithTitle:NSLocalizedString(@"Correct Spelling Automatically", @"")
									  action:@selector(toggleAutomaticSpellingCorrection:) keyEquivalent:@""];
	[spellingAndGrammarItem setSubmenu:spellingAndGrammarMenu];
	
	// Add a text substitutions submenu.
	NSMenuItem *substitutionsItem = [menu addItemWithTitle:NSLocalizedString(@"Substitutions", @"")
													action:NULL keyEquivalent:@""];
	NSMenu *substitutionsMenu = [[NSMenu alloc] initWithTitle:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Show Substitutions", @"")
								 action:@selector(orderFrontSubstitutionsPanel:) keyEquivalent:@""];
	[substitutionsMenu addItem:[NSMenuItem separatorItem]];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Copy/Paste", @"")
								 action:@selector(toggleSmartInsertDelete:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Quotes", @"")
								 action:@selector(toggleAutomaticQuoteSubstitution:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Dashes", @"")
								 action:@selector(toggleAutomaticDashSubstitution:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Smart Links", @"")
								 action:@selector(toggleAutomaticLinkDetection:) keyEquivalent:@""];
	[substitutionsMenu addItemWithTitle:NSLocalizedString(@"Text Replacement", @"")
								 action:@selector(toggleAutomaticTextReplacement:) keyEquivalent:@""];
	[substitutionsItem setSubmenu:substitutionsMenu];
	
	// Add a text transformations submenu.
	NSMenuItem *transformationsItem = [menu addItemWithTitle:NSLocalizedString(@"Transformations", @"")
													  action:NULL keyEquivalent:@""];
	NSMenu *transformationsMenu = [[NSMenu alloc] initWithTitle:@""];
	[transformationsMenu addItemWithTitle:NSLocalizedString(@"Make Upper Case", @"")
								   action:@selector(uppercaseWord:) keyEquivalent:@""];
	[transformationsMenu addItemWithTitle:NSLocalizedString(@"Make Lower Case", @"")
								   action:@selector(lowercaseWord:) keyEquivalent:@""];
	[transformationsMenu addItemWithTitle:NSLocalizedString(@"Capitalize", @"")
								   action:@selector(capitalizeWord:) keyEquivalent:@""];
	[transformationsItem setSubmenu:transformationsMenu];
	
	// Add a speech-to-text submenu to handle dictation.
	NSMenuItem *speechItem = [menu addItemWithTitle:NSLocalizedString(@"Speech", @"")
											 action:NULL keyEquivalent:@""];
	NSMenu *speechMenu = [[NSMenu alloc] initWithTitle:@""];
	[speechMenu addItemWithTitle:NSLocalizedString(@"Start Speaking", @"")
						  action:@selector(startSpeaking:) keyEquivalent:@""];
	[speechMenu addItemWithTitle:NSLocalizedString(@"Stop Speaking", @"")
						  action:@selector(stopSpeaking:) keyEquivalent:@""];
	[speechItem setSubmenu:speechMenu];
	
	// Return the forwarded text-editing menu.
	return [self.nsView menuWithPatchedItems:menu];
}

- (void)_replaceMisspelledWord:(NSMenuItem *)menuItem {
	NSString *oldString = [self.text substringWithRange:self.selectedTextCheckingResult.range];
	NSString *replacement = [menuItem representedObject];
	
	// Remove the underline and color for the current text.
	[[self.editor backingStore] beginEditing];
	[[self.editor backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:self.selectedTextCheckingResult.range];
	[[self.editor backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:self.selectedTextCheckingResult.range];
	[[self.editor backingStore] replaceCharactersInRange:self.selectedTextCheckingResult.range withString:replacement];
	[[self.editor backingStore] endEditing];
	[self.editor reset];
	
	// Replace the current text with the replacement text.
	NSInteger lengthChange = replacement.length - oldString.length;
	[self setSelectedRange:NSMakeRange(self.selectedRange.location + lengthChange, self.selectedRange.length)];
	
	// We no longer have a text checking result to handle.
	[self _textDidChange];
	self.selectedTextCheckingResult = nil;
}

- (void)_replaceAutocorrectedWord:(NSMenuItem *)menuItem {
	NSString *oldString = [self.text substringWithRange:self.selectedTextCheckingResult.range];
	NSString *replacement = [menuItem representedObject];
	
	// Remove the underline and color for the current text.
	[[self.editor backingStore] beginEditing];
	[[self.editor backingStore] removeAttribute:(id)kCTUnderlineColorAttributeName range:self.selectedTextCheckingResult.range];
	[[self.editor backingStore] removeAttribute:(id)kCTUnderlineStyleAttributeName range:self.selectedTextCheckingResult.range];
	[[self.editor backingStore] replaceCharactersInRange:self.selectedTextCheckingResult.range withString:replacement];
	[[self.editor backingStore] endEditing];
	[self.editor reset];
	
	// Replace the current text with the replacement text.
	NSInteger lengthChange = replacement.length - oldString.length;
	[self setSelectedRange:NSMakeRange(self.selectedRange.location + lengthChange, self.selectedRange.length)];
	
	[self _textDidChange];
	self.selectedTextCheckingResult = nil;
}

#pragma mark -
#pragma mark Key Equivalent Handling

- (void)selectAll:(id)sender {
	[self setSelectedRange:NSMakeRange(0, self.text.length)];
}

- (void)clear:(id)sender {
	if(_textViewFlags.delegateTextViewShouldClear) {
		if([(id <TUITextViewDelegate>)_delegate textViewShouldClear:self])
			self.text = @"";
	} else self.text = @"";
}

- (void)_tabToNext {
	if(_textViewFlags.delegateTextViewShouldTabToNext)
		[(id <TUITextViewDelegate>)_delegate textViewShouldTabToNext:self];
}

- (BOOL)performKeyEquivalent:(NSEvent *)event {
	if([self.nsWindow.firstResponder isEqual:self.editor])
		return [self.editor performKeyEquivalent:event];
	
	return [super performKeyEquivalent:event];
}

- (BOOL)doCommandBySelector:(SEL)selector {
	if(_textViewFlags.delegateDoCommandBySelector) {
		if([(id <TUITextViewDelegate>)_delegate textView:self doCommandBySelector:selector])
			return YES;
	}
	
	if(selector == @selector(moveUp:)) {
		CGRect rect = [self.editor firstRectForCharacterRange:ABCFRangeFromNSRange(self.selectedRange)];
		CFIndex aboveIndex = [self.editor stringIndexForPoint:CGPointMake(rect.origin.x - rect.size.width, rect.origin.y + rect.size.height*2)];
		self.selectedRange = NSMakeRange(MAX(aboveIndex - 1, 0), 0);
		
		return YES;
	} else if(selector == @selector(moveDown:)) {
		CGRect rect = [self.editor firstRectForCharacterRange:ABCFRangeFromNSRange(self.selectedRange)];
		CFIndex belowIndex = [self.editor stringIndexForPoint:CGPointMake(rect.origin.x - rect.size.width, rect.origin.y)];
		belowIndex = MAX(belowIndex - 1, 0);
		
		// if we're on the same level as the belowIndex, then we've hit the last line and want to go to the end
		CGRect belowRect = [self.editor firstRectForCharacterRange:CFRangeMake(belowIndex, 0)];
		if(belowRect.origin.y == rect.origin.y) {
			belowIndex = MIN(belowIndex + 1, self.text.length);
		}
		self.selectedRange = NSMakeRange(belowIndex, 0);
		
		return YES;
	}
	
	return NO;
}

#pragma mark -
#pragma mark Text Renderer Delegate Forwarding

- (void)textRendererWillBecomeFirstResponder:(TUITextRenderer *)textRenderer {
	if(self.clearsOnBeginEditing)
		[self clear:nil];
	
	if(_textViewFlags.delegateWillBeginEditing)
		[_delegate textViewWillBeginEditing:self];
}

- (void)textRendererDidBecomeFirstResponder:(TUITextRenderer *)textRenderer {
	if(_textViewFlags.delegateDidBeginEditing)
		[_delegate textViewDidBeginEditing:self];
}

- (void)textRendererWillResignFirstResponder:(TUITextRenderer *)textRenderer {
	if(_textViewFlags.delegateWillEndEditing)
		[_delegate textViewWillEndEditing:self];
}

- (void)textRendererDidResignFirstResponder:(TUITextRenderer *)textRenderer {
	if(_textViewFlags.delegateDidEndEditing)
		[_delegate textViewDidEndEditing:self];
}

#pragma mark -

@end

@implementation TUITextViewEditor

#pragma mark -
#pragma mark Editor Modifications

- (BOOL)becomeFirstResponder {
	self.selectedRange = NSMakeRange(self.text.length, 0);
	return [super becomeFirstResponder];
}

#pragma mark -

@end
