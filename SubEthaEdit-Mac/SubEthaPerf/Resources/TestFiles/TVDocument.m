#import "TVApplication.h"
#import "TVDocument.h"
#import "TVDocumentShowSettings.h"
#import "TVShowController.h"
#import "TVDocumentSettingsController.h"
#import "TVRenderingEngine.h"
#import "TVDeviceManager.h"
#import "TVErrorController.h"
#import "BXProgressController.h"

// layers
#import "TVProtocol.h"
#import "TVVideoLayer.h"
#import "TVVideoLayerSetting.h"
#import "TVAudioLayer.h"
#import "TVAudioLayerSetting.h"
#import "TVLayerEntryBackgroundView.h"
#import "TVLayerEntryViewController.h"
#import "TVLayerContainerView.h"

// sources
#import "TVDeviceVideoSource.h"
#import "TVFilterTemplateRepository.h"

// audio
#import "TVAudioGraph.h"
#import "BXVUMeterView.h"

// windows, views & cells
#import "TVSaveAsTemplateController.h"
#import "TVPreviewPanelController.h"
#import "TVDebugWindowController.h"
#import "TVFullscreenWindow.h"
#import "TVCompositionParameterView.h"
#import "TVPreviewsGradientView.h"
#import "TVToolbarView.h"
#import "TVAppDelegate.h"
#import "TVLicenseController.h"
#import "TVDisclosureGroupButton.h"
#import "TVOpenGLView.h"
#import "iMovieScroller.h"
#import "TVLayerTemplate.h"
#import "TVLayerTemplateFilterViewController.h"
#import "TVSourceRepositoryViewController.h"
#import "BXActionButton.h"
#import "BXPushOnOffButton.h"
#import "BXImageBackgroundView.h"
#import "BXPerformanceMeterView.h"
#import "TVBigTimerLCDView.h"
#import "TVShowProgressView.h"
#import "TVPreviewPanel.h"
#import "TVMemoryUsageMemStringView.h"

// streaming
#import "TVStreamEndpoint.h"
#import "TVStreamDiskEndpoint.h"
#import "TVStreamTransmitter.h"

// protocols
#import "BXFullscreenProtocol.h"

// misc
#import "TVSourceRepository.h"
#import "TVFileRepository.h"
#import "TVDocumentDeviceManager.h"
#import "TVPostProductionController.h"
#import "TVPerformanceController.h"
#import "TVDefaultsController.h"
#import "TVDocumentController.h"
#import "TVMoviePresetUtilities.h"
#import "TVPrefsFullscreen.h"
#import "TVError.h"
#import "BXHotkey.h"
#import "NSImageAdditions.h"
#import "NGSCategories.h"
#import "BalloonController.h"
#import <BXServices/QLPreviewPanel.h>
#import <Sparkle/SUUpdater.h>


#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
#include "pthread.h"
#endif

// for the preview image size of templates
#define  MAX_PREVIEW_WIDTH 380.0
#define  MAX_PREVIEW_HEIGHT 230.0

// strings, later to be localized

#define AlertQuitWhileRecordingTitle @"BoinxTV is currently recording."
#define AlertQuitWhileRecordingDescription @"You cannot quit while BoinxTV is recording a show. Continue finish recording your show and then quit.\n\nAbort and Quit will immediately quit BoinxTV. Please note that this will render the currently running recording unusable."
#define AlertQuitWhileRecordingContinueButtonTitle @"Continue"
#define AlertQuitWhileRecordingSaveAndQuitButtonTitle @"Save and Quit"
#define AlertQuitWhileRecordingQuitImmediateButtonTitle @"Abort and Quit"

#define AlertCloseWhileRecordingDescription @"You cannot close the document while BoinxTV is recording a show. Continue finish recording your show and then close the document.\n\nAbort and Close will continue closing your document. Please note that this will render the currently running recording unusable."
#define AlertCloseWhileRecordingSaveAndCloseButtonTitle @"Save and Close"
#define AlertCloseWhileRecordingQuitImmediateButtonTitle @"Abort and Close"

#define BUNDLE [NSBundle mainBundle]

static inline NSString * IntelGMAAlertTitle()
{
	return NSLocalizedStringWithDefaultValue(
											 @"IntelGMAAlertTitle",
											 @"Document",
											 BUNDLE,
											 @"Slow Graphics Processor Found.",
											 @"alert title shown on document open/create when an Intel GMA is found");
}


static inline NSString * IntelGMAAlertMessage()
{
	return NSLocalizedStringWithDefaultValue(
											 @"IntelGMAAlertMessage",
											 @"Document",
											 BUNDLE,
											 @"BoinxTV cannot work properly because the onboard graphics subsystem of your computer is too slow. This computer is not supported by BoinxTV.\n\nYou can continue and set up this document, but you should not use this computer for recording or broadcasting.",
											 @"alert message shown on document open/create when an Intel GMA is found");
}


static inline NSString * IntelGMAAlertOKButton()
{
	return NSLocalizedStringWithDefaultValue(
											 @"IntelGMAAlertOKButton",
											 @"Document",
											 BUNDLE,
											 @"Continue",
											 @"button title");
}


static inline NSString * NVIDIA9400AlertTitle()
{
	return NSLocalizedStringWithDefaultValue(
											 @"NVIDIA9400AlertTitle",
											 @"Document",
											 BUNDLE,
											 @"Running On Slow Graphics Processor.",
											 @"alert title shown on document open/create when both a NVIDIA 9400 and 9600 GPU are found");
}


static inline NSString * NVIDIA9400AlertMessage()
{
	return NSLocalizedStringWithDefaultValue(
											 @"NVIDIA9400AlertMessage",
											 @"Document",
											 BUNDLE,
											 @"BoinxTV needs a fast graphics processor for optimum performance. Your computer has two graphics processors, a slower and a faster one. Unfortunately the slow one is currently selected in the System Preferences.\n\nYou may continue and accept bad performance, but is strongly recommended that your switch to the faster processor.\n\nChoose \"Switch Now...\". In the window that will open select the \"Higher performance\" setting next to the label \"Graphics\".",
											 @"alert message shown on document open/create when both a NVIDIA 9400 and 9600 GPU are found");
}


static inline NSString * NVIDIA9400AlertOKButton()
{
	return NSLocalizedStringWithDefaultValue(
											 @"NVIDIA9400AlertOKButton",
											 @"Document",
											 BUNDLE,
											 @"Continue",
											 @"button title");
}

 
static inline NSString * NVIDIA9400AlertSwitchButton()
{
	return NSLocalizedStringWithDefaultValue(
											 @"NVIDIA9400AlertSwitchButton",
											 @"Document",
											 BUNDLE,
											 @"Switch Now...",
											 @"button title");
}


void * TVDocumentObservingContextLayerSelection = (void *)2093;
void * TVDocumentObservingContextQueryResults = (void *)2094;
void * TVDocumentObservingContextSelectedLayerTrigger = (void *)2095;
void * TVDocumentObservingContextSelectedSettingTriggerHotKey = (void *)2096;
void * TVDocumentObservingContextSelectedSetting = (void *)3123;
void * TVDocumentObservingContextSelectedSettingName = (void *)9813;
void * TVDocumentObservingContextSelectedSettingIsActive = (void *)9815;
void * TVDocumentObservingContextLayerLiveStatus = (void *)9814;
void * TVDocumentObservingContextShowIsRolling = (void *)9816;
void * TVDocumentObservingContextShowInEndTimerOffset = (void *)9817;
void * TVDocumentObservingContextShowHasEndTimerOffset = (void *)9818;
void * TVDocumentObservingContextEngineIsPaused = (void *)9819;
void * TVDocumentObservingContextDocumentSizePopUpIndexChanged = (void *)9820;

extern void * LayersObservationContext;

NSString * const TVDocumentWillCloseNotification = @"TVDocumentWillCloseNotification";

static NSString * TVDocumentAudioGraphPropertyListKey = @"com.boinxtv.document.audiograph";

extern NSString * TVLayerContainerViewLayersBindingName;

NSString * const TVApplicationCreatorCode = @"BXTV";
NSString * const TVDocumentTypeShowOSCode = @"Show";
NSString * const TVDocumentTypeShow = @"com.boinx.boinxtv.show";
NSString * const TVDocumentPropertyList = @"Document.plist";
static const float kDocumentFormatVersion = 1.011f;		// significant to three decimal places

// picking good values for these will stop the document loading progress bar from slowing
//	down or speeding up too much when we learn how many layers and sources there are to load
static const double kLayersEstimate = 5.0;		// must be at least 1 per document
static const double kSourcesEstimate = 10.0;	// there are always 6 default sources anyway

const CGFloat minPropertyColumnWidth = 310.0;
const CGFloat minLayersColumnWidth   = 689.0;
const CGFloat minPreviewColumnWidth  = 120.0 + 12.0;
static const CGFloat kPreviewColumnWidthMargin = 13.0;

NSString * const SupportFolderLayersPathComponent = @"Application Support/Boinx/BoinxTV/Layers";
NSString * const AppBundleLayersPathComponent = @"Compositions";

CFStringRef const kUTTypeQuartzComposition = CFSTR("com.apple.quartz-composer-composition");


@implementation NSSegmentedControl (DomAdditions)

- (void)deselectAll 
{
	int count = [self segmentCount];
	while (count-- > 0)
	{
		[self setSelected:NO forSegment:count];
	}
}

- (void)selectExactlyThisSegment:(NSInteger)inSegmentIndex;
{
	[self deselectAll];
	if (inSegmentIndex != NSNotFound && inSegmentIndex >= 0)
	{
		[self setSelected:YES forSegment:inSegmentIndex];
	}
}

- (int)indexOfSegmentWithTag:(int)inTag 
{
	NSSegmentedCell *cell=self.cell;
	int segment = [self segmentCount];
	while (segment--) 
	{
		if ([cell tagForSegment:segment] == inTag)
		{
			return segment;
		}
	}
	return -1;
}

@end


@interface TVDocument ()

@property (nonatomic, assign) NSUInteger documentSizePopUpIndex;

@property (nonatomic, retain, readwrite) NSPanel *outputAudioSettingsPanel;

@property (readwrite, retain) id <TVStreamEndpoint> fileEndpoint;
@property (readwrite, retain) NSMutableArray *recordedMovies;
@property BOOL hasNonUndoableChange;

@property (nonatomic, retain) NSDate *recordingDate;

- (void)_installCodecList;
- (void)relayoutPropertyColumn;
- (void)_adjustBackgroundInsetToScroller:(NSNotification*)inNotification;

// document saving
- (NSDictionary *)dictionaryRepresentationOfDocumentState;

// rendering engine control
- (void)startRenderingEngine;
- (void)stopRenderingEngine;
- (void)startNeededDisplayThreads;
- (void)stopDisplayThreads;
- (void)recalibrateWithSize:(NSSize)size;

// KVO & bindings
- (void)registerKVO;
- (void)unregisterKVO;
- (BOOL)sourcesVisible;
- (void)validateUIRecordingState;
- (void)validateTriggerEventUI;
- (void)validateCurrentSettingsControl;
- (void)validateStatusLine;
- (void)validatePropertiesBackground;
- (void)validateGPU;

// undo support
- (void)setCodecValue:(NSNumber *)value;

// windowing & fullscreen
- (void)resizeColumnViews;
- (void)updateWidthAndHeightFields;
- (void)startFullscreen;
- (void)stopFullscreen;

// timer callbacks
- (void)updateShowTime:(NSTimer *)timer;
- (void)updatePerformanceMeter:(NSTimer *)timer;
- (void)updateVUMeter:(NSTimer *)timer;
- (void)updateDiscSpace:(NSTimer *)timer;
- (void)updateFreeMemory:(NSTimer *)timer;

// general
- (void)renderOutputInThread;
- (void)renderPreviewInThread;
- (void)changeVideoSize:(id)sender;
- (void)setCompressionCodec:(id)sender;
- (void)performSetRepositoryVisibility:(NSNumber *)inNumber;

// sheets & panels
- (BOOL)displayAlertDocument:(NSString *)filePath savedByFutureVersion:(NSString *)applicationVersion;
- (void)saveAsTemplateSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;

// extended demo
- (void)_installOrRemoveBuyNowView:(BOOL)install;
@end

#pragma mark -

@implementation TVDocument

@synthesize hasNonUndoableChange = _hasNonUndoableChange;

@synthesize outputPreview;
@synthesize renderingEngine = _renderingEngine;
@synthesize showController = _showController;
@synthesize videoSize = _videoSize;

@synthesize layers = _layers;
@synthesize layersController = _layersController;
@synthesize layersManipulationLock = _layersManipulationLock;
@synthesize layerTemplateRepository = _layerTemplateRepository;
@synthesize filterTemplateRepository = _filterTemplateRepository;
@synthesize deviceManager = _deviceManager;
@synthesize sourceRepository = _sourceRepository;
@synthesize sourceRepositoryViewController = _sourceRepositoryViewController;
@synthesize fullscreenWindow = _fullscreenWindow;
@synthesize fullscreenOpenGLView = _fullscreenGLView;

@synthesize fileRepository = _fileRepository;
@synthesize fileEndpoint = _fileEndpoint;
@synthesize recordedMovies = _recordedMovies;

@synthesize postprocessing = _postprocessing;
@synthesize postProductionController = _postProductionController;

@synthesize savingTemplate = _savingTemplate;
@synthesize metadata = _metadata;
@synthesize templateMetadata = _templateMetadata;
@synthesize exportSettings = _exportSettings;
@synthesize filename = _filename;
@synthesize templateURL = _templateURL;

@synthesize audioMixer = _audioMixer;
@synthesize currentParameterView = _currentParameterView;
@synthesize actionSafeAreaEnabled = _actionSafeAreaEnabled;
@synthesize titleSafeAreaEnabled = _titleSafeAreaEnabled;
@synthesize layerPanelOpen = _previewPanelOpen;
@synthesize outputPanelOpen = _outputPanelOpen;
@synthesize layerPanelThreadShouldStop = _previewPanelThreadShouldStop;
@synthesize outputPanelThreadShouldStop = _outputPanelThreadShouldStop;
@synthesize layerPreviewContext = _layerPreviewContext;
@synthesize outputPreviewContext = _outputPreviewContext;
@synthesize panelController = _ibPanelController;

@synthesize debugPerformanceChart = _debugPerformanceChart;
@synthesize debugWindowController = _debugWindowController;

@synthesize volatileStateFromRead = _volatileStateFromRead;
@synthesize showSettings = _showSettings;
@synthesize resizeError = _resizeError;

@synthesize playthroughDevices = _playthroughDevices;
@synthesize playthroughDevice = _playthroughDevice;

@synthesize hasWarnings = _hasWarnings;
@synthesize windowIsMain = _windowIsMain;

@synthesize isLicensed = _isLicensed;
@synthesize licenseAllowsRecording = _licenseAllowsRecording;
@synthesize licenseAllowsPreviews = _licenseAllowsPreviews;
@synthesize licenseAllowsFullscreen = _licenseAllowsFullscreen;
@synthesize licenseIsSponsoredVersion = _licenseIsSponsoredVersion;

@synthesize outputPreviewStatusString = _outputPreviewStatusString;
@synthesize outputAudioSettingsPanel = _outputAudioSettingsPanel;

@synthesize documentSizePopUpIndex = _documentSizePopUpIndex;

@synthesize recordingDate = _recordingDate;

// this initializer is only being called by the alternate "New Empty Document" menu entry in the file menu
// and newly on Lion when the system tries to restore a not yet saved document, possibly after a crash.
// We rather want to prevent having a wonky document and don't restore here.
// "New Empty Document" has therefor be removed as it was always a debug only option.
- (id)init
{
    return nil;
}


- (id)initWithContentsOfURL:(NSURL *)inAbsoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
	NSParameterAssert(outError != nil);
	
	// this is hacky and needs to change somehow - imho best way would be to defer the actualy creation of size dependent stuff when loading the UI - dom
	NSString *plistPath = [[inAbsoluteURL path] stringByAppendingPathComponent:TVDocumentPropertyList];
	NSDictionary *plistDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	NSDictionary *sizeDictionary = [plistDictionary valueForKeyPath:@"documentState.renderingVideoSize"];
	
	NSSize customSize = NSMakeSize(640,480);

	if (sizeDictionary && [sizeDictionary isKindOfClass:[NSDictionary class]])
	{
		NSNumber *pixelDimension = nil;
		pixelDimension = [sizeDictionary valueForKey:@"pixelWidth"];
		if ([pixelDimension respondsToSelector:@selector(floatValue)])
		{
			customSize.width = [pixelDimension floatValue];
		}
		pixelDimension = [sizeDictionary valueForKey:@"pixelHeight"];
		if ([pixelDimension respondsToSelector:@selector(floatValue)])
		{
			customSize.height = [pixelDimension floatValue];
		}
	}
	
	if (customSize.width == 0 || customSize.height == 0)
	{
		customSize = NSMakeSize(640, 480);
	}
	
	if (customSize.width < 320)
	{
		float ratio = customSize.height / customSize.width;
		customSize.width = 320;
		customSize.height = ceilf(customSize.width * ratio);
	}
	
	self = [self initWithSize:customSize];
	if (!self) {
		// TODO: generate Error
		return nil;
	}
	
	if (![self readFromURL:inAbsoluteURL ofType:typeName error:outError])
	{
		return nil;
	}
	
	[self setFileURL:inAbsoluteURL];
	[self setFileType:typeName];
	[self setFileModificationDate:[self fileModificationDate]];
	
	BXTracker *const tracker = BXTracker.sharedTracker;
	[tracker trackPageview:TVTrackPageDocument withError:nil];
	
	return self;
}


- (id)initWithSize:(NSSize)inSize
{
	self = [super init];
	if (!self) return nil;
	
//	[self disableUndoRegistration];
	
	// set show duration (in seconds)
	_firstFire = YES;
	_performanceMeterTimer = [[NSTimer timerWithTimeInterval:0.5 target:self selector:@selector(updatePerformanceMeter:) userInfo:nil repeats:YES] retain];
	_vuMeterTimer = [[NSTimer timerWithTimeInterval:1.0/30.0 target:self selector:@selector(updateVUMeter:) userInfo:nil repeats:YES] retain];
	_updateFreeMemoryTimer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateFreeMemory:) userInfo:nil repeats:YES] retain];
	_undoLock = [[NSRecursiveLock alloc] init];
	[_undoLock setName:@"undo lock"];
	
	// videoSize from HandyCam is a 720x576 px pixel buffer in k2vuyPixelFormat
	_videoSize = inSize;
	_actionSafeAreaEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowActionSafeArea"];
	_titleSafeAreaEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowTitleSafeArea"];
	
	// steps for the progress bar
	double steps = 26.0 + kLayersEstimate + kSourcesEstimate;	// 26 == number of occurences of -incrementProgressWithText:
	[[BXProgressController sharedController] setMaximumProgress:steps];
	
	_layers = [[NSMutableArray alloc] init];
	_layersManipulationLock = [[NSRecursiveLock alloc] init];
	[_layersManipulationLock setName:[NSString stringWithFormat:@"layersMainpulationLock of %@", [self description]]];
	self.recordedMovies = [[[NSMutableArray alloc] init] autorelease];
	_metadata = [[NSMutableDictionary alloc] init];
	_templateMetadata = [[NSMutableDictionary alloc] init];
	_exportSettings = [[NSMutableDictionary alloc] init];

	[[BXProgressController sharedController] incrementProgressWithText:@"Initializing show settings..."];
	_layersController = [[NSArrayController alloc] initWithContent:self.layers];
	[_layersController setPreservesSelection:YES];
	[_layersController setSelectsInsertedObjects:YES];
	self.showSettings = [[[TVDocumentShowSettings alloc] initWithDictionary:nil televisionDocument:self] autorelease];
	
    // assign a new mixer
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating audio mixer..."];
    self.audioMixer = [[[TVAudioGraph alloc] initWithOutputDeviceID:nil televisionDocument:self] autorelease];
    [self.audioMixer setOutputVolume:1.0];
    [self.audioMixer setPlaythroughVolume:0.0];
	
	// create the file endpoint for recording to disk (fileEndpoint is KVC observed)
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating file endpoint..."];
	self.fileEndpoint = [TVStreamDiskEndpoint sharedEndpoint];
	
	// file repository
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating file repository..."];
	_fileRepository = [[TVFileRepository alloc] initWithTelevisionDocument:self];
	// set the media path for relativeness
	NSString *mediaFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"MediaFolderLocation"];
	if (mediaFolder) 
	{
		[_fileRepository setMediaFolderURL:[NSURL fileURLWithPath:mediaFolder]];
	}
	
	// initalise templates and sources
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating device manager..."];
	_deviceManager = [[TVDocumentDeviceManager alloc] init];
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating layer repository..."];
	_layerTemplateRepository = [[TVLayerTemplateRepository alloc] initWithTelevisionDocument:self];
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating filter repository..."];
	_filterTemplateRepository = [[TVFilterTemplateRepository alloc] initWithTelevisionDocument:self];
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating source repository..."];
	_sourceRepository = [[TVSourceRepository alloc] initWithTelevisionDocument:self];
	[_sourceRepository setDelegate:self];
	
	// create context for compositions
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating rendering engine..."];
	_renderingEngine = [[TVRenderingEngine alloc] initWithTelevisionDocument:self];
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Initalizing OpenGL..."];
	[self createOpenGLContext];
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating show controller..."];
	_showController = [[TVShowController alloc] initWithTelevisionDocument:self];
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Loading layer templates..."];
	[self loadLayerTemplates];
	
	// why are we using CTGradient here not NSGradient?
	_normalPropertyBackground = [[CTGradient gradientWithBeginningColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.4 alpha:1.0]
															endingColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.0 brightness:0.25 alpha:1.0]] retain];
	_livePropertyBackground = [[CTGradient gradientWithBeginningColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.1 brightness:0.35 alpha:1.0]
														  endingColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.4 brightness:0.30 alpha:1.0]] retain];
//	_livePropertyBackground = [[CTGradient gradientWithBeginningColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.8 brightness:0.7 alpha:1.0]
//														  endingColor:[NSColor colorWithCalibratedHue:0.0 saturation:0.99 brightness:0.55 alpha:1.0]] retain];
	
	// The PostProductionController has to be initialized
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating post-production controller..."];
	_postProductionController = [[TVPostProductionController alloc] initWithTelevisionDocument:self];
	_postprocessing = [[NSMutableSet alloc] init];
	
	[self registerForNotifications];

	return self;
}


- (void)resizeVideo:(NSValue *)newValue
{
	NSSize oldSize = _videoSize;
	NSValue *oldValue = [NSValue valueWithSize:oldSize];
	NSSize newSize = [newValue sizeValue];
	[self recalibrateWithSize:newSize];
	[(TVPreviewsGradientView *)[layerPreview superview] frameDidChange:nil];
	[(TVPreviewsGradientView *)[outputPreview superview] frameDidChange:nil];
	[self resizeColumnViews];
	[self validateUIRecordingState];
	[self validateStatusLine];
	[_ibPanelController recalibrateFromOldSize:oldSize toNewSize:newSize];
	[_ibPanelController updateWindowTitles];
	
	// fixes #1811: recalibrate fullscreen view
	[self.fullscreenWindow recalibrationWithSize:newSize];

	// fixes #1793: forces refresh
	[[_ibParameterViewEnclosingScrollView contentView] scrollToPoint:NSMakePoint(0.0, 1.0)];
	[[_ibParameterViewEnclosingScrollView contentView] scrollToPoint:NSMakePoint(0.0, 0.0)];
	
	[[self undoManager] registerUndoWithTarget:self selector:@selector(resizeVideo:) object:oldValue];
	[[self undoManager] setActionName:NSLocalizedString(@"UndoActionResizeVideo",nil)];
}


- (void)recalibrateWithSize:(NSSize)size
{
	[_renderingEngine pauseOutputRendering];
	[_renderingEngine pausePreviewRendering];
	
	while (!_renderingEngine.outputRenderingPaused && !_renderingEngine.previewRenderingPaused)
	{
		// wait until output is actually paused, in blocks of one 100th of a second
		
		// we have two choices here, we can either sleep, which is fast enough for the user to never really notice
		//	or we can run a run loop, which updates the UI (pause button) but might interfere with performAfterDelay: and similar
		usleep(1.0/100.0 * 1.0e+6);
	}
	usleep(1.0/10.0 * 1.0e+6); // additional sleep for at least 1/10 of a second to make sure we are in a good state
	
	
	// setting the size is being observed by all layers, which is schnging the preview layer, so we keep it here and set it again at the end of this method.
	id preview = _renderingEngine.preview;
	self.videoSize = size;
	[_renderingEngine recalibrateWithSize:size];
	
	
#if 0
	// this code needs to be enabled to easily/reliably trigger bug #1249
	// after that bug has been fixed, it can be deleted
	NSError *error = nil;
	NSMutableArray *dicts = [[NSMutableArray alloc] init];
	{
		[_layersManipulationLock lock];
		id <TVLayerProtocol> layer;
		for (layer in _layers)
			[dicts addObject:[layer dictionaryRepresentationAndError:&error]];
		NSUInteger oldCount = [_layers count];
		NSIndexSet *oldSelection = [[_layersController selectionIndexes] copy];
		[_layersManipulationLock unlock];
		
		for (NSDictionary *dictionaryRepresentation in dicts)
		{
			error = nil;
			layer = [_layerTemplateRepository layerWithDictionaryRepresentation:dictionaryRepresentation error:&error];
			if (layer)
			{
				[_layersController addObject:layer];
			}
		}
		
		[_layersController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndiciesInRange:NSMakeRange(0,oldCount)]];
		[_layersController setSelectionIndexes:oldSelection];
		[oldSelection release];
	}
	[dicts release];	
#endif
	
	CGLContextObj cgl_ctx = [_outputPreviewContext CGLContextObj];
	CGLLockContext(cgl_ctx);
	CGLSetCurrentContext(cgl_ctx);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0.0, size.width, 0.0, size.height, -1.0, 1.0);
	CGLUnlockContext(cgl_ctx);
	
	cgl_ctx = [_layerPreviewContext CGLContextObj];
	CGLLockContext(cgl_ctx);
	CGLSetCurrentContext(cgl_ctx);
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(0.0, size.width, 0.0, size.height, -1.0, 1.0);
	CGLUnlockContext(cgl_ctx);
	
	if(self.fullscreenOpenGLView)
	{
		cgl_ctx = [self.fullscreenOpenGLView.openGLContext CGLContextObj];
		CGLLockContext(cgl_ctx);
		CGLSetCurrentContext(cgl_ctx);
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0.0, size.width, 0.0, size.height, -1.0, 1.0);
		CGLUnlockContext(cgl_ctx);
	}
	
	_renderingEngine.preview = preview;	
	[_renderingEngine unpauseOutputRendering];
	[_renderingEngine unpausePreviewRendering];
	
}

- (void)dealloc
{
#if defined (CONFIGURATION_Debug)
	BXLog(@"%s", __FUNCTION__);
#endif
	[self cancelAllDelayedSelectors];
	
	_ibLayerPreviewContainerView = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	@synchronized (_renderingEngine)
	{
		BXRelease(_renderingEngine);
	}
	[_layersController setContent:nil];

	BXRelease(_metadata);
	BXRelease(_templateMetadata);
	BXRelease(_layerTableViews);
	BXRelease(_outputPreviewContext);
	BXRelease(_layerPreviewContext);
	BXRelease(_movieSourceTreeNodes);
	BXRelease(_imageSourceTreeNodes);
	BXRelease(_recordedMovies);
	BXRelease(_layersController);
	BXRelease(_layers);
	BXRelease(_layersManipulationLock);
	BXRelease(_audioMixer);
	BXRelease(_fullscreenPrefs);
	BXRelease(_fileRepository);
	BXRelease(_filterTemplateRepository);
	BXRelease(_layerTemplateRepository);
	BXRelease(_layerTemplateFilterViewController);
	BXRelease(_fullscreenWindow);
	BXRelease(_fullscreenGLView);
	BXRelease(_deviceManager);
	BXRelease(_sourceRepository);
	BXRelease(_debugWindowController);
	BXRelease(_postProductionController);
	BXRelease(_postprocessing);
	BXRelease(_showSettings);
	BXRelease(_volatileStateFromRead);
	BXRelease(_normalPropertyBackground);
	BXRelease(_livePropertyBackground);
	BXRelease(_exportSettings);
	BXRelease(_playthroughDevices);
	BXRelease(_outputPreviewStatusString);
	BXRelease(_originalDocumentPropertyList);
	BXRelease(_undoLock);
	
	[super dealloc];
}


- (NSString *)windowNibName
{
	return @"TVDocument";
}


- (void)_installCodecList
{
	NSMenu *submenu = [(TVAppDelegate *)[NSApp delegate] copyCodecSubmenu];
	[_ibRecordingFormatItem setSubmenu:submenu];
	[submenu release];
}


