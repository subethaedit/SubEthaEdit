JsOsaDAS1.001.00bplist00�Vscript_VObjC.import('Foundation')

function seescriptsettings() {
	return {
		displayName: 'Decode Base64'
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
    let hasSelection = (see.selection()?.contents()?.length > 0)
    let someText;
    if (hasSelection) {
      someText = see.selection().contents()
    } else {
      someText = document.contents()
    }
  
    let changedTextData = $.NSData.alloc.initWithBase64EncodedStringOptions($(someText), 0)
    
    if (!changedTextData.isNil()) {
      let changedTextObj = $.NSString.alloc.initWithDataEncoding(changedTextData, $.NSUTF8StringEncoding)
    
      if (hasSelection) {
        document.selection().contents = changedTextObj.js
      } else {
        document.contents = changedTextObj.js
      }
    }
  } catch (e) {
    app.displayAlert('An error occured', { 
      message: `${e.message} (line: ${e.line})`, 
      as: 'critical',
      button: 'OK'
    })
  }
}
                              ljscr  ��ޭ