//
//  WebPreviewViewController.m
//  was : WebPreviewWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Jul 07 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//  refactored to be a ViewController by liz

#import "TCMMMSession.h"
#import "WebPreviewViewController.h"
#import "PlainTextDocument.h"
#import "FoldableTextStorage.h"
#import "DocumentMode.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

static NSString *WebPreviewWindowSizePreferenceKey =@"WebPreviewWindowSize";
static NSString *WebPreviewRefreshModePreferenceKey=@"WebPreviewRefreshMode";

@interface WebPreviewViewController ()
@property (nonatomic, strong) IBOutlet WebView *oWebView;
@property (nonatomic, strong) IBOutlet NSTextField *oBaseUrlTextField;
@property (nonatomic, strong) IBOutlet NSPopUpButton *oRefreshButton;
@property (nonatomic, strong) IBOutlet NSTextField *oStatusTextField;

@property (nonatomic, strong) PlainTextDocument *plainTextDocument;
@property (nonatomic, weak) NSTimer *delayedRefreshTimer;

@property (nonatomic) NSRect documentVisibleRect;
@property (nonatomic) BOOL hasSavedVisibleRect;
@property (nonatomic) SEEWebPreviewRefreshType refreshType;
@property (nonatomic) BOOL shallCache;

// Localized XIB
@property (nonatomic, readonly) NSString *localizedBaseURLLabelText;
@property (nonatomic, readonly) NSString *localizedRefreshLabelText;
@property (nonatomic, readonly) NSString *localizedManualRefreshButtonToolTip;
@property (nonatomic, readonly) NSString *localizedManualRefreshPopupItemAutomatic;
@property (nonatomic, readonly) NSString *localizedManualRefreshPopupItemDelayed;
@property (nonatomic, readonly) NSString *localizedManualRefreshPopupItemOnSave;
@property (nonatomic, readonly) NSString *localizedManualRefreshPopupItemManual;

@property (nonatomic, weak) id documentDidChangeObserver;
@property (nonatomic, weak) id documentDidSaveObserver;

@end

@implementation WebPreviewViewController

@synthesize plainTextDocument=_plainTextDocument;
@synthesize refreshType=_refreshType;

- (id)initWithPlainTextDocument:(PlainTextDocument *)aDocument {
    self=[super initWithNibName:@"WebPreview" bundle:nil];
    _plainTextDocument=aDocument;
    _hasSavedVisibleRect=NO;
    _shallCache=YES;
    NSNumber *refreshTypeNumber=[[[aDocument documentMode] defaults] objectForKey:WebPreviewRefreshModePreferenceKey];
    _refreshType=kWebPreviewRefreshDelayed;
    if (refreshTypeNumber) {
        int refreshType=[refreshTypeNumber intValue];
        if (refreshType>0 && refreshType <=kWebPreviewRefreshDelayed) {
            _refreshType=refreshType;
        }
    }

	__weak __typeof__(self) weakSelf = self;
	self.documentDidChangeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PlainTextDocumentDidChangeTextStorageNotification object:aDocument queue:nil usingBlock:^(NSNotification *note) {
		__typeof__(self) strongSelf = weakSelf;

		if ([strongSelf refreshType] == kWebPreviewRefreshAutomatic) {
			[strongSelf refresh:strongSelf];
		} else if ([strongSelf refreshType] == kWebPreviewRefreshDelayed) {
			[strongSelf triggerDelayedWebPreviewRefresh];
		}
	}];
	
	self.documentDidSaveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PlainTextDocumentDidSaveShouldReloadWebPreviewNotification object:aDocument queue:nil usingBlock:^(NSNotification *note) {
		__typeof__(self) strongSelf = weakSelf;

		if ([strongSelf refreshType] == kWebPreviewRefreshOnSave) {
			[strongSelf refreshAndEmptyCache:strongSelf];
		}
	}];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(synchronizeWindowTitleWithDocumentName)
                                                 name:TCMMMSessionDidChangeNotification 
                                               object:[_plainTextDocument session]];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(synchronizeWindowTitleWithDocumentName)
                                                 name:PlainTextDocumentDidChangeDisplayNameNotification 
                                               object:_plainTextDocument];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(somePlainTextDocumentDidSave:)
                                                 name:PlainTextDocumentDidSaveNotification 
                                               object:nil];
    return self;
}