- (void)adjustUIToVolatileStateRead
{
	NSDictionary *volatileState = self.volatileStateFromRead;
	if (volatileState)
	{
		// window frames
		NSString *windowFrame = [volatileState valueForKeyPath:@"windowFrames.Main"];
		if (windowFrame)
		{
			// restore the saved frame only on the condition that it fits on an existing screen without overspill
			NSRect savedFrame = NSRectFromString(windowFrame);
			for (NSScreen *screen in [NSScreen screens])
			{
				NSRect screenFrame = [screen visibleFrame];
				NSRect largerScreenFrame = NSInsetRect(screenFrame, -10.0f, -10.0f); // add a few pixels on all sides, as users tend to be not that exact
				NSRect intersection = NSIntersectionRect(savedFrame, largerScreenFrame);
				if (NSEqualRects(savedFrame, intersection))
				{
					[ibMainWindow setFrame:NSIntersectionRect(savedFrame,screenFrame) display:NO];
					break;
				}
			}
		}
		
		// panels
		[_ibPanelController adjustUIToVolatileState:volatileState];
		
		// overlays - don't synchronise user defaults with these values
		self.actionSafeAreaEnabled = [[volatileState valueForKey:@"showActionSafeBounds"] boolValue];
		self.titleSafeAreaEnabled = [[volatileState valueForKey:@"showTitleSafeBounds"] boolValue];
		
		// expanded layers
		NSArray *expandedLayersArray = [volatileState valueForKey:@"expandedLayers"];
		if (expandedLayersArray) 
		{
			NSSet *expandedLayerIdentifiers = [NSSet setWithArray:expandedLayersArray];
			for (TVLayerEntryViewController *controller in [_ibLayerContainerView allEntryViewControllers])
			{
				NSString *expandedViewLayerIdentifier = [[controller representedObject] identifier];
				if (expandedViewLayerIdentifier && 
				   [expandedLayerIdentifiers containsObject:expandedViewLayerIdentifier])
				{
					[controller setExpandedState:YES];
				}
			}
		}
		
		// selected layer
		
		// repository
		NSNumber *repositoryVisiblity = [volatileState valueForKeyPath:@"repositoryVisiblity"];
		if (repositoryVisiblity)
		{
			// delay setting here
			[self performSelector:@selector(performSetRepositoryVisibility:) withObject:repositoryVisiblity afterDelay:0.0];
		}
		
		// restore fullscreen if screen setup matches
		if ([[TVLicenseController defaultLicenseController] allowsFullscreen])
		{
            NSNumber *fullscreen = [volatileState valueForKeyPath:@"fullscreenRunning"];
            if (fullscreen && [fullscreen boolValue])
			{
                NSArray *savedScreenFrames = [volatileState valueForKey:@"screenFrames"];
                if (savedScreenFrames)
                {
                    NSMutableArray *screenFrames = [NSMutableArray arrayWithCapacity:4];
                    NSArray *screens = [NSScreen screens];
                    // Only show fullscreen if the number of screen are more then 1
                    if(screens.count > 1)
                    {
                        for (NSScreen *screen in [NSScreen screens])
                        {
                            [screenFrames addObject:NSStringFromRect([screen frame])];
                        }
                        if ([savedScreenFrames isEqualToArray:screenFrames])
                        {
                            // go fullscreen
                            [self startFullscreen];
                        }
                    }
                }
			}
		}
	}
}


- (void)_adjustBackgroundInsetToScroller:(NSNotification*)inNotification
{
#pragma unused (inNotification)
    NSInteger rightInset = 15;
    if ([NSApp runningOnLionOrHigher])
    {
        if ([[NSScroller class] respondsToSelector:@selector(preferredScrollerStyle)])
        {
            // NSScrollerStyleOverlay = 1 only defined in 10.7 SDK
            if ((NSInteger)[[NSScroller class] performSelector:@selector(preferredScrollerStyle)] == 1)
            //if ([NSScroller preferredScrollerStyle] == 1)
            {
                rightInset = 0;
            }
        }
    }
	[_ibLayerListBackgroundView setRightInset:rightInset];
}


- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
	START_TIMING_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, windowcontroller);
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Setting up window..."];

 	[_ibMainDisclosureContainerView setFlipped:YES];
	[_ibPreviewDisclosureView setFlipped:YES];
	[_ibTriggerDisclosureView setFlipped:YES];
	[_ibParametersDisclosureView setFlipped:YES];
	[self _installCodecList];
	
	// make this the primary window
	[[[self windowControllers] objectAtIndex:0] setShouldCloseDocument:YES];
	
	// setting up the main window borders
	CGFloat minYEdgeThickness = 28.0;
	CGFloat maxYEdgeThickness = 55.0;
	[super windowControllerDidLoadNib:controller];
	NSWindow *window = [controller window];
	[window setAutorecalculatesContentBorderThickness:NO forEdge:NSMinYEdge];
	[window setAutorecalculatesContentBorderThickness:NO forEdge:NSMaxYEdge];
	[window setContentBorderThickness:minYEdgeThickness forEdge:NSMinYEdge];
	[window setContentBorderThickness:maxYEdgeThickness forEdge:NSMaxYEdge];
//	[window setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];

	NSView *contentView = [window contentView];
	NSRect progressRect = [_ibProgressBackgroundView frame];
	[(BXImageBackgroundView *)_ibProgressBackgroundView setBackgroundImageName:@"ProgressOverlayBackground"];
	NSRect windowBounds = [contentView bounds];
	progressRect.origin.x = ceilf((NSWidth(windowBounds) - NSWidth(progressRect)) / 2.0f);
	progressRect.origin.y = ceilf(windowBounds.origin.y + windowBounds.size.height / 3.0f);
	[_ibProgressBackgroundView setFrame:progressRect];
	
	[contentView addSubview:_ibProgressBackgroundView];
	if (_progressRetainCount != 0) 
	{
		[_ibProgressBackgroundView setHidden:NO];
		[_ibOverlayProgressIndicator startAnimation:nil];
	} 
	else
	{
		[_ibProgressBackgroundView setHidden:YES];
	}
	
	// toolbar
	_ibImageBackgroundView.backgroundImageName = @"MainLCDDisplayBackground";
	
	[_ibShowTimeLCDView setDrawBackground:NO];
	[_ibShowTimeLCDView setRedThreshold:0];
	[_ibShowTimeLCDView setPrecisionDigits:0];
	[_ibShowTimeLCDView setMinPositions:6];
	
	[_ibRecordButton setImage:                [NSImage imageNamed:@"ToolbarRecordButton_Off"]];
	[_ibRecordButton setPressedImage:         [NSImage imageNamed:@"ToolbarRecordButton_Off_Pressed"]];
	[_ibRecordButton setAlternateImage:       [NSImage imageNamed:@"ToolbarRecordButton_On"]];
	[_ibRecordButton setAlternatePressedImage:[NSImage imageNamed:@"ToolbarRecordButton_On_Pressed"]];
	
	[[_ibShowTimerEnabled cell] setTextColor:[NSColor whiteColor]];
	[[_ibShowTimerUpDown cell] setTextColor:[NSColor whiteColor]];
	[[_ibShowTimerTriggerEnabled cell] setTextColor:[NSColor whiteColor]];

	[_ibShowDurationDatePicker setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	[_ibShowEndTimerOffsetDatePicker setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

	[[[_ibPlaythroughActionButton pullDownMenu] itemWithTag:42] setState:([_audioMixer outputIsEnhanced] ? NSOnState : NSOffState)];

	// use German locale for nice date picking
	NSLocale *germanLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"];
	[_ibShowDurationDatePicker       setLocale:germanLocale];
	[_ibShowEndTimerOffsetDatePicker setLocale:germanLocale];
	[germanLocale release];
	
	// set the three columns to the correct sizes
	[self resizeColumnViews];
    [self _adjustBackgroundInsetToScroller:nil];

	[_ibLayerContainerView setInset:NSMakeSize(5,5)];
	
	[_ibPropertyShortcutButton setTitle:[_ibPropertyShortcutButton title]];
	[(id)[outputPreview superview] setBorderColor:nil];
	[(id)[outputPreview superview] setHorizontalAlignment:NSRightTextAlignment];
	
	// add all the column views to the main view and set up KVO & bindings
	[_ibMainContentView addSubview:_ibPropertyColumnView];
	[_ibMainContentView addSubview:_ibLayerListBackgroundView];
	[_ibMainContentView addSubview:_ibMainPreviewColumnView];
	[[_ibLayerContainerView window] setInitialFirstResponder:_ibLayerContainerView];
	[[_ibLayerContainerView window] makeFirstResponder:_ibLayerContainerView];
	[_ibLayerListBackgroundView configureWithBasename:@"LayerContainerBackground-"];
	[_ibLayerContainerView bind:@"layers"           toObject:self.layersController withKeyPath:@"arrangedObjects" options:nil];
	[_ibLayerContainerView bind:@"selectionIndexes" toObject:self.layersController withKeyPath:@"selectionIndexes" options:nil];
	[_ibLayerContainerView adjustToNewLayerSituation];
	
	// collapsing property column information
	[_ibLayerPreviewContainerView setMaxHeight:NSHeight(_ibLayerPreviewContainerView.frame)];
	[_ibTriggerContainerView      setMaxHeight:NSHeight(_ibTriggerContainerView.frame)];
	[_ibLayerPreviewContainerView setMinHeight:22.0];
	[_ibTriggerContainerView      setMinHeight:49.0];
	[_ibTriggerContainerView      setButton:_ibPropertyShortcutButton];
	[_ibLayerPreviewContainerView setButton:_ibLayerPreviewHeader];
	
	// trigger aspect correction in preview view
//	[self relayoutPropertyColumn];
//	[[layerPreview superview] performSelector:@selector(frameDidChange:) withObject:nil];

	// start the toolbar show time timer
	_showStartTime = [[NSDate date] timeIntervalSinceReferenceDate];
	[[NSRunLoop mainRunLoop] addTimer:_performanceMeterTimer forMode:NSRunLoopCommonModes];
	[[NSRunLoop mainRunLoop] addTimer:_vuMeterTimer forMode:NSRunLoopCommonModes];
	[[NSRunLoop mainRunLoop] addTimer:_updateFreeMemoryTimer forMode:NSRunLoopCommonModes];
	[_ibMainVolumeSlider setFloatValue:[self.audioMixer outputVolume]];
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Preparing layer repository..."];
	
	_layerTemplateFilterViewController = [[TVLayerTemplateFilterViewController alloc] initWithTVDocument:self];
	
	NSView *view = [_layerTemplateFilterViewController view];	// this is very slow
	NSRect frame = [_ibMainContentView frame];
	frame.size.height = 1;
	[view setFrame:frame];
	[view setHidden:YES];
	[[_ibMainContentView superview] addSubview:view];	
	
	_layerTemplateFilterViewController.layerTemplateArrayController = (TVCategoryFilteringArrayController *) _layerTemplateRepository.templatesController;

	[[BXProgressController sharedController] incrementProgressWithText:@"Preparing source repository..."];
	
	_sourceRepositoryViewController = [[TVSourceRepositoryViewController alloc] initWithTelevisionDocument:self];
    _sourceRepositoryViewController.sourcesArrayController =  _sourceRepository.sourcesController;
	
	view  = [_sourceRepositoryViewController view];
	frame = [_ibMainContentView frame];
	frame.size.height = 1;
	[view setFrame:frame];
	[view setHidden:YES];
	[[_ibMainContentView superview] addSubview:view];	


	[[BXProgressController sharedController] incrementProgressWithText:@"Preparing preview windows..."];
	
	// configure the NSOpenGLViews
	NSOpenGLPixelFormatAttribute attributes[] = {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFAMinimumPolicy,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFAWindow,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFAAllowOfflineRenderers,
	0 };
	NSOpenGLPixelFormat *pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];

	[outputPreview setPreview:NO];
	[outputPreview setPixelFormat:pixelFormat];
	[outputPreview setOpenGLContext:_outputPreviewContext];
	[outputPreview setDelegate:_renderingEngine];
	
	if (_renderingEngine.renderingEngineManager.rendererIDs.count <= 1 && !DISABLE_LAYER_BACKED_PREVIEW  && !ON_SNOW_LEOPARD_OR_HIGHER)
	{
		[layerPreview setWantsLayer:YES];
	}

	[layerPreview setPreview:YES];
	[layerPreview setPixelFormat:pixelFormat];
	[layerPreview setOpenGLContext:_layerPreviewContext];
	[layerPreview setDelegate:_renderingEngine];
	
	TVPreviewsGradientView *layerpreviewbackground = (TVPreviewsGradientView *)[layerPreview superview];
	[layerpreviewbackground setDrawsBorder:YES];
	
	NSView *hackView = [[NSView alloc] initWithFrame:NSMakeRect(0.,0.,1.,1.)];
	[hackView setWantsLayer:YES];
	[layerPreview addSubview:hackView];
	[hackView release];
	[pixelFormat release];
	
	// configure look of the LCD timer view
	CTGradient *lcdGradient = [CTGradient gradientWithBeginningColor:[NSColor colorWithDeviceRed:39.0/255.0 green:39.0/255.0 blue:39.0/255.0 alpha:1.0]
														 endingColor:[NSColor colorWithDeviceRed:23.0/255.0 green:23.0/255.0 blue:23.0/255.0 alpha:1.0]];
	lcdGradient = [lcdGradient addColorStop:[NSColor colorWithDeviceRed:60.0/255.0 green:60.0/255.0 blue:70.0/255.0 alpha:1.0] atPosition:0.50];
	lcdGradient = [lcdGradient addColorStop:[NSColor colorWithDeviceRed:33.0/255.0 green:33.0/255.0 blue:38.0/255.0 alpha:1.0] atPosition:0.50];
	[ibTimerView setBackgroundGradient:lcdGradient];
	[ibTimerView setBevelGradient:[CTGradient gradientWithBeginningColor:[NSColor colorWithDeviceRed:127.0/255.0 green:127.0/255.0 blue:127.0/255.0 alpha:0.0]
	                                                         endingColor:[NSColor colorWithDeviceRed:127.0/255.0 green:127.0/255.0 blue:127.0/255.0 alpha:0.0]]];
	[ibTimerView setBevelGradient:[CTGradient gradientWithBeginningColor:[NSColor colorWithDeviceRed:69.0/255.0 green:67.0/255.0 blue:69.0/255.0 alpha:0.5]
	                                                         endingColor:[NSColor colorWithDeviceRed:95.0/255.0 green:96.0/255.0 blue:97.0/255.0 alpha:0.5]]];
	[ibTimerView setFrameColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.0]];
	NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
	[shadow setShadowOffset:NSMakeSize(0.0,4.0)];
	[shadow setShadowBlurRadius:2.0];
	[ibTimerView setShadow:shadow];
	[ibTimerView setCornerRadius:2.0];
	
	_ibVirtualMemoryView.virtualMemoryDisplayOffset = [TVApp startupVirtualMemoryUsage]; 
	[_ibPerformanceMeter setup];
	
	[_ibLayerTriggerRecorder setAllowedFlags:ShortcutRecorderAllFlags];
	[_ibLayerTriggerRecorder setRequiredFlags:ShortcutRecorderEmptyFlags];
	[_ibLayerTriggerRecorder setCanCaptureGlobalHotKeys:YES];
	[_ibLayerTriggerRecorder setAllowsKeyOnly:YES escapeKeysRecord:NO];
	
	[_ibSettingTriggerHotKeyRecorder setAllowedFlags:ShortcutRecorderAllFlags];
	[_ibSettingTriggerHotKeyRecorder setRequiredFlags:ShortcutRecorderEmptyFlags];
	[_ibSettingTriggerHotKeyRecorder setCanCaptureGlobalHotKeys:YES];
	[_ibSettingTriggerHotKeyRecorder setAllowsKeyOnly:YES escapeKeysRecord:NO];
	
	//	[parameterView setDelegate:renderingEngine];
	
	// only for debugging, window needs to be loaded from nib before setting the performance controller's rendering engine
	_debugWindowController = [[TVDebugWindowController alloc] initWithWindowNibName:@"TVDocumentDebug"];
	[_debugWindowController setTelevisionDocument:self];
 	[[_debugWindowController window] setTitle:[self displayName]];
	[_renderingEngine.performance setRenderingEngine:_renderingEngine];
	
	[[controller window] center];
	
	[self.layersController setAutomaticallyRearrangesObjects:NO];
	[self registerKVO];
	[self.currentParameterView updateMediaMenus];
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Starting render engine..."];

	// defer starting of rendering engine - should be on some reasonable event, just a delay for now
	[self performSelector:@selector(startRenderingEngine) withObject:nil afterDelay:0.8];
	[self validateButtonStates];
	
	[self adjustUIToVolatileStateRead];
	
	[self licenseListDidChange:nil]; // update licensing status for correct behaviour
	
    // assign a new mixer
    [self rebuildDeviceMenu];
#if 0
	self.audioMixer = [[[TVAudioGraph alloc] initWithOutputDeviceID:self.playthroughDevice] autorelease];
#endif
	
	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, windowcontroller,@"COMPLETE");
}

- (BOOL)windowShouldClose:(id)window
{
	if (window == ibMainWindow)
	{
		if (self.showController.isRolling)
		{
			NSAlert *alert = [NSAlert alertWithMessageText:AlertQuitWhileRecordingTitle
											 defaultButton:AlertQuitWhileRecordingContinueButtonTitle
										   alternateButton:nil //AlertCloseWhileRecordingSaveAndCloseButtonTitle
											   otherButton:AlertCloseWhileRecordingQuitImmediateButtonTitle
								 informativeTextWithFormat:AlertCloseWhileRecordingDescription];
			[alert setAlertStyle:NSCriticalAlertStyle];
			NSInteger result = [alert runModal];
			
/*			if (result == NSAlertAlternateReturn)
			{
				SEL selector = @selector(performClose:);
				NSMethodSignature *signature = [[window class] instanceMethodSignatureForSelector:selector];
				NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
				[invocation setSelector:selector];
				[invocation setTarget:window];
				[invocation setArgument:self atIndex:2];
				
				self.postProductionController.sheetEnabled = NO;
				[self.showController forceStopRecordingWithInnvocation:[invocation autorelease]];  // in order to close after recording is finished we need to rewirite saveMove to not show export sheet
				return NO;
			}
			else
*/			if (result == NSAlertOtherReturn)
			{
				return YES;
			}
			else
			{
				return NO;
			}
		}
		else
		{
			return YES;
		}
	}
	return YES;
}


- (void)terminate:(id)inSender
{
	if (self.showController.isRolling)
	{
		NSAlert *alert = [NSAlert alertWithMessageText:AlertQuitWhileRecordingTitle
										 defaultButton:AlertQuitWhileRecordingContinueButtonTitle
									   alternateButton:nil //AlertQuitWhileRecordingSaveAndQuitButtonTitle
										   otherButton:AlertQuitWhileRecordingQuitImmediateButtonTitle
							 informativeTextWithFormat:AlertQuitWhileRecordingDescription];
		[alert setAlertStyle:NSCriticalAlertStyle];
		NSInteger result = [alert runModal];
		
/*		if (result == NSAlertAlternateReturn)
		{
			SEL selector = @selector(terminate:);
			NSMethodSignature *signature = [[NSApp class] instanceMethodSignatureForSelector:selector];
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
			[invocation setSelector:selector];
			[invocation setTarget:NSApp];
			[invocation setArgument:inSender atIndex:2];
			
			self.postProductionController.sheetEnabled = NO;
			[self.showController forceStopRecordingWithInnvocation:[invocation autorelease]]; // in order to quit after recording is finished we need to rewirite saveMove to not show export sheet
		}
		else
*/		if (result == NSAlertOtherReturn)
		{
			[NSApp terminate:inSender];
		}
		else
		{
			return;
		}
	}
	else
	{
		[NSApp terminate:inSender];
	}
}


- (void)startRenderingEngine
{
	if (_renderingEngine)
	{
		if (!_renderingEngine.isRunning || ((!_renderingEngine.outputRenderingIsRunning) && (!_renderingEngine.previewRenderingIsRunning)))
		{
			// start rendering engine
			[NSThread detachNewThreadSelector:@selector(startPreviewRendering) toTarget:self.renderingEngine withObject:nil];
			while (!_renderingEngine.previewRenderingIsRunning)
			{
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
			}
			
			[NSThread detachNewThreadSelector:@selector(startOutputRendering) toTarget:self.renderingEngine withObject:nil];
			while (!_renderingEngine.outputRenderingIsRunning)
			{
				[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
			}
			[self startNeededDisplayThreads];
		}
	}
}


- (void)startNeededDisplayThreads
{
	if (_renderingEngine)
	{
		if (_renderingEngine.outputRenderingIsRunning)
		{
			[NSThread detachNewThreadSelector:@selector(renderOutputInThread) toTarget:self withObject:nil];
		}
		if (_renderingEngine.previewRenderingIsRunning)
		{
			[NSThread detachNewThreadSelector:@selector(renderPreviewInThread) toTarget:self withObject:nil];
		}
	}
}

- (IBAction)toggleRenderingPause:(id)inSender
{
#pragma unused (inSender)
	TVRenderingEngine *engine = self.renderingEngine;
	BOOL wasPaused = [engine outputRenderingPaused];
	if (wasPaused)
	{
		[engine unpauseOutputRendering];
		[engine unpausePreviewRendering];
	}
	else
	{
		[engine pauseOutputRendering];
		[engine pausePreviewRendering];
	}
}

- (IBAction)debugPauseUnpauseOutputRendering:(id)inSender
{
	[self.renderingEngine pauseUnpauseOutputRendering:inSender];
}


- (IBAction)debugPauseUnpausePreviewRendering:(id)inSender
{
	[self.renderingEngine pauseUnpausePreviewRendering:inSender];
}


- (IBAction)debugLogMixerInformation:(id)inSender
{
	#pragma unused (inSender)
	[self.audioMixer logInformation];
}

- (IBAction)debugToggleFixedFrameRate:(id)inSender
{
	#pragma unused (inSender)
	self.renderingEngine.fixedRecordingFrameRate = !(self.renderingEngine.fixedRecordingFrameRate);
}

- (void)stopRenderingEngine
{
	if (_renderingEngine.outputRenderingIsRunning)
	{
		[_renderingEngine stopOutputRendering];
	}
	if (_renderingEngine.previewRenderingIsRunning)
	{
		[_renderingEngine stopPreviewRendering];
	}
	
	while(_renderingEngine.outputRenderingIsRunning || _renderingEngine.previewRenderingIsRunning) // waiting for rendering to be really stopped
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		
		for (TVVideoSource *videoSource in [self.sourceRepository allVideoSources])
		{
			if ([videoSource respondsToSelector:@selector(updateSignal)])
			{
				[videoSource performSelector:@selector(updateSignal)];
			}
		}
		BXLogInDomain(kLogDomainRendering, kLogLevelDebug, @"Waiting for rendering engine to stop. Output:%d, Preview:%d", _renderingEngine.outputRenderingIsRunning, _renderingEngine.previewRenderingIsRunning);
	}
}


- (void)stopDisplayThreads
{
	// first unpause both threads so we do actually can safely exit our threads
	[self.renderingEngine unpauseOutputRendering];
	[self.renderingEngine unpausePreviewRendering];

	// stop all display threads
	if (_fullscreenThreadIsRunning)
	{
		_fullscreenThreadShouldStop = YES;
	}
	if (_outputPanelThreadIsRunning)
	{
		_outputPanelThreadShouldStop = YES;
	}
	if (_outputThreadIsRunning)
	{
		_outputThreadShouldStop = YES;
	}
	if (_previewThreadIsRunning)
	{
		_previewThreadShouldStop = YES;
	}
	if (_previewPanelThreadIsRunning)
	{
		_previewPanelThreadShouldStop = YES;
	}
	
	while(_fullscreenThreadIsRunning || _outputPanelThreadIsRunning || _outputThreadIsRunning || _previewThreadIsRunning || _previewPanelThreadIsRunning) // waiting for threads to be really stopped
	{
		[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
		BXLogInDomain(kLogDomainRendering, kLogLevelDebug, @"Waiting for display threads to stop.");
	}	
}

#pragma mark
#pragma mark KVO & Messaging

- (void)registerForNotifications
{
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(licenseListDidChange:) name:BXLicenseListDidChangeNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(fieldEditorDidBeginEditing:) name:NSTextDidBeginEditingNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(fieldEditorDidEndEditing:) name:NSTextDidEndEditingNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(rendererDidChange:) name:TVRenderingEngineVirtualScreenDidChangeNotification object:self.renderingEngine];
    if ([NSApp runningOnLionOrHigher])
    {
        [notificationCenter addObserver:self selector:@selector(_adjustBackgroundInsetToScroller:) name:@"NSPreferredScrollerStyleDidChangeNotification" object:nil];
        // should not be a string costant but NSPreferredScrollerStyleDidChangeNotification, but this does not exist on 10.6 SDK
    }
}


- (void)registerKVO
{
//	[self.layersController addObserver:_renderingEngine forKeyPath:@"selection.settingsController.selectedObjects" options:NSKeyValueObservingOptionInitial context:NULL];
	[self.layersController addObserver:self forKeyPath:@"selection.settingsController.selectionIndexes" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextSelectedSetting];
	[self.layersController addObserver:self forKeyPath:@"selection.settingsController.selection.name" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextSelectedSettingName];
	[self.layersController addObserver:self forKeyPath:@"selection.settingsController.selection.isActiveSetting" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextSelectedSettingIsActive];
	[self.layersController addObserver:self forKeyPath:@"selection.settingsController.selection.isLiveSetting" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextSelectedSettingIsActive];
	[self.layersController addObserver:self forKeyPath:@"selection.settingsController.selection.triggerHotKey" options:0 context:TVDocumentObservingContextSelectedSettingTriggerHotKey];
	[self.layersController addObserver:self forKeyPath:@"selection.trigger" options:0 context:TVDocumentObservingContextSelectedLayerTrigger];
	[self.layersController addObserver:self forKeyPath:@"selection" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextLayerSelection];
	[self.layersController addObserver:self forKeyPath:@"arrangedObjects.active" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextLayerLiveStatus];
	
	[self.showSettings addObserver:self forKeyPath:@"hasShowEndTimerOffset" options:0 context:TVDocumentObservingContextShowHasEndTimerOffset];
	[self.showSettings addObserver:self forKeyPath:@"recordsMovie" options:0 context:TVDocumentObservingContextShowIsRolling];
	[self.showSettings addObserver:self forKeyPath:@"recordsFullscreen" options:0 context:TVDocumentObservingContextShowIsRolling];
//	[self.showSettings addObserver:self forKeyPath:@"recordsStream" options:0 context:TVDocumentObservingContextShowIsRolling];
	[self.showController addObserver:self forKeyPath:@"isRolling" options:NSKeyValueObservingOptionInitial context:TVDocumentObservingContextShowIsRolling];
	[self.showController addObserver:self forKeyPath:@"isInShowEndTimerOffset" options:0 context:TVDocumentObservingContextShowInEndTimerOffset];
	
	[self.renderingEngine addObserver:self forKeyPath:@"outputRenderingPaused" options:0 context:TVDocumentObservingContextShowIsRolling];
}


- (void)unregisterKVO
{
//	[self.layersController removeObserver:_renderingEngine forKeyPath:@"selection.settingsController.selectedObjects"];
	[self.layersController removeObserver:self forKeyPath:@"selection.settingsController.selectionIndexes"];
	[self.layersController removeObserver:self forKeyPath:@"selection.settingsController.selection.name"];
	[self.layersController removeObserver:self forKeyPath:@"selection.settingsController.selection.isActiveSetting"];
	[self.layersController removeObserver:self forKeyPath:@"selection.settingsController.selection.isLiveSetting"];
	[self.layersController removeObserver:self forKeyPath:@"selection.settingsController.selection.triggerHotKey"];
	[self.layersController removeObserver:self forKeyPath:@"selection.trigger"];
	[self.layersController removeObserver:self forKeyPath:@"selection"];
	[self.layersController removeObserver:self forKeyPath:@"arrangedObjects.active"];
	
	[self.showSettings removeObserver:self forKeyPath:@"hasShowEndTimerOffset"];
	[self.showSettings removeObserver:self forKeyPath:@"recordsMovie"];
	[self.showSettings removeObserver:self forKeyPath:@"recordsFullscreen"];
//	[self.showSettings removeObserver:self forKeyPath:@"recordsStream"];
	[self.showController removeObserver:self forKeyPath:@"isRolling"];
	[self.showController removeObserver:self forKeyPath:@"isInShowEndTimerOffset"];
	
	[self.renderingEngine removeObserver:self forKeyPath:@"outputRenderingPaused"];
}


