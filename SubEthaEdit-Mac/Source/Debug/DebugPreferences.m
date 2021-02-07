//  DebugPreferences.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu Feb 26 2004.

#ifndef TCM_NO_DEBUG


#import "DebugPreferences.h"
#import "DebugController.h"


@implementation DebugPreferences

- (instancetype)init {
    self = [super init];
    if (self) {
        levels = [NSMutableArray new];
        [levels addObject:[NSMutableDictionary dictionaryWithObject:@"Nix" forKey:@"levelName"]];
        [levels addObject:[NSMutableDictionary dictionaryWithObject:@"Simple" forKey:@"levelName"]];
        [levels addObject:[NSMutableDictionary dictionaryWithObject:@"Detailed" forKey:@"levelName"]];
        [levels addObject:[NSMutableDictionary dictionaryWithObject:@"All" forKey:@"levelName"]];

        logDomains = [NSMutableArray new];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSEnumerator *domains = [[NSArray arrayWithObjects:
                                        @"BEEPLogDomain",
                                        @"SASLLogDomain",
                                        @"RendezvousLogDomain",
                                        @"MillionMonkeysLogDomain",
                                        @"SyntaxHighlighterDomain",
                                        @"FileIOLogDomain",
                                        @"InternetLogDomain",
                                        @"ModesDomain",
                                        nil] objectEnumerator];
        NSString *domain = nil;
        while ((domain = [domains nextObject])) {
            NSMutableDictionary *domainDict =
                   [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                        domain, @"domain",
                                        [levels objectAtIndex:[defaults integerForKey:domain]], @"level",
                                        nil];
            [domainDict addObserver:self
                         forKeyPath:@"level"
                            options:NSKeyValueObservingOptionNew
                            context:NULL];
            [logDomains addObject:domainDict];
        }
    }
    return self;
}

- (NSImage *)icon {
    if (@available(macOS 10.16, *)) {
        return [NSImage imageWithSystemSymbolName:@"ladybug" accessibilityDescription:nil];
    } else {
        return [NSImage imageNamed:@"debug"];
    }
}

- (NSString *)iconLabel {
    return @"Debug";
}

- (NSString *)identifier {
    return @"de.codingmonkeys.subethaedit.preferences.debug";
}

- (NSString *)mainNibName {
    return @"DebugPrefs";
}

- (void)mainViewDidLoad {
    // Initialize user interface elements to reflect current preference settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL enableDebugMenu = [defaults boolForKey:@"EnableDebugMenu"];
	[toggleDebugMenuCheckBox setState:(enableDebugMenu ? NSControlStateValueOn : NSControlStateValueOff)];
	BOOL enableBEEPLogging = [defaults boolForKey:@"EnableBEEPLogging"];
	[toggleBEEPLoggingCheckBox setState:(enableBEEPLogging ? NSControlStateValueOn : NSControlStateValueOff)];
    [[DebugController sharedInstance] enableDebugMenu:enableDebugMenu];
}

- (void)didUnselect {
    // Save preferences
}

#pragma mark -

- (IBAction)toggleDebugMenu:(id)sender {
    int state = [sender state];
    if (state == NSControlStateValueOn) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EnableDebugMenu"];
        [[DebugController sharedInstance] enableDebugMenu:YES];
    } else if (state == NSControlStateValueOff) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"EnableDebugMenu"];        
        [[DebugController sharedInstance] enableDebugMenu:NO];
    }
}

- (IBAction)toggleBEEPLogging:(id)sender {
    int state = [sender state];
    if (state == NSControlStateValueOn) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"EnableBEEPLogging"];
    } else if (state == NSControlStateValueOff) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"EnableBEEPLogging"];        
    }
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"level"]) {
        NSString *logDomain = [object objectForKey:@"domain"];
        unsigned levelNumber = [levels indexOfObject:[object objectForKey:@"level"]];
        [[NSUserDefaults standardUserDefaults] setInteger:levelNumber forKey:logDomain];
    }
}

@end


#endif