- (void)dealloc {
    [self.oWebView setFrameLoadDelegate:nil];
    [self.oWebView setUIDelegate:nil];
    [self.oWebView setResourceLoadDelegate:nil];
	[self.oWebView setPolicyDelegate:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self.documentDidSaveObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.documentDidChangeObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark
- (void)setPlainTextDocument:(PlainTextDocument *)aDocument {
    _plainTextDocument = aDocument;
    if (!aDocument) {
        [self.oWebView stopLoading:self];
    }
}


- (PlainTextDocument *)plainTextDocument {
    return _plainTextDocument;
}

#pragma mark
- (NSURL *)baseURL {
    return [NSURL URLWithString:[self.oBaseUrlTextField stringValue]];
}

- (void)setBaseURL:(NSURL *)aBaseURL {
    [self.oBaseUrlTextField setStringValue:[aBaseURL absoluteString]];
}

- (void)updateBaseURL {
    NSURL *fileURL;
    if ((fileURL=[[self plainTextDocument] fileURL])) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            [self.oBaseUrlTextField setStringValue:[fileURL absoluteString]];
        }
    } 
}

#pragma mark
void logSubViews(NSArray *aSubviewsArray) {
    if (aSubviewsArray) NSLog(@"---");
    for (NSView *subview in aSubviewsArray) {
        NSLog(@"%@",[subview description]);
        logSubViews([subview subviews]);
    }
}

NSScrollView * firstScrollView(NSView *aView) {
    NSArray *aSubviewsArray=[aView subviews];
    unsigned i;
    for (i=0;i<[aSubviewsArray count];i++) {
        if ([[aSubviewsArray objectAtIndex:i] isKindOfClass:[NSScrollView class]]) {
            return [aSubviewsArray objectAtIndex:i];
        }
    }
    for (i=0;i<[aSubviewsArray count];i++) {
        NSScrollView *scrollview=firstScrollView([aSubviewsArray objectAtIndex:i]);
        if (scrollview) return scrollview;
    }
    return nil;
}

-(void)reloadWebViewCachingAllowed:(BOOL)aFlag {
    _shallCache=aFlag;
    NSScrollView *scrollView=firstScrollView(self.oWebView);
    // NSLog(@"found scrollview: %@",[scrollView description]);
    if (scrollView && !_hasSavedVisibleRect) {
        _documentVisibleRect=[scrollView documentVisibleRect];
        _hasSavedVisibleRect=YES;
    }
    
    NSURL *baseURL=[NSURL URLWithString:@"http://localhost/"];
    NSString *potentialURLString = [self.oBaseUrlTextField stringValue];
    if ([potentialURLString length] > 0) {
    	NSURL *tryURL = [NSURL URLWithString:potentialURLString];
//    	NSLog(@"%s %@ %@",__FUNCTION__,[tryURL debugDescription],[tryURL standardizedURL]);
    	if ([[tryURL host] length] > 0 || [[tryURL scheme] isEqualToString:@"file"]) {
    		baseURL = tryURL;
    	} else if ([potentialURLString characterAtIndex:0] == '/') {
    		tryURL = [NSURL URLWithString:[@"file://" stringByAppendingString:potentialURLString]];
    		baseURL = tryURL;
    	} else {
    		tryURL = [NSURL URLWithString:[@"http://" stringByAppendingString:potentialURLString]];
    		baseURL = tryURL;
    		[self.oBaseUrlTextField setStringValue:[tryURL absoluteString]];
    	}
    }

//	NSLog(@"%s using URL: %@",__FUNCTION__,baseURL);
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:baseURL];
    [request setMainDocumentURL:baseURL];
    
    FoldableTextStorage *textStorage = (FoldableTextStorage *)[[self plainTextDocument] textStorage];
    NSString *string=[[textStorage fullTextStorage] string];
    NSStringEncoding encoding = [textStorage encoding];
    [request setHTTPBody:[string dataUsingEncoding:encoding]];
    NSString *IANACharSetName=(NSString *)CFStringConvertEncodingToIANACharSetName(
                CFStringConvertNSStringEncodingToEncoding(encoding));
    [[self.oWebView mainFrame] loadData:[string dataUsingEncoding:encoding] MIMEType:@"text/html" textEncodingName:IANACharSetName baseURL:baseURL];
}

