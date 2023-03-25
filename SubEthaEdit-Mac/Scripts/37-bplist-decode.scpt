JsOsaDAS1.001.00bplist00�Vscript_�ObjC.import('AppKit')

function seescriptsettings() {
	return {
		displayName: 'Decode Binary Plist'
	}
}

function run() {
	let see = Application('SubEthaEdit')
	let app = Application.currentApplication()
	app.includeStandardAdditions = true

	if (see.documents.length == 0) {
		return
	}

  try {
    let document = see.documents[0]
		let file = document.file()
		let content = document.contents()
    let encoding = $.CFStringConvertEncodingToNSStringEncoding(
      $.CFStringConvertIANACharSetNameToEncoding($(document.encoding()))
    )
		let textDataObj = $(content).dataUsingEncoding(encoding)

    var error = $()
    var format = Ref()
    var plistObj = $.NSPropertyListSerialization
      .propertyListWithDataOptionsFormatError(textDataObj, 0, format, error)

    // fallback to reading file from disk
    if (plistObj.isNil() && file != null) {
      let filePath = file.toString()
      let textDataObj = $.NSData.dataWithContentsOfFile(filePath)
      plistObj = $.NSPropertyListSerialization
        .propertyListWithDataOptionsFormatError(textDataObj, 0, format, undefined)
    }
    
    if (!plistObj.isNil()) {
      if (format[0] == $.NSPropertyListBinaryFormat_v1_0) {
        plistXMLData = $.NSPropertyListSerialization
          .dataWithPropertyListFormatOptionsError(
            plistObj, 
            $.NSPropertyListXMLFormat_v1_0, 
            0, 
            undefined
          )
        let changedTextObj = $.NSString.alloc.initWithDataEncoding(plistXMLData, $.NSUTF8StringEncoding)    
        document.contents = changedTextObj.js
      }
    } else {
      app.displayAlert(error.localizedDescription.js, { 
        message: error.localizedFailureReason.js ?? '', 
        as: 'critical',
        button: 'OK'
      })
    }
  } catch (e) {
    app.displayAlert('An error occured', { 
      message: `${e.message} (line: ${e.line})`, 
      as: 'critical',
      button: 'OK'
    })
  }
}
                              �jscr  ��ޭ