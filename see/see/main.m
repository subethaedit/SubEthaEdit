//  main.m
//  see
//
//  Created by Martin Ott on Tue Apr 14 2004.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <getopt.h>
#import <libProc.h>
/*

see -h
see -v
see -l
see -p [options] [files]
see [options] [files]

*/

static struct option longopts[] = {
    { "help",       no_argument,            0,  'h' }, // command
    { "version",    no_argument,            0,  'v' }, // command
    { "background", no_argument,            0,  'b' }, // option
    { "wait",       no_argument,            0,  'w' }, // option
    { "resume",     no_argument,            0,  'r' }, // option
    { "launch",     no_argument,            0,  'l' }, // command
    { "print",      no_argument,            0,  'p' }, // command/option
    { "encoding",   required_argument,      0,  'e' }, // option
    { "mode",       required_argument,      0,  'm' }, // option
    { "open-in",    required_argument,      0,  'o' }, // option
    { "pipe-dirty", no_argument,            0,  'd' }, // option
    { "pipe-title", required_argument,      0,  't' }, // option
    { "job-description", required_argument, 0,  'j' }, // option
    { "goto",            required_argument, 0,  'g' }, // option
    { 0,            0,                      0,  0 }
};

static NSURL *tempFileURL() {
    NSError *error;
    NSURL *tmpURL = [[NSFileManager defaultManager] URLForDirectory:NSItemReplacementDirectory inDomain:NSUserDomainMask appropriateForURL:[NSURL fileURLWithPath:@"/"] create:YES error:&error];
    if (!tmpURL) {
        fprintf(stderr, "Error creating temporary file: %s\n", [[error localizedDescription] UTF8String]);
    }
    NSString *filename = [NSString stringWithFormat:@"see-%@.seetmpstdin", [[NSUUID UUID] UUIDString]];
    return [tmpURL URLByAppendingPathComponent:filename];
}

static void printHelp() {
    fprintf(stdout, "Usage: see [-bdhlprvw] [-g line[:column]] [-o where] [-e encoding_name] [-m mode_identifier] [-t title] [-j description] [file ...]\n");
    fflush(stdout);
}

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)

#define SEE_REPO_REVISION_NSSTRING @STRINGIZE2(SEE_REPO_REVISION)
#define SEE_CLT_VERSION_NSSTRING @STRINGIZE2(SEE_CLT_VERSION)

void parseShortVersionString(int *major, int *minor) {
    NSString *shortVersion = SEE_CLT_VERSION_NSSTRING; //[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; // with sandboxing the plist is inaccessible
    NSScanner *scanner = [NSScanner scannerWithString:shortVersion];
    (void)[scanner scanInt:major];
    (void)[scanner scanString:@"." intoString:nil];
    (void)[scanner scanInt:minor];
}

BOOL meetsRequiredVersion(NSString *string) {
    if (!string) {
        return NO;
    }
    
    int myMajor, myMinor;
    parseShortVersionString(&myMajor, &myMinor);
    
    BOOL result;
    int major = 0;
    int minor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    result = ([scanner scanInt:&major]
        && [scanner scanString:@"." intoString:nil]
        && [scanner scanInt:&minor]);
    
    if (result) {
        if (major < myMajor
            || (major == myMajor && minor <= myMinor)) {
            return YES;
        }
    }
    
    return NO;
}

#define SEE_APP_IDENTIFIER_BASE_STRING @ STRINGIZE2(SEE_APP_IDENTIFIER_BASE)
#define THESE_APP_IDENTIFIERS(base) \
                        SEE_APP_IDENTIFIER_BASE_STRING ".Mac",\
                        SEE_APP_IDENTIFIER_BASE_STRING ".MacFULL",\
                        SEE_APP_IDENTIFIER_BASE_STRING ".MacBETA",\
                        SEE_APP_IDENTIFIER_BASE_STRING ".MacBETADev",\
                        SEE_APP_IDENTIFIER_BASE_STRING ".MacFULLDev",

