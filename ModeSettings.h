//
//  ModeSettings.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.
//  Copyright 2006 TheCodingMonkeys. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface ModeSettings : NSObject {
    NSMutableArray *I_recognitionExtenstions;
    NSMutableArray *I_recognitionCasesensitveExtenstions;
    NSMutableArray *I_recognitionRegexes;
    NSMutableArray *I_recognitionFilenames;
    NSString *I_templateFile;
    BOOL everythingOkay;
}

- (id)initWithFile:(NSString *)aPath;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (id)initWithPlist:(NSString *)bundlePath;

/*"Accessors"*/
- (NSArray *)recognizedExtensions;
- (NSArray *)recognizedCasesensitveExtensions;
- (NSArray *)recognizedRegexes;
- (NSArray *)recognizedFilenames;
- (NSString *)templateFile;
- (void)setTemplateFile:(NSString *)aString;

@end
