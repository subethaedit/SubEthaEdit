//
//  WebPreviewWindowController.m
//  SubEthaEdit
//
//  Created by Dominik Wagner on Mon Jul 07 2003.
//  Copyright (c) 2003 TheCodingMonkeys. All rights reserved.
//

#import "WebPreviewWindowController.h"
#import "PlainTextDocument.h"

int const kWebPreviewRefreshAutomatic=1;
int const kWebPreviewRefreshOnSave   =2;
int const kWebPreviewRefreshManually =3;
int const kWebPreviewRefreshDelayed  =4;

static NSString *WebPreviewWindowSizePreferenceKey=@"WebPreviewWindowSize";

@implementation WebPreviewWindowController

- (id)initWithPlainTextDocument:(PlainTextDocument *)aDocument {
    self=[super initWithWindowNibName:@"WebPreview"];
    _plainTextDocument=aDocument;
    [self updateBaseURL];
    _hasSavedVisibleRect=NO;
    _shallCache=YES;
    _refreshType=kWebPreviewRefreshDelayed;
    return self;
}

- (void)dealloc {
    [[self window] orderOut:self];
    [super dealloc];
}

- (PlainTextDocument *)plainTextDocument {
    return _plainTextDocument;
}

- (void)updateBaseURL {
    NSString *fileName;
    if ((fileName=[[self plainTextDocument] fileName])) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            [oBaseUrlTextField setStringValue:
                [[NSURL fileURLWithPath:[[self plainTextDocument] fileName]] absoluteString]];
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
    NSURL *MyURL=[NSURL URLWithString:[oBaseUrlTextField stringValue]];
    if ([[MyURL absoluteString] length]==0 || MyURL==nil) MyURL=[NSURL URLWithString:@"http://localhost/"];
    NSMutableURLRequest *request=[NSMutableURLRequest requestWithURL:MyURL];
    [request setMainDocumentURL:MyURL];
    NSString *string=[[[self plainTextDocument] textStorage] string];
    [request setHTTPBody:[string dataUsingEncoding:[string fastestEncoding]]];
    NSString *IANACharSetName=(NSString *)CFStringConvertEncodingToIANACharSetName(
                CFStringConvertNSStringEncodingToEncoding([string fastestEncoding]));
    [request setValue:IANACharSetName forHTTPHeaderField:@"LocalContentAndThisIsTheEncoding"];
    [request setCachePolicy:aFlag?NSURLRequestUseProtocolCachePolicy:NSURLRequestReloadIgnoringCacheData];
    [[oWebView mainFrame] loadRequest:request];
//    [[oWebView mainFrame]
//        loadHTMLString:[[[self plainTextDocument] textStorage] string]
//               baseURL:[NSURL URLWithString:[oBaseUrlTextField stringValue]]];
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
    _refreshType=[[aSender selectedItem] tag];     
}

-(void)windowDidLoad {
    [super windowDidLoad];
    [oWebView setFrameLoadDelegate:self];
    [oWebView setUIDelegate:self];
    [oWebView setResourceLoadDelegate:self];
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

- (void) synchronizeWindowTitleWithDocumentName {
    NSString *displayName=[[self plainTextDocument] displayName];
    if (!displayName) displayName=@"";
    [[self window] setTitle:[self windowTitleForDocumentDisplayName:displayName]];
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
            [[scrollView documentView] scrollRectToVisible:_documentVisibleRect];
            _hasSavedVisibleRect=NO;
        }
    }
}

- (void)webView:(WebView *)sender mouseDidMoveOverElement:(NSDictionary *)elementInformation modifierFlags:(unsigned int)modifierFlags {
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