//- (void)windowWillClose:(NSNotification *)aNotification {
//	// when we see our window closing, we empty the contents so no javascript will run in background
//    [[self.oWebView mainFrame] loadHTMLString:@"" baseURL:nil];
//}

#pragma mark
-(IBAction)refreshAndEmptyCache:(id)aSender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self reloadWebViewCachingAllowed:NO];
}

-(IBAction)refresh:(id)aSender {
    [self reloadWebViewCachingAllowed:YES];
}

- (SEEWebPreviewRefreshType)refreshType {
    return _refreshType;
}

- (void)setRefreshType:(SEEWebPreviewRefreshType)aRefreshType {
    [[[[self plainTextDocument] documentMode] defaults] setObject:[NSNumber numberWithInt:aRefreshType] forKey:WebPreviewRefreshModePreferenceKey];
    if ([self view]) {
        int index=[self.oRefreshButton indexOfItemWithTag:aRefreshType];
        if (index!=-1) {
            _refreshType=aRefreshType;
            [self.oRefreshButton selectItemAtIndex:index];
        }
    } else {
        _refreshType=aRefreshType;
    }
}

-(IBAction)changeRefreshType:(id)aSender {
    [self setRefreshType:[[aSender selectedItem] tag]];
}

#pragma mark - Localized Xib
- (NSString *)localizedBaseURLLabelText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_BASE_URL_LABEL", nil, [NSBundle mainBundle], @"Base URL:", @"Web Preview - Label for the Base URL");
	return string;
}


- (NSString *)localizedRefreshLabelText {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_REFRESH_LABEL", nil, [NSBundle mainBundle], @"Refresh:", @"Web Preview - Label for the Refresh Popup");
	return string;
}

- (NSString *)localizedManualRefreshButtonToolTip {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_MANUAL_REFRESH_TOOL_TIP", nil, [NSBundle mainBundle], @"Refresh", @"Web Preview - Tool Tip for the Manual Refresh Button");
	return string;
}

// PopUp Refresh Menu Items

- (NSString *)localizedManualRefreshPopupItemAutomatic {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_REFRESH_POPUP_AUTOMATIC", nil, [NSBundle mainBundle], @"automatic", @"Web Preview - Refresh Popup Item - Automatic");
	return string;
}

- (NSString *)localizedManualRefreshPopupItemDelayed {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_REFRESH_POPUP_DELAYED", nil, [NSBundle mainBundle], @"delayed", @"Web Preview - Refresh Popup Item - Delayed");
	return string;
}

- (NSString *)localizedManualRefreshPopupItemOnSave {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_REFRESH_POPUP_ON_SAVE", nil, [NSBundle mainBundle], @"on save", @"Web Preview - Refresh Popup Item - On Save");
	return string;
}

- (NSString *)localizedManualRefreshPopupItemManual {
	NSString *string = NSLocalizedStringWithDefaultValue(@"WEB_PREVIEW_REFRESH_POPUP_MANUAL", nil, [NSBundle mainBundle], @"manually", @"Web Preview - Refresh Popup Item - Manual");
	return string;
}