- (void)rendererDidChange:(NSNotification *)inNotification
{
	#pragma unused (inNotification)
	[self validateStatusLine];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (! [NSThread isMainThread])
	{
		// observeValueForKeyPath dispached to the main thread to avoid AppKit crashes...
		BXLogInDomain(kLogDomainMisc, kLogLevelDebug, @"dispaching %s to main thread", __FUNCTION__);
		SEL selector = @selector(observeValueForKeyPath:ofObject:change:context:);
		NSMethodSignature *signature = [self methodSignatureForSelector:selector];
		NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
		[invocation setSelector:selector];
		[invocation setArgument:&keyPath atIndex:2];
		[invocation setArgument:&object atIndex:3];
		[invocation setArgument:&change atIndex:4];
		[invocation retainArguments];
		[invocation setArgument:&context atIndex:5];
		[invocation performSelectorOnMainThread:@selector(invokeWithTarget:) withObject:self waitUntilDone:NO];
		return;
	}
	
	// update the shortcut recorder control
	if (context == TVDocumentObservingContextSelectedLayerTrigger)
	{
		KeyCombo keyCombo = SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags);
		BXHotkey *hotkey = [object valueForKeyPath:keyPath];
		if (hotkey)	keyCombo = SRMakeKeyCombo([hotkey keyCode], [hotkey modifierFlags]);
		[_ibLayerTriggerRecorder updateWithKeyCombo:keyCombo];
	}
	
	else if (context == TVDocumentObservingContextSelectedSettingTriggerHotKey)
	{
		KeyCombo keyCombo = SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags);
		BXHotkey *hotkey = [object valueForKeyPath:keyPath];
		if (hotkey)	keyCombo = SRMakeKeyCombo([hotkey keyCode], [hotkey modifierFlags]);
		[_ibSettingTriggerHotKeyRecorder updateWithKeyCombo:keyCombo];
	}
	
	// update composition and movie source lists
/*	else if (context == TVDocumentObservingContextQueryResults)
	{
		[self updateQueryResults:object];
	}
*/	
	else if (context == TVDocumentObservingContextSelectedSetting)
	{
		[self selectedSettingDidChange];
	}
	else if (context == TVDocumentObservingContextSelectedSettingName)
	{
		[self validateCurrentSettingsControl];
	}
	else if (context == TVDocumentObservingContextLayerLiveStatus)
	{
		[self validateStatusLine];
	}
	else if (context == TVDocumentObservingContextSelectedSettingIsActive)
	{
		[self validatePropertiesBackground];
	}
	else if (context == TVDocumentObservingContextLayerSelection)
	{
		// layer selection change
		// swap the parameter views
		[self selectedLayerDidChange];
	}
	else if (context == TVDocumentObservingContextShowIsRolling)
	{
		if (!_documentIsClosing)
		{
			[_showTimer invalidate];
			BXRelease(_showTimer);
			_showTimer = [[NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(updateShowTime:) userInfo:nil repeats:YES] retain];
			[[NSRunLoop mainRunLoop] addTimer:_showTimer forMode:NSRunLoopCommonModes];
			
			[_updateFreeSpaceTimer invalidate];
			BXRelease(_updateFreeSpaceTimer);
			[self updateDiscSpace:nil];
			_updateFreeSpaceTimer = [[NSTimer timerWithTimeInterval:60.0 target:self selector:@selector(updateDiscSpace:) userInfo:nil repeats:YES] retain];
			[[NSRunLoop mainRunLoop] addTimer:_updateFreeSpaceTimer forMode:NSRunLoopCommonModes];
			
			
			[self validateUIRecordingState];
		}
	} 
	else if (context == TVDocumentObservingContextShowInEndTimerOffset)
	{
		[self validateUIRecordingState];
	}
	else if (context == TVDocumentObservingContextShowHasEndTimerOffset)
	{
		[self validateTriggerEventUI];
	}
	else if (context == TVDocumentObservingContextDocumentSizePopUpIndexChanged)
	{
		[self updateWidthAndHeightFields];
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}


#pragma mark
#pragma mark Loading & Saving

- (void)setFileURL:(NSURL *)inURL
{
	if ([inURL isEqualTo:self.fileURL]) 
	{
		// calling super anyways because it might have other effects
		[super setFileURL:inURL];
	}
	else
	{
		NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
		[center postNotificationName:@"TVDocumentWillChangeFileURLNotificaiton" object:self];
		[super setFileURL:inURL];
		[center postNotificationName:@"TVDocumentDidChangeFileURLNotificaiton" object:self];
	}
}

- (void)updateChangeCountWithNonUndoableChange
{
	self.hasNonUndoableChange = YES;
	[self updateChangeCount:NSChangeDone];
	for (NSWindowController *windowController in [self windowControllers])
	{
		[windowController setDocumentEdited:YES];
	}
}

/*!	@method		undoManager
	@abstract	Overrides super's implementation
	We now manage our own enabling and disabling of undo registration, because NSUndoManager's implementation of -enableUndoRegistration not only enables registration, but also closes the current open undo group, a behaviour we don't want. I tried opening a new undo group  when calling -disableUndoRegistration, but then the event-based undo groups created automatically were not getting closed, leaving open undo groups when we return to the event loop. By returning nil for the document's undo manager when undo disable counter is greater tan zero, we can ensure that all undo registrations are sent to nil.
	This REQUIRES that users call [document undoManager] immediatly before trying to use it, and not earlier in the method, in case an intervening call disables registration.
*/
- (NSUndoManager *)undoManager
{
	if (_undoDisableState == 0)
		return [super undoManager];
	return nil;
}

/*!	@method		disableUndoRegistration
	@abstract	Call this instead of [[document undoManager] disableUndoRegistration]
	Always disable/enable undo registration via these methods, to avoid threading issues.
	We use a lock to block the current thread until the other thread calls -enableUndoRegistration and releases this lock. this prevents sequences like: disable, disable, enable, enable
	This is called from background threads and the main thread, so we use a lock to ensure that they don't trample on one another.
	Work done between calls to -disableUndoRegistration and -enableUndoRegistration should be as short as possible, so that the lock is not held for longer than necessary and blocks other threads from doing work.
*/
- (void)disableUndoRegistration
{
	[_undoLock lock];
	_undoDisableState++;
	BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"undos disabled (at level %i); current undo grouping level = %i", _undoDisableState, [[super undoManager] groupingLevel]);
	return;
}

- (void)enableUndoRegistration
{
	if (_undoDisableState != 0)
	{
		_undoDisableState--;
	}
	else
	{
		BXLogInDomain(kLogDomainUndo, kLogLevelWarning, @"Attempt to enabled undos when they were already enabled.");
	}
	BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"undos  enabled (at level %i); current undo grouping level = %i", _undoDisableState, [[super undoManager] groupingLevel]);
	[_undoLock unlock];
	return;
}

- (BOOL)isDocumentEdited
{
	return ([super isDocumentEdited] || self.hasNonUndoableChange);
}

- (void)updateChangeCount:(NSDocumentChangeType)inChange
{
	if (inChange == NSChangeCleared) 
	{
		self.hasNonUndoableChange = NO;
	}
	[super updateChangeCount:inChange];
}

- (void)updateHasWarnings 
{
	for (TVSource *source in self.sourceRepository.sourcesController.content) 
	{
		if (source.hasWarning)
		{
			self.hasWarnings = YES;
			return;
		}
	}
	self.hasWarnings = NO;
}


- (BOOL)readFromURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName error:(NSError **)outError
{
#pragma unused (inTypeName)

	START_TIMING_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url);
	
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"---- LOADING FROM URL (%@) ----", [inAbsoluteURL absoluteString]);
	[[BXProgressController sharedController] incrementProgressWithText:@"Checking document format..."];
	
	if (outError)
	{
		*outError = nil;
	}
	[self disableUndoRegistration];

	// read Format.plist and check if we can read the rest of the document
	
	NSString *bundlePath = [inAbsoluteURL path];
	NSString *formatPath = [bundlePath stringByAppendingPathComponent:@"Format.plist"];
	NSDictionary *formatDictionary = [NSDictionary dictionaryWithContentsOfFile:formatPath];
	if (formatDictionary)
	{
		float documentFormatVersion = [[formatDictionary objectForKey:@"TVDocumentFormatVersion"] floatValue];
		if (floorf(documentFormatVersion) > floorf(kDocumentFormatVersion))
		{
			// document has a newer major version number than we support, abort opening
			[[BXProgressController sharedController] endProgressSheet];
			NSString *filename = [[NSFileManager defaultManager] displayNameAtPath:bundlePath];
			NSString *applicationVersion = [formatDictionary objectForKey:@"TVApplicationVersion"];
			NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTable(@"DocumentMajorVersionNewerDescription", @"Errors", nil), filename, applicationVersion];
			NSString *suggestion = NSLocalizedStringFromTable(@"DocumentMajorVersionNewerRecoverySuggestion", @"Errors", nil);
			NSArray *buttons = [NSArray arrayWithObjects:
				NSLocalizedStringFromTable(@"DocumentMajorVersionNewerRecoveryOptionCancel", @"Errors", nil),
				NSLocalizedStringFromTable(@"DocumentMajorVersionNewerRecoveryOptionUpdate", @"Errors", nil),
				nil];
			NSError *error = [NSError errorWithDomain:BoinxTVErrorDomain code:documentMajorVersionTooHigh userInfo:
				[NSDictionary dictionaryWithObjectsAndKeys:
					description, NSLocalizedDescriptionKey,
					suggestion, NSLocalizedRecoverySuggestionErrorKey,
					buttons, NSLocalizedRecoveryOptionsErrorKey,
					bundlePath, NSFilePathErrorKey,
					nil]];
			NSAlert *alert = [NSAlert alertWithError:error];
			NSInteger returnCode = [alert runModal];	// this runs modally because (a) we don't have a document yet, and (b) there is already a sheet open on the Template Chooser window
			switch (returnCode)
			{
				case NSAlertFirstButtonReturn:
					// abort
					break;
				case NSAlertSecondButtonReturn:
				{
					// software update
					Class SoftwareUpdater = NSClassFromString(@"SUUpdater");
					[[SoftwareUpdater sharedUpdater] checkForUpdates:self];
					break;
				}
				default:
					// unexpected return code received, log it and abort
					BXLog(@"unexpected return code %d received from -[NSAlert runModal] for error %@", returnCode, error);
					break;
			}
			return NO;
		}
		else if (documentFormatVersion > kDocumentFormatVersion)
		{
			// document has a newer minor version number than we support, ask the user if they want to try anyway, go to software update, or abort
			NSString *applicationVersion = [formatDictionary objectForKey:@"TVApplicationVersion"];
			BOOL continueLoading = [self displayAlertDocument:bundlePath savedByFutureVersion:applicationVersion];
			if (!continueLoading)
			{
				[[BXProgressController sharedController] endProgressSheet];
				return NO;
			}
		}
#ifndef CONFIGURATION_Debug
		else if (documentFormatVersion < kDocumentFormatVersion)
		{
			// document has an older version number than the current build. do nothing in this case, we should be able to read it fine.
		}
		else
		{
			// doucment format is the same as the current build, check for app revision number.
			//	this catches cases where the we forget to increment the document version number when its format changes.
			unsigned int applicationRevision = [[NSApp bundleVersionAsNumber] unsignedIntValue];
			unsigned int documentRevision = [[formatDictionary objectForKey:@"TVApplicationRevision"] unsignedIntValue];
			if (documentRevision > applicationRevision)
			{
				NSString *applicationVersion = [formatDictionary objectForKey:@"TVApplicationVersion"];
				BOOL continueLoading = [self displayAlertDocument:bundlePath savedByFutureVersion:applicationVersion];
				if (!continueLoading)
				{
					[[BXProgressController sharedController] endProgressSheet];
					return NO;
				}
			}
		}
#endif
	}
	else
	{
		BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"format dictionary of file could not be found - trying to continue anyway\n\texpected Format.plist path: %@", formatPath);
	}
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Loading document..."];

	// now that the format is clear, begin loading
	NSString *documentPlistPath = [bundlePath stringByAppendingPathComponent:TVDocumentPropertyList];
	NSDictionary *documentDictionary = [NSDictionary dictionaryWithContentsOfFile:documentPlistPath];
	if (!documentDictionary)
	{
		if (outError)
		{
			*outError = [NSError errorWithDomain:BoinxTVErrorDomain code:plistLoadFailed userInfo:
				[NSDictionary dictionaryWithObject:documentPlistPath forKey:NSFilePathErrorKey]];
		}
		[[BXProgressController sharedController] endProgressSheet];
		return NO;
	}
	
	// preserve the whole (immutable) dictionary so that we can save out unknown keys
	_originalDocumentPropertyList = [documentDictionary retain];
	
	// now that we have the document dictionary, update the maximum steps for the progress bar
	double progress = [[BXProgressController sharedController] progress];
	double steps = [[BXProgressController sharedController] maximumProgress];
	double fraction = progress / steps;
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"progress == %.0f out of %.0f (%.2f%%); estimated remaining steps: %.0f", progress, steps, progress/steps*100, steps - progress);
	steps += [(NSArray *)[_originalDocumentPropertyList objectForKey:@"layers"] count];
	steps += [(NSArray *)[_originalDocumentPropertyList objectForKey:@"sources"] count];
	steps += [TVSourceRepository appBundleStockMediaCount];
	steps -= kLayersEstimate + kSourcesEstimate;
	double remainingSteps = steps - progress;
	steps = ceil(remainingSteps / (1.0 - fraction));
	progress = steps - remainingSteps;
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"progress == %.0f out of %.0f (%.2f%%); actual remaining steps: %.0f", progress, steps, progress/steps*100, remainingSteps);
	[[BXProgressController sharedController] setProgress:progress];
	[[BXProgressController sharedController] setMaximumProgress:steps];
	
	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" document.plist read");

	NSMutableDictionary *metadataDictionary = [[[documentDictionary objectForKey:@"documentMetadata"] mutableCopy] autorelease];
	if (metadataDictionary)
	{
		// merge in the metadata written in the file
		[self.metadata addEntriesFromDictionary:metadataDictionary];
		NSImage *thumbnailImage = [[[NSImage alloc] initWithData:[metadataDictionary objectForKey:@"image"]] autorelease];
		if ([metadataDictionary objectForKey:@"image"] != nil && thumbnailImage != nil) {
			[self.metadata setObject:thumbnailImage forKey:@"image"];
		}
	}
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Restoring document state..."];

	NSDictionary *documentState = [documentDictionary objectForKey:@"documentState"];
	if (documentState)
	{
		NSMutableDictionary *exportSettings = [[[documentState objectForKey:@"exportSettings"] mutableCopy] autorelease];
		if (exportSettings)
		{
			// merge in the Metadata written in the file
			[self.exportSettings addEntriesFromDictionary:exportSettings];
		}
		
		NSMutableDictionary *showSettingsDict = [documentState objectForKey:@"showSettings"];
		if (showSettingsDict)
		{
			self.showSettings = [[[TVDocumentShowSettings alloc] initWithDictionary:showSettingsDict televisionDocument:self] autorelease];
		}
		
		NSNumber *number = nil;
        NSString *deviceUID = [documentState objectForKey:@"playThroughDeviceUID"];
        BOOL playThroughDeviceisMuted = [[documentState objectForKey:@"playThroughDeviceisMuted"] boolValue];
        [self rebuildDeviceMenu];
        if (deviceUID && [self.playthroughDevices containsObject:deviceUID])
        {
            self.playthroughDevice = deviceUID;
            [self.audioMixer setPlaythroughVolume:playThroughDeviceisMuted ? 1.0 : 0.0];
            [self.audioMixer connectToOutputDeviceWithID:self.playthroughDevice];
        }
        // needs to be after the output device is connected or it doesn't get set properly
		number = [documentState objectForKey:@"masterOutputAudioVolume"];
		if (number) [self.audioMixer setValue:number forKey:@"outputVolume"];
		number = [documentState objectForKey:@"playThroughAudioVolume"];
		if (number) [self.audioMixer setValue:number forKey:@"playthroughVolume"];
	}

	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @" ---- LOADING REPOSITORY INFORMATION ----");
	
	[[BXProgressController sharedController] incrementProgressWithText:@"Loading audio setup"];
	[self.audioMixer updateWithPropertyListRepresentation:[documentDictionary objectForKey:TVDocumentAudioGraphPropertyListKey]];

	[[BXProgressController sharedController] incrementProgressWithText:@"Loading document media..."];

	// loading repositories
	if (![self.fileRepository addFileReferencesFromPropertyList:[documentDictionary objectForKey:@"fileReferences"] originalDocumentURL:inAbsoluteURL error:outError])
	{
		BXLogInDomain(kLogDomainLoading, kLogLevelError, @"%s loading of file repository failed",__FUNCTION__);
		[[BXProgressController sharedController] endProgressSheet];
		return NO;
	}

	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" read file references");
	
	if (![self.filterTemplateRepository addCompositionTemplatesFromPropertyList:[documentDictionary objectForKey:@"filterTemplates"] originalDocumentURL:inAbsoluteURL error:outError])
	{
		BXLogInDomain(kLogDomainLoading, kLogLevelError, @"%s loading of filterTemplateRepository failed",__FUNCTION__);
		[[BXProgressController sharedController] endProgressSheet];
		return NO;
	}
	
	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" read filter templates");

	if (![self.layerTemplateRepository addCompositionTemplatesFromPropertyList:[documentDictionary objectForKey:@"layerTemplates"] originalDocumentURL:inAbsoluteURL error:outError])
	{
		BXLogInDomain(kLogDomainLoading, kLogLevelError, @"%s loading of layerTemplateRepository failed",__FUNCTION__);
		[[BXProgressController sharedController] endProgressSheet];
		return NO;
	}

	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" read composition templates");
	
	if (![self.sourceRepository addSourcesFromPropertyList:[documentDictionary objectForKey:@"sources"] error:outError])
	{
		BXLogInDomain(kLogDomainLoading, kLogLevelError, @"%s loading of sourceRepository failed",__FUNCTION__);
		[[BXProgressController sharedController] endProgressSheet];
		return NO;
	}
	
	// automatically create sources for all connected devices
	BOOL automaticDeviceSources = [[[NSUserDefaults standardUserDefaults] objectForKey:@"AutomaticDeviceSources"] boolValue];
	if (automaticDeviceSources && [documentDictionary objectForKey:@"templateMetadata"] != nil)
	{
		[self.sourceRepository addDefaultDeviceSources];
	}
	
	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" read sources");

	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"---- LOADING LAYERS ----");

	[[BXProgressController sharedController] setProgressText:@"Loading layers..."];

	// turn off observation of selected layer before adding all the layers
	[_renderingEngine unregisterKVO];
	
	// now after the repositories let us load the layers
	NSArray *layersArray = [documentDictionary objectForKey:@"layers"];
	NSAutoreleasePool *localPool = nil;
	for (NSDictionary *layerDict in layersArray)
	{
		[localPool drain];
		localPool = [[NSAutoreleasePool alloc] init];

		BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"Layer ID: %@", [layerDict objectForKey:@"layerTemplateIdentifier"]);
		id layer = [self.layerTemplateRepository layerWithDictionaryRepresentation:layerDict error:outError];
		if (layer) 
		{
			NSMutableDictionary *dictionary = [[[NSMutableDictionary alloc] init] autorelease];
			[dictionary setObject:[NSArray arrayWithObject:layer] forKey:@"layers"];
			[dictionary setObject:[NSIndexSet indexSetWithIndex:[(NSArray *)[self.layersController arrangedObjects] count]] forKey:@"indicies"];
			[self insertLayers:dictionary];
		}
		else
		{
			BXLogInDomain(kLogDomainLoading, kLogLevelWarning, @"layer with representation did not get instanciated: %@",layerDict);
		}
		[[BXProgressController sharedController] incrementProgress];
	}
	[localPool drain];
	localPool = nil;

	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" read layers");
	
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @"---- LOADING VOLATILE STATE ----");

	[[BXProgressController sharedController] setProgressText:@"Loading volatile state..."];

	// read all volatile state that can be set already
	NSDictionary *volatileState = [documentDictionary objectForKey:@"volatileState"];
	if (volatileState)
	{
		id selectedLayer = nil;
		NSString *selectedLayerIdentifier = [volatileState objectForKey:@"selectedLayer"];
		NSSet *selectedSettingsIdentifiers = [NSSet setWithArray:[volatileState objectForKey:@"selectedSettings"]];
		
		for (id layer in self.layersController.arrangedObjects)
		{
			[localPool drain];
			localPool = [[NSAutoreleasePool alloc] init];
			if ([selectedLayerIdentifier isEqualToString:[layer identifier]])
			{
				selectedLayer = [layer retain];
			}
			
			NSArrayController *settingsController = [layer settingsController];
			for (id setting in [settingsController arrangedObjects])
			{
				if ([selectedSettingsIdentifiers containsObject:[setting identifier]])
				{
					[settingsController setSelectedObjects:[NSArray arrayWithObject:setting]];
					break;
				}
			}
			[selectedLayer release];
			selectedLayer = nil;
		}
		[localPool drain];
		localPool = nil;
		
		if (selectedLayer)
		{
			[self.layersController setSelectedObjects:[NSArray arrayWithObject:selectedLayer]];
		}
		[selectedLayer release];
		selectedLayer = nil;
		
		if ([volatileState objectForKey:@"recordedMovies"] != nil &&
			[[volatileState objectForKey:@"recordedMovies"] isKindOfClass:[NSArray class]])
		{
			self.recordedMovies = [[[volatileState objectForKey:@"recordedMovies"] mutableCopy] autorelease];
		}
		// record the rest for the end of the window loading code
		self.volatileStateFromRead = volatileState;
		
	}
	[localPool drain];
	localPool = nil;
		
	[self enableUndoRegistration];
	
	// restore observation of selected layer
	[_renderingEngine registerKVO];
	
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @" %@", self.filterTemplateRepository.description);
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @" %@", self.layerTemplateRepository.description);
	BXLogInDomain(kLogDomainLoading, kLogLevelDebug, @" ---- LOADING DONE ----");

	[self updateHasWarnings];
	
	REPORT_LAP_TIME_WITH_LOG_DOMAIN_AND_LEVEL(kLogDomainLoading, kLogLevelDebug, read_from_url,@" COMPLETE - read volatile state");
	
	return YES;
}


- (void)makeWindowControllers
{
	[[BXProgressController sharedController] incrementProgressWithText:@"Creating Window..."];
	[super makeWindowControllers];
}


- (void)addWindowController:(NSWindowController *)windowController
{
	[[BXProgressController sharedController] incrementProgressWithText:@"Adding Window..."];
	[super addWindowController:windowController];
}


- (void)showWindows
{
	[[BXProgressController sharedController] incrementProgressWithText:@"Showing Window..."];

	[super showWindows];

	[self performSelector:@selector(validateGPU) withObject:nil afterDelay:0.5];
//	[self validateGPU];
}


- (BOOL)writeQuickLookFilesToPath:(NSString *)inPath error:(NSError **)outError
{
	// create QuickLook directory
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *quicklookDirectory = [inPath stringByAppendingPathComponent:@"QuickLook"];
	if (![fm createDirectoryAtPath:quicklookDirectory withIntermediateDirectories:YES attributes:nil error:outError])
	{
		return NO;
	}

	// save Thumbnail.png (smaller representation, used for finder icon and coverflow)
	BOOL didSaveThumbnail = NO;

	NSImage *thumbnailImage = _preview;
	if (thumbnailImage)
	{
		NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithData:[thumbnailImage TIFFRepresentation]] autorelease];
		if (bitmapRep)
		{
			NSData *thumbnailData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
			if (thumbnailData)
			{
				NSString *thumbnailPath = [quicklookDirectory stringByAppendingPathComponent:@"Thumbnail.png"];
				if (![thumbnailData writeToFile:thumbnailPath options:0 error:outError])
				{
					return NO;
				}
				didSaveThumbnail = YES;
			}
			else
			{
				BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"failed to convert bitmap representation of thumbnail image %@ to NSData", thumbnailImage);
			}
		}
		else
		{
			BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"failed to create bitmap representation of thumbnail image %@", thumbnailImage);
		}
	}
	else
	{
		BXLogInDomain(kLogDomainSaving, kLogLevelDebug, @"no metadata.preview available for use as thumbnail, copying Preview.png to Thumbnail.png");
	}
	
	// save Preview.png (full document, used for quicklook)
	NSImage *previewImage = [_ibLayerContainerView contentImageWithBounds:[_ibLayerContainerView contentBounds] alpha:1.0];
	if (previewImage)
	{
		NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithData:[previewImage TIFFRepresentation]] autorelease];
		if (bitmapRep)
		{
			NSData *previewData = [bitmapRep representationUsingType:NSPNGFileType properties:nil];
			if (previewData)
			{
				if (!didSaveThumbnail)		// no thumbnail saved yet
				{
//					NSString *thumbnailPath = [quicklookDirectory stringByAppendingPathComponent:@"Thumbnail.png"];
//					if (![previewData writeToFile:thumbnailPath options:0 error:outError])
//					{
//						BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"failed to write quicklook thumbnail because %@", [*outError localizedDescription]);
//						return NO;
//					}
				}
				
				NSString *previewPath = [quicklookDirectory stringByAppendingPathComponent:@"Preview.png"];
				if (![previewData writeToFile:previewPath options:0 error:outError])
				{
					if (outError)
					{
						BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"failed to write quicklook preview because %@", [*outError localizedDescription]);
					}
					else
					{
						BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"failed to write quicklook preview");
					}

				}
			}
			else
			{
				BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"could not generate quicklook PNG representation of %@", bitmapRep);
			}
		}
		else
		{
			BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"failed to create bitmap representation of image %@", previewImage);
		}
	}
	else
	{
		BXLogInDomain(kLogDomainSaving, kLogLevelWarning, @"layer container view returned nil content image when trying to create quicklook files");
	}

	return YES;
}

- (BOOL)writeBasicBundleToPath:(NSString *)inPath error:(NSError **)outError
{
	if (outError) *outError = nil;
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSString *contentsPath = [inPath stringByAppendingPathComponent:@"Contents"];
	
	// make sure directory exists
	if (![fm fileExistsAtPath:inPath])
	{
		if (![fm createDirectoryAtPath:contentsPath withIntermediateDirectories:YES attributes:nil error:outError])
		{
			return NO;
		}
	}
	else
	{
		// probably never happens
		return NO;
	}
	
	// generate package contents and Info.plist
	NSString *version = [NSApp shortVersionString];
	NSString *savedWith = [NSString stringWithFormat:NSLocalizedString(@"SavedWithVersion", nil), version];
	NSString *infoPlistPath = [contentsPath stringByAppendingPathComponent:@"Info.plist"];
	NSDictionary *infoPlist = [NSDictionary dictionaryWithObjectsAndKeys:
		@"6.0",                   @"CFBundleInfoDictionaryVersion",
		TVDocumentTypeShowOSCode, @"CFBundlePackageType",
		version,                  @"CFBundleShortVersionString",
		savedWith,                @"CFBundleGetInfoString",
		nil];
	if (![infoPlist writeToFile:infoPlistPath atomically:NO])
	{
		// TODO: create error
		return NO;
	}
	
	NSString *pkginfoPath = [contentsPath stringByAppendingPathComponent:@"PkgInfo"];
	if (![[NSString stringWithFormat:@"%@%@", TVApplicationCreatorCode, TVDocumentTypeShowOSCode] writeToFile:pkginfoPath atomically:NO encoding:NSASCIIStringEncoding error:outError])
	{
		return NO;
	}
	
	// generate Quicklook files
	if (![self writeQuickLookFilesToPath:inPath error:outError])
	{
		return NO;
	}
	
	NSDictionary *formatDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat:@"%.3f", kDocumentFormatVersion], @"TVDocumentFormatVersion",
#ifndef CONFIGURATION_Debug
		[NSApp bundleVersionAsNumber], @"TVApplicationRevision",
#endif
		version, @"TVApplicationVersion",
		nil];
	
	if (![formatDictionary writeToFile:[inPath stringByAppendingPathComponent:@"Format.plist"] atomically:NO])
	{
		// TODO: create error
		return NO;
	}
	
	return YES;
}

- (NSDictionary *)dictionaryRepresentationOfMetadata
{
	NSMutableDictionary *result = [[self.metadata mutableCopy] autorelease];
	if (! result)
	{
		result = [NSMutableDictionary dictionary];
	}
	if (!result)
		return nil;
	
	NSImage *image = [result objectForKey:@"image"];
	NSData *tiffData = nil;
	if (image != nil && (tiffData = [image TIFFRepresentation]) != nil)
	{
		// replace NSImage with NSData
		[result setObject:tiffData forKey:@"image"];
	}
	NSImage *placeholderImage = [result objectForKey:@"placeholder"];
	NSData *placeholderTiffData = nil;
	if (placeholderImage != nil && (placeholderTiffData = [placeholderImage TIFFRepresentation]) != nil)
	{
		// replace NSImage with NSData
		[result setObject:placeholderTiffData forKey:@"placeholder"];
	}
	return result;
}

