//  AboutPanelController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.

#import "AboutPanelController.h"
#import <OgreKit/OgreKit.h>
#import "AppController.h"

// this file needs arc - either project wide,
// or add -fobjc-arc on a per file basis in the compile build phase
#if !__has_feature(objc_arc)
#error ARC must be enabled!
#endif

@interface AboutPanelController ()
@property (nonatomic, strong) IBOutlet NSImageView *O_appIconView;
@property (nonatomic, strong) IBOutlet NSTextField *O_legalTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_versionField;
@property (nonatomic, strong) IBOutlet NSTextField *O_ogreVersionField;
@property (nonatomic, strong) IBOutlet NSTextField *O_licenseTypeField;
@property (nonatomic, strong) IBOutlet NSTextField *appNameField;
@end

@implementation AboutPanelController

- (id)init {
    self = [super initWithWindowNibName:@"AboutPanel"];
    return self;
}

- (void)windowDidLoad {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *versionString = AppController.localizedVersionString;
    NSString *ogreVersion = [NSString stringWithFormat:@"OgreKit v%@, Oniguruma v%@", [OGRegularExpression version], [OGRegularExpression onigurumaVersion]];

    [self.O_versionField setObjectValue:versionString];
    [self.O_ogreVersionField setObjectValue:ogreVersion];
    [self.O_legalTextField setObjectValue:[[[mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"] componentsSeparatedByString:@". "] componentsJoinedByString:@".\n"]];
    [self.appNameField setObjectValue:AppController.localizedApplicationName];
    
    NSString *licenseType = nil;
#ifdef BETA
#ifdef BETA_EXPIRE_DATE
#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define BETA_EXPIRE_DATE_LITERAL @ STRINGIZE2(BETA_EXPIRE_DATE)
    
    NSString *expireDateString = BETA_EXPIRE_DATE_LITERAL;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd' 'HH':'mm':'ss' 'xx"];
    
    NSDate *expireDate = [dateFormatter dateFromString:expireDateString];
    licenseType = [NSString stringWithFormat:@"Beta - %@", expireDate];
#else // !BETA_EXPIRE_DATE
    licenseType = @"Beta";
#endif // BETA_EXPIRE_DATE
#else // ! BETA
#ifdef MAC_APP_STORE_RECEIPT_VALIDATION
    licenseType = @"AppStore Version";
#else //! MAC_APP_STORE_RECEIPT_VALIDATION
    licenseType = @"Outside AppStore Version";
#endif // MAC_APP_STORE_RECEIPT_VALIDATION
#endif // BETA

    if (licenseType) {
        self.O_licenseTypeField.stringValue = licenseType;
    }
    
    [[self window] center];
}

- (IBAction)showWindow:(id)sender {
    [[self window] center];
    [super showWindow:self];
}

@end