#pragma mark
-(void)loadView {
    [super loadView];
	
    [self.oWebView setFrameLoadDelegate:self];
    [self.oWebView setUIDelegate:self];
    [self.oWebView setResourceLoadDelegate:self];
	[self.oWebView setPolicyDelegate:self];

    [self.oWebView setPreferencesIdentifier:@"WebPreviewPreferences"];
    WebPreferences *prefs = [self.oWebView preferences];
    [prefs setLoadsImagesAutomatically:YES];
    [prefs setJavaEnabled:YES];
    [prefs setJavaScriptEnabled:YES];
    [prefs setPlugInsEnabled:YES];
    [self.oStatusTextField setStringValue:@""];
//    NSString *frameString=[[NSUserDefaults standardUserDefaults] 
//                            stringForKey:WebPreviewWindowSizePreferenceKey];
//    if (frameString) {
//        [[self window] setFrameFromString:frameString];
//    }
	
	[self updateBaseURL];
    [self setRefreshType:_refreshType];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSString *title=[[[self.oWebView mainFrame] dataSource] pageTitle];
    
    title=title?[title stringByAppendingFormat:@" [%@]",displayName]:
                [NSString stringWithFormat:@"[%@]",displayName];
    
    return title; 
}

- (void)synchronizeWindowTitleWithDocumentName {
    NSString *displayName=[[self plainTextDocument] displayName];
    if (!displayName) displayName=@"";
    [self setTitle:[self windowTitleForDocumentDisplayName:displayName]];
}

#pragma mark -
#pragma mark ### CSS-update ###

- (void)somePlainTextDocumentDidSave:(NSNotification *)aNotification {
    NSString *savedFileName = [[[aNotification object] fileName] lastPathComponent];
    if ([[[savedFileName pathExtension] lowercaseString] isEqualToString:@"css"]) {
        if ([[[[self plainTextDocument] textStorage] string] rangeOfString:savedFileName options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [self refreshAndEmptyCache:self];
        }
    }
}

#pragma mark -
#pragma mark ### Actions ###

//- (IBAction)showWindow:(id)aSender {
//    [super showWindow:aSender];
//    [self updateBaseURL];
//    [self refresh:aSender];
//    [self synchronizeWindowTitleWithDocumentName];
//}

#pragma mark -
#pragma mark ### First Responder Actions ###

//- (IBAction)saveWindowSize:(id)aSender {
//    [[NSUserDefaults standardUserDefaults] 
//        setObject:[[self window] stringWithSavedFrame] 
//           forKey:WebPreviewWindowSizePreferenceKey];
//}
//
//- (void)windowDidResize:(NSNotification *)aNotification {
//    [self saveWindowSize:self];
//}

#pragma mark -
#pragma mark ### WebResourceLoadDelegate ###

-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
	//    NSLog(@"Got request:%@ withPolicy:%d",[request URL],[request cachePolicy]);
	if (![request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"]) {

		NSURL *url = request.URL;
		if (url.isFileURL) {
			if ([url checkResourceIsReachableAndReturnError:nil]) {
				NSError *error = nil;
				NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedAlways error:&error];
				if (!data) {
					NSLog(@"Error: %@", error);

					NSOpenPanel *openPanel = [NSOpenPanel openPanel];
//					openPanel.canChooseDirectories = YES;
					openPanel.canChooseFiles = YES;
					openPanel.directoryURL = url;
					openPanel.allowsMultipleSelection = YES;
					openPanel.prompt = @"Allow";
					openPanel.title = @"Allow resource access";

					NSInteger result = [openPanel runModal];
					if (result == NSFileHandlingPanelOKButton) {
						NSMutableArray *bookmarks = self.plainTextDocument.persistentDocumentScopedBookmarkURLs;

						NSArray *URLs = openPanel.URLs;

						for (NSURL *choosenURL in URLs) {
							[bookmarks addObject:choosenURL];
						}
					}
				}
			}
		}

		NSMutableURLRequest *mutableRequest = [request mutableCopy];
		[mutableRequest setCachePolicy:_shallCache ? NSURLRequestReturnCacheDataElseLoad : NSURLRequestReloadIgnoringCacheData];
		return mutableRequest;
	}
    return request;
}

