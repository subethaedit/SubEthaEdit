/*
 * Name: OgreFindProgressSheet.m
 * Project: OgreKit
 *
 * Creation Date: Oct 01 2003
 * Author: Isao Sonobe <sonobe@gauge.scphys.kyoto-u.ac.jp>
 * Copyright: Copyright (c) 2003 Isao Sonobe, All rights reserved.
 * License: OgreKit License
 *
 * Encoding: UTF8
 * Tabsize: 4
 */

#import <OgreKit/OgreTextFindProgressSheet.h>

@implementation OgreTextFindProgressSheet

- (id)initWithWindow:(NSWindow*)parentWindow title:(NSString*)aTitle didEndSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-initWithWindow: of OgreTextFindProgressSheet");
#endif
	self = [super init];
	if (self) {
		_parentWindow = parentWindow;
		_cancelSelector = nil;
		_cancelTarget = nil;
		_cancelArgument = nil;
		_didEndSelector = aSelector;
		_didEndTarget = [aTarget retain];
		_didEndArgument = ((anObject != self)? [anObject retain] : self);
		_shouldRelease = YES;
		_title = [aTitle retain];
		[NSBundle loadNibNamed:@"OgreTextFindProgressSheet" owner:self];
	}
	
	return self;
}

-(void)awakeFromNib
{
	[[self retain] retain]; // close:とsheetDidEnd:のときに一度ずつreleaseされる
	[titleTextField setStringValue:_title];
	[button setTitle:OgreTextFinderLocalizedString(@"Cancel")];
	[NSApp beginSheet: progressWindow 
		modalForWindow: _parentWindow 
		modalDelegate: self
		didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:) 
		contextInfo: nil];
	[progressBar setUsesThreadedAnimation:YES];
	[progressBar startAnimation:self];
}

- (void)sheetDidEnd:(NSWindow*)sheet returnCode:(int)returnCode contextInfo:(void*)contextInfo
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-sheetDidEnd: of OgreTextFindProgressSheet");
#endif
	[_didEndTarget performSelector:_didEndSelector withObject:_didEndArgument];
	[self release];
}

- (void)dealloc
{
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-dealloc of OgreTextFindProgressSheet");
#endif
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[progressWindow release];
	[_title release];
	[_didEndTarget release];
	if (_didEndArgument != self) [_cancelArgument release];
	[_cancelTarget release];
	if (_cancelArgument != self) [_cancelArgument release];
	
	[super dealloc];
}

- (void)setCancelSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anObject
{
	_cancelSelector = aSelector;
	_cancelTarget = [aTarget retain];
	_cancelArgument = ((anObject != self)? [anObject retain] : self);
}

- (IBAction)cancel:(id)sender
{
	if ([[sender title] isEqualToString:OgreTextFinderLocalizedString(@"Cancel")]) {
		// Cancel
		[_cancelTarget performSelector:_cancelSelector withObject:_cancelArgument];
	} else {
		// OK
		// closeは一回だけ実行できるrelease
		if (progressWindow) {
			[progressWindow close];
			[NSApp endSheet:progressWindow returnCode:nil];
			progressWindow = nil;
		}
		if (_shouldRelease) {
			_shouldRelease = NO;
			[self release];
		}
	}
}

- (void)setReleaseWhenOKButtonClicked:(BOOL)shouldRelease
{
	_shouldRelease = shouldRelease;
}

- (void)autoclose:(id)sender
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self close:self];
}

- (void)close:(id)anObject
{
	// アプリケーションがinactivateな場合はactivateになったら実行する。
	if (![NSApp isActive]) {
#ifdef DEBUG_OGRE_FIND_PANEL
		NSLog(@"request -autoclose: of OgreTextFindProgressSheet");
#endif
		// Applicationのinactivateを拾う
		[[NSNotificationCenter defaultCenter] addObserver: self 
			selector: @selector(autoclose:) 
			name: NSApplicationDidBecomeActiveNotification
			object: NSApp];
		return;
	}
	
#ifdef DEBUG_OGRE_FIND_PANEL
	NSLog(@"-close: of OgreTextFindProgressSheet");
#endif
	// closeは一回だけ実行できるrelease
	if (progressWindow) {
		[progressWindow close];
		[NSApp endSheet:progressWindow returnCode:nil];
		[_parentWindow flushWindow];
		[progressWindow release];
		progressWindow = nil;
	}
	_shouldRelease = NO;
	[self release];
}

- (void)setProgress:(double)progression message:(NSString*)message
{
	if (progressWindow && [NSApp isActive]) {
		//[progressBar setUsesThreadedAnimation:NO];
		[progressBar setIndeterminate:NO];
		[progressTextField setStringValue:message];
		[progressBar setDoubleValue:progression];
	}
}

- (void)done:(double)progression message:(NSString*)message
{
	if (progressWindow) {
		//[progressBar setUsesThreadedAnimation:NO];
		[progressBar setIndeterminate:NO];
		[progressTextField setStringValue:message];
		[progressBar setDoubleValue:progression];
		[button setTitle:OgreTextFinderLocalizedString(@"OK")];
		[button setKeyEquivalent:@"\r"];
		[button setKeyEquivalentModifierMask:0];
	}
}

/* show error alert */
- (void)showErrorAlert:(NSString*)title message:(NSString*)errorMessage
{
	if (progressWindow) {
		[_parentWindow makeKeyAndOrderFront:self];
		[titleTextField setStringValue:title];
		[progressBar setHidden:YES];
		[progressTextField setStringValue:errorMessage];
		[button setTitle:OgreTextFinderLocalizedString(@"OK")];
		[button setKeyEquivalent:@"\r"];
		[button setKeyEquivalentModifierMask:0];
	}
}

@end
