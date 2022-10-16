JsOsaDAS1.001.00bplist00�Vscript_�ObjC.import('Foundation')

function seescriptsettings() {
	return {
		displayName: 'Encode as Base64'
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
    
    let textDataObj = $(someText).dataUsingEncoding($.NSUTF8StringEncoding)
    let changedTextObj = textDataObj.base64EncodedStringWithOptions(0)
    if (hasSelection) {
      document.selection().contents = changedTextObj.js
    } else {
      document.contents = changedTextObj.js
    }
  } catch (e) {
    app.displayAlert('An error occured', { 
      message: `${e.message} (line: ${e.line})`, 
      as: 'critical',
      button: 'OK'
    })
  }
}
                               jscr  ��ޭ