- (NSDictionary *)dictionaryRepresentationOfTemplateMetadata
{
	return self.templateMetadata;
}

- (NSDictionary *)dictionaryRepresentationOfDocumentState
{
	NSMutableDictionary *result = [[[_originalDocumentPropertyList objectForKey:@"documentState"] mutableCopy] autorelease];
	if (!result)
	{
		result = [NSMutableDictionary dictionary];
	}
	if (!result)
		return nil;
	
	NSMutableDictionary *sizeRepresentation = [[result objectForKey:@"renderingVideoSize"] mutableCopy];
	if (!sizeRepresentation)
		sizeRepresentation = [[NSMutableDictionary alloc] init];
		
	[sizeRepresentation setObject:[NSNumber numberWithFloat:_videoSize.width]  forKey:@"pixelWidth"];
	[sizeRepresentation setObject:[NSNumber numberWithFloat:_videoSize.height] forKey:@"pixelHeight"];
	
	[result setObject:sizeRepresentation forKey:@"renderingVideoSize"];
	[result setObject:[self.audioMixer valueForKey:@"outputVolume"] forKey:@"masterOutputAudioVolume"];
	[result setObject:[self.audioMixer valueForKey:@"playthroughVolume"] forKey:@"playThroughAudioVolume"];
	[result setObject:self.playthroughDevice forKey:@"playThroughDeviceUID"];
	[result setObject:[NSNumber numberWithBool:([_audioMixer playthroughVolume] <= 0.0)] forKey:@"playThroughDeviceisMuted"];
	[result setObject:self.exportSettings forKey:@"exportSettings"];
	[result setObject:[self.showSettings dictionaryRepresentation] forKey:@"showSettings"];
	[sizeRepresentation release];
	return result;
}

- (NSDictionary *)dictionaryRepresentationOfVolatileState
{
	NSMutableDictionary *result = [[[_originalDocumentPropertyList objectForKey:@"volatileState"] mutableCopy] autorelease];
	if (! result)
	{
		result = [NSMutableDictionary dictionary];
	}
	if (!result)
		return nil;
	
	// selected layer
	[result setValue:[[[self.layersController selectedObjects] lastObject] identifier] forKey:@"selectedLayer"];
	
	// selected settings
	NSMutableSet *selectedSettings = [[NSMutableSet alloc] init];
	for (id layer in self.layersController.arrangedObjects)
	{
		NSString *selectedSettingIdentifier = [[layer editSetting] identifier];
		if (selectedSettingIdentifier) 
		{
			[selectedSettings addObject:selectedSettingIdentifier];
		}
	}
	[result setObject:[selectedSettings allObjects] forKey:@"selectedSettings"];
	[selectedSettings release];
	
	// expanded layers
	NSMutableSet *expandedLayers = [[NSMutableSet alloc] init];
	for (TVLayerEntryViewController *controller in [_ibLayerContainerView allEntryViewControllers])
	{
		NSString *expandedViewLayerIdentifier = [[controller representedObject] identifier];
		if (expandedViewLayerIdentifier && [controller isExpanded])
		{
			[expandedLayers addObject:expandedViewLayerIdentifier];
		}
	}
	[result setObject:[expandedLayers allObjects]   forKey:@"expandedLayers"];
	[expandedLayers release];
	
	// overlays
	[result setObject:(_actionSafeAreaEnabled ? NSTrue : NSFalse) forKey:@"showActionSafeBounds"];
	[result setObject:( _titleSafeAreaEnabled ? NSTrue : NSFalse) forKey:@"showTitleSafeBounds"];
	
	// window frames
	NSMutableDictionary *windowFrames = [[result objectForKey:@"windowFrames"] mutableCopy];
	if (!windowFrames)
		windowFrames = [[NSMutableDictionary alloc] init];
	[windowFrames setValue:[ibMainWindow stringWithSavedFrame] forKey:@"Main"];
	[windowFrames setValue:[_ibPanelController.outputPanel stringWithSavedFrame] forKey:@"OutputPreview"];
	[windowFrames setValue:[_ibPanelController.layerPanel  stringWithSavedFrame] forKey:@"LayerPreview"];
	[result setObject:windowFrames forKey:@"windowFrames"];
	[windowFrames release];
	
	// preview panels
	[result addEntriesFromDictionary:[_ibPanelController dictionaryRepresentationOfVolatileState]];
	
	// fullscreen setup
	BOOL fullscreen = (_fullscreenWindow != nil);
	if (fullscreen)
	{
		NSMutableArray *screenFrames = [[NSMutableArray alloc] init];
		for (NSScreen *screen in [NSScreen screens])
		{
			[screenFrames addObject:NSStringFromRect([screen frame])];
		}
		[result setObject:screenFrames forKey:@"screenFrames"];
		[result setObject:NSTrue forKey:@"fullscreenRunning"];
		[screenFrames release];
	}
    else
    {
        [result setObject:NSFalse forKey:@"fullscreenRunning"];
    }
	
	// repository
	NSNumber *repositoryVisiblity = [NSNumber numberWithInt:_repositoryVisiblityState];
	[result setObject:repositoryVisiblity forKey:@"repositoryVisiblity"];

	// recorded Movies
	[result setObject:self.recordedMovies forKey:@"recordedMovies"];
	
	return result;
}


- (void)saveDocumentWithDelegate:(id)delegate didSaveSelector:(SEL)didSaveSelector contextInfo:(void *)contextInfo
{
	if (! self.isLicensed)
	{
		// this call blocks until user either buys a license or decides not do
		[[TVLicenseController defaultLicenseController] informAboutSaving:self];
	}
	else
	{
		[super saveDocumentWithDelegate:delegate didSaveSelector:didSaveSelector contextInfo:contextInfo];
	}
}


- (BOOL)writeToURL:(NSURL *)destinationURL ofType:(NSString *)inTypeName forSaveOperation:(NSSaveOperationType)inSaveOperation originalContentsURL:(NSURL *)inOriginalContentsURL error:(NSError **)outError
{
#pragma unused(inTypeName, inSaveOperation, inOriginalContentsURL)
	
	// write basic bundle. this also initialises *outError
	NSString *destinationPath = [destinationURL path];
	if (![self writeBasicBundleToPath:destinationPath error:outError])
		return NO;
	
    NSMutableDictionary *documentRepresentation = [[_originalDocumentPropertyList mutableCopy] autorelease];
	if (!documentRepresentation)
		documentRepresentation = [NSMutableDictionary dictionary];
	
	// failure to save the document state is fatal (it contains the video size)
	id documentState = [self dictionaryRepresentationOfDocumentState];
	if (!documentState) return NO;
	[documentRepresentation setObject:documentState forKey:@"documentState"];
	
	// failure to save metadata is non-fatal
	if (self.savingTemplate)
	{
		[documentRepresentation setObject:[self dictionaryRepresentationOfTemplateMetadata] forKey:@"templateMetadata"];
	}
	[documentRepresentation setObject:[self dictionaryRepresentationOfMetadata] forKey:@"documentMetadata"];
	
	// layer dependencies
	NSMutableDictionary *dependenciesDictionary = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSMutableSet set], @"fileReferences",
		[NSMutableSet set], @"layerTemplates",
		[NSMutableSet set], @"filterTemplates",
		[NSMutableSet set], @"sources",
		nil];
	
	// walk through all the layers determing the dependencies and simultaneously writing stuff out into a dictionary
	NSMutableArray *layers = [NSMutableArray array];
	for (id <TVLayerProtocol> layer in [self.layersController arrangedObjects])
	{
		NSDictionary *dictRep = [layer dictionaryRepresentationDeterminingSavingDependencies:dependenciesDictionary error:outError];
		if (!dictRep) return NO;
		[layers addObject:dictRep];
	}
	
	[documentRepresentation setObject:layers forKey:@"layers"];
	
	[self.fileRepository determineSavingDependencies:dependenciesDictionary];
	[self.sourceRepository determineSavingDependencies:dependenciesDictionary];
	[self.audioMixer determineSavingDependencies:dependenciesDictionary];
	
	// special case for saving a template: if layer, filter, transition is not provided by system or app bundle, this files have to be copied into the template. otherwise, a provided file don´t have to be added to the template.
	if (self.savingTemplate)
	{
		NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES);
		NSString *bundlePath = [[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]] absoluteString];
		NSString *systemPath = [[NSURL fileURLWithPath:[domains objectAtIndex:0]] absoluteString];
		
		NSMutableArray *deleteLayers = [[NSMutableArray alloc] init];
		NSMutableArray *deleteFilters = [[NSMutableArray alloc] init];
		
		for (NSString *identifier in [dependenciesDictionary objectForKey:@"layerTemplates"])
		{
			TVCompositionTemplate *compositionTemplate = [self.layerTemplateRepository templateWithIdentifier:identifier];
			NSString *layerPath = [[compositionTemplate compositionURL] absoluteString];
			
			if ([layerPath hasPrefix:bundlePath])
			{
				[deleteLayers addObject:identifier];
			}
		}
		
		for (NSString *deleteIdentifier in deleteLayers)
		{
			
			[[dependenciesDictionary objectForKey:@"layerTemplates"] removeObject:deleteIdentifier];
		}
		[deleteLayers release];
		
		
		for (NSString *filterIdentifier in [dependenciesDictionary objectForKey:@"filterTemplates"])
		{
			TVCompositionTemplate *compositionTemplate = [self.filterTemplateRepository templateWithIdentifier:filterIdentifier];
			NSString *filterPath = [[compositionTemplate compositionURL] absoluteString];
			
			if ([filterPath hasPrefix:bundlePath] || [filterPath hasPrefix:systemPath])
			{
				[deleteFilters addObject:filterIdentifier];
			}
		}
		
		for (NSString *deleteIdentifier in deleteFilters)
		{
			
			[[dependenciesDictionary objectForKey:@"filterTemplates"] removeObject:deleteIdentifier];
		}
		[deleteFilters release];
		
		
	}
	
	[self.filterTemplateRepository     determineSavingDependencies:dependenciesDictionary];
	[self.layerTemplateRepository      determineSavingDependencies:dependenciesDictionary];
	
	
	id layerTemplateRep = [self.layerTemplateRepository propertyListRepresentationWithSavingDependencies:dependenciesDictionary documentLocation:destinationURL error:outError];
	if (!layerTemplateRep) return NO;
	[documentRepresentation setObject:layerTemplateRep forKey:@"layerTemplates"];
	
	// sources
	id sourcesRep = [self.sourceRepository propertyListRepresentationWithSavingDependencies:dependenciesDictionary documentLocation:destinationURL error:outError];
	if (!sourcesRep) return NO;
	[documentRepresentation setObject:sourcesRep forKey:@"sources"];
	NSAssert([NSPropertyListSerialization propertyList:sourcesRep isValidForFormat:NSPropertyListXMLFormat_v1_0], @"Sources did not serialize in a valid property list format");
	
	// filters
	id filterRep = [self.filterTemplateRepository propertyListRepresentationWithSavingDependencies:dependenciesDictionary documentLocation:destinationURL error:outError];
	if (!filterRep) return NO;
	[documentRepresentation setObject:filterRep forKey:@"filterTemplates"];
	NSAssert([NSPropertyListSerialization propertyList:filterRep isValidForFormat:NSPropertyListXMLFormat_v1_0], @"FilterTemplates did not serialize in a valid property list format");
	
	// file references
	id fileReferenceRep = [self.fileRepository propertyListRepresentationWithSavingDependencies:dependenciesDictionary documentLocation:destinationURL error:outError];
	if (!fileReferenceRep) return NO;
	[documentRepresentation setObject:fileReferenceRep forKey:@"fileReferences"];
	NSAssert([NSPropertyListSerialization propertyList:fileReferenceRep isValidForFormat:NSPropertyListXMLFormat_v1_0], @"Files did not serialize in a valid property list format");
	
	// audioMixer
	{
		id propertyList = [self.audioMixer propertyListRepresentationWithSavingDependencies:dependenciesDictionary documentLocation:destinationURL error:outError];
		if(propertyList == nil)
		{
			return NO;
		}
		[documentRepresentation setObject:propertyList forKey:TVDocumentAudioGraphPropertyListKey];
		NSAssert([NSPropertyListSerialization propertyList:propertyList isValidForFormat:NSPropertyListXMLFormat_v1_0], @"audioMixer did not serialize in a valid property list format");
	}
	
	if (self.savingTemplate == NO)
	{
		// failure to save volatile state is non-fatal
		NSDictionary *volatileState = [self dictionaryRepresentationOfVolatileState];
		if (volatileState)
			[documentRepresentation setValue:volatileState forKey:@"volatileState"];
	}
	
	NSAssert([NSPropertyListSerialization propertyList:documentRepresentation isValidForFormat:NSPropertyListXMLFormat_v1_0], @"The document representation as a whole did not serialize in a valid property list format");
	
	// special template saving handling, some informations have to be removed and some have to be added
	if (self.savingTemplate)
	{
		NSEnumerator *e = [[documentRepresentation allKeys] objectEnumerator];
		NSString *key = nil;
		while ((key = [e nextObject]))
		{
			if ([key isEqualToString:@"sources"])
			{
				for (NSMutableDictionary *aSource in [documentRepresentation objectForKey:key])
				{
					if ([[aSource objectForKey:@"class"] isEqualToString:@"TVDeviceVideoSource"])
					{
						[aSource setObject:[NSDictionary dictionary] forKey:@"audioDevice"];
						[aSource setObject:[NSDictionary dictionary] forKey:@"videoDevice"];
						[aSource setObject:[NSNumber numberWithBool:YES] forKey:@"templateSource"];
					}
				}
			}
			else if ([key isEqualToString:@"documentState"])
			{
				[[documentRepresentation objectForKey:key] removeObjectsForKeys:[NSArray arrayWithObjects:@"playThroughDeviceisMuted", @"playThroughDeviceUID", nil]];
				[[[documentRepresentation objectForKey:key] objectForKey:@"showSettings"] removeObjectsForKeys:[NSArray arrayWithObjects:@"recordingCodec", @"previewFrameRate", @"movieFrameRate", @"displayFrameRate", @"activeEndpointIdentifiers", nil]];
			}
			else if ([key isEqualToString:@"layers"])
			{
				for (NSMutableDictionary *aLayer in [documentRepresentation objectForKey:key])
				{
					[aLayer removeObjectsForKeys:[NSArray arrayWithObjects:@"outputPan", @"outputVolume", nil]];
				}
			}
		}
	}
	
	
	NSString *errorString = nil;
	NSData *binaryPlistData = [NSPropertyListSerialization dataFromPropertyList:documentRepresentation format:NSPropertyListBinaryFormat_v1_0 errorDescription:&errorString];
	if (!binaryPlistData)
	{
		return NO;
	}
	
	if (![binaryPlistData writeToFile:[[destinationURL path] stringByAppendingPathComponent:TVDocumentPropertyList] atomically:NO])
	{
		// TODO: generate NSError
		return NO;
	}
	
	return YES;
}

#pragma mark
#pragma mark Video Frame Output

- (void)renderOutputInThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init], *innerPool;
	TVRenderingEngine *engine = [self.renderingEngine retain];
	
	NSString *threadName = [NSString stringWithFormat:@"BoinxTV:%p:OutputViewThread", self];
	[[NSThread currentThread] setName:threadName];
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
	if ([NSApp runningOnSnowLeopardOrHigher])
	{
		// this is new in 10.6, this is the name displayed in gdb and stacktraces
		pthread_setname_np([threadName cStringUsingEncoding:NSUTF8StringEncoding]);
	}
#endif		

	_outputThreadShouldStop = NO;
	_outputThreadIsRunning = YES;
	while (!_outputThreadShouldStop)
	{
		innerPool = [[NSAutoreleasePool alloc] init];
		[engine prepareConsumingOutputBufferWaitForFrame];
		
		if (!_outputThreadShouldStop)
			[_renderingEngine renderPixelBuffer:_renderingEngine.outputPixelBuffer intoContext:_outputPreviewContext texture:&_outputTexture configured:&_outputPreviewContextConfigured];

		[engine endConsumingOutputBuffer];

		[innerPool release];
	}
	[engine release];
	[pool release];
	_outputThreadShouldStop = NO;
	_outputThreadIsRunning = NO;
}

- (void)renderOutputPanelInThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init], *innerPool;
	TVRenderingEngine *engine = [self.renderingEngine retain];
	NSOpenGLContext *context = [[_ibPanelController.outputPanelGLView openGLContext] retain];

	NSString *threadName = [NSString stringWithFormat:@"BoinxTV:%p:OutputPanelThread", self];
	[[NSThread currentThread] setName:threadName];
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
	if ([NSApp runningOnSnowLeopardOrHigher])
	{
		// this is new in 10.6, this is the name displayed in gdb and stacktraces
		pthread_setname_np([threadName cStringUsingEncoding:NSUTF8StringEncoding]);
	}
#endif	

	_outputPanelThreadShouldStop = NO;
	_outputPanelThreadIsRunning = YES;
	while (!_outputPanelThreadShouldStop)
	{
		innerPool = [[NSAutoreleasePool alloc] init];
		[engine prepareConsumingOutputBufferWaitForFrame];
		
		if (!_outputPanelThreadShouldStop)
			[_renderingEngine renderPixelBuffer:_renderingEngine.outputPixelBuffer intoContext:context texture:&_outputPanelTexture configured:&_panelOutputPreviewContextConfigured];
		
		[engine endConsumingOutputBuffer];

		[innerPool release];
	}
	[context release];
	[engine release];
	[pool release];
	_outputPanelThreadShouldStop = NO;
	_outputPanelThreadIsRunning = NO;
}

- (void)renderFullscreenInThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init], *innerPool;
	TVRenderingEngine *engine = [self.renderingEngine retain];
	NSOpenGLContext *context = [[self.fullscreenOpenGLView openGLContext] retain];
	
	NSString *threadName = [NSString stringWithFormat:@"BoinxTV:%p:OutputPanelThread", self];
	[[NSThread currentThread] setName:threadName];
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
	if ([NSApp runningOnSnowLeopardOrHigher])
	{
		// this is new in 10.6, this is the name displayed in gdb and stacktraces
		pthread_setname_np([threadName cStringUsingEncoding:NSUTF8StringEncoding]);
	}
#endif
	
	_fullscreenThreadShouldStop = NO;
	_fullscreenThreadIsRunning = YES;
	while (!_fullscreenThreadShouldStop)
	{
		innerPool = [[NSAutoreleasePool alloc] init];
		[engine prepareConsumingOutputBufferWaitForFrame];
		
		if (!_fullscreenThreadShouldStop)
			[_renderingEngine renderPixelBuffer:_renderingEngine.outputPixelBuffer intoContext:context texture:&_fullscreenTexture configured:&_fullscreenContextConfigured];
		
		[engine endConsumingOutputBuffer];
		
		[innerPool release];
	}
	[context release];
	[engine release];
	[pool release];
	_fullscreenThreadShouldStop = NO;
	_fullscreenThreadIsRunning = NO;
}

- (void)renderPreviewInThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init], *innerPool;
	TVRenderingEngine *engine = [self.renderingEngine retain];
	_previewThreadShouldStop = NO;
	_previewThreadIsRunning = YES;

	NSString *threadName = [NSString stringWithFormat:@"BoinxTV:%p:PreviewViewThread", self];
	[[NSThread currentThread] setName:threadName];
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
	if ([NSApp runningOnSnowLeopardOrHigher])
	{
		// this is new in 10.6, this is the name displayed in gdb and stacktraces
		pthread_setname_np([threadName cStringUsingEncoding:NSUTF8StringEncoding]);
	}
#endif	
	
	while (!_previewThreadShouldStop)
	{
		innerPool = [[NSAutoreleasePool alloc] init];
		[engine prepareConsumingPreviewBufferWaitForFrame];
		
		if (!_previewThreadShouldStop && _ibLayerPreviewContainerView.button.state == NSOnState) // only update display if not collapsed
		{
			[self previewLayerDrawing];
		}
		[engine endConsumingPreviewBuffer];

		[innerPool release];
	}
	[engine release];
	[pool release];
	_previewThreadShouldStop = NO;
	_previewThreadIsRunning = NO;
}


- (void)renderLayerPanelInThread
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init], *innerPool;
	TVRenderingEngine *engine = [self.renderingEngine retain];
	NSOpenGLContext *context = [[_ibPanelController.layerPanelGLView openGLContext] retain];

	NSString *threadName = [NSString stringWithFormat:@"BoinxTV:%p:PreviewPanelThread", self];
	[[NSThread currentThread] setName:threadName];
#if defined(MAC_OS_X_VERSION_10_6) && (MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_6)
	if ([NSApp runningOnSnowLeopardOrHigher])
	{
		// this is new in 10.6, this is the name displayed in gdb and stacktraces
		pthread_setname_np([threadName cStringUsingEncoding:NSUTF8StringEncoding]);
	}
#endif	

	_previewPanelThreadShouldStop = NO;
	_previewPanelThreadIsRunning = YES;
	while (!_previewPanelThreadShouldStop)
	{
		innerPool = [[NSAutoreleasePool alloc] init];
		[engine prepareConsumingPreviewBufferWaitForFrame];
		
		if (!_previewPanelThreadShouldStop)
			[_renderingEngine renderPixelBuffer:_renderingEngine.layerPixelBuffer intoContext:context texture:&_previewPanelTexture configured:&_panelLayerPreviewContextConfigured];

		[engine endConsumingPreviewBuffer];

		[innerPool release];
	}
	[context release];
	[engine release];
	[pool release];
	_previewPanelThreadShouldStop = NO;
	_previewPanelThreadIsRunning = NO;
}

- (void)previewLayerDrawing
{
	[_renderingEngine renderPixelBuffer:_renderingEngine.layerPixelBuffer intoContext:_layerPreviewContext texture:&_layerPreviewTexture configured:&_layerPreviewContextConfigured];
}

- (void)queueEvent:(NSEvent *)event
{
	[_renderingEngine queueEvent:event];
}


- (void)queueMouseMovedEvent:(NSEvent *)event
{
	[_renderingEngine queueMouseMovedEvent:event];
}


- (void)updateShowTime:(NSTimer *)timer
{
	// let us update the darget date of the timer here to get better results
	NSDate *targetFireDate = _showController.fireDateForNextSecond;
//	NSLog(@"%s fireDate:%f targetFireDate:%f difference:%f showTime:%f",__FUNCTION__,[timer.fireDate timeIntervalSinceReferenceDate],[targetFireDate timeIntervalSinceReferenceDate],[timer.fireDate timeIntervalSinceReferenceDate] - [targetFireDate timeIntervalSinceReferenceDate],self.showController.showTime);
	[timer performSelector:@selector(setFireDate:) withObject:targetFireDate afterDelay:0.0];
	
	#pragma unused (timer)
	_ibShowProgessView.percentage = self.showController.showProgress;
	_ibShowProgessView.drawsRed = self.showController.isInShowEndTimerOffset;
	_ibShowTimeLCDView.drawRed = self.showController.isInShowEndTimerOffset;
	// if we adjust our timer so it adjusts its fire date (as we do above) rounding seems to work best
    _ibShowTimeLCDView.seconds = round(self.showController.showTime);
	// this was my previous attempt - but it seems that we also have times where we are a tad early, so rounding seems the best approach
    // _ibShowTimeLCDView.seconds = self.showSettings.showDuration > 0.0 ? ceil(self.showController.showTime) : floor(self.showController.showTime);
	
	if (! self.showController.isRolling)
	{
		// just every other second - regardless of when we are called
		_ibShowTimeLCDView.drawColons = ((uint32_t)[NSDate timeIntervalSinceReferenceDate]) % 2;
	}
	else
	{
		_ibShowTimeLCDView.drawColons = YES;
	}
	[_ibShowTimeLCDView setNeedsDisplay:YES];
	
	// updating vmem ussage
	vm_size_t vsize = [TVApp virtualMemoryUsage];
	_ibVirtualMemoryView.usedVirtualMemory = vsize;
	
	// Using this timer to estimate the remaining recording time
	ByteCount spaceUsedPerSecond = 0;
	for (TVStreamEndpoint *endpoint in [TVStreamDiskEndpoint currentEndpoints])
	{
		spaceUsedPerSecond += [(TVStreamTransmitter *)[endpoint transmitter] byteCountPerSecond];
	}
	// subtract the space used this second
	_freeSpaceOnDestinationDevice -= spaceUsedPerSecond;
	
	if (spaceUsedPerSecond != 0)
	BXLogInDomain(kLogDomainRecording, kLogLevelDebug, @"Space Free: %llu, Space used per sec: %lu, Time Remaining %llu sec", _freeSpaceOnDestinationDevice, spaceUsedPerSecond, _freeSpaceOnDestinationDevice/spaceUsedPerSecond);
}


- (void)updateVUMeter:(NSTimer *)inTimer
{
#pragma unused (inTimer)
	LevelMeterValues levels = [_audioMixer masterMeterAverage];
	[_ibMainVUMeter setLevels:levels];
}


- (void)updatePerformanceMeter:(NSTimer *)inTimer
{
#pragma unused (inTimer)
	[_ibPerformanceMeter setWorkload:self.renderingEngine.performance.lastSecondAverage];
}


- (void) updateDiscSpace:(NSTimer*)theTimer
{
#pragma unused (theTimer)
	NSString *movieSaveLocation = [[NSUserDefaults standardUserDefaults] stringForKey:@"MovieSaveLocation"];
	NSString *defaultMovieSaveLocation = [TVDefaultsController defaultMovieSaveFolder];

	if (! movieSaveLocation)
	{
		movieSaveLocation = defaultMovieSaveLocation;
	}
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([movieSaveLocation isEqualToString:defaultMovieSaveLocation])
	{
		while (! [fileManager fileExistsAtPath:movieSaveLocation])
		{
			movieSaveLocation = [movieSaveLocation stringByDeletingLastPathComponent];
		}
	}
	
	NSDictionary* fileAttributes = [fileManager attributesOfFileSystemForPath:movieSaveLocation error:NULL];
	_freeSpaceOnDestinationDevice = [[fileAttributes objectForKey:NSFileSystemFreeSize] longLongValue];
}


- (void) updateFreeMemory:(NSTimer*)theTimer
{
#pragma unused (theTimer)
#if defined(CONFIGURATION_Debug)
	if (sDomainLevel[kLogDomainMisc] >= kLogLevelWarning) 
#else
	if (sDomainLevel[kLogDomainMisc] >= kLogLevelDebug) 
#endif
	{
		[self validateStatusLine];
	}
}


#pragma mark
#pragma mark UI validation

+ (NSSet *)keyPathsForValuesAffectingCanRecord
{
	return [NSSet setWithObjects:@"windowIsMain", @"licenseAllowsRecording", @"showSettings.codec", @"showSettings.recordsMovie", @"renderingEngine.outputRenderingPaused", @"fileEndpoint.connected", @"fileEndpoint.streaming", nil];
}

- (BOOL)canRecord
{
	if (![self windowIsMain]) return NO;
	if (![self licenseAllowsRecording]) return NO;
	if (_showSettings.codec == 0x00000000) return NO;
	if (_renderingEngine.outputRenderingPaused == YES) return NO;
	BOOL recordsToDisk = _showSettings.recordsMovie;
	if (recordsToDisk && _fileEndpoint.connected == NO) return NO;
	if (recordsToDisk && _fileEndpoint.streaming == YES &&
		_renderingEngine.outputQueue != _fileEndpoint.outputQueue) return NO;
	return YES;
}

