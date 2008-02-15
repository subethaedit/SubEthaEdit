//
//  AppController.m
//  PortMap
//
//  Created by Dominik Wagner on 25.01.08.
//  Copyright 2008 TheCodingMonkeys. All rights reserved.
//

#import "AppController.h"
#import <TCMPortMapper/TCMPortMapper.h>
#import "TCMStatusImageFromMappingStatusValueTransformer.h"
#import "TCMPortStringFromPublicPortValueTransformer.h"
#import "TCMPortMappingAdditions.h"

@interface NSWindow (privateLeopardAdditions)
- (void)setAutorecalculatesContentBorderThickness:(BOOL)autorecalculateContentBorderThickness forEdge:(NSRectEdge)edge;
- (void)setContentBorderThickness:(float)borderThickness forEdge:(NSRectEdge)edge;
@end

@implementation AppController

+ (void)initialize {
    [NSValueTransformer setValueTransformer:[TCMStatusImageFromMappingStatusValueTransformer new] forName:@"TCMStatusImageFromMappingStatus"];
    [NSValueTransformer setValueTransformer:[TCMPortStringFromPublicPortValueTransformer new] forName:@"TCMPortStringFromPublicPort"];
    [NSValueTransformer setValueTransformer:[TCMReplacedStringFromPortMappingReferenceStringValueTransformer new] forName:@"TCMReplacedStringFromPortMappingReferenceString"];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSWindow *mainWindow = [O_refreshButton window];
    if ([mainWindow respondsToSelector:@selector(setContentBorderThickness:forEdge:)]) {
        [mainWindow setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];
        [mainWindow setContentBorderThickness:20.0 forEdge:NSMaxYEdge];
    }

    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    NSNotificationCenter *center=[NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(portMapperExternalIPAddressDidChange:) name:TCMPortMapperExternalIPAddressDidChange object:pm];
    [center addObserver:self selector:@selector(portMapperWillSearchForRouter:) name:TCMPortMapperWillSearchForRouterNotification object:pm];
    [center addObserver:self selector:@selector(portMapperDidFindRouter:) name:TCMPortMapperDidFindRouterNotification object:pm];
    [center addObserver:self selector:@selector(portMappingDidChangeMappingStatus:) name:TCMPortMappingDidChangeMappingStatusNotification object:nil];
    [center addObserver:self selector:@selector(startProgressIndicator:) name:TCMPortMapperDidStartWorkNotification object:nil];
    [center addObserver:self selector:@selector(stopProgressIndicator:) name:TCMPortMapperDidEndWorkNotification   object:nil];
    NSEnumerator *mappings=[[[NSUserDefaults standardUserDefaults] objectForKey:@"StoredMappings"] objectEnumerator];
    NSDictionary *mappingRep = nil;
    while ((mappingRep = [mappings nextObject])) {
       TCMPortMapping *mapping = [TCMPortMapping portMappingWithDictionaryRepresentation:mappingRep];
       [O_mappingsArrayController addObject:mapping];
       [mapping addObserver:self forKeyPath:@"userInfo.active" options:0 context:nil];
       if ([[[mapping userInfo] objectForKey:@"active"] boolValue]) {
           [pm addPortMapping:mapping];
       }
    }
    [[TCMPortMapper sharedInstance] start]; 

    NSArray *array = [[[NSArray alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Presets" ofType:@"plist"]] autorelease];
    NSEnumerator *presets = [array objectEnumerator];
    NSDictionary *preset = nil;
    while ((preset = [presets nextObject])) {
        NSString *title = [preset objectForKey:@"mappingTitle"];
        if (title) {
            [O_addPresetPopupButton addItemWithTitle:title];
            [[[O_addPresetPopupButton itemArray] lastObject] setRepresentedObject:preset];
        }
    }
}

- (void)writeMappingDefaults {
    NSEnumerator *mappings = [[O_mappingsArrayController arrangedObjects] objectEnumerator];
    NSMutableArray *mappingsToStore = [NSMutableArray array];
    TCMPortMapping *mapping = nil;
    while ((mapping=[mappings nextObject])) {
        [mappingsToStore addObject:[mapping dictionaryRepresentation]];
    }
    [[NSUserDefaults standardUserDefaults] setObject:mappingsToStore forKey:@"StoredMappings"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self writeMappingDefaults];
    [[TCMPortMapper sharedInstance] stopBlocking];
}

- (IBAction)refresh:(id)aSender {
    [[TCMPortMapper sharedInstance] refresh];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)aSender {
    [[O_currentIPTextField window] orderFront:self];
    return NO;
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSLog(@"%s %@ %@ %@",__FUNCTION__,keyPath,object,change);
    if ([[[object userInfo] objectForKey:@"active"] boolValue]) {
        [[TCMPortMapper sharedInstance] addPortMapping:object];
    } else {
        [[TCMPortMapper sharedInstance] removePortMapping:object];
    }
    [self writeMappingDefaults];
}

- (void)updateTagLine {
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm isRunning]) {
        if ([pm externalIPAddress]) {
            [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerName],[pm routerIPAddress]]];
        } else {
            [O_taglineTextField setStringValue:[NSString stringWithFormat:@"%@ - %@ - %@",[pm mappingProtocol],[pm routerName],[pm routerIPAddress]]];
        }
    } else {
        [O_taglineTextField setStringValue:@"Stopped"];
    }

}

