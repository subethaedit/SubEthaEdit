//  ModeSettings.h
//  SubEthaEdit
//
//  Created by Martin Pittenauer on 02.05.06.

#import <Cocoa/Cocoa.h>
#import <OgreKit/OgreKit.h>

@interface ModeSettings : NSObject {
    BOOL everythingOkay;
}

@property (nonatomic, strong, readonly) NSArray *recognizedExtensions;
@property (nonatomic, strong, readonly) NSArray *recognizedCasesensitveExtensions;
@property (nonatomic, strong, readonly) NSArray *recognizedRegexes;
@property (nonatomic, strong, readonly) NSArray *recognizedFilenames;
@property (nonatomic, copy) NSString *templateFile;

- (instancetype)initWithFile:(NSString *)aPath;

/*"XML parsing"*/
- (void)parseXMLFile:(NSString *)aPath;
- (instancetype)initWithPlist:(NSString *)bundlePath;

@end
