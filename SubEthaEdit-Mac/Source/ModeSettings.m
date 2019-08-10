//  ModeSettings.m
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.

#import "ModeSettings.h"

// this file needs arc - add -fobjc-arc in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif



@implementation ModeSettings {
    NSMutableArray *_recognizedExtensions;
    NSMutableArray *_recognizedCasesensitveExtensions;
    NSMutableArray *_recognizedRegexes;
    NSMutableArray *_recognizedFilenames;
}

- (void)getReady {
	everythingOkay = YES;
	_recognizedExtensions = [NSMutableArray new];
	_recognizedRegexes = [NSMutableArray new];
	_recognizedFilenames = [NSMutableArray new];
	_recognizedCasesensitveExtensions = [NSMutableArray new];
}

- (instancetype)initWithFile:(NSString *)aPath {
    self=[super init];
    if (self) {
        if (!aPath) {
            self = nil;
            return nil;
        }
        // Parse XML File
		[self getReady];
        [self parseXMLFile:aPath];

		if (! everythingOkay) {
			NSLog(@"Critical errors while loading mode settings. ModeSettings.xml will be ignored, falling back to Info.plist.");
            self = nil;
			return nil;
		}
    }
	return self;
}

- (instancetype)initWithPlist:(NSString *)bundlePath {
    self=[super init];
    if (self) {
        if (!bundlePath) {
			self = nil;
            return nil;
        }

		[self getReady];
    
		CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef) bundlePath, kCFURLPOSIXPathStyle, 1);
        CFDictionaryRef infodict = CFBundleCopyInfoDictionaryInDirectory(url);
        NSDictionary *infoDictionary = (NSDictionary *) CFBridgingRelease(infodict);
        [_recognizedExtensions addObjectsFromArray:[infoDictionary objectForKey:@"TCMModeExtensions"]];
        CFRelease(url);
    }
	
	return self;
}

#pragma mark - XML parsing

-(void)parseXMLFile:(NSString *)aPath {
	if (aPath) {
		NSData *data = [NSData dataWithContentsOfFile:aPath];
		if (data) {
			NSError *err=nil;
			NSXMLDocument *modeSettingsXML = [[NSXMLDocument alloc] initWithData:[NSData dataWithContentsOfFile:aPath] options:0 error:&err];

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
					if ([caseSensitive isEqualToString:@"yes"]) [_recognizedCasesensitveExtensions addObject:value];
					else {
						BOOL alreadyInThere = NO;
						NSEnumerator *enumerator = [_recognizedExtensions objectEnumerator];
						id object;
						while ((object = [enumerator nextObject])) {
							if ([[object uppercaseString] isEqualToString:[value uppercaseString]]) alreadyInThere = YES;
						}
						if (!alreadyInThere) [_recognizedExtensions addObject:value];
					}
				}  else if ([@"filename" isEqualToString:name]) {
					[_recognizedFilenames addObject:value];
				}  else if ([@"regex" isEqualToString:name]) {
					if ([OGRegularExpression isValidExpressionString:value]) {
						[_recognizedRegexes addObject:value];
					} else {
						NSAlert *alert = [[NSAlert alloc] init];
						[alert setAlertStyle:NSAlertStyleWarning];
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

- (NSString *)description {
    return [NSString stringWithFormat:@"Mode Settings:\n Extensions:%@ \n\n Filenames:%@\n\n Regex: %@\n\n Template: %@", [self recognizedExtensions], [self recognizedFilenames], [self recognizedRegexes], [self templateFile]];
}

@end
