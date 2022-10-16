JsOsaDAS1.001.00bplist00�Vscript_5ObjC.import('CoreFoundation');
ObjC.import('AppKit');

function seescriptsettings() {
	return {
		displayName: 'Encode as HTML/XML Hex'
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
  
    let changedTextObj = $(someText).mutableCopy
    if ($.CFStringTransform(changedTextObj, undefined, $.kCFStringTransformToXMLHex, false)) {
      if (hasSelection) {
        document.selection().contents = changedTextObj.js
      } else {
        document.contents = changedTextObj.js
      }
    } else {
      $.NSBeep()
    }
  } catch (e) {
    app.displayAlert('An error occured', { 
      message: `${e.message} (line: ${e.line})`, 
      as: 'critical',
      button: 'OK'
    })
  }
}
                              K jscr  ��ޭ