static NSArray *subEthaEditBundleIdentifiers(void) {
	NSArray *result = @[THESE_APP_IDENTIFIERS(xstr(SEE_APP_IDENTIFIER_BASE))
                        @"de.codingmonkeys.SubEthaEdit.Mac",
						@"de.codingmonkeys.SubEthaEdit.MacFULL",
						@"de.codingmonkeys.SubEthaEdit.MacBETA",
//						@"de.codingmonkeys.SubEthaEdit.MacDev", // no option due to signing
						@"de.codingmonkeys.SubEthaEdit.MacFULLDev",
						@"de.codingmonkeys.SubEthaEdit.MacBETADev",
						@"de.codingmonkeys.SubEthaEdit",
                        ];
	return result;
}

CFURLRef CopyURLRefForSubEthaEdit(void) {
	NSURL *applicationURL = nil;
    NSUInteger bundleVersion = 0;

	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
	[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];

	NSArray *appIdentifiers = subEthaEditBundleIdentifiers();

	// Look if some version of SubEthaEdit is currently running.
	NSMutableArray *runningSubEthaEdits = [NSMutableArray array];
	for (NSString *identifier in appIdentifiers) {
		[runningSubEthaEdits addObjectsFromArray:[NSRunningApplication runningApplicationsWithBundleIdentifier:identifier]];
	}

	for (NSRunningApplication *subEthaEditInstance in runningSubEthaEdits) {
		NSURL *runningApplicationBundleURL = [subEthaEditInstance bundleURL];
		NSBundle *appBundle = [NSBundle bundleWithURL:runningApplicationBundleURL];
		NSInteger version = [[[appBundle infoDictionary] objectForKey:(id)kCFBundleVersionKey] integerValue];
		NSString *minimumSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMMinimumSeeToolVersion"];

		if (version > bundleVersion && meetsRequiredVersion(minimumSeeToolVersionString)) {
			bundleVersion = version;
			applicationURL = [[runningApplicationBundleURL retain] autorelease];
		}
	}
    
	if (applicationURL) {
		return (CFURLRef)[applicationURL copy];
	}

	// Look for the default version of SubEthaEdit
	NSMutableArray *workspaceAppURLs = [NSMutableArray array];
	for (NSString *identifier in appIdentifiers) {
		NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:identifier];
		if (url) {
			[workspaceAppURLs addObject:url];
		}
	}

	for (NSURL *bundleURL in workspaceAppURLs) {
		NSBundle *appBundle = [NSBundle bundleWithURL:bundleURL];
		NSInteger version = [[[appBundle infoDictionary] objectForKey:(id)kCFBundleVersionKey] integerValue];
		NSString *minimumSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMMinimumSeeToolVersion"];

		if (version > bundleVersion && meetsRequiredVersion(minimumSeeToolVersionString))
		{
			bundleVersion = version;
			applicationURL = [[bundleURL retain] autorelease];
		}
	}
	if (applicationURL) {
		return (CFURLRef)[applicationURL copy];
	}

	// Look for any app that understands the see:// URL protocol
	applicationURL = [[NSWorkspace sharedWorkspace] URLForApplicationToOpenURL:[NSURL URLWithString:@"see://egal"]];
	if (applicationURL) {
        NSBundle *appBundle = [NSBundle bundleWithURL:applicationURL];
        NSString *minimumSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMMinimumSeeToolVersion"];
        if (meetsRequiredVersion(minimumSeeToolVersionString)) {
			return (CFURLRef)[applicationURL copy];
        }
	}
	return NULL;
}

