//
//  AppController.m
//  SubEthaHighlighter
//
//  Created by Dominik Wagner on Tue Jan 27 2004.
//  Copyright (c) 2004 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import "SyntaxManager.h"

int const kFormatMenuTag = 2000;
int const kSyntaxColoringMenuItemTag = 2002;
int const kTestsMenuTag = 2004;
int const kNoneModeMenuItemTag = 1;

@implementation AppController
/*"Just a initialisation class for things you need to do at startup, 
   like setup the SyntaxColoringSubmenu"*/
static AppController *sharedInstance;

+ (AppController *)sharedInstance {
    return sharedInstance;
}

- (void)awakeFromNib {
    sharedInstance = self;
    [self setupSyntaxColoringSubmenu];
    [self setupTestsSubmenu];
}

/*"setup the SyntaxColoringSubmenu in the Main Menu with tag kFormatMenuTag and the submenuitem with Tag kSyntaxColoringMenuItemTag"*/
- (void)setupSyntaxColoringSubmenu {
    NSMenuItem *syntaxColoringMenuItem=[[[[NSApp mainMenu] itemWithTag:kFormatMenuTag] 
                                            submenu] itemWithTag:kSyntaxColoringMenuItemTag];
    NSMenu *syntaxColoringSubmenu=[syntaxColoringMenuItem submenu];
    
    NSMutableArray *syntaxNames=[[[[SyntaxManager sharedInstance] availableSyntaxNames] allKeys] mutableCopy];
    [syntaxNames sortUsingSelector:@selector(compare:)];
    NSEnumerator *availableSyntaxNames=[syntaxNames objectEnumerator];
    NSString *syntaxName;
    while ((syntaxName=[availableSyntaxNames nextObject])) {
        NSMenuItem *menuItem =[[NSMenuItem alloc] initWithTitle:syntaxName 
                                                         action:@selector(chooseSyntaxName:)
                                                  keyEquivalent:@""];
        [syntaxColoringSubmenu addItem:menuItem];
        [menuItem release];
    }
    [syntaxNames release];
}

- (void)setupTestsSubmenu {
    NSMenuItem *testsMenuItem=[[NSApp mainMenu] itemWithTag:kTestsMenuTag];
    NSMenu *testsMenu = [testsMenuItem submenu];
    
    NSEnumerator *testsEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Tests/"]];
    
    NSString *fileName;
    while ((fileName = [testsEnumerator nextObject])) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:fileName 
                                                         action:@selector(runTest:)
                                                  keyEquivalent:@""];
        [testsMenu addItem:menuItem];
        [menuItem release];
    }
}



@end
