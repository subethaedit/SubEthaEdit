//
//  WebPreviewWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Jul 07 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "TCMMMSession.h"
#import "WebPreviewWindowController.h"
#import "PlainTextDocument.h"
#import "FoldableTextStorage.h"
#import "DocumentMode.h"
#import "BacktracingException.h"

int const kWebPreviewRefreshAutomatic=1;
int const kWebPreviewRefreshOnSave   =2;
int const kWebPreviewRefreshManually =3;
int const kWebPreviewRefreshDelayed  =4;

static NSString *WebPreviewWindowSizePreferenceKey =@"WebPreviewWindowSize";
static NSString *WebPreviewRefreshModePreferenceKey=@"WebPreviewRefreshMode";

@implementation WebPreviewWindowController

- (id)initWithPlainTextDocument:(PlainTextDocument *)aDocument {
    self=[super initWithWindowNibName:@"WebPreview"];
    _plainTextDocument=aDocument;
    [self updateBaseURL];
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
    [oWebView setFrameLoadDelegate:nil];
    [oWebView setUIDelegate:nil];
    [oWebView setResourceLoadDelegate:nil];
    [oWebView setPolicyDelegate:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[self window] orderOut:self];
    [super dealloc];
}

- (void)setPlainTextDocument:(PlainTextDocument *)aDocument {
    _plainTextDocument = aDocument;
    if (!aDocument) {
        [oWebView stopLoading:self];
    }
}


- (PlainTextDocument *)plainTextDocument {
    return _plainTextDocument;
}

- (NSURL *)baseURL {
    return [NSURL URLWithString:[oBaseUrlTextField stringValue]];
}

- (void)setBaseURL:(NSURL *)aBaseURL {
    [oBaseUrlTextField setStringValue:[aBaseURL absoluteString]];
}

- (void)updateBaseURL {
    NSURL *fileURL;
    if ((fileURL=[[self plainTextDocument] fileURL])) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL path]]) {
            [oBaseUrlTextField setStringValue:[fileURL absoluteString]];
        }
    } 
}

void logSubViews(NSArray *aSubviewsArray) {
    unsigned i;
    if (aSubviewsArray) NSLog(@"---");
    for (i=0;i<[aSubviewsArray count];i++) {
        NSView *subview=[aSubviewsArray objectAtIndex:i];
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
    NSScrollView *scrollView=firstScrollView(oWebView);
    // NSLog(@"found scrollview: %@",[scrollView description]);
    if (scrollView && !_hasSavedVisibleRect) {
        _documentVisibleRect=[scrollView documentVisibleRect];
        _hasSavedVisibleRect=YES;
    }
    
    NSURL *baseURL=[NSURL URLWithString:@"http://localhost/"];
    NSString *potentialURLString = [oBaseUrlTextField stringValue];
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
    		[oBaseUrlTextField setStringValue:[tryURL absoluteString]];
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
    [[oWebView mainFrame] loadData:[string dataUsingEncoding:encoding] MIMEType:@"text/html" textEncodingName:IANACharSetName baseURL:baseURL];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	// when we see our window closing, we empty the contents so no javascript will run in background
    [[oWebView mainFrame] loadHTMLString:@"" baseURL:nil];
}

-(IBAction)refreshAndEmptyCache:(id)aSender {
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    [self reloadWebViewCachingAllowed:NO];
}

-(IBAction)refresh:(id)aSender {
    [self reloadWebViewCachingAllowed:YES];
}

- (int)refreshType {
    return _refreshType;
}

- (void)setRefreshType:(int)aRefreshType {
    [[[[self plainTextDocument] documentMode] defaults] setObject:[NSNumber numberWithInt:aRefreshType] forKey:WebPreviewRefreshModePreferenceKey];
    if ([self isWindowLoaded]) {
        int index=[oRefreshButton indexOfItemWithTag:aRefreshType];
        if (index!=-1) {
            _refreshType=aRefreshType;
            [oRefreshButton selectItemAtIndex:index];
        }
    } else {
        _refreshType=aRefreshType;
    }
}


-(IBAction)changeRefreshType:(id)aSender {
    [self setRefreshType:[[aSender selectedItem] tag]];
}

-(void)windowDidLoad {
    [super windowDidLoad];
    [oWebView setFrameLoadDelegate:self];
    [oWebView setUIDelegate:self];
    [oWebView setResourceLoadDelegate:self];
	[oWebView setPolicyDelegate:self];

    [oWebView setPreferencesIdentifier:@"WebPreviewPreferences"];
    WebPreferences *prefs = [oWebView preferences];
    [prefs setLoadsImagesAutomatically:YES];
    [prefs setJavaEnabled:YES];
    [prefs setJavaScriptEnabled:YES];
    [prefs setPlugInsEnabled:YES];
    [oStatusTextField setStringValue:@""];
    NSString *frameString=[[NSUserDefaults standardUserDefaults] 
                            stringForKey:WebPreviewWindowSizePreferenceKey];
    if (frameString) {
        [[self window] setFrameFromString:frameString];
    }
    [self setRefreshType:_refreshType];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    NSString *title=[[[oWebView mainFrame] dataSource] pageTitle];
    
    title=title?[title stringByAppendingFormat:@" [%@]",displayName]:
                [NSString stringWithFormat:@"[%@]",displayName];
    
    return title; 
}

- (void)synchronizeWindowTitleWithDocumentName {
    NSString *displayName=[[self plainTextDocument] displayName];
    if (!displayName) displayName=@"";
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:displayName]];
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