static void printVersion(void) {
    OSStatus status = noErr;
    CFURLRef appURL = NULL;
    NSString *appVersion = @"";
    NSString *versionString = nil;
    NSString *localizedVersionString = nil;
    NSString *appShortVersionString = @"n/a";
    NSString *bundledSeeToolVersionString = nil;
    
    appURL = CopyURLRefForSubEthaEdit();
    if (appURL) {
        CFAutorelease(appURL);
        NSBundle *appBundle = [NSBundle bundleWithPath:[(NSURL *)appURL path]];
        appVersion = [[appBundle infoDictionary] objectForKey:@"CFBundleVersion"];
        versionString = [[appBundle infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        bundledSeeToolVersionString = [[appBundle infoDictionary] objectForKey:@"TCMBundledSeeToolVersion"];
        localizedVersionString = [[appBundle localizedInfoDictionary] objectForKey:@"CFBundleShortVersionString"];
    }
        
    if (versionString) {
        appShortVersionString = versionString;
    } else if (localizedVersionString) {
        appShortVersionString = localizedVersionString;
    }

    NSString *shortVersion = SEE_CLT_VERSION_NSSTRING; // [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]; // But with sandboxing the plist cannot be loaded
    NSString *bundleVersion = SEE_REPO_REVISION_NSSTRING; // [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]; // But with sandboxing the plist cannot be loaded
    fprintf(stdout, "see %s (%s)\n", [shortVersion UTF8String], [bundleVersion UTF8String]);
    if (appURL) {
        fprintf(stdout, "%s %s (%s)\n", [[(NSURL *)appURL path] fileSystemRepresentation], [appShortVersionString UTF8String], [appVersion UTF8String]);
        if (bundledSeeToolVersionString) {
            int myMajor, myMinor;
            parseShortVersionString(&myMajor, &myMinor);
        
            BOOL result;
            BOOL newerBundledVersion = NO;
            int major = 0;
            int minor = 0;
            NSScanner *scanner = [NSScanner scannerWithString:bundledSeeToolVersionString];
            result = ([scanner scanInt:&major]
                && [scanner scanString:@"." intoString:nil]
                && [scanner scanInt:&minor]);
            
            if (result) {
                if (major > myMajor
                    || (major == myMajor && minor > myMinor)) {
                    newerBundledVersion = YES;
                }
            }

            if (newerBundledVersion) {
                fprintf(stdout, "\nA newer version of the see command line tool is available.\nThe found SubEthaEdit bundles version %s of the see command.\n\n", [bundledSeeToolVersionString UTF8String]);
            }
        }
    }
    fflush(stdout);
    
    if (kLSApplicationNotFoundErr == status || appURL == NULL) {
        fprintf(stderr, "see: Couldn't find compatible SubEthaEdit.\n     Please install a current version of SubEthaEdit.\n");
        fflush(stderr);
    }
	
}


NSRunningApplication *findSubEthaeditPID(pid_t aParentPid) {
	NSRunningApplication *result = nil;
	pid_t pids[1024];
	int numberOfProcesses = proc_listchildpids(aParentPid, pids, 1024);
	proc_listpids(PROC_ALL_PIDS, 0, pids, sizeof(pids));
	for (int i = 0; i < numberOfProcesses; ++i) {
		pid_t pid = pids[i];
		if (pid == 0) {
			continue;
		}
		char name[1024];
		proc_name(pid, name, sizeof(name));
		//		printf("Found process: %s\n", name);
		if (strlen(name) > 7 && strncmp(name, "SubEtha", 7) == 0) {
			result = [NSRunningApplication runningApplicationWithProcessIdentifier:pid];
		} else {
			result = findSubEthaeditPID(pid);
		}
		if (result) {
			break;
		}
	}
	return result;
}

static NSRunningApplication *launchSubEthaEdit(NSDictionary *options) {
	NSRunningApplication *result = nil;
    CFURLRef appURL = NULL;

    appURL = CopyURLRefForSubEthaEdit();
    if (appURL == NULL) {
        fprintf(stderr, "see: Couldn't find compatible SubEthaEdit.\n     Please install a current version of SubEthaEdit.\n");
        fflush(stderr);
    } else {
        CFAutorelease(appURL);
        BOOL dontSwitch = [[options objectForKey:@"background"] boolValue];
        
        LSLaunchURLSpec inLaunchSpec;
        inLaunchSpec.appURL = appURL;
        inLaunchSpec.itemURLs = NULL;
        inLaunchSpec.passThruParams = NULL;
        if (dontSwitch) {
            inLaunchSpec.launchFlags = kLSLaunchDontSwitch;
        } else {
            inLaunchSpec.launchFlags = 0;
        }
        inLaunchSpec.asyncRefCon = NULL;
        CFURLRef outURL;
        LSOpenFromURLSpec(&inLaunchSpec, &outURL);
		//        NSLog(@"%s %@  -  %@ - %@",__FUNCTION__,(NSURL *)appURL,(NSURL *)outURL, [[NSWorkspace sharedWorkspace] runningApplications]);
		
		NSArray *appIdentifiers = subEthaEditBundleIdentifiers();
		NSMutableArray *runningSubEthaEdits = [NSMutableArray array];
		for (NSString *identifier in appIdentifiers) {
			[runningSubEthaEdits addObjectsFromArray:[NSRunningApplication runningApplicationsWithBundleIdentifier:identifier]];
		}
		result = runningSubEthaEdits.firstObject;
		if (!result) {
			for (NSRunningApplication *application in [[NSWorkspace sharedWorkspace] runningApplications]) {
				if ([application.localizedName hasPrefix:@"SubEthaEdit"]) {
					// somehow the bundle identifier isn't set, but the localized name is correct as it is just the proccess name when run in debugger
					result = [NSRunningApplication runningApplicationWithProcessIdentifier:application.processIdentifier];
				}
			}
		}
		if (!result) {
			// probably the debugger case find the pid for a running subethaedit
			// not needed anymore but kept for interesting bits here
			/*
			NSRunningApplication *xcode = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dt.Xcode"].firstObject;
			if (xcode) {
				result = findSubEthaeditPID(xcode.processIdentifier);
			}
			*/
			fprintf(stderr, "see: Couldn't start compatbile SubEthaEdit.\n");
			fflush(stderr);
		} else {
			while (!result.isFinishedLaunching) {
				NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
				[runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
			}
		}
		
    }
	return result;
}


static NSAppleEventDescriptor *propertiesEventDescriptorWithOptions(NSDictionary *options) {
    NSAppleEventDescriptor *propRecord = [NSAppleEventDescriptor recordDescriptor];
    
    NSString *mode = [options objectForKey:@"mode"];
    if (mode) {
        [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:mode]
                       forKeyword:'Mode'];                
    }
    NSString *encoding = [options objectForKey:@"encoding"];
    if (encoding) {
        [propRecord setDescriptor:[NSAppleEventDescriptor descriptorWithString:encoding]
                       forKeyword:'Encd'];                
    }
                    
    return propRecord;
}


static NSArray *see(NSArray *fileNames, NSArray *newFileNames, NSString *stdinFileName, NSDictionary *options) {
    NSRunningApplication *runningSubEthaEdit = launchSubEthaEdit(options);
    if (!runningSubEthaEdit) {
        return nil;
    }	

	NSMutableArray *urls = [NSMutableArray array];
	for (NSString *fileName in fileNames) {
		NSURL *fileURL = [NSURL fileURLWithPath:fileName];
		[urls addObject:fileURL];
	}

	if (stdinFileName) {
		NSURL *fileURL = [NSURL fileURLWithPath:stdinFileName];
		[urls addObject:fileURL];
	}

    AESendMode sendMode = kAEQueueReply | kAEWantReceipt;
    long timeOut = kAEDefaultTimeout;
    pid_t pid = [runningSubEthaEdit processIdentifier];
    NSAppleEventDescriptor *addressDescriptor = [[[NSAppleEventDescriptor alloc] initWithDescriptorType:typeKernelProcessID bytes:&pid length:sizeof(pid)] autorelease];
    
    NSMutableArray *resultFileNames = [NSMutableArray array];
    if (!addressDescriptor) {
        fprintf(stderr, "see: Could not successfully address a SubEthaEdit.app");
        fflush(stderr);
        exit(EXIT_FAILURE);
    } else {
        if (urls.count > 0) {
            NSAppleEventDescriptor *fileList = [NSAppleEventDescriptor listDescriptor];
            [urls enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger index, BOOL *_stop) {
                [fileList insertDescriptor:[NSAppleEventDescriptor descriptorWithFileURL:url] atIndex:index + 1];
            }];
            NSAppleEventDescriptor *openEvent = [NSAppleEventDescriptor appleEventWithEventClass:kCoreEventClass eventID:[[options objectForKey:@"print"] boolValue] ? kAEPrintDocuments : kAEOpenDocuments targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
            [openEvent setParamDescriptor:fileList forKeyword:keyDirectObject];
            
            AppleEvent reply;
            AESendMode sendMode = kAEQueueReply | kAEWantReceipt;
            long timeOut = kAEDefaultTimeout;
            
            OSStatus err = AESendMessage([openEvent aeDesc], &reply, sendMode, timeOut);
            if (err != noErr) {
                fprintf(stderr, "see: Error occurred while sending AppleEvent: %d\n", (int)err);
                fflush(stderr);
                exit(EXIT_FAILURE);
            }
        }
        
        NSAppleEventDescriptor *appleEvent = [NSAppleEventDescriptor appleEventWithEventClass:'Hdra' eventID:'See ' targetDescriptor:addressDescriptor returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
        if (appleEvent != nil) {
            
            NSUInteger count = [fileNames count];
            if (count > 0) {
                NSAppleEventDescriptor *filesDesc = [NSAppleEventDescriptor listDescriptor];
                for (NSUInteger i = 0; i < count; i++) {
                    [filesDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[fileNames objectAtIndex:i]]
                                        atIndex:i + 1];
                }
                [appleEvent setParamDescriptor:filesDesc
                                    forKeyword:'File'];
            }
            
            count = [newFileNames count];
            if (count > 0) {
                NSAppleEventDescriptor *newFilesDesc = [NSAppleEventDescriptor listDescriptor];
                for (NSUInteger i = 0; i < count; i++) {
                    [newFilesDesc insertDescriptor:[NSAppleEventDescriptor descriptorWithString:[newFileNames objectAtIndex:i]]
                                           atIndex:i + 1];
                }
                [appleEvent setParamDescriptor:newFilesDesc
                                    forKeyword:'NuFl'];
            }
            
            if (stdinFileName) {
                sendMode = kAEWaitReply;
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:stdinFileName]
                                    forKeyword:'Stdi'];
            }
            
            NSAppleEventDescriptor *propRecord = propertiesEventDescriptorWithOptions(options);
            [appleEvent setParamDescriptor:propRecord
                                forKeyword:keyAEPropData];
            
            NSString *jobDescription = [options objectForKey:@"job-description"];
            if (jobDescription) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:jobDescription]
                                    forKeyword:'JobD'];
            }
            
            NSString *gotoString = [options objectForKey:@"goto"];
            if (gotoString) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:gotoString]
                                    forKeyword:'GoTo'];
            }
            
            NSString *openinString = [options objectForKey:@"open-in"];
            if (openinString) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:openinString]
                                    forKeyword:'OpIn'];
            }
            
            
            NSString *pipeTitle = [options objectForKey:@"pipe-title"];
            if (pipeTitle) {
                [appleEvent setDescriptor:[NSAppleEventDescriptor descriptorWithString:pipeTitle]
                               forKeyword:'Pipe'];
                
            }
            
            if ([[options objectForKey:@"print"] boolValue]) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'Prnt'];
            }
            
            if ([[options objectForKey:@"wait"] boolValue]) {
                sendMode = kAEWaitReply;
                timeOut = kNoTimeOut;
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'Wait'];
            }
            
            if ([[options objectForKey:@"pipe-out"] boolValue]) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'PipO'];
            }
            
            if ([[options objectForKey:@"pipe-dirty"] boolValue]) {
                [appleEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithBoolean:true]
                                    forKeyword:'Pdty'];
            }
            
            
            AppleEvent reply;
            OSStatus err = AESendMessage([appleEvent aeDesc], &reply, sendMode, timeOut);
            if (err == noErr) {
                NSAppleEventDescriptor *replyDesc = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&reply];
                NSAppleEventDescriptor *directObjectDesc = [replyDesc descriptorForKeyword:keyDirectObject];
                if (directObjectDesc) {
                    NSUInteger count = [directObjectDesc numberOfItems];
                    for (NSUInteger i = 1; i <= count; i++) {
                        NSString *item = [[directObjectDesc descriptorAtIndex:i] stringValue];
                        if (item) {
                            [resultFileNames addObject:item];
                        }
                    }
                }
                [replyDesc release];
            } else {
                fprintf(stderr, "see: Error occurred while sending AppleEvent: %d\n", (int)err);
                fflush(stderr);
            }
        }
    }
    
    return resultFileNames;
}