- (void)portMapperExternalIPAddressDidChange:(NSNotification *)aNotification {
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm isRunning]) {
        if ([pm externalIPAddress]) {
            [O_currentIPTextField setObjectValue:[pm externalIPAddress]];
        }
    } else {
        [O_currentIPTextField setStringValue:@"Stopped"];
    }
    [self updateTagLine];
}

- (IBAction)togglePortMapper:(id)aSender {
    if ([aSender state]==NSOnState) {
        [[TCMPortMapper sharedInstance] start];
    } else {
        [[TCMPortMapper sharedInstance] stop];
        [self portMapperExternalIPAddressDidChange:nil];
    }
}

- (void)portMapperWillSearchForRouter:(NSNotification *)aNotification {
    [O_refreshButton setEnabled:NO];
    [O_currentIPTextField setStringValue:@"Searching..."];
}

- (void)portMapperDidFindRouter:(NSNotification *)aNotification {
    [O_refreshButton setEnabled:YES];
    TCMPortMapper *pm=[TCMPortMapper sharedInstance];
    if ([pm externalIPAddress]) {
        [O_currentIPTextField setObjectValue:[pm externalIPAddress]];
    } else {
        [O_currentIPTextField setStringValue:@"Router incompatible."];
    }
    [self updateTagLine];
}

- (IBAction)addMapping:(id)aSender {
    [NSApp beginSheet:O_addSheetPanel modalForWindow:[O_currentIPTextField window] modalDelegate:self didEndSelector:@selector(addMappingSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)removeMapping:(id)aSender {
    NSEnumerator *mappings = [[O_mappingsArrayController selectedObjects] objectEnumerator];
    TCMPortMapping *mapping = nil;
    while ((mapping=[mappings nextObject])) {
        if ([[[mapping userInfo] objectForKey:@"active"] boolValue]) {
            [[TCMPortMapper sharedInstance] removePortMapping:mapping];
        }
        [mapping removeObserver:self forKeyPath:@"userInfo.active"];
    }
    [O_mappingsArrayController removeObjects:[O_mappingsArrayController selectedObjects]];
}

- (void)addMappingSheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (IBAction)addMappingEndSheet:(id)aSender {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],@"active",[O_addDescriptionField stringValue],@"mappingTitle",[O_addReferenceStringField stringValue],@"referenceString",nil];
    TCMPortMapping *mapping = [TCMPortMapping portMappingWithPrivatePort:[O_addLocalPortField intValue] desiredPublicPort:[O_addDesiredField intValue] userInfo:userInfo];
    int transportProtocol = 0;
    if ([O_addProtocolTCPButton state] == NSOnState) transportProtocol+=TCMPortMappingTransportProtocolTCP;
    if ([O_addProtocolUDPButton state] == NSOnState) transportProtocol+=TCMPortMappingTransportProtocolUDP;
    [mapping setTransportProtocol:transportProtocol];
    [mapping addObserver:self forKeyPath:@"userInfo.active" options:0 context:nil];
    [O_mappingsArrayController addObject:mapping];
    [[TCMPortMapper sharedInstance] addPortMapping:mapping];
    [NSApp endSheet:O_addSheetPanel];
//    [O_addSheetPanel orderOut:self];
    [self writeMappingDefaults];
}

- (IBAction)addMappingCancelSheet:(id)aSender {
    [NSApp endSheet:O_addSheetPanel];
//    [O_addSheetPanel orderOut:self];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    NSTextView *fieldEditor = [[aNotification userInfo] objectForKey:@"NSFieldEditor"];
    if (fieldEditor == [O_addLocalPortField currentEditor]) {
        [O_addDesiredField setStringValue:[O_addLocalPortField stringValue]];
    }
    [O_invalidLocalPortView   setHidden:[O_addLocalPortField intValue]>0 && [O_addLocalPortField intValue]<=65535];
    [O_invalidDesiredPortView setHidden:  [O_addDesiredField intValue]>0 &&   [O_addDesiredField intValue]<=65535];
}

- (IBAction)choosePreset:(id)aSender {
    NSLog(@"%s %@ %@ %@",__FUNCTION__,aSender, [aSender selectedItem],[[aSender selectedItem] representedObject]);
    NSDictionary *preset = [[aSender selectedItem] representedObject];
    [O_addLocalPortField setObjectValue:[preset objectForKey:@"localPort"]];
    [O_addDesiredField   setObjectValue:[preset objectForKey:@"desiredPort"]];
    [O_addReferenceStringField setObjectValue:[preset objectForKey:@"referenceString"]];
    [O_addDescriptionField setObjectValue:[preset objectForKey:@"mappingTitle"]];
    [O_addProtocolTCPButton setState:([[preset objectForKey:@"transportProtocol"] intValue] & TCMPortMappingTransportProtocolTCP)?NSOnState:NSOffState];
    [O_addProtocolUDPButton setState:([[preset objectForKey:@"transportProtocol"] intValue] & TCMPortMappingTransportProtocolUDP)?NSOnState:NSOffState];
}

- (void)portMappingDidChangeMappingStatus:(NSNotification *)aNotification {
    [O_replacedReferenceStringTextField setStringValue:[[NSValueTransformer valueTransformerForName:@"TCMReplacedStringFromPortMappingReferenceString"] transformedValue:[O_mappingsArrayController selectedObjects]]];
}

- (void)startProgressIndicator:(NSNotification *)aNotification {
    [O_globalProgressIndicator startAnimation:self];
}


- (void)stopProgressIndicator:(NSNotification *)aNotification {
    [O_globalProgressIndicator stopAnimation:self];
}

@end