- (IBAction)showWindow:(id)aSender {
    [super showWindow:aSender];
    [self updateBaseURL];
    [self refresh:aSender];
    [self synchronizeWindowTitleWithDocumentName];
}

#pragma mark -
#pragma mark ### First Responder Actions ###

- (IBAction)saveWindowSize:(id)aSender {
    [[NSUserDefaults standardUserDefaults] 
        setObject:[[self window] stringWithSavedFrame] 
           forKey:WebPreviewWindowSizePreferenceKey];
}

- (void)windowDidResize:(NSNotification *)aNotification {
    [self saveWindowSize:self];
}

#pragma mark -
#pragma mark ### ResourceLoadDelegate ###

-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse fromDataSource:(WebDataSource *)dataSource {
//    NSLog(@"Got request:%@ withPolicy:%d",[request URL],[request cachePolicy]);
     if (![request valueForHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"]) {
         NSMutableURLRequest *mutableRequest=[[request mutableCopy] autorelease];
         [mutableRequest setCachePolicy:_shallCache?
            NSURLRequestReturnCacheDataElseLoad:NSURLRequestReloadIgnoringCacheData];
         return mutableRequest;
     }
    return request;
}

- (void)webView:(WebView *)webView decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener {
	[listener use];
}

#pragma mark -
#pragma mark ### FrameLoadDelegate ###

- (void)        webView:(WebView *)aSender 
        didReceiveTitle:(NSString *)title 
               forFrame:(WebFrame *)frame {
    if ([[aSender mainFrame] isEqualTo:frame]) {
        [self synchronizeWindowTitleWithDocumentName];
    }
}

- (void)webView:(WebView *)aSender didFinishLoadForFrame:(WebFrame *)aFrame {
    if ([aFrame isEqualTo:[oWebView mainFrame]]) {
        NSScrollView *scrollView=firstScrollView(oWebView);
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
        [oStatusTextField setStringValue:string];
    } else {
        if (![[oStatusTextField stringValue] isEqualToString:@""]) {
            [oStatusTextField setStringValue:@""];
        }
    }
}

- (NSArray *)webView:(WebView *)sender contextMenuItemsForElement:(NSDictionary *)element defaultMenuItems:(NSArray *)defaultMenuItems {
    NSMutableArray *returnArray = [NSMutableArray array];
    int i;
    for (i=0;i<[defaultMenuItems count];i++) {
        NSMenuItem *defaultItem=[defaultMenuItems objectAtIndex:i];
        int tag=[defaultItem tag];
        if (tag == WebMenuItemTagOpenLinkInNewWindow) {
            NSMenuItem *item=[[defaultItem copy] autorelease];
            [item setTitle:NSLocalizedString(@"Open Link in Browser",@"Web preview open link in browser contextual menu item")];
            [item setAction:@selector(openInBrowser:)];
            [item setTarget:nil];
            [item setRepresentedObject:element];
            [returnArray addObject:item];
        } else if (tag == WebMenuItemTagCopyLinkToClipboard ||
                   tag == WebMenuItemTagCopyImageToClipboard ||
                   tag == WebMenuItemTagCopy) {
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

@end
