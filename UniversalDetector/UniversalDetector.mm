#import "UniversalDetector.h"

#import "nscore.h"
#import "nsUniversalDetector.h"
#import "nsCharSetProber.h"

class wrappedUniversalDetector:public nsUniversalDetector
{
	public:
	void Report(const char* aCharset) {}

	const char *charset(float &confidence)
	{
		if(!mGotData)
		{
			confidence=0;
			return 0;
		}

		if(mDetectedCharset)
		{
			confidence=1;
			return mDetectedCharset;
		}

		switch(mInputState)
		{
			case eHighbyte:
			{
				float proberConfidence;
				float maxProberConfidence = (float)0.0;
				PRInt32 maxProber = 0;

				for (PRInt32 i = 0; i < NUM_OF_CHARSET_PROBERS; i++)
				{
					proberConfidence = mCharSetProbers[i]->GetConfidence();
					if (proberConfidence > maxProberConfidence)
					{
						maxProberConfidence = proberConfidence;
						maxProber = i;
					}
				}

				confidence=maxProberConfidence;
				return mCharSetProbers[maxProber]->GetCharSetName();
			}
			break;

			case ePureAscii:
				confidence=0;
				return "US-ASCII";
		}

		confidence=0;
		return 0;
	}

	bool done()
	{
		if(mDetectedCharset) return true;
		return false;
	}

	void reset() { Reset(); }
};



@implementation UniversalDetector

-(id)init
{
	if(self=[super init])
	{
		detectorptr=(void *)new wrappedUniversalDetector;
		charset=nil;
	}
	return self;
}

-(void)dealloc
{
	delete (wrappedUniversalDetector *)detectorptr;
	[charset release];
	[super dealloc];
}

-(void)analyzeData:(NSData *)data
{
	[self analyzeBytes:(const char *)[data bytes] length:[data length]];
}

-(void)analyzeBytes:(const char *)data length:(int)len
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;

	if(detector->done()) return;

	detector->HandleData(data,len);
	[charset release];
	charset=nil;
}

-(void)reset
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
	detector->reset();
}

-(BOOL)done
{
	wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
	return detector->done()?YES:NO;
}

-(NSString *)MIMECharset
{
	if(!charset)
	{
		wrappedUniversalDetector *detector=(wrappedUniversalDetector *)detectorptr;
		const char *cstr=detector->charset(confidence);
		if(!cstr) return nil;
		charset=[[NSString alloc] initWithUTF8String:cstr];
	}
	return charset;
}

-(NSStringEncoding)encoding
{
	NSString *mimecharset=[self MIMECharset];
	if(!mimecharset) return 0;
	CFStringEncoding cfenc=CFStringConvertIANACharSetNameToEncoding((CFStringRef)mimecharset);
	if(cfenc==kCFStringEncodingInvalidId) return 0;
	return CFStringConvertEncodingToNSStringEncoding(cfenc);
}

-(float)confidence
{
	if(!charset) [self MIMECharset];
	return confidence;
}

+(UniversalDetector *)detector
{
	return [[[UniversalDetector alloc] init] autorelease];
}

@end
