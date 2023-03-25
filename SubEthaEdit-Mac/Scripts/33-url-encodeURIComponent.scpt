JsOsaDAS1.001.00bplist00�Vscript_\function seescriptsettings() {
	return {
		displayName: 'Encode as URI component',
		inContextMenu: 'yes'
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
		let changedText = encodeURIComponent(someText)
		if (hasSelection) {
			document.selection().contents = changedText
		} else {
			document.contents = changedText
		}
	} catch (e) {
    app.displayAlert('An error occured', { 
      message: `${e.message} (line: ${e.line})`, 
      as: 'critical',
      button: 'OK'
    })
	}
}

                              rjscr  ��ޭ