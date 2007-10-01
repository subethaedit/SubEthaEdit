//
//  ModeSettings.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import "ModeSettings.h"


@implementation ModeSettings

- (id)initWithFile:(NSString *)aPath {
    self=[super init];
    if (self) {
        if (!aPath) {
            [self dealloc];
            return nil;
        }
        everythingOkay = YES;
        I_recognitionExtenstions = [NSMutableArray new];
        I_recognitionRegexes = [NSMutableArray new];
        I_recognitionFilenames = [NSMutableArray new];
		I_recognitionCasesensitveExtenstions = [NSMutableArray new];
        // Parse XML File
        [self parseXMLFile:aPath];
    }

    if (everythingOkay) return self;
    else {
        NSLog(@"Critical errors while loading mode settings. ModeSettings.xml will be ignored, falling back to Info.plist.");
        [self dealloc];
        return nil;
    }
}

- (void)dealloc {
    [I_recognitionExtenstions release];
    [I_recognitionCasesensitveExtenstions release];
    [I_recognitionRegexes release];
    [I_recognitionFilenames release];
    [I_templateFile release];
    [super dealloc];
}

#pragma mark - 
#pragma mark - XML parsing
#pragma mark - 

-(void)parseXMLFile:(NSString *)aPath {

    NSError *err=nil;
	// FIXME seed
    NSXMLDocument *modeSettingsXML = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:aPath] options:NSXMLDocumentTidyXML error:&err];

    if (err) {
        NSLog(@"Error while loading '%@': %@", aPath, [err localizedDescription]);
        everythingOkay = NO;
        return;
    } 
    
    // Set template file name, if there is one.
    [self setTemplateFile:[[[modeSettingsXML nodesForXPath:@"/settings/template" error:&err] lastObject] stringValue]];

    if (err) {
        NSLog(@"Error while parsing template section of '%@': %@", aPath, [err localizedDescription]);
        everythingOkay = NO;
        return;
    } 
        
    NSArray *recognitionEntries = [modeSettingsXML nodesForXPath:@"/settings/recognition/*" error:&err];

    if (err) {
        NSLog(@"Error while parsing recognition section of '%@': %@", aPath, [err localizedDescription]);
        everythingOkay = NO;
        return;
    } 

    NSEnumerator *enumerator = [recognitionEntries objectEnumerator];
    id entry;
    while ((entry = [enumerator nextObject])) {
        NSString *name = [entry name];
        NSString *value = [entry stringValue];
        
        if ([@"extension" isEqualToString:name]) {
			// Check
			NSString *caseSensitive = [[entry attributeForName:@"casesensitive"] stringValue];
			if ([caseSensitive isEqualToString:@"no"]) [I_recognitionCasesensitveExtenstions addObject:value];
			else {
				BOOL alreadyInThere = NO;
				NSEnumerator *enumerator = [I_recognitionExtenstions objectEnumerator];
				id object;
				while ((object = [enumerator nextObject])) {
					if ([[object uppercaseString] isEqualToString:[value uppercaseString]]) alreadyInThere = YES;
				}				
				if (!alreadyInThere) [I_recognitionExtenstions addObject:value];
			}
        }  else if ([@"filename" isEqualToString:name]) {
            [I_recognitionFilenames addObject:value];
        }  else if ([@"regex" isEqualToString:name]) {
            if ([OGRegularExpression isValidExpressionString:value]) {
                [I_recognitionRegexes addObject:value];
            } else {                
                NSAlert *alert = [[[NSAlert alloc] init] autorelease];
                [alert setAlertStyle:NSWarningAlertStyle];
                [alert setMessageText:NSLocalizedString(@"Regular Expression Error",@"Regular Expression Error Title")];
                [alert setInformativeText:NSLocalizedString(@"One of the specified <regex> elements in the mode's settings is not a valid regular expression. ModeSettings.xml will be ignored, falling back to Info.plist. Please check your regular expression in Find Panel's Ruby mode.",@"Mode Settings Expression Error Informative Text")];
                [alert addButtonWithTitle:@"OK"];
                [alert runModal];
                everythingOkay = NO;
            }
        }
    }    
    
    [modeSettingsXML release];
}

- (NSArray *)recognizedCasesensitveExtensions {
    return I_recognitionCasesensitveExtenstions;
}

- (NSArray *)recognizedExtensions {
    return I_recognitionExtenstions;
}

- (NSArray *)recognizedRegexes {
    return I_recognitionRegexes;
}

- (NSArray *)recognizedFilenames {
    return I_recognitionFilenames;
}

- (NSString *)templateFile {
    return I_templateFile;
}

- (void)setTemplateFile:(NSString *)aString {
    [I_templateFile autorelease];
    I_templateFile = [aString copy];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Mode Settings:\n Extensions:%@ \n\n Filenames:%@\n\n Regex: %@\n\n Template: %@", [self recognizedExtensions], [self recognizedFilenames], [self recognizedRegexes], [self templateFile]];
}


@end