static void openFiles(NSArray *fileNames, NSDictionary *options) {
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL wait = [[options objectForKey:@"wait"] boolValue];
    BOOL resume = [[options objectForKey:@"resume"] boolValue];
    NSMutableDictionary *mutatedOptions = [[options mutableCopy] autorelease];
    NSUInteger i = 0;
    NSUInteger count = 0;
	
	NSRunningApplication *frontmostApplication = [[NSWorkspace sharedWorkspace] frontmostApplication];
	
    BOOL isStandardInputATTY = isatty([[NSFileHandle fileHandleWithStandardInput] fileDescriptor]);
    BOOL isStandardOutputATTY = isatty([[NSFileHandle fileHandleWithStandardOutput] fileDescriptor]);
    if (!isStandardOutputATTY) {
        [mutatedOptions setObject:@YES forKey:@"wait"];
        [mutatedOptions setObject:@YES forKey:@"pipe-out"];
        wait = YES;
    }
    
    //
    // Read from stdin when no file names have been specified
    //
    
    NSString *stdinFileName = nil;
    NSMutableArray *files = [NSMutableArray array];
    NSMutableArray *newFileNames = [NSMutableArray array];
    
    if ([fileNames count] == 0 || !isStandardInputATTY) {
        NSURL *url = tempFileURL();
        NSString *fileName = [url path];
        [fileManager createFileAtPath:fileName contents:[NSData data] attributes:nil];
        NSFileHandle *fdout = [NSFileHandle fileHandleForWritingAtPath:fileName];
        NSFileHandle *fdin = [NSFileHandle fileHandleWithStandardInput];
        unsigned length = 0;
        while (TRUE) {
            NSData *data = [fdin readDataOfLength:1024];
            length += [data length];
            if ([data length] != 0) {
                [fdout writeData:data];
            } else {
                break;
            }
        }
        [fdout closeFile];
        
        if (length == 0) {
            (void)[fileManager removeItemAtPath:stdinFileName error:nil];
        } else {
            stdinFileName = fileName;
        }
    }
    
    if ([fileNames count] != 0) {
        BOOL isDir;
        count = [fileNames count];
        for (i = 0; i < count; i++) {
            NSString *fileName = [fileNames objectAtIndex:i];
            if ([fileManager fileExistsAtPath:fileName isDirectory:&isDir]) {
                if (isDir) {
                	if ([[fileName pathExtension] caseInsensitiveCompare:@"seetext"] == NSOrderedSame) {
						[files addObject:fileName];
                	} else {
						//fprintf(stdout, "\"%s\" is a directory.\n", fileName);
						//fflush(stdout);
					}
                } else {
                    NSError *error;
                    NSString *destination;
                    NSDictionary *attributes = [fileManager attributesOfItemAtPath:fileName error:&error];
                    if ([attributes[NSFileType] isEqualToString:NSFileTypeSymbolicLink]) {
                        if ((destination = [fileManager destinationOfSymbolicLinkAtPath:fileName error:&error])) {
                            [files addObject:destination.isAbsolutePath ? destination : [[fileName stringByDeletingLastPathComponent] stringByAppendingPathComponent:destination]];
                        }
                    } else {
                        [files addObject:fileName];
                    }
                }
            } else {
                [newFileNames addObject:fileName];
            }
        }
    }
    
	
    NSArray *resultFileNames = see(files, newFileNames, stdinFileName, mutatedOptions);
	
    //
    // Bring terminal to front when wait and resume was specified
    //
    
    if (resume || wait) {
		[frontmostApplication activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    }
	
	
    //
    // Write files to stdout when it isn't a terminal
    //
    
    if (!isStandardOutputATTY) {
        count = [resultFileNames count];
        NSFileHandle *fdout = [NSFileHandle fileHandleWithStandardOutput];
        for (i = 0; i < count; i++) {
            NSString *path = [resultFileNames objectAtIndex:i];
            NSFileHandle *fdin = [NSFileHandle fileHandleForReadingAtPath:path];
            while (TRUE) {
                NSData *data = [fdin readDataOfLength:1024];
                if ([data length] != 0) {
                    [fdout writeData:data];
                } else {
                    break;
                }
            }
            [fdin closeFile];
            (void)[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
    }
    
    
    if (stdinFileName) {
        (void)[[NSFileManager defaultManager] removeItemAtPath:stdinFileName error:nil];
    }
}


int main (int argc, const char * argv[]) {
	
    @autoreleasepool {
#ifdef CONFIGURATION_Debug
		// sleep long enough for lldb to attach to us
		[NSThread sleepForTimeInterval:0.1];
#endif
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSMutableDictionary *options = [NSMutableDictionary dictionary];
		BOOL launch = NO;
		BOOL version = NO;
		BOOL help = NO;
		NSMutableArray *fileNames = [NSMutableArray array];
		int i;
		
		
		//
		// Parsing arguments
		//
		
		int ch;
		while ((ch = getopt_long(argc, (char * const *)argv, "bhlprvwe:m:o:dt:j:g:", longopts, NULL)) != -1) {
			switch(ch) {
				case 'b':
					[options setObject:@YES forKey:@"background"];
					break;
				case 'd':
					[options setObject:@YES forKey:@"pipe-dirty"];
					break;
				case 'h':
					help = YES;
					break;
				case 'v':
					version = YES;
					break;
				case 'w':
					[options setObject:@YES forKey:@"wait"];
					break;
				case 'r':
					[options setObject:@YES forKey:@"resume"];
					break;
				case 'l':
					launch = YES;
					break;
				case 'p':
					[options setObject:@YES forKey:@"print"];
					break;
				case 'e': {
                    // argument is a IANA charset name, convert using CFStringConvertIANACharSetNameToEncoding()
                    NSString *encoding = [NSString stringWithUTF8String:optarg];
                    [options setObject:encoding forKey:@"encoding"];
                } break;
				case 'g': {
                    // argument is a goto string of the form line[:column]
                    NSString *gotoString = [NSString stringWithUTF8String:optarg];
                    [options setObject:gotoString forKey:@"goto"];
                } break;
				case 'm': {
                    // identifies mode via BundleIdentifier, e.g. SEEMode.Objective-C ("SEEMode." is optional)
                    NSString *mode = [NSString stringWithUTF8String:optarg];
                    [options setObject:mode forKey:@"mode"];
                } break;
				case 'o': {
                    NSString *openin = [NSString stringWithUTF8String:optarg];
                    [options setObject:openin forKey:@"open-in"];
                } break;
				case 't': {
                    NSString *pipeTitle = [NSString stringWithUTF8String:optarg];
                    [options setObject:pipeTitle forKey:@"pipe-title"];
                } break;
				case 'j': {
                    NSString *jobDesc = [NSString stringWithUTF8String:optarg];
                    [options setObject:jobDesc forKey:@"job-description"];
                } break;
				case ':': // missing option argument
				case '?': // invalid option
				default:
					help = YES;
			}
		}
				
		//
		// Parsing filename arguments
		//
		
		argc -= optind;
		argv += optind;
		
		for (i = 0; i < argc; i++) {
			NSString *fileName = [NSString stringWithUTF8String:argv[i]];
			if (!fileName.isAbsolutePath) {
				fileName = [[fileManager currentDirectoryPath] stringByAppendingPathComponent:fileName];
			}
			
			if (fileName) {
				//NSLog(@"fileName after realpath: %@", fileName);
				[fileNames addObject:fileName.stringByStandardizingPath];
			} else {
				launch = YES;
				//NSLog(@"Error occurred while resolving path: %s", argv[i]);
			}
		}
        
		//
		// Executing command
		//
		
		if (help) {
			printHelp();
		} else if (version) {
			printVersion();
		} else if (launch && ([fileNames count] == 0)) {
			(void)launchSubEthaEdit(options);
		} else {
			openFiles(fileNames, options);
		}
        
	}
    return 0;
}