- (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener {
	[listener use];
}

#pragma mark -
#pragma mark ### FrameLoadDelegate ###

- (void) webView:(WebView *)aSender
        didReceiveTitle:(NSString *)title 
               forFrame:(WebFrame *)frame {
    if ([[aSender mainFrame] isEqualTo:frame]) {
        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (void)webView:(WebView *)aSender didFinishLoadForFrame:(WebFrame *)aFrame {
    if ([aFrame isEqualTo:[self.oWebView mainFrame]]) {
        NSScrollView *scrollView=firstScrollView(self.oWebView);
        if (scrollView && _hasSavedVisibleRect) {
            [(NSView *)[scrollView documentView] scrollRectToVisible:_documentVisibleRect];
            _hasSavedVisibleRect=NO;
        }
    }
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(NSUInteger)modifierFlags {
    if ([elementInformation objectForKey:WebElementImageKey] ||
        [elementInformation objectForKey:WebElementLinkURLKey]) {
        // NSLog(@"%@",[elementInformation description]);
        NSMutableString *string=[NSMutableString string];
        NSURL    *url   =[elementInformation objectForKey:WebElementLinkURLKey];
        id        target=[elementInformation objectForKey:WebElementLinkTargetFrameKey];
        NSString *title =[elementInformation objectForKey:WebElementLinkTitleKey];
        if (title)         [string appendFormat:@"%@ ",title];
        if (url)           [string appendFormat:@"<%@> ",[url relativeString]];
        if ([target name]) [string appendFormat:@"->%@ ",[target name]];
        NSString *alt   =[elementInformation objectForKey:@"WebElementImageAltString"];
        NSImage *image  =[elementInformation objectForKey:WebElementImageKey];
        if (alt)           [string appendFormat:@"'%@' ",alt];
        if (image)         [string appendFormat:@"%@ ",NSStringFromSize([image size])];
        [self.oStatusTextField setStringValue:string];
    } else {
        if (![[self.oStatusTextField stringValue] isEqualToString:@""]) {
            [self.oStatusTextField setStringValue:@""];
        }
    }
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    NSMutableArray *returnArray = [NSMutableArray array];
    for (NSMenuItem *defaultItem in defaultMenuItems) {
        int tag=[defaultItem tag];
        if (tag == WebMenuItemTagOpenLinkInNewWindow) {
            NSMenuItem *item=[defaultItem copy];
            [item setTitle:NSLocalizedString(@"Open Link in Browser",@"Web preview open link in browser contextual menu item")];
            [item setAction:@selector(openInBrowser:)];
            [item setTarget:nil];
            [item setRepresentedObject:element];
            [returnArray addObject:item];
        } else if (tag == WebMenuItemTagDownloadImageToDisk ||
        		   tag == WebMenuItemTagDownloadLinkToDisk) {
        	// don't add
        } else {
            [returnArray addObject:defaultItem];
        }
    }
    return returnArray;
}

- (IBAction)openInBrowser:(id)aSender {
    NSMenuItem *item=(NSMenuItem *)aSender;
    NSDictionary *element=[item representedObject];
    NSURL *url = [element objectForKey:WebElementLinkURLKey];
    if (url) {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
}

#pragma mark - Refresh timer

#define WEBPREVIEWDELAYEDREFRESHINTERVAL 1.2

- (void)triggerDelayedWebPreviewRefresh {
	NSTimer *timer = self.delayedRefreshTimer;
	if ([timer isValid]) {
		[timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:WEBPREVIEWDELAYEDREFRESHINTERVAL]];
	} else {
		timer = [NSTimer timerWithTimeInterval:WEBPREVIEWDELAYEDREFRESHINTERVAL
										target:self
									  selector:@selector(delayedWebPreviewRefreshAction:)
									  userInfo:nil
									   repeats:NO];
		timer.tolerance = 0.5;

		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
		self.delayedRefreshTimer = timer;
	}
}

- (void)delayedWebPreviewRefreshAction:(NSTimer *)aTimer {
    [self refresh:self];
}

@end
