JsOsaDAS1.001.00bplist00�Vscript_�ObjC.import('Foundation')

function seescriptsettings() {
	return {
		displayName: 'Prettify JSON'
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
    var error = $()
    let JSONObj = $.NSJSONSerialization
      .JSONObjectWithDataOptionsError(
        textDataObj, 
        $.NSJSONReadingAllowFragments, 
        error
      )
    
    if (!JSONObj.isNil()) {
      let changedTextData = $.NSJSONSerialization
        .dataWithJSONObjectOptionsError(
          JSONObj, 
          $.NSJSONWritingPrettyPrinted|$.NSJSONWritingFragmentsAllowed|$.NSJSONWritingWithoutEscapingSlashes, 
          undefined
        )
      let changedTextObj = $.NSString.alloc.initWithDataEncoding(changedTextData, $.NSUTF8StringEncoding)
    
      if (hasSelection) {
        document.selection().contents = changedTextObj.js
      } else {
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
                              �jscr  ��ޭ