- (void)validateUIRecordingState
{
	BOOL recordsToDisk = self.showSettings.recordsMovie;
	BOOL recordsFullscreen = self.showSettings.recordsFullscreen;
	
	if (recordsToDisk) 
	{
		[_ibRecordsMovieImageView setImage:[NSImage imageNamed:@"tb-showmode-recording_on"]];
	}
	else
	{
		[_ibRecordsMovieImageView setImage:[NSImage imageNamed:@"tb-showmode-recording_off"]];
	}
	if (recordsFullscreen)
	{
		[_ibRecordsFullscreenImageView setImage:[NSImage imageNamed:@"tb-showmode-fullscreen_on"]];
	}
	else
	{
		[_ibRecordsFullscreenImageView setImage:[NSImage imageNamed:@"tb-showmode-fullscreen_off"]];
	}
	
	// as long as we don't have streaming
	[_ibRecordsStreamingImageView setImage:[NSImage imageNamed:@"tb-showmode-empty"]];
	
	if (!recordsToDisk && !recordsFullscreen)
	{
		[_ibRecordsMovieImageView setImage:[NSImage imageNamed:@"tb-showmode-recording_none"]];
	}
	
	NSString *outputPreviewStatusString = nil;
	if (self.renderingEngine.outputRenderingPaused)
	{
		outputPreviewStatusString = NSLocalizedStringFromTable(@"OutputPreviewStatusPaused", @"Document", nil);
		[_ibRecDisplay setStringValue:NSLocalizedStringFromTable(@"RecDisplayPaused", @"Document", nil)];
		[_ibRecDisplay setTextColor:[NSColor colorWithCalibratedRed:0.957 green:0.839 blue:0.122 alpha:0.9f]];
//		[_ibRecordButton setEnabled:NO];
	}
	else
	{
//		[_ibRecordButton setEnabled:YES];
		if (! self.showController.isRolling)
		{
			outputPreviewStatusString = NSLocalizedStringFromTable(@"OutputPreviewStatusReady", @"Document", nil);
			[_ibRecDisplay setStringValue:NSLocalizedStringFromTable(@"RecDisplayReady", @"Document", nil)];
			[_ibRecDisplay setTextColor:[NSColor colorWithCalibratedRed:0.114 green:0.996 blue:0.106 alpha:0.85f]];
		}
		else
		{
			if (! self.showController.isInShowEndTimerOffset)
			{
				if (recordsToDisk) 
				{
					outputPreviewStatusString = NSLocalizedStringFromTable(@"OutputPreviewStatusRecord", @"Document", nil);
					[_ibRecDisplay setStringValue:NSLocalizedStringFromTable(@"RecDisplayRecord", @"Document", nil)];
					[_ibRecDisplay setTextColor:[NSColor colorWithCalibratedRed:0.957 green:0.000 blue:0.078 alpha:0.9f]];
				}
				else 
				{
					outputPreviewStatusString = NSLocalizedStringFromTable(@"OutputPreviewStatusRoll", @"Document", nil);
					[_ibRecDisplay setStringValue:NSLocalizedStringFromTable(@"RecDisplayRoll", @"Document", nil)];
					[_ibRecDisplay setTextColor:[NSColor colorWithCalibratedRed:0.949 green:0.200 blue:0.094 alpha:0.9f]];
				}
			}
			else
			{
				outputPreviewStatusString = NSLocalizedStringFromTable(@"OutputPreviewStatusOutro", @"Document", nil);
				[_ibRecDisplay setStringValue:NSLocalizedStringFromTable(@"RecDisplayOutro", @"Document", nil)];
				[_ibRecDisplay setTextColor:[NSColor colorWithCalibratedRed:0.949 green:0.400 blue:0.094 alpha:0.9f]];
			}
		}
	}
	
	[_ibRecordButton setImage:       [NSImage imageNamed:recordsToDisk ? @"ToolbarRecordButton_Off"         : @"ToolbarRecordButton_Play"        ]];
	[_ibRecordButton setPressedImage:[NSImage imageNamed:recordsToDisk ? @"ToolbarRecordButton_Off_Pressed" : @"ToolbarRecordButton_Play_Pressed"]];

	if (! self.showController.isRolling)
	{
		[_ibRecordButton setToolTip:recordsToDisk ? NSLocalizedString(@"ToolbarItemToolTipStartRecording", nil) : NSLocalizedString(@"ToolbarItemToolTipStartRolling", nil) ];
		[_ibRecordButton setState:NSOffState];
		[_ibRecordButton setAlternateImage:       [NSImage imageNamed:@"ToolbarRecordButton_On"        ]];
		[_ibRecordButton setAlternatePressedImage:[NSImage imageNamed:@"ToolbarRecordButton_On_Pressed"]];
	}
	else
	{
		[_ibRecordButton setToolTip:recordsToDisk ? NSLocalizedString(@"ToolbarItemToolTipStopRecording", nil) : NSLocalizedString(@"ToolbarItemToolTipStopRolling", nil) ];
		if (! self.showController.isInShowEndTimerOffset)
		{
			[_ibRecordButton setState:NSMixedState];
			[_ibRecordButton setAlternateImage:       [NSImage imageNamed:@"ToolbarRecordButton_On"        ]];
			[_ibRecordButton setAlternatePressedImage:[NSImage imageNamed:@"ToolbarRecordButton_On_Pressed"]];
		}
		else
		{
			[_ibRecordButton setState:NSOnState];
			[_ibRecordButton setAlternateImage:       [NSImage imageNamed:@"ToolbarRecordButton_End"]];
			[_ibRecordButton setAlternatePressedImage:[NSImage imageNamed:@"ToolbarRecordButton_End_Pressed"]];
		}
	}

	[_ibPauseRenderingButton setState:[self.renderingEngine outputRenderingPaused] ? NSOnState : NSOffState];
	[_ibPauseRenderingButton setEnabled:!self.showController.isRolling];
	
	NSString *format = NSLocalizedStringFromTable(@"OutputPreviewHeaderFormat", @"Document", nil);
	self.outputPreviewStatusString = outputPreviewStatusString;
	CGFloat pointUnit = 1.0;
	if (NSAppKitVersionNumber > NSAppKitVersionNumber10_7)
	{
		// checking for retina resolution
		pointUnit = [ibMainWindow backingScaleFactor];
	}
	NSString *newPreviewHeaderString = [NSString stringWithFormat:format, [self scaleForGLView:outputPreview] * pointUnit, self.outputPreviewStatusString];
	// NSLog(@"%@", newPreviewHeaderString);
	[_ibMainPreviewHeader setTitle:newPreviewHeaderString];
	if (_outputPanelOpen)
	{
		[_ibPanelController updateWindowTitles];
	}
}


- (void)validateTriggerEventUI
{
	[[_ibLayerTriggerEventPopup menu] update]; // updates the selected menu item to be enabled/disabled
	[[_ibSettingTriggerEventPopup menu] update]; // updates the selected menu item to be enabled/disabled
}


- (void)validateStatusLine 
{
	NSArray *layers = [self.layersController arrangedObjects];
	[_bottomStatusLineTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%d Layers total - %d Layers live", @"Main window status line template text"), [layers count], [[layers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"active != 0"]] count]]];
	
	NSDictionary *rendererInfo = [self.renderingEngine.renderingEngineManager infoForRendererID:self.renderingEngine.usedRendererID];
	
	NSString *rendererName = [rendererInfo objectForKey:TVRenderingEngineManagerRendererDisplayName];
	NSString *rendererDriver = [rendererInfo objectForKey:TVRenderingEngineManagerRendererDriver];
	
#if defined(CONFIGURATION_Debug)
	if (sDomainLevel[kLogDomainMisc] >= kLogLevelWarning) 
#else
	if (sDomainLevel[kLogDomainMisc] >= kLogLevelDebug) 
#endif
	{
		vm_size_t vsize = [TVApp virtualMemoryUsage];
		vm_size_t freeSize = 0xFFFFFFFF - vsize;
		[_bottomRightStatusLineTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Mem Avail.: %uMB - Size: %d × %d pixels - %@ - %@", @"Main window status line bottom right template text"), freeSize / 0x100000, (int) self.videoSize.width, (int) self.videoSize.height, rendererName, rendererDriver]];
	}
	else
	{
		[_bottomRightStatusLineTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Size: %d × %d pixels - %@", @"Main window status line bottom right template text"), (int) self.videoSize.width, (int) self.videoSize.height, rendererName]];
	}

}


- (void)validateCurrentSettingsControl 
{
	TVVideoLayer *selectedLayer = [self selectedLayer];
	if (selectedLayer)
	{
		BOOL didAnythingChange = NO;
		NSArrayController *settingsController = [selectedLayer settingsController];
		NSString *newString = [settingsController valueForKeyPath:@"selection.name"];
		if (![newString isEqualToString:[_ibPropertiesSettingTitle stringValue]]) 
		{
			[_ibPropertiesSettingTitle setObjectValue:newString];
			didAnythingChange = YES;
		}
		
		newString = [selectedLayer name];

		id liveSetting = [settingsController valueForKeyPath:@"selection.isLiveSetting"];

		if (liveSetting && [liveSetting boolValue])
		{
			[(TVDisclosureGroupButton*)_ibLayerPreviewHeader setIsLive:YES];
			[_ibLayerPreviewHeader setTitle:[newString stringByAppendingString:@" - LIVE"]];
			if (![newString isEqualToString:[_ibLayerPreviewHeader title]]) 
			{
				didAnythingChange = YES;
			}
		}
		else
		{
			[(TVDisclosureGroupButton*)_ibLayerPreviewHeader setIsLive:NO];
			[_ibLayerPreviewHeader setTitle:newString];
			if (![newString isEqualToString:[_ibLayerPreviewHeader title]]) 
			{
				didAnythingChange = YES;
			}
		}
		
		if (didAnythingChange)
		{
			[_ibPanelController updateWindowTitles];
		}
	}
}


- (void)validatePropertiesBackground
{
	if (self.renderingEngine)
	{
//		TVVideoLayer *selectedLayer = [self selectedLayer];
//		if (selectedLayer)
//		{
//			NSArrayController *settingsController = [selectedLayer settingsController];
//			if (settingsController)
//			{
//				id liveSetting = [settingsController valueForKeyPath:@"selection.isLiveSetting"];
//				if (liveSetting)
//				{
//					BOOL live = [liveSetting boolValue];
//					if (_ibLiveWarningBackground) [_ibLiveWarningBackground setGradient:(live) ? _livePropertyBackground : _normalPropertyBackground];
//					if (_ibPropertyColumnView) [_ibPropertyColumnView setGradient:(live) ? _livePropertyBackground : _normalPropertyBackground];
//				}
//			}
//		}
//		else 
//		{
//			if (_ibLiveWarningBackground) [_ibLiveWarningBackground setGradient:_normalPropertyBackground];
//			if (_ibPropertyColumnView)    [_ibPropertyColumnView setGradient:_normalPropertyBackground];
//		}
		[self validateCurrentSettingsControl];
	}
}


// does a cheap check for Intel onboard PGUs and alerts user if found
- (void)validateGPU
{
	TVRenderingEngine *renderingEngine = self.renderingEngine;
	if(!renderingEngine)
	{
		return;
	}
	
	SInt32 versionMajor, versionMinor, versionBugFix;
    Gestalt(gestaltSystemVersionMajor, &versionMajor);
    Gestalt(gestaltSystemVersionMinor, &versionMinor);
    Gestalt(gestaltSystemVersionBugFix, &versionBugFix);
	
	NSDictionary *rendererInfo = [renderingEngine.renderingEngineManager infoForRendererID:renderingEngine.usedRendererID];
	NSString *rendererName = [rendererInfo objectForKey:TVRenderingEngineManagerRendererName];
	NSString *rendererDriver = [rendererInfo objectForKey:TVRenderingEngineManagerRendererDriver];

	if([rendererName rangeOfString:@"Intel GMA"].location != NSNotFound)
	{
		BXAlert *alert = [BXAlert alertWithMessageText:IntelGMAAlertTitle()
 										 defaultButton:IntelGMAAlertOKButton()
 									   alternateButton:nil
 										   otherButton:nil
							 informativeTextWithFormat:IntelGMAAlertMessage(), nil];
		
		[alert setIdentifier:@"Do not show Intel GMA alert"];
		[alert setAlertStyle:NSCriticalAlertStyle];

		[alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	}
	else if([rendererName rangeOfString:@"NVIDIA GeForce 9400M"].location != NSNotFound)
	{
		NSOpenGLPixelFormatAttribute allRendererAttributes[] = {
			NSOpenGLPFAAccelerated,
			NSOpenGLPFANoRecovery,
			NSOpenGLPFAAllowOfflineRenderers,
			0 
		};
		NSOpenGLPixelFormat *glPixelFormatAll = [[NSOpenGLPixelFormat alloc] initWithAttributes:allRendererAttributes];
		if (glPixelFormatAll)
		{
			GLint numberOfAllVirtualScreens = [glPixelFormatAll numberOfVirtualScreens];
			if (numberOfAllVirtualScreens > 1)
			{
				BOOL hasBetterGraphics = NO;
				GLint rendererID;
				for (GLint virtualScreen = 0; virtualScreen < numberOfAllVirtualScreens; virtualScreen++)
				{
					[glPixelFormatAll getValues:&rendererID forAttribute:NSOpenGLPFARendererID forVirtualScreen:virtualScreen];
					
					if (renderingEngine.usedRendererID != rendererID)
					{
						NSOpenGLContext *testContext = [[NSOpenGLContext alloc] initWithFormat:glPixelFormatAll shareContext:nil];
						if (testContext)
						{
							CGLContextObj cgl_ctx = [testContext CGLContextObj];
							CGLSetVirtualScreen(cgl_ctx, virtualScreen);
							NSString *rendererName = [[NSString stringWithFormat:@"%s",  glGetString(GL_RENDERER)] stringByReplacingOccurrencesOfString:@" OpenGL Engine" withString:@""];
							if ([rendererName isEqualToString:@"NVIDIA GeForce 9600M GT"])
							{
								hasBetterGraphics = YES;
							}
							BXRelease(testContext);
						}
					}
				}
				
				if (hasBetterGraphics)
				{
					BXAlert *alert = [BXAlert alertWithMessageText:NVIDIA9400AlertTitle()
													 defaultButton:NVIDIA9400AlertOKButton()
												   alternateButton:NVIDIA9400AlertSwitchButton()
													   otherButton:nil
										 informativeTextWithFormat:NVIDIA9400AlertMessage(), nil];
					
					[alert setIdentifier:@"Do not show slow NVIDIA alert"];
					[alert setAlertStyle:NSCriticalAlertStyle];
					
					[alert beginSheetModalForWindow:[self windowForSheet] modalDelegate:self didEndSelector:@selector(nvidiaAlertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
				}
			}
			[glPixelFormatAll release];
		}
	}
	// all 10.7 versions have problems with X1000 drivers 
	else if(versionMajor == 10 && versionMinor == 7 && [rendererDriver isEqualToString:@"ATIRadeonX1000GLDriver"])
	{
		NSString *title = NSLocalizedStringWithDefaultValue(@"RadeonX1000Driver-10.7-AlertTitle", @"Document", BUNDLE, @"Unstable Graphics Driver found.", @"");
		NSString *message = NSLocalizedStringWithDefaultValue(@"RadeonX1000Driver-10.7-AlertMessage", @"Document", BUNDLE, @"OS X Lion (10.7) is the last OS version that supports your graphic card, but shipped with an unstable driver. This combination might cause crashes under massive system loads. So far, we can't prevent those crashes from happening as they are beyond our control. If you experience those crashes the only solution with your hardware setup would be downgrading to OS X Snow Leopard (10.6.8) or reduce the complexity of your setup.", @"");
		NSString *defaultButton = NSLocalizedStringWithDefaultValue(@"RadeonX1000Driver-10.7-AlertOK", @"Document", BUNDLE, @"Continue", @"");
		
		BXAlert *alert = [BXAlert alertWithMessageText:title
 										 defaultButton:defaultButton
 									   alternateButton:nil
 										   otherButton:nil
							 informativeTextWithFormat:message, nil];
		
		[alert setIdentifier:@"No Radeon X1000 driver on 10.7"];
		[alert setAlertStyle:NSCriticalAlertStyle];
		
		[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	}
	// 10.7.5 have problems with X2000 and X3000 drivers, name can be ATI or AMD
	else if(versionMajor == 10 && versionMinor == 7 && versionBugFix == 5
		&& (
			[rendererDriver isEqualToString:@"ATIRadeonX2000GLDriver"] ||
			[rendererDriver isEqualToString:@"AMDRadeonX2000GLDriver"] ||
			[rendererDriver isEqualToString:@"ATIRadeonX3000GLDriver"] ||
			[rendererDriver isEqualToString:@"AMDRadeonX3000GLDriver"]
	    )) {
			NSString *title = NSLocalizedStringWithDefaultValue(@"RadeonX3000Driver-10.7.5-AlertTitle", @"Document", BUNDLE, @"Unstable Graphics Driver found", @"");
			NSString *message = NSLocalizedStringWithDefaultValue(@"RadeonX3000Driver-10.7.5-AlertMessage", @"Document", BUNDLE, @"OS X Lion (10.7.5) shipped with an unstable driver for your graphics card. This combination might cause crashes under massive system loads. So far, we can't prevent those crashes from happening as they are beyond our control. If you experience those crashes please update to OS X Mountain Lion (10.8) or reduce the complexity of your setup.", @"");
			NSString *defaultButton = NSLocalizedStringWithDefaultValue(@"RadeonX3000Driver-10.7.5-AlertOK", @"Document", BUNDLE, @"Continue", @"");
		
			BXAlert *alert = [BXAlert alertWithMessageText:title
											 defaultButton:defaultButton
										   alternateButton:nil
											   otherButton:nil
								 informativeTextWithFormat:message, nil];
			
			[alert setIdentifier:@"No Radeon X2000/X3000 driver on 10.7.5"];
			[alert setAlertStyle:NSCriticalAlertStyle];
			
			[alert beginSheetModalForWindow:self.windowForSheet modalDelegate:nil didEndSelector:NULL contextInfo:NULL];
	}
}


- (void)nvidiaAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
	#pragma unused(alert,contextInfo)

	[NSApp stopModal];
	if (returnCode == NSAlertSecondButtonReturn)
	{
		[[NSWorkspace sharedWorkspace] openFile:@"/System/Library/PreferencePanes/EnergySaver.prefPane"];
	}
}


#pragma mark
#pragma mark Undo


- (void)fieldEditorDidBeginEditing:(NSNotification *)notification
{
	if (!_reallyEditing)
	{
		id <NSTextViewDelegate> field = nil;
		NSTextView *object = (NSTextView *)[notification object];
		BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"fieldEditorDidBeginEditing: %@", object);
		if ([object respondsToSelector:@selector(delegate)])
		{
			field = [object delegate];
		}
		else
		{
			BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"object %@ does not respond to -delegate", object);
			return;
		}
		if (!field || ![field respondsToSelector:@selector(tag)] || ![field respondsToSelector:@selector(superview)])
		{
			BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"object %@ (with tag %d) returned a nil delegate", object, (int)[object tag]);
			return;
		}
		
		_undoGroupIndex = NSNotFound;
		
		if ([field isKindOfClass:[NSView class]])
		{
			NSView *view = (NSView *)field;
			while ((view = [view superview]) != nil)
			{
				// loop through superviews, looking for a TVCompositionParameterView (so that we know we're editing a parameter)
				if ([view isKindOfClass:[TVCompositionParameterView class]])
				{
					[self beginUndoGroupingForTextView:(NSView *)field];
					_reallyEditing = YES;
					break;
				}
			}
		}
	}
	else
	{
		BXLogInDomain(kLogDomainUndo, kLogLevelError, @"fieldEditorDidBeginEditing: called while previous editing session was still active.");
	}
}


- (void)fieldEditorDidEndEditing:(NSNotification *)notification
{
	if (_reallyEditing)
	{
		NSTextField *field = nil;
		id object = [notification object];
		BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"fieldEditorDidEndEditing: %@", object);
		_reallyEditing = NO;
		if ([object respondsToSelector:@selector(delegate)])
			field = [object delegate];
		if (!field || ![field respondsToSelector:@selector(tag)] || ![field respondsToSelector:@selector(superview)])
			return;
		
		if (_undoGroupIndex == NSNotFound)
			return;
		if (_undoGroupIndex != [field tag])
		{
			BXLogInDomain(kLogDomainUndo, kLogLevelError, @"current undo group index %d did not match field tag %d", _undoGroupIndex, [field tag]);
			return;
		}
		
		NSView *view = field;
		while ((view = [view superview]) != nil)
		{
			if ([view isKindOfClass:[TVCompositionParameterView class]])
			{
				[self endUndoGrouping];
				break;
			}
		}
		_undoGroupIndex = NSNotFound;
	}
}

- (void)beginUndoGroupingForTextView:(NSView *)view
{
	if (! _undoGroupSetting)
	{
		_undoGroupIndex = [view tag];	// 'view' is either an NSTextField or an NSTextView
		if (_undoGroupIndex >= 0 && _undoGroupIndex != NSNotFound)		// tags are -1 for invalid views
		{
			_undoGroupSetting = [[[self selectedLayer] editSetting] retain];
			[_undoGroupSetting beginUndoGroupForInputKeyAtIndex:_undoGroupIndex];
		}
		else 
		{
			BXLogInDomain(kLogDomainUndo, kLogLevelError, @"view %@ had tag of %d", view, [view tag]);
		}
	}
	else
	{
		BXLogInDomain(kLogDomainUndo, kLogLevelError, @"currently in undo group, can't group undo for view %@ ", view);
	}
}

- (void)endUndoGrouping
{
	if (_undoGroupSetting)
	{
		if (_undoGroupIndex >= 0 && _undoGroupIndex != NSNotFound)
		{
			[_undoGroupSetting endUndoGroupForInputKeyAtIndex:_undoGroupIndex];
			BXRelease(_undoGroupSetting);
			_undoGroupIndex = NSNotFound;
		}
	}
}

- (NSUndoManager *)undoManagerForTextView:(NSTextView *)inTextView
{
	BXLogInDomain(kLogDomainUndo, kLogLevelDebug, @"undo manager requested for text view %@", inTextView);
	return [self undoManager];
}

#pragma mark
#pragma mark Playthrough Device Support

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	#pragma unused(menu)
    [self rebuildDeviceMenu];
}

- (void)rebuildDeviceMenu 
{  
    NSMenuItem *playthroughDevicesMenuItem = [[_ibPlaythroughActionButton pullDownMenu] itemWithTag:23];
    NSMenu *deviceMenu = [playthroughDevicesMenuItem submenu];
    if (!deviceMenu) {
        deviceMenu = [[NSMenu new] autorelease];
        [playthroughDevicesMenuItem setSubmenu:deviceMenu];
    }
    
    [[_ibPlaythroughActionButton pullDownMenu] setDelegate:self];
    
    for (NSMenuItem *item in [deviceMenu itemArray])
        [deviceMenu removeItem:item];

    if (!self.playthroughDevice) self.playthroughDevice = [TVAudioGraph defaultOutputDevice];    
    
    self.playthroughDevices = [TVAudioGraph availableOutputDevices];
    for(NSUInteger i = 0; i < self.playthroughDevices.count; ++i)
    {
        NSString *outputDevice = [self.playthroughDevices objectAtIndex:i];

		NSString *title = [TVAudioGraph nameOfDeviceWithUID:outputDevice];
		if(title == nil)
		{
			BXLogInDomain(kLogDomainDevices, kLogLevelError, @"+[TVAudioGraph nameOfDeviceWithUID:name]. No device with UID: %@", outputDevice);
			continue;
		}
		
        NSMenuItem *newDeviceMenuItem = [[NSMenuItem new] autorelease];
        [newDeviceMenuItem setTitle:title];
        [newDeviceMenuItem setAction:@selector(selectPlaythroughDevice:)];
        [newDeviceMenuItem setTag:i];
        [newDeviceMenuItem setState:[self.playthroughDevice isEqualToString:outputDevice]?NSOnState:NSOffState];
		if(self.showController.isRolling)
		{
			[newDeviceMenuItem setEnabled:NO];
		}
		[deviceMenu addItem:newDeviceMenuItem];
    }
    
		//if (!self.showController.isRolling) [playthroughDevicesMenuItem setEnabled:([self.playthroughDevices count]>0)];

}

- (IBAction)selectPlaythroughDevice:(id)inSender
{
    self.playthroughDevice = [self.playthroughDevices objectAtIndex:[(NSControl *)inSender tag]];
    [self.audioMixer connectToOutputDeviceWithID:self.playthroughDevice];
}

#pragma mark
#pragma mark First Responder Methods

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	SEL action = [menuItem action];
	
	// FILE MENU
	
	if (action == @selector(saveDocument:))
	{
		return (self.isLicensed) ? YES : NO;		
	}

	if (action == @selector(saveDocumentAs:))
	{
		return (self.isLicensed) ? YES : NO;		
	}

	if (action == @selector(saveAsTemplate:))
	{
		return (self.isLicensed) ? YES : NO;		
	}

	if (action == @selector(showExportSheet:))
	{
		return (self.licenseAllowsRecording) ? YES : NO;		
	}
	
	// LAYER MENU
	
	if (action == @selector(toggleLiveStateOfSelectedLayer:))
	{
		[menuItem setTitle:([self selectedLayerIsLive] ? NSLocalizedString(@"MenuItemTitleSwitchOffLayer", nil) : NSLocalizedString(@"MenuItemTitleSwitchOnLayer", nil))];
	}
	else if (action == @selector(toggleExpandedStateOfSelectedLayer:))
	{
		[menuItem setTitle:([self selectedLayerIsExpanded] ? NSLocalizedString(@"MenuItemTitleCollapseLayer", nil) : NSLocalizedString(@"MenuItemTitleExpandLayer", nil))];
	}
	else if (action == @selector(deleteLayers:))
	{
		return ([(NSArray *)[self.layersController arrangedObjects] count] > 1);
	}
	else if (action == @selector(selectLayerAbove:))
	{
		return [[self layersController] canSelectPrevious];
	}
	else if (action == @selector(selectLayerBelow:))
	{
		return [[self layersController] canSelectNext];
	}
	else if (action == @selector(selectPreviousSetting:))
	{
		return [[[self selectedLayer] settingsController] canSelectPrevious];
	}
	else if (action == @selector(selectNextSetting:))
	{
		return [[[self selectedLayer] settingsController] canSelectNext];
	}
	else if (action == @selector(removeSetting:))
	{
		return [[self selectedLayer] canRemoveEditSetting];
	}
	else if (action == @selector(duplicateLayer:))
	{
		return ([self selectedLayer] != nil && [self isAllowedToInsertOneMoreLayer]);
	}
	
	// SOURCE MENU
		
	// toggle source list
	if (action == @selector(showHideSources:))
	{
		if ([self sourcesVisible])
		{
			[menuItem setTitle:NSLocalizedString(@"MenuItemTitleHideSources", nil)];
		}
		else
		{
			[menuItem setTitle:NSLocalizedString(@"MenuItemTitleShowSources", nil)];
		}
		return YES;
	}
	
	if (action == @selector(addCameraSource:))
	{
		NSUInteger maxAllowedCameras = [[TVLicenseController defaultLicenseController] numberOfCamerasAllowed];
		NSUInteger installedCameraSources = [[[self sourceRepository] allBasicDeviceVideoSources] count];
		if (installedCameraSources >= maxAllowedCameras)
		{
			return NO;
		}
	}
		
	// SHOW MENU
	
	// start/stop recording
	if (action == @selector(toggleRecording:))
	{
		if (self.showController.isRolling)
		{
			[menuItem setTitle:NSLocalizedString(@"MenuItemTitleStopRecording", nil)];
		}
		else
		{
			[menuItem setTitle:NSLocalizedString(@"MenuItemTitleStartRecording", nil)];
		}
		BOOL canRecord = self.licenseAllowsRecording;
		BOOL hasCodec = (_showSettings.codec != 0);
		if (! canRecord) BXLog(@"-#-#-#-#-#-#-#- license does not allow recording");
		if (! hasCodec) BXLog(@"-#-#-#-#-#-#-#- no recording codec");
		return (canRecord && hasCodec) ? YES : NO;
	}
	
	if (action == @selector(toggleRecordsMovie:))
	{
		[menuItem setState:[self.showSettings.activeEndpointIdentifiers containsObject:[[[TVStreamDiskEndpoint currentEndpoints] lastObject] identifier]]];
		return !self.showController.isRolling;
	}

	if (action == @selector(toggleRecordsFullscreen:))
	{
		[menuItem setState:(self.showSettings.recordsFullscreen ? NSOnState : NSOffState)];
		return self.licenseAllowsFullscreen;
	}
	
	if (action == @selector(setRecordingFrameRate:))
	{
		[menuItem setState:( (self.showSettings.movieFrameRate == [menuItem tag]) ? NSOnState : NSOffState)];
	}
	
	if (action == @selector(togglePlaythrough:))
	{
		BOOL playthroughIsMuted = ([_audioMixer playthroughVolume] <= 0.);
		[menuItem setTitle: playthroughIsMuted ?
			NSLocalizedString(@"Enable Playthrough",@"Menu item title text in Action and Main menu for enabling Playthrough") :
			NSLocalizedString(@"Mute Playthrough",@"Menu item title text in Action and Main menu for muting Playthrough")];
	}
	
	if (action == @selector(toggleEnhancedOutput:))
	{
		return YES;
	}
	
	
	// SHOW MENU / SHOW ACTION POP-UP MENU
		
	if (action == @selector(toggleTimerSettings:))
	{
		return !_showController.isRolling;
	}
	
	if (action == @selector(changeVideoSize:))
	{
		BOOL currentSize = NO;
		switch ([menuItem tag])
		{
			case 320:
				currentSize = NSEqualSizes(_videoSize, NSMakeSize(320,240));
				break;
			case 640:
				currentSize = NSEqualSizes(_videoSize, NSMakeSize(640,480));
				break;
			case 1024:
				currentSize = NSEqualSizes(_videoSize, NSMakeSize(1024,768));
				break;
		}
		[menuItem setState:(currentSize ? NSOnState : NSOffState)];
		
		return !_showController.isRolling;
	}
	
	if (action == @selector(setRecordingFrameRate:))
	{
		return !_showController.isRolling;
	}
	
	if (action == @selector(setCompressionCodec:))
	{
		if (_showController.isRolling)
		{
			return NO;
		}
		
		// I assume this is quite inefficient
		//	might be better to save the index in an ivar
		//	(though that risks getting out of sync)
		CodecNameSpecListPtr list = NULL;
		OSErr error = GetCodecNameList(&list, 0);
		if (!error && list)
		{
			// find the right codec
			NSInteger index = [menuItem tag];
			[menuItem setState:(list->list[index].cType == _showSettings.codec) ? NSOnState : NSOffState];
			DisposeCodecNameList(list);
		}
		return YES;
	}
	
	if (action == @selector(setCompressionQuality:))
	{
		if (_showController.isRolling)
		{
			return NO;
		}
		
		// TODO: this if() should list all codecs we use that don't support a quality
		//	icod is the only one installed on my machine that doesn't -- nicholas.
		if (_showSettings.codec == 'icod')
		{
			[menuItem setState:([menuItem tag] == (NSInteger) codecMaxQuality) ? NSOnState : NSOffState];
			return NO;
		}
		
		CodecQ quality = _showSettings.codecQuality;
		switch (quality)
		{
			case codecLosslessQuality:
			case codecMaxQuality:
			case codecMinQuality:
			case codecLowQuality:
			case codecNormalQuality:
			case codecHighQuality:
				[menuItem setState:([menuItem tag] == (NSInteger) quality) ? NSOnState : NSOffState];
				return YES;
			
			default:
				NSAssert1(true, @"invalid codec quality %lu", quality);
				return NO;
		}
	}

	if (action == @selector(showDocumentSizeWindow:))
	{
		return !_showController.isRolling;
	}
	
	// VIEW MENU
	
	// start/stop fullscreen
	if (action == @selector(toggleFullscreen:))
	{
		if (self.fullscreenWindow)
		{
			[menuItem setTitle:NSLocalizedString(@"MenuItemTitleStopFullscreen", nil)];
		}
		else
		{
			[menuItem setTitle:NSLocalizedString(@"MenuItemTitleStartFullscreen", nil)];
		}
		return self.licenseAllowsFullscreen;
	}	
	if (action == @selector(toggleRenderingPause:))
	{
		if ([self.renderingEngine outputRenderingPaused])
		{
			[menuItem setTitle:@"Continue Rendering"];			
		}
		else
		{
			[menuItem setTitle:@"Pause Rendering"];			
		}
		
	}
	if (action == @selector(showLayerPreviewPanel:))
	{
		if (_previewPanelOpen)
		     [menuItem setTitle:@"Hide Selected Layer Window"];
		else [menuItem setTitle:@"Show Selected Layer in Window"];
		return self.licenseAllowsPreviews;		
	}
	if (action == @selector(showOutputPreviewPanel:))
	{
		if (_outputPanelOpen)
		     [menuItem setTitle:@"Hide Live Output Window"];
		else [menuItem setTitle:@"Show Live Output in Window"];
		return self.licenseAllowsPreviews;		
	}
	if (action == @selector(floatLayerPanel:))
	{
		[menuItem setState:_ibPanelController.layerPanelFloatOnTop];
		return self.licenseAllowsPreviews;
	}
	if (action == @selector(hideLayerPanelTitleBar:))
	{
		[menuItem setState:_ibPanelController.layerPanelHideTitleBar];
		return self.licenseAllowsPreviews;
	}
	if (action == @selector(floatOutputPanel:))
	{
		[menuItem setState:_ibPanelController.outputPanelFloatOnTop];
		return self.licenseAllowsPreviews;
	}
	if (action == @selector(hideOutputPanelTitleBar:))
	{
		[menuItem setState:_ibPanelController.outputPanelHideTitleBar];
		return self.licenseAllowsPreviews;
	}
		
	// title & action safe areas
	if (action == @selector(toggleActionSafeArea:))
	{
		[menuItem setState:(_actionSafeAreaEnabled ? NSOnState : NSOffState)];
	}
	
	if (action == @selector(toggleTitleSafeArea:))
	{
		[menuItem setState:(_titleSafeAreaEnabled ? NSOnState : NSOffState)];
	}
	
	// DEBUG MENU
	
	if (action == @selector(setPerformanceChart:))
	{
		NSInteger chart = _renderingEngine.performance.chart;
		switch (chart)
		{
			case 0 ... 4:
				[menuItem setState:([menuItem tag] == chart) ? NSOnState : NSOffState];
				return YES;
			
			default:
				NSAssert1(true, @"invalid performance chart %d", chart);
				return NO;
		}
	}
	
	if (action == @selector(selectLayerTriggerEvent:))
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressTriggerEventAlertMessages"])
		{
			return [self allowsLayerTriggerEventWithType:[menuItem tag] reason:nil];
		}
	}
	
	if (action == @selector(selectSettingTriggerEvent:))
	{
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SuppressTriggerEventAlertMessages"])
		{
			return [self allowsSettingTriggerEventWithType:[menuItem tag] reason:nil];
		}
	}
	// DEFAULT CASE

	return YES;
}


