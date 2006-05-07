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
    [I_recognitionRegexes release];
    [I_recognitionFilenames release];
    [I_templateFile release];
    [super dealloc];
}

#pragma mark - 
#pragma mark - XML parsing
#pragma mark - 

-(void)parseXMLFile:(NSString *)aPath {
    CFXMLTreeRef cfXMLTree;
    CFDataRef xmlData;
    CFURLRef sourceURL = (CFURLRef)[NSURL fileURLWithPath:aPath];
    NSDictionary *errorDict;

    CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault, sourceURL, &xmlData, NULL, NULL, NULL);

    cfXMLTree = CFXMLTreeCreateFromDataWithError(kCFAllocatorDefault,xmlData,sourceURL,kCFXMLParserSkipMetaData,kCFXMLNodeCurrentVersion,(CFDictionaryRef *)&errorDict);

    if (!cfXMLTree) {
        NSLog(@"Error parsing mode settings \"%@\":\n%@", aPath, [errorDict description]);
        everythingOkay = NO;
        return;
    }        

    
    CFXMLTreeRef    xmlTree = NULL;
    CFXMLNodeRef    xmlNode = NULL;
    int             childCount;
    int             index;

    // Get a count of the top level node’s children.
    childCount = CFTreeGetChildCount(cfXMLTree);

    for (index = 0; index < childCount; index++) {
        xmlTree = CFTreeGetChildAtIndex(cfXMLTree, index);
        xmlNode = CFXMLTreeGetNode(xmlTree);
        if ((CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) &&
            [@"settings" isEqualToString:(NSString *)CFXMLNodeGetString(xmlNode)]) {
            break;
        }
    }

    if (xmlTree && xmlNode) {
        childCount = CFTreeGetChildCount(xmlTree);
        
        for (index = 0; index < childCount; index++) {
            CFXMLTreeRef xmlSubTree = CFTreeGetChildAtIndex(xmlTree, index);
            CFXMLNodeRef xmlSubNode = CFXMLTreeGetNode(xmlSubTree);

            if ([@"template" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
                // Parse for the template
                [self setTemplateFile:extractStringWithEntitiesFromTree(xmlSubTree)];
            } else if ([@"recognition" isEqualToString:(NSString *)CFXMLNodeGetString(xmlSubNode)]) {
                [self parseRecognition:xmlSubTree];
            }
        }
    }
    CFRelease(cfXMLTree);
    CFRelease(xmlData);
}

- (void)parseRecognition:(CFXMLTreeRef)aTree
{
    int childCount;
    int index;
    NSString *aString;

    childCount = CFTreeGetChildCount(aTree);
    for (index = 0; index < childCount; index++) {
        CFXMLTreeRef xmlTree = CFTreeGetChildAtIndex(aTree, index);
        CFXMLNodeRef xmlNode = CFXMLTreeGetNode(xmlTree);
        if (CFXMLNodeGetTypeCode(xmlNode) == kCFXMLNodeTypeElement) {
            NSString *tag = (NSString *)CFXMLNodeGetString(xmlNode);
            if ([@"extension" isEqualToString:tag]) {
                aString = extractStringWithEntitiesFromTree(xmlTree);
                [I_recognitionExtenstions addObject:aString];
            }  else if ([@"filename" isEqualToString:tag]) {
                aString = extractStringWithEntitiesFromTree(xmlTree);
                [I_recognitionFilenames addObject:aString];
            }  else if ([@"regex" isEqualToString:tag]) {
                aString = extractStringWithEntitiesFromTree(xmlTree);

                if ([OGRegularExpression isValidExpressionString:aString]) {
                    //[I_recognitionRegexes addObject:[[[OGRegularExpression alloc] initWithString:aString options:OgreFindNotEmptyOption]autorelease]];
                    [I_recognitionRegexes addObject:aString];
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
    }
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
