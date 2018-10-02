//  ModeSettings.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.

#import "ModeSettings.h"


@implementation ModeSettings

- (void)getReady {
	everythingOkay = YES;
	I_recognitionExtenstions = [NSMutableArray new];
	I_recognitionRegexes = [NSMutableArray new];
	I_recognitionFilenames = [NSMutableArray new];
	I_recognitionCasesensitveExtenstions = [NSMutableArray new];
}

- (id)initWithFile:(NSString *)aPath {
    self=[super init];
    if (self) {
        if (!aPath) {
            [self release]; self = nil;
            return nil;
        }
        // Parse XML File
		[self getReady];
        [self parseXMLFile:aPath];

		if (! everythingOkay) {
			NSLog(@"Critical errors while loading mode settings. ModeSettings.xml will be ignored, falling back to Info.plist.");
            [self release]; self = nil;
			return nil;
		}
    }
	return self;
}

- (id)initWithPlist:(NSString *)bundlePath {
    self=[super init];
    if (self) {
        if (!bundlePath) {
			[self release]; self = nil;
            return nil;
        }

		[self getReady];
    
		CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) bundlePath, kCFURLPOSIXPathStyle, 1);
        CFDictionaryRef infodict = CFBundleCopyInfoDictionaryInDirectory(url);
        NSDictionary *infoDictionary = (NSDictionary *) infodict;
        [I_recognitionExtenstions addObjectsFromArray:[infoDictionary objectForKey:@"TCMModeExtensions"]];
        CFRelease(url);
        CFRelease(infodict);
    }
	
	return self;
}

- (void)dealloc {
    [I_recognitionExtenstions release];
    [I_recognitionCasesensitveExtenstions release];
    [I_recognitionRegexes release];
    [I_recognitionFilenames release];
    [I_templateFile release];
    [super dealloc];
}

#pragma mark - XML parsing

-(void)parseXMLFile:(NSString *)aPath {
	if (aPath) {
		NSData *data = [NSData dataWithContentsOfFile:aPath];
		if (data) {
			NSError *err=nil;
			NSXMLDocument *modeSettingsXML = [[[NSXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:aPath] options:0 error:&err] autorelease];

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

			id entry;
			for (entry in recognitionEntries) {
				NSString *name = [entry name];
				NSString *value = [entry stringValue];

				if ([@"extension" isEqualToString:name]) {
					// Check
					NSString *caseSensitive = [[entry attributeForName:@"casesensitive"] stringValue];
					if ([caseSensitive isEqualToString:@"yes"]) [I_recognitionCasesensitveExtenstions addObject:value];
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
		} else {
			NSLog(@"%s - Can't read file at path %@, please make sure it exists or you have access.", __FUNCTION__, aPath);
		}
	}
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
