//  AboutPanelController.m
//  SubEthaEdit
//
//  Created by Martin Ott on Thu May 13 2004.

#import "AboutPanelController.h"
#import <OgreKit/OgreKit.h>
#import "AppController.h"

@interface AboutPanelController ()
@property (nonatomic, strong) IBOutlet NSImageView *O_appIconView;
@property (nonatomic, strong) IBOutlet NSTextField *O_legalTextField;
@property (nonatomic, strong) IBOutlet NSTextField *O_versionField;
@property (nonatomic, strong) IBOutlet NSTextField *O_ogreVersionField;
@property (nonatomic, strong) IBOutlet NSTextField *O_licenseTypeField;
@property (nonatomic, strong) IBOutlet NSTextField *appNameField;
@end

@implementation AboutPanelController

- (instancetype)init {
    self = [super initWithWindowNibName:@"AboutPanel"];
    return self;
}

- (void)windowDidLoad {
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *versionString = AppController.localizedVersionString;
    NSString *ogreVersion = [NSString stringWithFormat:@"OgreKit v%@, Onigmo v%@", [OGRegularExpression version], [OGRegularExpression onigurumaVersion]];

    [self.O_versionField setObjectValue:versionString];
    [self.O_ogreVersionField setObjectValue:ogreVersion];
    [self.O_legalTextField setObjectValue:[[[mainBundle objectForInfoDictionaryKey:@"NSHumanReadableCopyright"] componentsSeparatedByString:@". "] componentsJoinedByString:@".\n"]];
    [self.appNameField setObjectValue:AppController.localizedApplicationName];
    
    NSString *licenseType = nil;
#ifdef BETA
    licenseType = @"Beta";
#else // ! BETA
#ifdef MAC_APP_STORE
    licenseType = @"AppStore Version";
#else //! MAC_APP_STORE
    licenseType = @"Website Version";
#endif // MAC_APP_STORE
#endif // BETA

    if (licenseType) {
        self.O_licenseTypeField.stringValue = SEE_NoLocalizationNeeded(licenseType);
    }
    
    [[self window] center];
}

- (IBAction)showWindow:(id)sender {
    [[self window] center];
    [super showWindow:self];
}

@end
