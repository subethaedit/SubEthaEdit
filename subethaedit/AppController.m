//
//  AppController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Wed Feb 25 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "TCMBEEP/TCMBEEP.h"
#import "TCMMillionMonkeys/TCMMillionMonkeys.h"
#import "TCMMMUserSEEAdditions.h"
#import "AppController.h"
#import "TCMPreferenceController.h"
#import "RendezvousBrowserController.h"
#import "InternetController.h"
#import "DebugPreferences.h"
#import "EncodingPreferences.h"
#import "HandshakeProfile.h"
#import "SessionProfile.h"
#import "DocumentModeManager.h"
#import "TextOperation.h"
#import "SelectionOperation.h"


@implementation AppController

+ (void)initialize {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];

    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
    
    
    [[TCMMMTransformator sharedInstance] registerTransformationTarget:[TextOperation class] selector:@selector(transformTextOperation:serverTextOperation:) forOperationId:[TextOperation operationID] andOperationID:[TextOperation operationID]];
    [SelectionOperation operationID]; // initalize selectionOperation
}

- (void)addMe {
    ABPerson *meCard=[[ABAddressBook sharedAddressBook] me];

    // add self as user 
    TCMMMUser *me=[TCMMMUser new];
    
    NSString *myName;            
    NSImage *myImage;
    NSImage *scaledMyImage;
    if (meCard) {
        NSString *firstName = [meCard valueForProperty:kABFirstNameProperty];
        NSString *lastName = [meCard valueForProperty:kABLastNameProperty];            

        if ((firstName!=nil) && (lastName!=nil)) {
            myName=[NSString stringWithFormat:@"%@ %@",firstName,lastName];
        } else if (firstName!=nil) {
            myName=firstName;
        } else if (lastName!=nil) {
            myName=lastName;
        } else {
            myName=NSFullUserName();
        }
        NSData  *imageData;
        if (imageData=[meCard imageData]) {
            myImage=[[NSImage alloc]initWithData:imageData];
            [myImage setCacheMode:NSImageCacheNever];
        } else {
            myImage=[NSImage imageNamed:@"DefaultPerson.tiff"];
        }
    } else {
        myName=NSFullUserName();
        myImage=[NSImage imageNamed:@"DefaultPerson.tiff"];
    }
    
    // resizing the image
    [myImage setScalesWhenResized:YES];
    NSSize originalSize=[myImage size];
    NSSize newSize=NSMakeSize(64.,64.);
    if (originalSize.width>originalSize.height) {
        newSize.height=(int)(originalSize.height/originalSize.width*newSize.width);
        if (newSize.height<=0) newSize.height=1;
    } else {
        newSize.width=(int)(originalSize.width/originalSize.height*newSize.height);            
        if (newSize.width <=0) newSize.width=1;
    }
    [myImage setSize:newSize];
    scaledMyImage=[[NSImage alloc] initWithSize:newSize];
    [scaledMyImage setCacheMode:NSImageCacheNever];
    [scaledMyImage lockFocus];
    NSGraphicsContext *context=[NSGraphicsContext currentContext];
    NSImageInterpolation oldInterpolation=[context imageInterpolation];
    [context setImageInterpolation:NSImageInterpolationHigh];
    [NSColor clearColor];
    NSRectFill(NSMakeRect(0.,0.,newSize.width,newSize.height));
    [myImage compositeToPoint:NSMakePoint(0.,0.) operation:NSCompositeCopy];
    [context setImageInterpolation:oldInterpolation];
    [scaledMyImage unlockFocus];
    
    NSData *pngData=[scaledMyImage TIFFRepresentation];
    pngData=[[NSBitmapImageRep imageRepWithData:pngData] representationUsingType:NSPNGFileType properties:[NSDictionary dictionary]];

    NSString *userID=[[NSUserDefaults standardUserDefaults] stringForKey:@"UserID"];
    if (!userID) {
        userID=[NSString UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"UserID"];
    }
    [me setUserID:userID];

    [me setName:myName];
    [[me properties] setObject:scaledMyImage forKey:@"Image"];
    [[me properties] setObject:pngData forKey:@"ImageAsPNG"];
    [myImage       release];
    [scaledMyImage release];
    [me prepareImages];
    TCMMMUserManager *userManager=[TCMMMUserManager sharedInstance];
    [userManager setMe:[me autorelease]];
}

#define MODEMENUTAG 50
#define SWITCHMODEMENUTAG 10
#define MODEMENUNAMETAG 20 

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    [self addMe];
    DocumentModeManager *manager=[DocumentModeManager sharedInstance];
    NSLog(@"%@",[manager description]);
    NSDictionary *availableModes=[manager availableModes];
    NSLog(@"Found modes: %@",[availableModes description]);
    NSMenu *modeMenu=[[[NSApp mainMenu] itemWithTag:MODEMENUTAG] submenu];
    NSMenu *modesMenu=[[modeMenu itemWithTag:SWITCHMODEMENUTAG] submenu];
    NSEnumerator *modeIDs=[availableModes keyEnumerator];
    NSString *modeID=nil;
    NSString *modeString=nil;
    while ((modeID=[modeIDs nextObject])) {
        modeString=[NSString stringWithFormat:@"%@ (%@)",[availableModes objectForKey:modeID],modeID];
        NSMenuItem *menuItem =[[NSMenuItem alloc] initWithTitle:modeString 
                                                         action:@selector(chooseMode:)
                                                  keyEquivalent:@""];
        [modesMenu addItem:menuItem];
        [menuItem release];
    }
    NSMenuItem *modeNameItem=[modeMenu itemWithTag:MODEMENUNAMETAG];
//    NSFontManager *fontManager=[NSFontManager sharedFontManager];
//    NSFont *myFont=[fontManager convertFont:[fontManager convertFont:[NSFont menuBarFontOfSize:0] toHaveTrait:NSBoldFontMask]];
//    myFont=[fontManager convertFont:myFont toSize:[myFont pointSize]+2.]; 
//    NSMutableAttributedString *title=[[NSMutableAttributedString alloc] initWithString:modeString attributes:[NSDictionary dictionaryWithObject:myFont forKey:NSFontAttributeName]];
    [modeNameItem setTitle:modeString];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // this is acutally after the opening of the first untitled document window!
    DebugPreferences *debugPrefs = [[DebugPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:debugPrefs];
    EncodingPreferences *encodingPrefs = [[EncodingPreferences new] autorelease];
    [TCMPreferenceController registerPrefModule:encodingPrefs];
    // set up beep profiles
    [TCMBEEPChannel setClass:[HandshakeProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditHandshake"];    
    [TCMBEEPChannel setClass:[TCMMMStatusProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/TCMMMStatus"];
    [TCMBEEPChannel setClass:[SessionProfile class] forProfileURI:@"http://www.codingmonkeys.de/BEEP/SubEthaEditSession"];

    [[TCMMMBEEPSessionManager sharedInstance] listen];
    [[TCMMMPresenceManager sharedInstance] setVisible:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}

@end
