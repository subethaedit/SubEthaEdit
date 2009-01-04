/* Definition of TextEdit-specific error domain and codes for NSError.
*/
#define TextEditErrorDomain @"com.apple.TextEdit"

enum {
    TextEditSaveErrorConvertedDocument = 1,
    TextEditSaveErrorLossyDocument = 2,
    TextEditSaveErrorRTFDRequired = 3, 
    TextEditSaveErrorEncodingInapplicable = 4,
    TextEditSaveErrorCouldNotCreateDocument = 5,
    TextEditOpenDocumentWithSelectionServiceFailed = 100,
    TextEditInvalidLineSpecification = 200,
    TextEditOutOfRangeLineSpecification = 201
};


