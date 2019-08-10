//  ModeSettings.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface ModeSettings : NSObject {
    NSMutableArray *_recognizedExtensions;
    NSMutableArray *_recognizedCasesensitveExtensions;
    NSMutableArray *_recognizedRegexes;
    NSMutableArray *_recognizedFilenames;
    BOOL everythingOkay;
}

@property (nonatomic, readonly) NSArray *recognizedExtensions;
@property (nonatomic, readonly) NSArray *recognizedCasesensitveExtensions;
@property (nonatomic, readonly) NSArray *recognizedRegexes;
@property (nonatomic, readonly) NSArray *recognizedFilenames;
@property (nonatomic, copy) NSString *templateFile;

- (instancetype)initWithFile:(NSString *)aPath;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (instancetype)initWithPlist:(NSString *)bundlePath;

@end