#pragma mark
#pragma mark Source repository notification & delegate methods

- (BOOL)sourceRepository:(TVSourceRepository *)inRepository shouldRemoveSource:(TVSource *)inSource
{
	BOOL result = YES;
	NSString *inUseLayerName = nil;
	NSString *inUseLayerSettingName = nil;
	
	if (inRepository == self.sourceRepository)
	{
		if (inSource)
		{
			for (id <TVLayerProtocol> layer in [self.layersController arrangedObjects])
			{
				NSArray *layerSettingsUsingSource = [layer layerSettingsUsingSource:inSource];
				if (layerSettingsUsingSource && [layerSettingsUsingSource count] > 0)
				{
					result = NO;
					inUseLayerName = [layer name];
					inUseLayerSettingName = [(id <TVLayerSettingProtocol>)[layerSettingsUsingSource objectAtIndex:0] name];
					BXLogInDomain(kLogDomainSources, kLogLevelWarning, @"layer settings %@ using source: %@", layerSettingsUsingSource, inSource);
				}
			}
		}
	}
	
	if (! result)
	{
		NSString *alertTitle = [NSString stringWithFormat:@"Source '%@' cannot be removed because it is in use.",[inSource name]];
		NSAlert *alert = [NSAlert alertWithMessageText: alertTitle
										 defaultButton:@"OK"
									   alternateButton:nil
										   otherButton:nil
							 informativeTextWithFormat:@"This source (%@) is in use by some layers settings, including '%@' in the layer '%@'.\n\nPlease unassign it from all layers and try again.\n", [inSource name], inUseLayerSettingName, inUseLayerName];
		[alert runModal];
	}
	
	return result;
}


//- (void)sourceRepositoryWillRemoveSource:(NSNotification *)inNotification
//{
//	
//}


//- (void)sourceRepositoryDidRemoveSource:(NSNotification *)inNotification
//{
//	
//}


#pragma mark
#pragma mark Window Handling

- (NSWindow *)mainWindow
{
	return ibMainWindow;
}


- (CGFloat)scaleForGLView:(NSOpenGLView *)view
{
	// a simple hack to get percentages
	return [view frameScaleRelativeToContentSize:_videoSize] * 100.0;
}


- (void)resizeColumnViews
{
	// idealPreviewColumnWidth is also used in windowWillUseStandardFrame: below
	CGFloat idealPreviewColumnWidth = [self getIdealPreviewColumnWidth];
	NSRect mainContentBounds = [_ibMainContentView bounds];
	
	// QC parameters column
	NSRect propertyColumnFrame = mainContentBounds;
	propertyColumnFrame.size.width = minPropertyColumnWidth;
	
	// TV layers column
	NSRect layersColumnFrame = mainContentBounds;
	layersColumnFrame.origin.x = NSMaxX(propertyColumnFrame);
	layersColumnFrame.size.width = minLayersColumnWidth;
	
	// output preview column
	NSRect previewColumnFrame = mainContentBounds;
	previewColumnFrame.origin.x = NSMaxX(layersColumnFrame);
	previewColumnFrame.size.width = idealPreviewColumnWidth;
	if (NSMaxX(previewColumnFrame) > NSMaxX(mainContentBounds))
	{
		// ideal preview width is too big, make it less than ideal
		previewColumnFrame.size.width = NSMaxX(mainContentBounds) - previewColumnFrame.origin.x;
	}
	else
	{
		// we have enough space for ideal preview width, give extra space to layer list
		previewColumnFrame.origin.x = NSMaxX(mainContentBounds) - previewColumnFrame.size.width;
		layersColumnFrame.size.width = previewColumnFrame.origin.x - layersColumnFrame.origin.x;
	}
	
	[_ibPropertyColumnView setFrame:propertyColumnFrame];
	[_ibLayerListBackgroundView setFrame:layersColumnFrame];
	[_ibMainPreviewColumnView setFrame:previewColumnFrame];
}

- (CGFloat)getIdealPreviewColumnWidth	
{
	// calculating the ideal Preview Coloum Width.
	// TODO: kPreviewColumnWidthMargin should be calculated based on the actual view coordinates
	
	CGFloat pointUnit = 1.0;
	if (NSAppKitVersionNumber > NSAppKitVersionNumber10_7)
	{
		// check for retina
		pointUnit = [ibMainWindow backingScaleFactor];
	}

	CGFloat videoSizeWidth = self.videoSize.width;
	
	// if the video frame is smaller than 720 pixels we are going to scale the video frame to 200% if on retina (see ticket #1848)
	return (videoSizeWidth < 720 ? videoSizeWidth * pointUnit : videoSizeWidth)+ kPreviewColumnWidthMargin;
}

#pragma mark
#pragma mark Window Notifications & Delegate Methods

- (NSRect)windowWillUseStandardFrame:(NSWindow *)window defaultFrame:(NSRect)maximumFrame
{
	// option-clicking the zoom button makes it fullscreen
	if ([NSApp isOptionKeyDown])
		return maximumFrame;
	
	if (window == ibMainWindow)
	{
		// calculate the ideal content width
		CGFloat idealPreviewColumnWidth = [self getIdealPreviewColumnWidth];
		NSRect contentRect = [window contentRectForFrameRect:[window frame]];
		contentRect.size.width = minPropertyColumnWidth + minLayersColumnWidth + idealPreviewColumnWidth;
		
		// constrain that to the maximum frame, adjusting the origin if it would exceed the right edge
		NSRect standardFrame = [window frameRectForContentRect:contentRect];
		standardFrame.size.width = MIN(standardFrame.size.width, maximumFrame.size.width);
		if (NSMaxX(standardFrame) > NSMaxX(maximumFrame))
			standardFrame.origin.x = NSMaxX(maximumFrame) - standardFrame.size.width;
		
		// maximise the height
		standardFrame.origin.y = maximumFrame.origin.y;
		standardFrame.size.height = maximumFrame.size.height;
		return standardFrame;
	}
	
	return maximumFrame;
}

- (void)windowDidResize:(NSNotification *)notification
{	
	id window = [notification object];
	if (window == ibMainWindow)
	{
		[self resizeColumnViews];
		[self validateUIRecordingState];
	}
}

- (void)windowDidChangeBackingProperties:(NSNotification *)notification
{
	id window = [notification object];
	if (window == ibMainWindow)
	{
		[self validateUIRecordingState];
	}
}


- (void)windowDidBecomeMain:(NSNotification *)notification
{
	#pragma unused (notification)
	self.windowIsMain = YES;
	
	// We must set the NSOpenGLContext setView selector after the windowNib is loaded to prevent
	// 'invalid drawable' logs from the NSOpenGLContext.
	// The Window is not visible in 'windowControllerDidLoadNib' and it seems that the
	// NSOpenGLContext has some problems with this
	[_outputPreviewContext setView:outputPreview];
	[_layerPreviewContext  setView:layerPreview];
}

- (void)windowDidResignMain:(NSNotification *)notification
{
	#pragma unused (notification)
	self.windowIsMain = NO;
}

- (void)windowWillClose:(NSNotification *)notification
{
	id window = [notification object];
	if (window == ibMainWindow)
	{
		_documentIsClosing = YES;
		[self cancelAllDelayedSelectors];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:TVDocumentWillCloseNotification object:self];
		[[NSNotificationCenter defaultCenter] removeObserver:self];
				
		// stop show timer
		[_showTimer invalidate];
		BXRelease(_showTimer);
		[_updateFreeSpaceTimer invalidate];
		BXRelease(_updateFreeSpaceTimer);
		[_vuMeterTimer invalidate];
		BXRelease(_vuMeterTimer);
		[_updateFreeMemoryTimer invalidate];
		BXRelease(_updateFreeMemoryTimer);
		[_performanceMeterTimer invalidate];
		BXRelease(_performanceMeterTimer);
		
		if (_debugWindowController)
		{
			[_debugWindowController cleanup];
			[_debugWindowController close];
			[_debugWindowController setTelevisionDocument:nil];
			BXRelease(_debugWindowController);
		}
		
		// close preview windows and stop fullscreen
		[self stopFullscreen];
		[_ibPanelController.outputPanel close];
		[_ibPanelController.layerPanel close];
		[_ibPanelController cleanup];
        
		[self hideOutputAudioSettingsPanel:window];
        [_audioMixer stop];

		// Stop the rendering engine
		[self stopDisplayThreads];
		[self stopRenderingEngine];
		
		// remove from KVO
		[self unregisterKVO];
		
		[[_layersController content] makeObjectsPerformSelector:@selector(cleanup) withObject:nil];
				
		_ibLiveWarningBackground = nil;// cancling all delayed requests to validatePropertiesBackground, because they will crash after this method is completly performed
		_ibPropertyColumnView = nil; 
		// This does not work with performSelectorOnMainThread:
//		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(validatePropertiesBackground) object:nil]; 
		
		[ibDocumentProxy setContent:nil];
		BXRelease(_sourceRepositoryViewController);
		
		[_showController cleanup];
		BXRelease(_showController);

		[_renderingEngine cleanup];
		BXRelease(_renderingEngine);
		
		[_sourceRepository cleanup];
		BXRelease(_sourceRepository);
		
		// releasing the file repository here already to make sure the temp file is closed
		BXRelease(_fileRepository);
		
		BXTracker *const tracker = BXTracker.sharedTracker;
		[tracker trackEvent:TVTrackEventCloseDocument];
	}
}


#pragma mark
#pragma mark RBSplitView Actions & Delegate Methods

- (IBAction)showHideSources:(id)sender
{	
#pragma unused (sender)
//	RBSplitSubview *sourcesSubview = [splitView subviewAtPosition:SOURCES_SUBVIEW_INDEX];
//	if ([sourcesSubview isCollapsed])
//	     [sourcesSubview expandWithAnimation];
//	else [sourcesSubview collapseWithAnimation];
}


- (BOOL)sourcesVisible
{
//	RBSplitSubview *sourcesSubview = [splitView subviewAtPosition:SOURCES_SUBVIEW_INDEX];
//	return ![sourcesSubview isCollapsed];
	return NO;
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(NSInteger)rowIndex
{
	// deselect all other table views
	NSTableView *tableView = aTableView;
	BOOL wasSelecting = (rowIndex != NSNotFound);
	if (wasSelecting)
	{
		for (NSTableView *layerTableView in _layerTableViews)
		{
			if (layerTableView != tableView)
			{
				[layerTableView deselectAll:nil];
			}
			else
			{
				BXLog(@"%s don't deselect scroll myself: %@", __FUNCTION__, tableView);
			}
		}
	}
	
	// show preview icon for main table view
	[_ibLayerPreviewObjectController setContent:[[[[[[tableView tableColumns] lastObject] infoForBinding:@"value"] objectForKey:NSObservedObjectKey] arrangedObjects] objectAtIndex:rowIndex]];
	
	if (wasSelecting) 
	{
		NSRect rect = [tableView rectOfRow:rowIndex];
		NSView *view = [_ibLayerListDisclosureView superview];
		[view scrollRectToVisible:[view convertRect:rect fromView:tableView]];
	}
	return YES;
}


// resizing the window should mostly resize the middle column 
- (void)willAdjustSubviews:(RBSplitView *)inSplitView
{
	RBSplitSubview *leftSubview    = [inSplitView subviewAtPosition:0];
	RBSplitSubview *centerSubview  = [inSplitView subviewAtPosition:1];
	RBSplitSubview *rightSubview   = [inSplitView subviewAtPosition:2];
	CGFloat dividerThickness = [inSplitView dividerThickness];
	NSRect frame = [inSplitView frame];
	NSRect leftFrame   = [leftSubview frame];
	NSRect centerFrame = [centerSubview frame];
	NSRect rightFrame  = [rightSubview frame];
	BOOL isCollapsed = [rightSubview isCollapsed];
	
	centerFrame.size.width = frame.size.width - 2*dividerThickness - leftFrame.size.width;
	if (!isCollapsed) centerFrame.size.width -= rightFrame.size.width;
	[centerSubview setFrame:centerFrame];
}


#pragma mark
#pragma mark Trigger Events & Hotkeys


// SRShortcutRecorder Delegate Protocol
- (BOOL)shortcutRecorder:(SRRecorderControl *)inRecorder isKeyCode:(signed short)inKeyCode andFlagsTaken:(unsigned int)inFlags reason:(NSString **)outReason
{
	if (outReason)
	{
		*outReason = nil;
	}

	BXHotkey *takenHotkey = [BXHotkey hotkeyWithKeyCode:inKeyCode andModifierFlags:inFlags];
	id <TVLayerProtocol> layer = [self selectedLayer];
	
	if (! [takenHotkey isEqualTo:[BXHotkey emptyHotkey]]) // always allow empty hotkeys
	{
		BXHotkey *layerTriggerHotkey = nil;
		NSArray *otherSettingsHotkeys = nil;
		NSDictionary *signalHotKeysDict = [layer inputTriggers];
		if (inRecorder == _ibLayerTriggerRecorder)
		{
			otherSettingsHotkeys = [[layer settings] valueForKey:@"triggerHotKey"];
		}
		else if (inRecorder == _ibSettingTriggerHotKeyRecorder)
		{
			id <TVLayerSettingProtocol> setting = [layer editSetting];
			layerTriggerHotkey = [layer trigger];
			NSMutableArray *relevantSettings = [NSMutableArray arrayWithArray:[layer settings]];
			[relevantSettings removeObject:setting];
			otherSettingsHotkeys = [relevantSettings valueForKey:@"triggerHotKey"];
		}
		else
		{
			BXLogInDomain(kLogDomainTriggers, kLogLevelError, @"Unknown shortcut recorder %@, allowing shortcut %@ for now.", inRecorder, takenHotkey);
			return NO; // unknown SRShorcutRecorder
		}
		
		if ([takenHotkey isEqualTo:layerTriggerHotkey])
		{
			if (outReason)
			{
				*outReason = NSLocalizedString(@"it's already being used as trigger by the layer and therfore it can't be used as trigger for this setting",
											   @"Shortcut was assigned to layer of this setting. (Caution it's incuded in recovery sugesstion by SRValidator)");
			}
			return YES;
		}
		
		for (BXHotkey *currentHotkey in otherSettingsHotkeys)
		{
			if ([takenHotkey isEqualTo:currentHotkey])
			{
				if (outReason)
				{
					if (inRecorder == _ibLayerTriggerRecorder)
					{
						*outReason = NSLocalizedString(@"it's already being used by a layer setting and therfore it can't be used as layer trigger",
													   @"Shortcut was assigned to a setting of this layer. (Caution it's incuded in recovery sugesstion by SRValidator)");
					}
					else if (inRecorder == _ibSettingTriggerHotKeyRecorder)
					{
						*outReason = NSLocalizedString(@"it's already being used by another layer setting and therfore it can't be used as trigger for this setting",
													   @"Shortcut was assigned to other setting of this layer. (Caution it's incuded in recovery sugesstion by SRValidator)");
					}
				}
				return YES;
			}
		}
		
		for (id signalKey in signalHotKeysDict)
		{
			BXHotkey *currentHotkey = [signalHotKeysDict objectForKey:signalKey];
			if ([takenHotkey isEqualTo:currentHotkey])
			{
				NSDictionary *attributes = nil;
				if ([layer conformsToProtocol:@protocol(QCCompositionRenderer)])
				{
					attributes = [[(TVRenderer *)layer attributes] objectForKey:signalKey];
				}
				NSString *signalName = [[layer cachedParameterView] labelStringForInputKey:signalKey attributes:[attributes objectForKey:signalKey]];
				if (outReason)
				{
					if (inRecorder == _ibLayerTriggerRecorder)
					{
						*outReason = [NSString stringWithFormat:NSLocalizedString(@"it's already being used by the layer as shortcut for %@, therfore it can't be used as layer trigger",
																				  @"Shortcut was assigned to signal of this layer (Caution it's incuded in recovery sugesstion by SRValidator)"), signalName];
					}
					else if (inRecorder == _ibSettingTriggerHotKeyRecorder)
					{
						*outReason = [NSString stringWithFormat:NSLocalizedString(@"it's already being used by the layer as shortcut for %@, therfore it can't be used as trigger for this setting",
																				  @"Shortcut was assigned to signal of enclosing layer. (Caution it's incuded in recovery sugesstion by SRValidator)"), signalName];
					}
				}
				return YES;
			}
		}
	}
	
	return NO;
}


// SRShortcutRecorder Delegate Protocol
- (void)shortcutRecorder:(SRRecorderControl *)recorder keyComboDidChange:(KeyCombo)keyCombo
{
	BXHotkey *hotkey = [BXHotkey hotkeyWithKeyCode:keyCombo.code andModifierFlags:keyCombo.flags];
	if (recorder == _ibLayerTriggerRecorder)
	{
		[[self selectedLayer] setTrigger:hotkey];
	}
	if (recorder == _ibSettingTriggerHotKeyRecorder)
	{
		[[[self selectedLayer] editSetting] setTriggerHotKey:hotkey];
	}
}


- (void)shortcutRecorder:(SRRecorderControl *)aRecorder beginsRecordingForKeyCombo:(KeyCombo)newKeyCombo
{
	#pragma unused (aRecorder, newKeyCombo)
	TVApp.handleKeyEventTrigger = NO;
}


- (void)shortcutRecorder:(SRRecorderControl *)aRecorder endsRecordingForKeyCombo:(KeyCombo)newKeyCombo
{
	#pragma unused (aRecorder, newKeyCombo)
	TVApp.handleKeyEventTrigger = YES;
}


- (BOOL)allowsLayerTriggerEventWithType:(TVTriggerEventType)inTriggerEventType reason:(NSString **)outReason
{	
	if (outReason)
		*outReason = nil;
	
	if (inTriggerEventType == TVNoneTriggerEvent) return YES; // None in popup
	
	BOOL result = YES;
	NSArray *settings = [[self selectedLayer] settings];
	for (id <TVLayerSettingProtocol> setting in settings)
	{
		TVTriggerEvent *triggerEvent = [TVTriggerEvent triggerEventForTriggerEventType:[setting triggerEvent]];
		result = result && (! [triggerEvent inSameTriggerEventGroupWithEventType:inTriggerEventType]);
		if (! result) 
		{
			if (outReason)
			{
				if (triggerEvent.eventType == inTriggerEventType)
				{
					*outReason = [NSString stringWithFormat:NSLocalizedString(@"The setting \"%@\" already uses \"%@\" as trigger.",
																			  @"Error reason if we are trying to use an event trigger thats used by a setting"), setting.name, [triggerEvent stringValue]];
				}
				else
				{
					*outReason = [NSString stringWithFormat:NSLocalizedString(@"The setting \"%@\" already uses \"%@\" The same kind of trigger can only used by either the layer or one of it's settings, but not by both.",
																			  @"Error reason if we are trying to use an event trigger thats used by a setting"), setting.name, [triggerEvent stringValue]];
				}
			}
			break;
		}
	}
	
	if (result == YES)
	{
		switch (inTriggerEventType)
		{
			case TVStartAtShowWillEnd:
			case TVStopAtShowWillEnd:
				result = [[self showSettings] hasShowEndTimerOffset];
				if (! result) 
				{
					if (outReason)
					{
						*outReason = NSLocalizedString(@"The document has no Show End Trigger set. Please select Show > Timer…, set up a Show End Trigger and try again.", @"");
					}
				}
				break;
			default:
				result = YES;
		}
	}
	return result;
}


- (IBAction)selectLayerTriggerEvent:(id)inSender
{
	if (inSender == _ibLayerTriggerEventPopup)
	{
		NSString *reason = nil;
		if ([self allowsLayerTriggerEventWithType:[[inSender selectedItem] tag] reason:&reason])
		{
			[[self selectedLayer] setTriggerEvent:[[inSender selectedItem] tag]];
		}
		else
		{
			[inSender selectItemWithTag:[self selectedLayer].triggerEvent];
			[[inSender menu] update]; // updates the selected menu item to be enabled/disabled
		}
	}
}


- (BOOL)allowsSettingTriggerEventWithType:(TVTriggerEventType)inTriggerEventType reason:(NSString **)outReason
{	
	if (outReason)
		*outReason = nil;
	
	if (inTriggerEventType == TVNoneTriggerEvent) return YES; // None in popup
	
	TVTriggerEvent *triggerEvent = [TVTriggerEvent triggerEventForTriggerEventType:[[self selectedLayer] triggerEvent]];
	if ([triggerEvent inSameTriggerEventGroupWithEventType:inTriggerEventType])
	{
		if (outReason)
		{
			if (triggerEvent.eventType == inTriggerEventType)
			{
				*outReason = [NSString stringWithFormat:NSLocalizedString(@"The layer containing this setting already uses \"%@\" as trigger. One trigger can be used either by the layer or by one of it's settings, but not by both.",
																		  @"Error reason if we are trying to use an event trigger thats used by the settings layer."), [triggerEvent stringValue]];
			}
			else
			{
				*outReason = [NSString stringWithFormat:NSLocalizedString(@"The layer containing this setting already uses \"%@\". Either the layer or one of it's settings can use the same kind of trigger, but not both.",
																		  @"Error reason if we are trying to use an event trigger thats used by the settings layer."), [triggerEvent stringValue]];
			}
		}
		return NO;
	}
	
	BOOL result = YES;
	NSArray *settings = [[self selectedLayer] settings];
	id <TVLayerSettingProtocol> editSetting = [[self selectedLayer] editSetting];
	for (id <TVLayerSettingProtocol> setting in settings)
	{
		if (setting != editSetting)
		{
			TVTriggerEvent *settingTriggerEvent = [TVTriggerEvent triggerEventForTriggerEventType:[setting triggerEvent]];
			result = result && (! [settingTriggerEvent inSameTriggerEventGroupWithEventType:inTriggerEventType]);
			if (! result) 
			{
				if (outReason)
				{
					if (settingTriggerEvent.eventType == inTriggerEventType)
					{
						*outReason = [NSString stringWithFormat:NSLocalizedString(@"The setting named \"%@\" already uses \"%@\" as trigger. Only one setting of a layer can be triggered at one time.",
																				  @"Error reason if we are trying to use an event trigger thats used by a setting"), setting.name, [settingTriggerEvent stringValue]];
					}
					else
					{
						*outReason = [NSString stringWithFormat:NSLocalizedString(@"The setting named \"%@\" already uses \"%@\" as trigger. Only one setting of a layer can use the same kind of trigger.",
																				  @"Error reason if we are trying to use an event trigger thats used by a setting"), setting.name, [settingTriggerEvent stringValue]];
					}
				}
				break;
			}
		}
	}
	
	if (result == YES)
	{
		switch (inTriggerEventType)
		{
			case TVStartAtShowWillEnd:
			case TVStopAtShowWillEnd:
				result = [[self showSettings] hasShowEndTimerOffset];
				if (! result) 
				{
					if (outReason)
					{
						*outReason = NSLocalizedString(@"The document has no Show End Trigger set. Please select Show > Timer\u2026, set up a Show End Trigger and try again.", @"");
					}
				}
				break;
			default:
				result = YES;
		}
	}
	return result;
}


- (IBAction)selectSettingTriggerEvent:(id)inSender
{
	if (inSender == _ibSettingTriggerEventPopup)
	{
		NSString *reason = nil;
		if ([self allowsSettingTriggerEventWithType:[[inSender selectedItem] tag] reason:&reason])
		{
			[[[self selectedLayer] editSetting] setTriggerEvent:[[inSender selectedItem] tag]];
		}
		else
		{
			[inSender selectItemWithTag:[[self selectedLayer] editSetting].triggerEvent];
			[[inSender menu] update]; // updates the selected menu item to be enabled/disabled
		}
	}
}


- (BOOL)performTriggerEvent:(TVTriggerEvent *)inEvent
{
	BOOL result = NO;
	
	NSUInteger modifierFlags = inEvent.representedEvent.modifierFlags;
	if ((modifierFlags & NSAlternateKeyMask) && (modifierFlags & NSCommandKeyMask)
		&& ([[inEvent.representedEvent charactersIgnoringModifiers] isEqualToString:@"f"]))
	{
		[self focusSearchField:inEvent];
		return YES;
	}
	
	NSRecursiveLock *manipulationLock = [self layersManipulationLock];
	NSArray *layers = nil;
	
	[manipulationLock lock];
	@try
	{
		layers = self.layers;	
		BXLogInDomain(kLogDomainTriggers, kLogLevelVerbose, @"%s <%p> - Document handling trigger event: %@", __FUNCTION__, self, inEvent);		
		for (TVVideoLayer *layer in layers)
		{
			result = [layer performTriggerEvent:inEvent] || result;
		}
	}
	@finally
	{
		[manipulationLock unlock];
	}
	return result;
}


#pragma mark
#pragma mark Alerts

- (BOOL)displayAlertDocument:(NSString *)filePath savedByFutureVersion:(NSString *)applicationVersion
{
	// this is called from two places, one that checks the document version number and one that checks the version of the app that saved it
	//	for now, these two cases both display the same error, which is why it's in a seperete method
	
	NSString *filename = [[NSFileManager defaultManager] displayNameAtPath:filePath];
	NSString *description = [NSString stringWithFormat:NSLocalizedStringFromTable(@"DocumentMinorVersionNewerDescription", @"Errors", nil), filename, applicationVersion];
	NSString *suggestion = NSLocalizedStringFromTable(@"DocumentMinorVersionNewerRecoverySuggestion", @"Errors", nil);
	NSArray *buttons = [NSArray arrayWithObjects:
		NSLocalizedStringFromTable(@"DocumentMinorVersionNewerRecoveryOptionContinue", @"Errors", nil),
		NSLocalizedStringFromTable(@"DocumentMinorVersionNewerRecoveryOptionCancel", @"Errors", nil),
		NSLocalizedStringFromTable(@"DocumentMinorVersionNewerRecoveryOptionUpdate", @"Errors", nil),
		nil];
	NSError *error = [NSError errorWithDomain:BoinxTVErrorDomain code:documentMinorVersionTooHigh userInfo:
		[NSDictionary dictionaryWithObjectsAndKeys:
			description, NSLocalizedDescriptionKey,
			suggestion, NSLocalizedRecoverySuggestionErrorKey,
			buttons, NSLocalizedRecoveryOptionsErrorKey,
			filePath, NSFilePathErrorKey,
			nil]];
	NSAlert *alert = [NSAlert alertWithError:error];
	NSInteger returnCode = [alert runModal];	// this runs modally because (a) we don't have a document yet, and (b) there is already a sheet open on the Template Chooser window
	switch (returnCode)
	{
		case NSAlertFirstButtonReturn:
			// continue
			return YES;
		case NSAlertSecondButtonReturn:
			// abort
			return NO;
		case NSAlertThirdButtonReturn:
		{
			// software update
			Class SoftwareUpdater = NSClassFromString(@"SUUpdater");
			[[SoftwareUpdater sharedUpdater] checkForUpdates:self];
			return NO;
		}
		default:
			// unexpected return code received, log it and try to open the document anyway
			BXLog(@"unexpected return code %d received from -[NSAlert runModal] for error %@", returnCode, error);
			return YES;
	}
}

#pragma mark
#pragma mark Audio settings panel


- (BOOL)isOutputAudioSettingsPanelVisible
{
	return self.outputAudioSettingsPanel.isVisible;
}


- (IBAction)toggleOutputAudioSettingsPanel:(id)sender
{
	if (self.isOutputAudioSettingsPanelVisible)
	{
		[self hideOutputAudioSettingsPanel:sender];
	}
	else
	{
		[self showOutputAudioSettingsPanel:sender];
	}
}


- (IBAction)showOutputAudioSettingsPanel:(id)sender
{
	if (! self.isOutputAudioSettingsPanelVisible)
	{
		NSView *enhanceUnitView = [TVAudioGraph viewForAudioUnit:self.audioMixer.enhanceUnit withSize:NSMakeSize(150.0, 150.0)];
		if (enhanceUnitView)
		{
			NSPanel *audioSettingsPanel = [[NSPanel alloc] initWithContentRect:[enhanceUnitView frame]
																	 styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSUnifiedTitleAndToolbarWindowMask
																	   backing:NSBackingStoreBuffered
																		 defer:YES];
			
			[[audioSettingsPanel contentView] setAutoresizesSubviews:NO];
			[[audioSettingsPanel contentView] addSubview:enhanceUnitView positioned:NSWindowAbove relativeTo:nil];
			[audioSettingsPanel setBecomesKeyOnlyIfNeeded:YES];
			[audioSettingsPanel setTitle:@"Audio Enhancement Settings"];
			[audioSettingsPanel setFrameAutosaveName:@"AudioOutputSettingsWindowFrame"];
			
			if ([audioSettingsPanel setFrameUsingName:@"AudioOutputSettingsWindowFrame" force:YES] == NO)
			{
				[audioSettingsPanel center];
			}
			else
			{
				// after restoring the old window frame we may have the issue that audio unit view details where expanded tha last time the window got closed.
				NSRect oldWindowFrame = audioSettingsPanel.frame;
				NSRect windowFrame = [NSWindow frameRectForContentRect:[enhanceUnitView frame]
															 styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSUnifiedTitleAndToolbarWindowMask];
				
				if (! NSEqualSizes(oldWindowFrame.size, windowFrame.size)) // the frame sizes changed
				{
					windowFrame.origin = oldWindowFrame.origin;
					windowFrame.origin.y = oldWindowFrame.origin.y + (oldWindowFrame.size.height - windowFrame.size.height);
					
					[audioSettingsPanel setFrame:windowFrame display:YES]; // so set the current view frame size...
				}
			}

			// register for frame changed notifications to react on detail expansion of audio unit view
			[enhanceUnitView setPostsFrameChangedNotifications:YES];
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(audioSettingsViewFrameDidChange:)
														 name:NSViewFrameDidChangeNotification
													   object:enhanceUnitView];
			
			self.outputAudioSettingsPanel = audioSettingsPanel;

			[audioSettingsPanel makeKeyAndOrderFront:sender];
			[audioSettingsPanel release];
		}
	}
	else
	{
		[self.outputAudioSettingsPanel makeKeyAndOrderFront:sender];
	}
}


