//  ModeSettings.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface ModeSettings : NSObject {
    NSMutableArray *_recognitionExtenstions;
    NSMutableArray *_recognitionCasesensitveExtenstions;
    NSMutableArray *_recognitionRegexes;
    NSMutableArray *_recognitionFilenames;
    BOOL everythingOkay;
}


@property (nonatomic, readonly) NSArray *recognizedExtensions;
@property (nonatomic, readonly) NSArray *recognizedCasesensitveExtensions;
@property (nonatomic, readonly) NSArray *recognizedRegexes;
@property (nonatomic, readonly) NSArray *recognizedFilenames;
@property (nonatomic, copy) NSString *templateFile;

- (id)initWithFile:(NSString *)aPath;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (id)initWithPlist:(NSString *)bundlePath;

@end