- (IBAction)hideOutputAudioSettingsPanel:(id)sender
{
	NSPanel *audioSettingsPanel = self.outputAudioSettingsPanel;
	if (audioSettingsPanel != nil)
	{
		[audioSettingsPanel orderOut:sender];
		[audioSettingsPanel close];
		self.outputAudioSettingsPanel = nil;
	}
}


- (void)audioSettingsViewFrameDidChange:(NSNotification *)inNotification
{
	NSView *view = (NSView *)[inNotification object];
	
	if (view)
	{
		[view setPostsFrameChangedNotifications:NO]; // disable frame notifications while updating window size to avoid recursive calls to this method
		{
			NSRect oldWindowFrame = self.outputAudioSettingsPanel.frame;
			NSRect windowFrame = [NSWindow frameRectForContentRect:[view frame]
														 styleMask:NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSUnifiedTitleAndToolbarWindowMask];
			windowFrame.origin = oldWindowFrame.origin;
			windowFrame.origin.y = windowFrame.origin.y + (oldWindowFrame.size.height - windowFrame.size.height);
			
			[self.outputAudioSettingsPanel setFrame:windowFrame display:YES animate:NO]; // animation flickers
		}
		[view setPostsFrameChangedNotifications:YES];
	}
}


#pragma mark
#pragma mark IB Actions


- (void)relayoutPropertyColumn
{
	NSRect totalFrame = _ibPropertyColumnView.frame;
	
	[NSAnimationContext beginGrouping];
	// preview Frame
	NSButton *button = _ibLayerPreviewContainerView.button;
	NSRect previewFrame = totalFrame;
	previewFrame.size.height = button.state == NSOnState ? [_ibLayerPreviewContainerView maxHeight] : [_ibLayerPreviewContainerView minHeight];
	previewFrame.origin.y = NSMaxY(totalFrame)-previewFrame.size.height;
	[[_ibLayerPreviewContainerView animator] setFrame:previewFrame];
	
	// trigger frame
	button = _ibTriggerContainerView.button;
	NSRect triggerFrame = _ibTriggerContainerView.frame;
	triggerFrame.size.height = button.state == NSOnState ? [_ibTriggerContainerView maxHeight] : [_ibTriggerContainerView minHeight];
	triggerFrame.origin.y = NSMinY(previewFrame)-triggerFrame.size.height;
	[[_ibTriggerContainerView animator] setFrame:triggerFrame];

	// rest of the parameterview
	totalFrame.size.height -= NSHeight(triggerFrame) + NSHeight(previewFrame);
	[[_ibParameterViewEnclosingScrollView animator] setFrame:totalFrame];

	[NSAnimationContext endGrouping];
}

- (IBAction)togglePreviewCollapse:(id)inSender
{
	// using the button state as the data model - not ideal
	NSButton *button = _ibLayerPreviewContainerView.button;
	if (inSender != button)
	{
		[button setState:button.state == NSOnState ? NSOffState : NSOnState];
	}
	[self relayoutPropertyColumn];
}

- (IBAction)toggleTriggerCollapse:(id)inSender
{
	// using the button state as the data model - not ideal
	NSButton *button = _ibTriggerContainerView.button;
	if (inSender != button)
	{
		[button setState:button.state == NSOnState ? NSOffState : NSOnState];
	}
	[self relayoutPropertyColumn];
}


- (void)saveAsTemplate:(id)sender
{
#pragma unused (sender)
	
	TVSaveAsTemplateController *controller = [[TVSaveAsTemplateController alloc] initWithWindowNibName:@"SaveAsTemplate"];
	if (!controller) return;
	
	// do some hacky stuff needed because the controller both *is* the save panel, and maintains the accessory view
	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	NSString *summary = [self.templateMetadata objectForKey:@"summary"];
	if (!(summary && [summary length]))
	{
		// create default summary
		[_layersManipulationLock lock];
		NSUInteger layerCount = [self.layers count];
		NSString *defaultSummary = [[[NSString alloc] initWithFormat:@"%u Layer%s", layerCount, (layerCount == 1) ? "" : "s"] autorelease];
		[_layersManipulationLock unlock];
		summary = defaultSummary;
	}
	[info setValue:summary forKey:@"summary"];


	NSString *description = [self.templateMetadata objectForKey:@"description"];	
	if (!(description && [description length]))
	{
		// create default description
		[_layersManipulationLock lock];
		NSUInteger layerCount = [self.layers count], settingCount;
		NSMutableString *defaultDescription = [[[NSMutableString alloc] initWithFormat:@"%u Layer%s: ", layerCount, (layerCount == 1) ? "" : "s"] autorelease];
		for (id <TVLayerProtocol> layer in self.layers)
		{
			settingCount = [[layer settings] count];
			if (settingCount == 1)
			     [defaultDescription appendFormat:@"%@, ", [layer name]];
			else [defaultDescription appendFormat:@"%@ (%u settings), ", [layer name], settingCount];
		}
		[_layersManipulationLock unlock];
		[defaultDescription deleteCharactersInRange:NSMakeRange([defaultDescription length] - 2, 2)];
		description = defaultDescription;
	}
	[info setValue:description forKey:@"description"];
	
	if (_preview)
	{
		[info setObject:_preview forKey:@"preview"];
	}
	
	[controller setAccessoryInfo:info];
	
	// display the save sheet
	NSWindow *sheet = [controller window];
	NSWindow *docWindow = [self windowForSheet];
	SEL didEnd = @selector(saveAsTemplateSheetDidEnd:returnCode:contextInfo:);
	[NSApp beginSheet:sheet modalForWindow:docWindow modalDelegate:self didEndSelector:didEnd contextInfo:(void *)controller];
}


- (void)saveAsTemplateSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet orderOut:nil];
	
	if (returnCode == NSOKButton)
	{
		// get the data from the accessory view, and save it to ivars read by -[self dictionaryRepresentation]
		TVSaveAsTemplateController *controller = (TVSaveAsTemplateController *)contextInfo;
		NSDictionary *info = [controller accessoryInfo];
		[self.templateMetadata setValue:[info valueForKey:@"summary"] forKey:@"summary"];
		[self.templateMetadata setValue:[info valueForKey:@"description"] forKey:@"description"];
		// TODO: make and use an accessor - also save the original filedata somehow
		[_preview autorelease];
		_preview = [[info valueForKey:@"preview"] retain];
		
		// write out the file
		NSError *error = nil;
		self.savingTemplate = YES;
		BOOL success = [self writeToURL:[controller URL] ofType:TVDocumentTypeShow forSaveOperation:NSSaveToOperation originalContentsURL:[self fileURL] error:&error];
		if (!success)
		{
			[[TVErrorController sharedErrorController] displayError:error suppressionKey:@"SaveAsTemplate" modalForDocument:self];
		}
		self.savingTemplate = NO;
	}
}

- (IBAction)toggleRecording:(id)sender
{
#pragma unused (sender)
	
	NSError *error = nil;
	NSString *suppressionKey = nil;
	
	BXTracker *const tracker = BXTracker.sharedTracker;
	
	if ([[TVLicenseController defaultLicenseController] allowsRecording])
	{
		if (self.showController.isRolling)
		{
			[self.showController stopRecording];
			NSTimeInterval recordingDuration = [[NSDate date] timeIntervalSinceDate:self.recordingDate];
			[tracker trackEvent:TVTrackEventStopRecording label:TVTrackLabelRecordingTime withValue:floor(recordingDuration)];
		}
		else
		{
			if (_showSettings.codec)
			{
				error = [self.showController startRecording];
				
				if (error == nil)
				{
					// recording started successfully
					[tracker trackEvent:TVTrackEventStartRecording label:TVTrackLabelNumberOfLayers withValue:self.layers.count];
					self.recordingDate = [NSDate date];
				}
			}
			else
			{
				BXLogInDomain(kLogDomainRecording, kLogLevelError, @"The user somehow managed to call -toggleRecording: when the recording codec was 0x0");
				NSString *description = @"The selected recording format was invalid.";
				NSString *suggestion = @"Select a different codec from the Recording Format submenu of the Show menu.";
				error = [NSError errorWithDomain:BoinxTVErrorDomain code:codecMissing userInfo:
					[NSDictionary dictionaryWithObjectsAndKeys:
						description, NSLocalizedDescriptionKey,
						suggestion, NSLocalizedRecoverySuggestionErrorKey,
						nil]];
				suppressionKey = @"InvalidRecordingCodec";
			}
		}
	}
	
	if (error)
	{
		id document = self;
		if (([error domain] == BoinxTVErrorDomain) && ([error code] == stillPostProcessing))
			document = nil;
		
		[_ibRecordButton setState:NSOffState];
		[[TVErrorController sharedErrorController] displayError:error suppressionKey:suppressionKey modalForDocument:document];
	}
}


- (void)setCompressionQuality:(id)sender
{
	if (_showController.isRolling)
		return;
	
	CodecQ quality = (CodecQ)[(NSControl *)sender tag];
	NSParameterAssert(quality == codecLosslessQuality || quality == codecMaxQuality || quality == codecMinQuality ||
	                  quality == codecLowQuality || quality == codecNormalQuality || quality == codecHighQuality);
	_showSettings.codecQuality = quality;
}


- (void)setCompressionCodec:(id)sender
{
	if (_showController.isRolling)
		return;
	
	CodecNameSpecListPtr list = NULL;
	OSErr error = GetCodecNameList(&list, 0);
	if (!error && list)
	{
		// set the codec of the document
		NSInteger index = [(NSControl *)sender tag];
		[self setCodecValue:[NSNumber numberWithUnsignedInt:list->list[index].cType]];
		DisposeCodecNameList(list);
		
		BXLogInDomain(kLogDomainRecording, kLogLevelDebug, @"now using codec [%@]", QTStringForOSType(_showSettings.codec));
	}
}


- (void)setCodecValue:(NSNumber *)value
{
	[[self undoManager] registerUndoWithTarget:self	selector:@selector(setCodecValue:) object:[NSNumber numberWithUnsignedInt:_showSettings.codec]];
	[[self undoManager] setActionName:NSLocalizedString(@"UndoActionChangeRecordingFormat",nil)];
	_showSettings.codec = [value unsignedIntValue];
}


- (void)toggleActionSafeArea:(id)sender
{
#pragma unused (sender)
	_actionSafeAreaEnabled = !_actionSafeAreaEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:_actionSafeAreaEnabled forKey:@"ShowActionSafeArea"];
}


- (void)toggleTitleSafeArea:(id)sender
{
#pragma unused (sender)
	_titleSafeAreaEnabled = !_titleSafeAreaEnabled;
	[[NSUserDefaults standardUserDefaults] setBool:_titleSafeAreaEnabled forKey:@"ShowTitleSafeArea"];
}


- (IBAction)showSettingsSheet:(id)sender
{
#pragma unused (sender)
	
	// create the sheet controller. It will be retained as long as the sheet is open...
	TVDocumentSettingsController *controller = [[TVDocumentSettingsController alloc] initWithWindowNibName:@"TVDocumentSettings"];
	if (!controller) return;
	
	NSMutableDictionary *metadataCopy = [self.metadata mutableCopy];
	if (!metadataCopy)
	{
		metadataCopy = [[NSMutableDictionary alloc] init];
	}
	if (metadataCopy)
	{
		controller.metadata = metadataCopy;
		[metadataCopy release];
	}

	// display the save sheet
	NSWindow *sheet = [controller window];
	NSWindow *docWindow = [self windowForSheet];
	SEL didEnd = @selector(documentSettingsSheetDidEnd:returnCode:contextInfo:);
	[NSApp beginSheet:sheet modalForWindow:docWindow modalDelegate:self didEndSelector:didEnd contextInfo:(void *)controller];
}

- (void)documentSettingsSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
#pragma unused (contextInfo)
	[sheet retain];
	[sheet orderOut:nil];
	
	if (returnCode == NSOKButton)
	{
		// copy metadata to document
		NSMutableDictionary *metadataCopy = [[[sheet windowController] metadata] mutableCopy];
		if (metadataCopy)
		{
			if (![self.metadata isEqualToDictionary:metadataCopy])
			{
				self.metadata = metadataCopy;
				[self updateChangeCount:NSChangeDone];
			}
			[metadataCopy release];
		}
	}
	[sheet release];
}

- (void)showExportSheet:(id)sender
{
#pragma unused (sender)
	[self showExportSheetForFilename:self.filename];
}

- (void)showExportSheetForFilename:(NSString *)inFilename
{
	if (inFilename != nil) {
		self.filename = inFilename;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"TVShowExportSheet" object:nil userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
																										 self, @"document",
																										 [NSNumber numberWithBool:YES], @"ignoreDefaults",
																										 nil]];
}

- (void)exportSheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
#pragma unused (returnCode, contextInfo)
	[sheet orderOut:nil];
	[self.renderingEngine unpausePreviewRendering];
	[self.renderingEngine unpauseOutputRendering];
}

- (IBAction)toggleTimerSettings:(id)inSender
{
#pragma unused (inSender)
	if(_ibShowTimeLCDView)
    {
        NSRect showTimeLCDFrame = [_ibShowTimeLCDView frame];
        NSPoint attachPoint = NSMakePoint(NSMidX(showTimeLCDFrame)+1, NSMidY(showTimeLCDFrame));
        [[BalloonController sharedController] displayBalloon:_ibTimerSettingsView
                                             attachedToPoint:attachPoint
                                                      inView:[_ibShowTimeLCDView superview]
                                                  identifier:[self className]
                                                    delegate:self
                                                    autoHide:NO];
    }
}


- (IBAction)focusSearchField:(id)inSender
{
#pragma unused (inSender)
	if (self.repositoryVisibility == 1) // layers
	{
		[_layerTemplateFilterViewController focusSearchField];
	}
	else if (self.repositoryVisibility == 2) // sources
	{
		 [_sourceRepositoryViewController focusSearchField];
	}
	else // closed 
	{
		self.repositoryVisibility = 1; // open layers
		[_layerTemplateFilterViewController focusSearchField];
	}
}	


- (IBAction)toggleLayerRepositoryAction:(id)inSender
{
#pragma unused (inSender)
	[self setRepositoryVisibility:(_repositoryVisiblityState == 1) ? 0 : 1];
}


- (IBAction)toggleSourceRepositoryAction:(id)inSender
{
#pragma unused (inSender)
	[self setRepositoryVisibility:(_repositoryVisiblityState == 2) ? 0 : 2];
}

- (IBAction)makeLayerContainerViewFirstResponder:(id)inSender 
{
#pragma unused (inSender)
	[[_ibMainContentView window] makeFirstResponder:_ibLayerContainerView];
}

- (void)performSetRepositoryVisibility:(NSNumber *)inNumber
{
	[self setRepositoryVisibility:[inNumber intValue]];
}

- (int)repositoryVisibility
{
	return _repositoryVisiblityState;
}

- (void)setRepositoryVisibility:(int)inValue
{
	if (inValue != _repositoryVisiblityState)
	{
		// hide the quicklook panel if open
		if (inValue != 2)
		{
			if (NSAppKitVersionNumber >= NSAppKitVersionNumber10_6)
			{
				[TVApp.quickLookLock lock];
				{
					if ([[QLPreviewPanelClass sharedPreviewPanel] currentController] &&
						[[QLPreviewPanelClass sharedPreviewPanel] dataSource] == (id)self.sourceRepositoryViewController)
					{
						if ([[QLPreviewPanelClass sharedPreviewPanel] currentController] && [[QLPreviewPanelClass sharedPreviewPanel] dataSource] == (id)self.sourceRepositoryViewController)
						{
							// set the delegate to nil so that it fades instead of zooms out
							[[QLPreviewPanelClass sharedPreviewPanel] setDelegate:nil];
							[[QLPreviewPanelClass sharedPreviewPanel] setDataSource:nil];
							[[QLPreviewPanelClass sharedPreviewPanel] close];
						}
					}
				}
				[TVApp.quickLookLock unlock];
			}
			else
			{
				BXQuickLookController *qlController = [BXQuickLookController sharedController];
				if ([qlController isOpen])
				{
					[qlController toggle:nil];
				}
			}
		}
		
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.2];
		double animationDelay = 0.0;
		
		if (_repositoryVisiblityState == 0)
		{
			// animate in either the layer or the sources view
			id viewController = _layerTemplateFilterViewController;
			if (inValue == 2) viewController = _sourceRepositoryViewController;

			NSView *viewToRollIn = [viewController view];
			CGFloat desiredHeight = [viewController desiredHeight];
			NSRect splitViewFrame    = [_ibMainContentView frame];
			NSRect rollInViewFrame   = [viewToRollIn frame];
			rollInViewFrame.size.height = desiredHeight;
			[viewToRollIn setHidden:NO];
			[[viewToRollIn animator] setFrame:rollInViewFrame];
			splitViewFrame.size.height = NSMaxY(splitViewFrame) - NSMaxY(rollInViewFrame);
			splitViewFrame.origin.y    = NSMaxY(rollInViewFrame);
			[[_ibMainContentView animator] setFrame:splitViewFrame];
			animationDelay = [[NSAnimationContext currentContext] duration] + 0.25;
		} 
		else if (inValue == 0)
		{
			id viewController = _layerTemplateFilterViewController;
			if (_repositoryVisiblityState == 2) viewController = _sourceRepositoryViewController;

			// animate out either the layer or the sources view
			NSView *viewToRollOut = [viewController view];
			NSRect splitViewFrame    = [_ibMainContentView frame];
			NSRect rollOutViewFrame  = [viewToRollOut frame];
			rollOutViewFrame.size.height = 0;
			[[viewToRollOut animator] setFrame:rollOutViewFrame];
			splitViewFrame.size.height = NSMaxY(splitViewFrame) - NSMaxY(rollOutViewFrame);
			splitViewFrame.origin.y    = NSMaxY(rollOutViewFrame);
			[[_ibMainContentView animator] setFrame:splitViewFrame];
			// roll out the current view
		}
		else
		{
			// exchange the two views
			id sourceViewController = _layerTemplateFilterViewController;
			id targetViewController = _sourceRepositoryViewController;
			if (_repositoryVisiblityState == 2) 
			{
				sourceViewController = _sourceRepositoryViewController;
				targetViewController = _layerTemplateFilterViewController;
			}
			NSView *sourceView = [sourceViewController view];
			NSView *targetView = [targetViewController view];
			
			targetView.frame = sourceView.frame;
			[sourceView setHidden:YES];
			[targetView setHidden:NO ];
			
			NSRect zeroHeightFrame = sourceView.frame;
			zeroHeightFrame.size.height = 0;
			sourceView.frame = zeroHeightFrame;
			
			NSRect desiredFrame = targetView.frame;
			CGFloat desiredHeight = [targetViewController desiredHeight];
			if (desiredHeight != desiredFrame.size.height)
			{
				desiredFrame.size.height = desiredHeight;
				NSRect splitViewFrame    = [_ibMainContentView frame];
				[[targetView animator] setFrame:desiredFrame];
				splitViewFrame.size.height = NSMaxY(splitViewFrame) - NSMaxY(desiredFrame);
				splitViewFrame.origin.y    = NSMaxY(desiredFrame);
				[[_ibMainContentView animator] setFrame:splitViewFrame];
			}
		}
		
		_repositoryVisiblityState = inValue;
		// update UI
		[_ibSegmentedRepositoryVisiblityStateControl  selectExactlyThisSegment:_repositoryVisiblityState-1];

		[NSAnimationContext endGrouping];

		NSWindow *window = [_ibMainContentView window];
		[window recalculateKeyViewLoop];
		if (_repositoryVisiblityState != 0)
		{
			id controller = _sourceRepositoryViewController;
			if (_repositoryVisiblityState == 1)
				controller = _layerTemplateFilterViewController;
			[window makeFirstResponder:[controller initialFirstResponder]];
		}
		else
		{
			id firstResponder = [window firstResponder];
			if ([firstResponder isKindOfClass:[NSView class]]) {
				if ([self viewShouldBeExcludedFromKeyLoop:firstResponder]) {
					[window makeFirstResponder:_ibLayerContainerView];
				}
			}
			else
			{
				[window makeFirstResponder:firstResponder];
			}
		}
		if (_repositoryVisiblityState == 1)
		{
			[_layerTemplateRepository performSelector:@selector(lazyLoad) withObject:nil afterDelay:0.2 + animationDelay];
		}
		else if (_repositoryVisiblityState == 2)
		{
			[_sourceRepository performSelector:@selector(lazyLoad) withObject:nil afterDelay:0.2 + animationDelay];
		}
	}
	[[self mainWindow] recalculateKeyViewLoop];
}

- (BOOL)viewShouldBeExcludedFromKeyLoop:(NSView *)aView 
{
	if ( ([aView isDescendantOf:[_layerTemplateFilterViewController view]] && 
		  _repositoryVisiblityState != 1) ||
		 ([aView isDescendantOf:[_sourceRepositoryViewController    view]] &&
		   _repositoryVisiblityState != 2) ) 
	{
		return YES;
	}
	return NO;
}


- (IBAction)repositoryVisibilitySegmentedControlAction:(id)inSender
{
	int selectedState = [inSender selectedSegment] + 1;
	if (selectedState == _repositoryVisiblityState)
	{
		[self setRepositoryVisibility:0];
	}
	else
	{
		[self setRepositoryVisibility:selectedState];
	}
}


- (IBAction)toggleLayerGroupView:(id)inSender
{
	if (inSender != _ibShowHideLayersButton) {
		[_ibShowHideLayersButton setState:([_ibShowHideLayersButton state] == NSOnState) ? NSOffState : NSOnState];
	}
	NSView *categoryView = [_sourceRepositoryViewController view];
	CGFloat desiredHeight = _sourceRepositoryViewController.desiredHeight;
	NSRect splitViewFrame = [_ibMainContentView frame];
	NSRect categoryViewFrame = [categoryView frame];
	if ([_ibShowHideLayersButton state] == NSOnState)
	{
		categoryViewFrame.size.height = desiredHeight;
		[categoryView setHidden:NO];
		[[categoryView animator] setFrame:categoryViewFrame];
	}
	else
	{
		categoryViewFrame.size.height = 0;
		[[categoryView animator] setFrame:categoryViewFrame];
	}
	splitViewFrame.size.height = NSMaxY(splitViewFrame) - NSMaxY(categoryViewFrame);
	splitViewFrame.origin.y    = NSMaxY(categoryViewFrame);
	[[_ibMainContentView animator] setFrame:splitViewFrame];
}

- (IBAction)setMasterVolume:(id)inSender
{
    double volume = [(NSControl *)inSender doubleValue] - 1.0;
    volume = - volume*volume + 1; // make volume sliders ease out
    [self.audioMixer setOutputVolume:volume];
}

- (void)validateButtonStates
{
	BOOL playthroughIsMuted = [_audioMixer playthroughVolume] <= 0.0;
	if (playthroughIsMuted) 
	{
		[_ibPlaythroughActionButton setImage:[NSImage imageNamed:@"ToolbarPlaythroughButton_Off"]];
		[_ibPlaythroughActionButton setAlternateImage:[NSImage imageNamed:@"ToolbarPlaythroughButton_Off_Pressed"]];
	}
	else
	{
		[_ibPlaythroughActionButton setImage:[NSImage imageNamed:@"ToolbarPlaythroughButton_On"]];
		[_ibPlaythroughActionButton setAlternateImage:[NSImage imageNamed:@"ToolbarPlaythroughButton_On_Pressed"]];
	}
	
}

- (void)togglePlaythrough:(id)inSender
{
#pragma unused (inSender)
	BOOL playthroughIsMuted = [_audioMixer playthroughVolume] <= 0.0;
	[_audioMixer setPlaythroughVolume: playthroughIsMuted ? 1.0 : 0.0];
	[self validateButtonStates];
}

- (void)toggleEnhancedOutput:(id)inSender
{
#pragma unused (inSender)
	BOOL outputIsEnhanced = [_audioMixer outputIsEnhanced];
	[_audioMixer enhanceOutput:!outputIsEnhanced];
	[self validateButtonStates];
    [[[_ibPlaythroughActionButton pullDownMenu] itemWithTag:42] setState:([_audioMixer outputIsEnhanced] ? NSOnState : NSOffState)];
}


- (void)changeVideoSize:(id)sender
{
	if (_showController.isRolling)
		return;
	
	switch ([(NSControl *)sender tag])
	{
		case 320:
			[self resizeVideo:[NSValue valueWithSize:NSMakeSize(320,240)]];
			break;
		case 640:
			[self resizeVideo:[NSValue valueWithSize:NSMakeSize(640,480)]];
			break;
		case 1024:
			[self resizeVideo:[NSValue valueWithSize:NSMakeSize(1024,768)]];
			break;
	}
}


#pragma mark Source Menu


- (IBAction)addSource:(id)inSender
{
	// display open dialog
	NSArray *allowedFileTypes = [TVSource supportedUTITypes];
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setTreatsFilePackagesAsDirectories:YES];
	[panel setAllowsMultipleSelection:YES];
	[panel setMessage:NSLocalizedString(@"AddMediaSourcePanelMessage", nil)];
	[panel setPrompt:NSLocalizedString(@"AddMediaSourcePanelDefaultButton", nil)];
	[panel setAllowedFileTypes:allowedFileTypes];
	[panel beginSheetModalForWindow:[self windowForSheet]
				  completionHandler:^(NSInteger result)
	 {
		 if (result == NSOKButton)
		 {
			 NSArray *fileURLs = [panel URLs];
			 NSMutableDictionary *contextDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
												 fileURLs, @"fileURLs",
												 nil];
			 if (inSender)
			 {
				 [contextDict setObject:inSender forKey:@"sender"];
			 }
			 [self performSelector:@selector(addMediaSourcesForURLsAsync:) withObject:contextDict afterDelay:0.0];
		 }
		 else if (result == NSCancelButton)
		 {
			 SEL didCancelSelector = @selector(documentDidCancelAddingSources:);
			 if (inSender && [inSender respondsToSelector:didCancelSelector])
			 {
				 [inSender documentDidCancelAddingSources:self];
			 }
		 }
	 }];
}


- (void)addMediaSourcesForURLsAsync:(NSDictionary *)inContextDict
{
	if (inContextDict)
	{
		NSArray *fileURLs = [inContextDict objectForKey:@"fileURLs"];
		id sender = [inContextDict objectForKey:@"sender"];
					 
		NSArray *addedMediaSources = [self.sourceRepository addSources:fileURLs];
		if (sender && [sender respondsToSelector:@selector(document:didAddSources:)]) 
		{
			[sender document:self didAddSources:addedMediaSources];
		}
	}
}


- (IBAction)addCameraSource:(id)inSender
{
#pragma unused (inSender)
	[self setRepositoryVisibility:2]; // make sure the source repository is open
	[self.sourceRepository addCameraSource];
}


- (IBAction)addScreenCaptureSource:(id)inSender
{
#pragma unused (inSender)
	[self setRepositoryVisibility:2]; // make sure the source repository is open
	[self.sourceRepository addScreenCaptureSource];
}


- (IBAction)addAudioSource:(id)inSender
{
#pragma unused (inSender)
	[self setRepositoryVisibility:2]; // make sure the source repository is open
	[self.sourceRepository addAudioSource];
}



#pragma mark Show Menu


- (IBAction)toggleRecordsMovie:(id)inSender
{
#pragma unused (inSender)
	[self toggleStreamingForEndpoint:[[TVStreamDiskEndpoint currentEndpoints] lastObject]];
}


- (IBAction)toggleRecordsFullscreen:(id)inSender
{
#pragma unused (inSender)
	self.showSettings.recordsFullscreen = !self.showSettings.recordsFullscreen;
}


- (void)setRecordingFrameRateToNumber:(NSNumber *)newValue
{
	NSNumber *oldValue = [NSNumber numberWithInteger:self.showSettings.movieFrameRate];
	NSInteger frameRate = [newValue integerValue];
	self.showSettings.movieFrameRate = frameRate;
	// now also setting output and preview render frame rate
	self.showSettings.displayFrameRate = frameRate;
	self.showSettings.previewFrameRate = frameRate * 0.5; // set it to half of the output frame rate
	[[self undoManager] registerUndoWithTarget:self selector:@selector(setRecordingFrameRateToNumber:) object:oldValue];
	[[self undoManager] setActionName:NSLocalizedString(@"UndoActionFrameRateChange",nil)];
}


- (void)setRecordingFrameRate:(id)sender
{
	if (_showController.isRolling)
		return;
	
	if ([sender respondsToSelector:@selector(tag)])
	{
		[self setRecordingFrameRateToNumber:[NSNumber numberWithInteger:[(NSControl *)sender tag]]];
	}
}


- (void)showDocumentSizeWindow:(id)sender
{
#pragma unused (sender)
	
	// read in the movie presets data into a temporary ivar
	_moviePresets = [TVMoviePresetUtilities copyMoviePresets];
	
#if 1
	// save the current size information to a dictionary for the popup action method to use
	_templateData = [[NSDictionary alloc] initWithObjectsAndKeys:CFINT(_videoSize.width), @"width", CFINT(_videoSize.height), @"height", nil];
#else
	// prepare information about the template this document was created with
	if (_templateURL)
	{
		NSMutableDictionary *templateData = [NSMutableDictionary dictionary];
		NSString *plistPath = [[_templateURL path] stringByAppendingPathComponent:TVDocumentPropertyList];
		NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
		id sizeDictionary = [plist valueForKeyPath:@"documentState.renderingVideoSize"];
		if (sizeDictionary && [sizeDictionary isKindOfClass:[NSDictionary class]])
		{
			id pixelDimension = [sizeDictionary valueForKey:@"pixelWidth"];
			if ([pixelDimension isKindOfClass:[NSNumber class]])
			{
				[templateData setObject:pixelDimension forKey:@"width"];
			
				pixelDimension = [sizeDictionary valueForKey:@"pixelHeight"];
				if ([pixelDimension isKindOfClass:[NSNumber class]])
				{
					[templateData setObject:pixelDimension forKey:@"height"];
					_templateData = [templateData retain];
				}
			}
		}
	}
#endif
	
	if (!_ibDocumentSizeView || !_ibDocumentSizePopUp)
	{
		[NSBundle loadNibNamed:@"DocumentSizePanel" owner:self];
	}
	[TVMoviePresetUtilities populatePopUp:_ibDocumentSizePopUp withMoviePresets:_moviePresets isDocument:YES];
	[TVMoviePresetUtilities validatePopUp:_ibDocumentSizePopUp forMoviePresets:_moviePresets];
	[self willChangeValueForKey:@"customSize"];
//	[_ibDocumentSizePopUp selectItemAtIndex:kMoviePresetMenuItemIndexCurrentSize];
	[self setValue:[NSNumber numberWithInt:kMoviePresetMenuItemIndexCurrentSize] forKey:@"documentSizePopUpIndex"];
	[self didChangeValueForKey:@"customSize"];
	[self addObserver:self forKeyPath:@"documentSizePopUpIndex" options:0 context:TVDocumentObservingContextDocumentSizePopUpIndexChanged];
	
	[_ibDocumentSizeWidthField setIntegerValue:_videoSize.width];
	[_ibDocumentSizeHeightField setIntegerValue:_videoSize.height];
	
	NSRect showTimeLCDFrame = [_ibShowTimeLCDView frame];
	NSPoint attachPoint = NSMakePoint(NSMidX(showTimeLCDFrame)+1, NSMidY(showTimeLCDFrame));
	[[BalloonController sharedController] displayBalloon:_ibDocumentSizeView attachedToPoint:attachPoint inView:[_ibShowTimeLCDView superview] identifier:@"document.videoSize" delegate:nil autoHide:NO];
}

#pragma mark View Menu

- (IBAction)showLayerPreviewPanel:(id)sender
{
#pragma unused (sender)
	if ([[TVLicenseController defaultLicenseController] allowsPreview])
	{
		self.layerPanelOpen = !_previewPanelOpen;
	}
}

- (IBAction)showOutputPreviewPanel:(id)sender
{
#pragma unused (sender)
	if ([[TVLicenseController defaultLicenseController] allowsPreview])
	{
		self.outputPanelOpen = !_outputPanelOpen;
	}
}

- (void)floatLayerPanel:(id)sender
{
	id panel = _ibPanelController.layerPanel;
	if (panel)
	{
		[panel floatWindow:sender];
		[_ibPanelController updateState];
	}
	else
	{
		_ibPanelController.layerPanelFloatOnTop = !_ibPanelController.layerPanelFloatOnTop;
	}
}

- (void)floatOutputPanel:(id)sender
{
	id panel = _ibPanelController.outputPanel;
	if (panel)
	{
		[panel floatWindow:sender];
		[_ibPanelController updateState];
	}
	else
	{
		_ibPanelController.outputPanelFloatOnTop = !_ibPanelController.outputPanelFloatOnTop;
	}
}

- (void)hideLayerPanelTitleBar:(id)sender
{
	id panel = _ibPanelController.layerPanel;
	if (panel)
	{
		[panel hideTitleBar:sender];
		[_ibPanelController updateState];
	}
	else
	{
		_ibPanelController.layerPanelHideTitleBar = !_ibPanelController.layerPanelHideTitleBar;
	}
}

- (void)hideOutputPanelTitleBar:(id)sender
{
	id panel = _ibPanelController.outputPanel;
	if (panel)
	{
		[panel hideTitleBar:sender];
		[_ibPanelController updateState];
	}
	else
	{
		_ibPanelController.outputPanelHideTitleBar = !_ibPanelController.outputPanelHideTitleBar;
	}
}


#pragma mark Others

- (void)controlTextDidChange:(NSNotification *)notification
{
	NSTextField *field = [notification object];
	if (field == _ibDocumentSizeWidthField || field == _ibDocumentSizeHeightField)
	{
		NSError *widthError = nil, *heightError = nil;
		NSUInteger width = (unsigned) [_ibDocumentSizeWidthField integerValue];
		NSUInteger height = (unsigned) [_ibDocumentSizeHeightField integerValue];
		[TVMoviePresetUtilities validateWidth:width error:&widthError];
		[TVMoviePresetUtilities validateHeight:height error:&heightError];
		if (widthError)
		     self.resizeError = widthError;
		else self.resizeError = heightError;
	}
}

- (void)updateWidthAndHeightFields
{
	NSUInteger width = 0;
	NSUInteger height = 0;
	[TVMoviePresetUtilities moviePresetWidth:&width height:&height frameRate:NULL fromPopUpSelection:_ibDocumentSizePopUp withMoviePresets:_moviePresets basedOnTemplate:_templateData];
	if (width != 0 && height != 0)
	{
		// apply the values from the selected preset to the text fields
		[_ibDocumentSizeWidthField setIntegerValue:width];
		[_ibDocumentSizeHeightField setIntegerValue:height];
		
		// check the validity of the entered values
		NSError *widthError = nil, *heightError = nil;
		[TVMoviePresetUtilities validateWidth:width error:&widthError];
		[TVMoviePresetUtilities validateHeight:height error:&heightError];
		if (widthError)
		     self.resizeError = widthError;
		else self.resizeError = heightError;
	}
	else
	{
		BXLog(@"Could not get all the values needed in updateWidthAndHeightFields (width = %u; height = %u)", width, height);
	}
}

- (void)hideDocumentSizeWindow:(id)sender
{
	if ([(NSControl *)sender tag] == NSOKButton)
	{
		NSUInteger width = [_ibDocumentSizeWidthField integerValue];
		NSUInteger height = [_ibDocumentSizeHeightField integerValue];
		if (width != 0 && height != 0)
		{
			[self resizeVideo:[NSValue valueWithSize:NSMakeSize(width,height)]];
		}
		else
		{
			BXLog(@"Could not get all the values needed in hideDocumentSizeWindow: (width = %u; height = %u)", width, height);
		}
		
		BXRelease(_templateData);
		BXRelease(_moviePresets);
	}
	[self removeObserver:self forKeyPath:@"documentSizePopUpIndex"];
	[[BalloonController sharedController] hideBalloon];
}

+ (NSSet *)keyPathsForValuesAffectingCustomSize
{
	return [NSSet setWithObject:@"documentSizePopUpIndex"];
}


- (BOOL)customSize
{
	// width and height text field enabled state is bound to this key
	return [TVMoviePresetUtilities popUpSelectionRepresentsCustomSize:_ibDocumentSizePopUp];
}

- (IBAction)showDocumentDebugWindow:(id)inSender
{
#pragma unused (inSender)
	
//	[[_debugWindowController window] setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];
	[_debugWindowController showWindow:inSender];
}


- (IBAction)toggleStreaming:(id)sender
{
	id <TVStreamEndpoint> endpoint = [sender representedObject];
	[self toggleStreamingForEndpoint:endpoint];
}


- (void)toggleStreamingForEndpoint:(id <TVStreamEndpoint>)endpoint
{
	if (_renderingEngine)
	{
		if (endpoint && [endpoint conformsToProtocol:@protocol(TVStreamEndpoint)])
		{
			if (! [self.showSettings.activeEndpointIdentifiers containsObject:endpoint.identifier])
			{
				NSMutableSet *newEndpoints = [self.showSettings.activeEndpointIdentifiers mutableCopy];
				[newEndpoints addObject:endpoint.identifier];
				self.showSettings.activeEndpointIdentifiers = [newEndpoints autorelease];
			}
			else
			{
				NSMutableSet *newEndpoints = [self.showSettings.activeEndpointIdentifiers mutableCopy];
				[newEndpoints removeObject:endpoint.identifier];
				self.showSettings.activeEndpointIdentifiers = [newEndpoints autorelease];
			}
		}
	}
}


- (IBAction)disableStreaming:(id)sender
{
#pragma unused (sender)
	if (_renderingEngine)
	{
		self.showSettings.activeEndpointIdentifiers = [NSSet set];
	}
}


#pragma mark Full Screen

- (void)prepareFullscreen
{
	if ([[TVLicenseController defaultLicenseController] allowsFullscreen])
	{
		id <BXFullscreen> fullscreenController = (id <BXFullscreen>) NSApp;
		
		BOOL displayAvailable = NO;
		CGDisplayCount displayCount;
		CGDirectDisplayID activeDisplayIDs[100];
		CGDirectDisplayID fullscreenDisplayID = [fullscreenController fullscreenDisplayID];
		CGDisplayErr error = CGGetActiveDisplayList(100, activeDisplayIDs, &displayCount);
		if (error)
		{
			BXLog(@"Hey, we got a really scary error, I couldn't get the active list of displays before going into fullscreen mode.");
			return;
		}
		
		for (unsigned i = 0; i < displayCount; i++)
		{
			if (activeDisplayIDs[i] == fullscreenDisplayID)
			{
				displayAvailable = YES;
				break;
			}
		}
		
		if (displayAvailable && ![NSApp isOptionKeyDown])
		{
			[self openFullscreen];
		}
		else
		{
			NSBundle *appBundle = [NSBundle mainBundle];
			if (appBundle)
			{
				unichar code = 27;
				NSString *esc = [NSString stringWithCharacters:&code length:1];
				NSString *ok = NSLocalizedStringWithDefaultValue(@"FullscreenConfigureButtonOK", nil, appBundle, @"MISSING_LOCALISATION_OK", nil);
				NSString *cancel = NSLocalizedStringWithDefaultValue(@"FullscreenConfigureButtonCancel", nil, appBundle, @"MISSING_LOCALISATION_CANCEL", nil);
				if (_fullscreenPrefs)
				{
					[_fullscreenPrefs release];
					_fullscreenPrefs = nil;
				}
				_fullscreenPrefs = [[TVPrefsFullscreen alloc] init];
				
				if (_fullscreenPrefs)
				{
					[ibFullscreenButton setState:NSOffState];
					
					BXSheetController *controller = [[BXSheetController alloc] init];
					[controller window];
					[controller setDocument:nil];
					[controller setDelegate:self]; // FIXME: the delgate will release instance
					[controller setDatasource:self];
					[controller addButtonWithTitle:ok keyEquivalent:@"\r" tag:NSOKButton offset:20.0];
					[controller addButtonWithTitle:cancel keyEquivalent:esc tag:NSCancelButton offset:12.0];
					[controller showSheetForParentWindow:[self windowForSheet] modal:YES];
				}
			}
		}
	}
}

- (void)toggleFullscreen:(id)sender
{
#pragma unused (sender)
	if ([[TVLicenseController defaultLicenseController] allowsFullscreen])
	{
		if (self.fullscreenWindow)
		{
			 [self stopFullscreen];
		}
		else
		{
			[self prepareFullscreen];
		}
	}
}

- (void)startFullscreen
{
	NSArray *orderedDocuments = [NSApp orderedDocuments];
	for(TVDocument *document in orderedDocuments)
	{
		[document stopFullscreen];
	}
    
	if ([[TVLicenseController defaultLicenseController] allowsFullscreen])
	{
		CGDirectDisplayID fullscreenDisplayID = [(id <BXFullscreen>)NSApp fullscreenDisplayID];
		
        // ensure fresh context
		_fullscreenContextConfigured = NO;
        self.fullscreenOpenGLView = [TVOpenGLView viewWithSharedContext:nil forDocument:self];
		self.fullscreenWindow = [TVFullscreenWindow fullscreenWindowForCGDisplayID:fullscreenDisplayID
																   withContentView:self.fullscreenOpenGLView
																	   contentSize:self.videoSize];
        self.fullscreenWindow.fullscreenDelegate = self;
        [self.fullscreenOpenGLView reshape];
        
		self.fullscreenWindow.hideCurserOverWindow = YES;
		[self.fullscreenWindow orderFront:self];
		
		// Startup the rendering of the Fullscreen preview
		[NSThread detachNewThreadSelector:@selector(renderFullscreenInThread) toTarget:self withObject:nil];
		
		[ibFullscreenButton setToolTip:NSLocalizedString(@"ToolbarItemToolTipStopFullscreen", nil)];
		[ibFullscreenButton setState:NSOnState];
	}
}


- (void)stopFullscreen
{
	_fullscreenThreadShouldStop = YES;	
	//self.fullscreenWindow = nil;
    if(self.fullscreenWindow)
    {
        [_fullscreenWindow release];
        _fullscreenWindow = nil;
    }

	if ([[TVLicenseController defaultLicenseController] allowsFullscreen])
	{
		[ibFullscreenButton setToolTip:NSLocalizedString(@"ToolbarItemToolTipStartFullscreen", nil)];
		[ibFullscreenButton setState:NSOffState];
	}
}


- (IBAction)openFullscreen
{
	// don't know why exactly but the BXSheetController is trashing our current context
	// at the callback time so we must start the next selector async to prevent loosing of
	// the main thread context
	[self performSelectorOnMainThread:@selector(startFullscreen) withObject:nil waitUntilDone:NO];
}


#pragma mark - TVFullscreenWindowDelegate

- (void)fullscreenWindow:(TVFullscreenWindow*)fullscreenWindow willMoveFromDisplayID:(CGDirectDisplayID)fromDisplayID toDisplayID:(CGDirectDisplayID)toDisplayID
{
#pragma unused(fullscreenWindow, fromDisplayID, toDisplayID)
    [self stopFullscreen];
}

- (void)fullscreenWindow:(TVFullscreenWindow*)fullscreenWindow willChangeDisplayConfiguration:(CGDirectDisplayID)displayID
{
#pragma unused(fullscreenWindow, displayID)
    [self stopFullscreen];
}

- (void)licenseListDidChange:(NSNotification *)inNotification
{
#pragma unused (inNotification)
	TVLicenseController *tempLicenseController = [TVLicenseController defaultLicenseController];

	self.isLicensed = [tempLicenseController isLicensed];
	self.licenseAllowsRecording = [tempLicenseController allowsRecording];
	self.licenseAllowsPreviews = [tempLicenseController allowsPreview];
	self.licenseAllowsFullscreen = [tempLicenseController allowsFullscreen];
	self.licenseIsSponsoredVersion = [tempLicenseController needsSponsoringCredit];
	
	NSImage *boinxImage = nil;
#ifdef BETA
#ifdef IS_SEEDING
	boinxImage = [NSImage imageNamed:@"tb_boinxtv-beta"];
#else
	boinxImage = [NSImage imageNamed:@"tb_boinxtv-beta"];
#endif
#else
	if ([tempLicenseController needsDemoOverlay])
	{
		boinxImage = [NSImage imageNamed:@"tb_boinxtv-demo"];
	}
	else if ([tempLicenseController isLicensedForOption:HOME])
	{
		boinxImage = [NSImage imageNamed:@"tb_boinxtv-home"];
	}
	else if (self.licenseIsSponsoredVersion)
	{
		boinxImage = [NSImage imageNamed:@"tb_boinxtv-sponsored"];
	}
	else if (self.isLicensed)
	{
		boinxImage = [NSImage imageNamed:@"tb_boinxtv-full"];
	}
	else
	{
		boinxImage = [NSImage imageNamed:@"tb_boinxtv-unlicensed"];
	}
	[_ibBoinxTVButton setAlternateImage:boinxImage];
#endif
	[_ibBoinxTVButton setImage:boinxImage];
	
	[self _installOrRemoveBuyNowView:[tempLicenseController needsDemoOverlay]];
}

#pragma mark -
#pragma mark BXSheetController Data Source Protocol

- (unsigned int)numberOfPanes
{
	return 1;
}

- (NSString *)identifierAtIndex:(unsigned int)index
{
#pragma unused (index)
	return @"TVPrefsFullscreen";
}

- (NSString *)toolbarNameAtIndex:(unsigned int)index
{
#pragma unused (index)
	return [_fullscreenPrefs paneName];
}

- (NSImage *)toolbarIconAtIndex:(unsigned int)index
{
#pragma unused (index)
	return [_fullscreenPrefs paneIcon];
}

- (NSString *)toolbarTooltipAtIndex:(unsigned int)index
{
#pragma unused (index)
	return [_fullscreenPrefs paneToolTip];
}

- (NSView *)paneViewAtIndex:(unsigned int)index
{
#pragma unused (index)
	return [_fullscreenPrefs paneView];
}

- (void)sheetController:(BXSheetController *)controller willShowSheet:(NSWindow *)sheet
{
#pragma unused (sheet)
	[controller retain];
}

- (void)sheetController:(BXSheetController *)controller didHideSheet:(NSWindow *)sheet withButton:(int)button
{
#pragma unused (sheet)
	[controller autorelease];
	if (button == NSOKButton)
	{
		// persist Display id
		CGDirectDisplayID fullscreenDisplayID = _fullscreenPrefs.selectedDisplayID;
		[(id <BXFullscreen>)NSApp setFullscreenDisplayID:fullscreenDisplayID];
		
		[self openFullscreen];
	}
}

#pragma mark -
#pragma mark sources

- (void)loadLayerTemplates
{
	// create directories
	NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	for (NSString *path in [domains objectEnumerator])
	{
		path = [path stringByAppendingPathComponent:SupportFolderLayersPathComponent];
		if(![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil])
			[[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
	}
	
	// get all the fixed paths where layer templates reside
	NSMutableArray *paths = [[[NSMutableArray alloc] init] autorelease];
	domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
	for (NSString *path in [domains objectEnumerator])
		[paths addObject:[path stringByAppendingPathComponent:SupportFolderLayersPathComponent]];
	// add path for build-in layers
	[paths addObject:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:AppBundleLayersPathComponent]];
	
	// iterate through that list looking for compositions
	NSFileManager *fileManager = [NSFileManager defaultManager];
	for (NSString *path in [paths reverseObjectEnumerator])
	{
		for (NSString *file in [fileManager enumeratorAtPath:path])
		{
			NSString *filePath = [path stringByAppendingPathComponent:file];
			
			if ( ([[filePath pathExtension] isEqualToString:@"qtz"]) || ([[filePath pathExtension] isEqualToString:@"tvlayer"]) )
			{
				// test if the filePath is a "bookmark" or "alias" (Note: 10.6-only-code!)
				NSData *bookmarkData = [NSURL bookmarkDataWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:nil];
			 
				if(bookmarkData != nil){
					// this is a "bookmark" or "alias", so we are going to resolve it
					NSURL *newURL = [NSURL URLByResolvingBookmarkData:bookmarkData options:0 relativeToURL:nil bookmarkDataIsStale:NO error:nil];
					filePath = [newURL path];
				}
			 
				[_layerTemplateRepository addTemplateAtURL:[NSURL fileURLWithPath:filePath isDirectory:NO]];
			}
		}
	}
	
	[_layerTemplateRepository addTemplate:[TVLayerTemplate audioOnlyLayerTemplate]];
	[_layerTemplateRepository.templatesController rearrangeObjects];
}

#pragma mark -
#pragma mark progress information

- (void)fileRepository:(TVFileRepository *)inRepository currentAddingProgress:(float)inProgress 
{
#pragma unused (inRepository, inProgress)
//	NSLog(@"%s %f",__FUNCTION__,inProgress);
}

- (void)compositionRepository:(TVCompositionRepository *)inRepository currentAddingProgress:(float)inProgress 
{
#pragma unused (inRepository, inProgress)
//	NSLog(@"%s %f",__FUNCTION__,inProgress);
}

#pragma mark progress display
- (void)indeterminateProgressDisplayRetain
{
//	NSLog(@"%s %d",__FUNCTION__,_progressRetainCount);
	if (_progressRetainCount++ == 0)
	{
		[_ibProgressBackgroundView setHidden:NO];
		[_ibOverlayProgressIndicator startAnimation:nil];
		[_ibProgressBackgroundView display];
	}
}

- (void)indeterminateProgressDisplayRelease 
{
	if (--_progressRetainCount == 0) 
	{
		[_ibProgressBackgroundView setHidden:YES];
		[_ibOverlayProgressIndicator stopAnimation:nil];
	}
//	NSLog(@"%s %d",__FUNCTION__,_progressRetainCount);
}



// Extended Demo
- (IBAction)removeOverlay:(id)inSender
{
#pragma unused (inSender)
	
	id delegate = [NSApp delegate];
	
	
	if ([delegate respondsToSelector:@selector(showExtendedDemoAssistant:)])
	{
		[delegate performSelector:@selector(showExtendedDemoAssistant:) withObject:self];
	}
	else
	{
		BXLogInDomain(kLogDomainMisc, kLogLevelDebug, @"Missing implementation of method 'showExtendedDemoAssistant' in class %@", NSStringFromClass([delegate class]));
	}

}


- (void)_installOrRemoveBuyNowView:(BOOL)install
{
	NSButton *closeButton = [ibMainWindow standardWindowButton:NSWindowCloseButton];
	NSView *view = [closeButton superview];
	if (! install)
	{
		if ([_ibRemoveOverlayView superview] == view)
		{
			[_ibRemoveOverlayView removeFromSuperview];
		}
	}
	else
	{
		NSRect viewBounds = [view bounds];
		NSRect buttonFrame = [_ibRemoveOverlayView frame];
		buttonFrame.origin.x = viewBounds.size.width - buttonFrame.size.width - 3;
		buttonFrame.origin.y = viewBounds.size.height - buttonFrame.size.height; // - 3;
		[_ibRemoveOverlayView setFrame:buttonFrame];
		//	[_actionButton setShowsBorderOnlyWhileMouseInside:YES];
		[view addSubview:_ibRemoveOverlayView];
	}
}


#pragma mark -
#pragma mark Revert to saved state

- (BOOL)revertToContentsOfURL:(NSURL *)inAbsoluteURL ofType:(NSString *)inTypeName error:(NSError **)outError
{
	[self unregisterKVO];
	[_layers removeAllObjects];

    BOOL result = [super revertToContentsOfURL:inAbsoluteURL ofType:inTypeName error:outError];
	[self registerKVO];
	
	return result;
}

@end

