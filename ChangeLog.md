### [unreleased] SubEthaEdit 5.2

#### Features:
* 

#### Bug fixes and maintenance:
* Modernised search and replace user interface
* Modernised preference user interface
* Fixed layout issues in web preview
* Fixed issue where the split view icon could disappear

#### Improved modes:
* 


### SubEthaEdit 5.1.7

#### Bug fixes and maintenance:
* Fixed an accidential de-map of the find next/previous shortcut in v5.1.6

Special thanks to ellduin [GitHub](https://github.com/ellduin) for catching this early

### SubEthaEdit 5.1.6

#### Bug fixes and maintenance:
* Modernised the document hub
* Modernised open URL popover
* Fixed crashing issue when connecting to manual addresses or see urls
* Fixed issue with printing and multiple pages on macOS 11
* Moved selection of the current highlighted entity from triple to 4 clicks, keeping double and triple click more in line with the system behavior

#### Improved modes:
* Fixed wrong highlight of default in python mode

Special thanks to new contributor Jan Cornelissen - [GitHub](https://github.com/jncn)

### SubEthaEdit 5.1.5

#### Features:
* Support for future macOS Releases.
* Support for Apple Silicon.

#### Bug fixes and maintenance:
* Increased size limit for default syntax highlighting.
* Add Change Log to Help menu.
* Updated the certificate the see-tool installer is signed with (App Store).

### SubEthaEdit 5.1.4

#### Features:
* New Option: Show inconsistent indentations - easily see mixed use of tabs and spaces.
* New Option: System monospaced Font is now available in the style preferences.

#### Bug fixes and maintenance:
* Fixed issue with style preferences that could lead to the font change not being taken.

#### Improved modes:
* Markdown preview: Fixed wrong table header colors in light mode
* Markdown preview: Fixed incorrect stripping of leading whitespace in code blocks
* Improved Bash mode: Added support for heredoc strings

### SubEthaEdit 5.1.3

#### Features:
* Added text transformation feature for preview for modes, to enable e.g. Markdown preview

#### Bug fixes and maintenance:
* Fixed issue that could lose data when saving while having folded text
* Fixed issue where SubEthaEdit could hang completely if one used blockedit while having more than one view of the same file open
* Improved performance on files with very many lines

#### Improved modes:
* Improved Markdown mode: added a markdown preview
* Improved Objective-C mode to handle properties with generic types better

### SubEthaEdit 5.1.2

#### Bug fixes and maintenance:
* Fixed issue where SubEthaEdit did not open documents when reacting to Spotlight searches
* Improved dark mode appearance
* Fixed an issue with the folding bar not unfolding correctly
* Switched tab shortcuts to the current system standard: ctrl-tab
* Improved handling of hidden extensions
* Improved display of document titles
* Made asking for revert less annoying by improving the recognition of real changes

#### Improved modes:
* Improved bash mode to handle complex $() interpolations better

### SubEthaEdit 5.1.1

#### Bug fixes and maintenance:
* Fixed an issue where default Avatars on macOS 10.15 looked bad in dark appearance
* Fixed top status bar text readability on live light/dark appearance change
* Fixed an issue where invitation windows needed to be dismissed twice to deny the invitation
* Updated the certificate for the `see` tool installer (AppStore version only)
* Fixed a rare crasher in TCMPortMapper

#### Improved modes:
* bash - improved indenting, handling of escaped strings and variables

### SubEthaEdit 5.1

#### Features:
* Switched to native macOS window tabs, removed PSMTabBarControl
* Improved Regular Expression features and speed. See Help > Regular Expressions for updated documentation and additional capabilities
* Improved security dialogs and `see` command line tool for future releases of macOS
* `see` command line tool now follows symlinks

#### Bug fixes and maintenance:
* Updated underlying RegEX Library (origuruma-mod) to onigmo 6.2
* Updated OgreKit to 3.0.2
* Fixed cascading of new windows to be of proper height and location
* Fixed top status bar to use fixed width at start for less jitter
* Blur behind bars now properly created using NSVisualEffectView
* Improved performance in general and for big font choices especially
* Upped minimum deployment version to macOS High Sierra and cleaned out dead code
* Moved all code to ARC (Automatic Reference Counting)
* Fixed dark appearance of encoding panel and encoding conflict resolution dialog
* Fixed remaining false colored dialogs and windows for dark mode

#### Improved modes:
* Markdown – improved syntax highlighting of code blocks
* HTML - improved symbol recognition


###  SubEthaEdit 5.0.2

#### Bug fixes and maintenance:
* Fixed performance issue that caused SubEthaEdit to get slower and more CPU intensive with every additional window
* Fixed an issue with the line number bar overlapping the text on scroll when line wrapping was turned off
* Fixed an issue where the initial character width value when turning on line wrap was wrong
* Fixed small memory leaks
* Fixed an issue with the command line install helper and case sensitive file systems
* Removed superfluous logging

#### Improved modes:
* Markdown – improved the symbol navigation


###  SubEthaEdit 5.0.1

#### Bug fixes and maintenance:
* Fixed an issue where the undo buffer could get corrupted in certain situations with a non empty selection
* Fixed ODB support, fixes external editor support for Fetch

#### New modes:
* Elixir Phoenix EEx

#### Improved modes:
* Elixir
* Javascript

###  SubEthaEdit 5.0

Now free and open source! The ideal tool for education, pair programming and tutoring and all your plain text editing needs.

#### Features:

* Support for Mojave Dark Appearance
* Overall facelift
* In bundle distribution of see command line tool and authentication script

#### Bug fixes and maintenance:
* Improved performance
* Improved reliability of see tool
* Fixed an issue where "Open Terminal Here" did not work reliably.

#### New Modes:
* TOML
* Markdown
* JSON
* Elixir

---

### SubEthaEdit 4.1

* New option to open empty document window on startup.
* Option to open Document HUD window works with empty document option.
* Saving unknown file types or .seetext filetype to names with different extension no longer causes .(null) extension dialog.
* "Save As…" from a .seetext file to a file with different extension no longer causes save error.
* "Find All" displays all results correctly.



### SubEthaEdit 4.0.3

#### Improved

* Mode improvements for indentation and "Close last Block/Tag"
* Included styles to support mode changes
* Indentation on enter and reindent
* State restauration restores last used font and font size per document

#### Fixed

* Regular Expression support for non-NL line endings
* Indent setting of Mode State now is respected
* State restoration behaviour when quit with keep windows and changes present
* Crash when invited to document
* Empty user images with coda 2.x



### SubEthaEdit 4.0.2

#### New

* Updated German localization
* Mode for Swift
* Mode creation documentation accessible via the help menu


#### Improved

* Enabled undo/redo in find and replace text fields
* Collaboration workflow so it is easier to advertise documents
* Zoom all windows behaviour with open Document Hub
* Appearance on upcoming OS releases
* Included styles for better contrast and legibility
* Support for creating custom modes
* Support for retina resolutions
* C and Objective-C mode


#### Fixed

* Crash while printing on a German system
* Crash related to rare networking conditions
* Bracket matching could cause a crash
* Crash related to syntax block detection
* Display errors when collaborating with Coda
* Better handling of unrecognized filetypes
* Command line tool -w option did not wait correctly
* German localization now features Help → Search item
* App icon badge could display a wrong number


### SubEthaEdit 4.0.1

* A fresh UI, ready for the future of OS X
* Reindenting
* New color theming engine
* Support for Back to my Mac
* Imrpoved Modes
* 64bit support
* Sandbox compliance for additional security
* Various bug fixes

---

### SubEthaEdit 3.5.3


#### Changes:

* Added various HTML5 related CSS properties and keywords.
* Improved the Erlang mode substantially.
* Various detail fixes and additions in HTML, Javascript, CSS and Obj-C modes.

#### Fixes:

* Fixed issues with the live web preview and Safari 5.0
* Fixed a bug in Javascript.mode that caused a wrong base color.
* Fixed issues with the LassoScript Mode



### SubEthaEdit 3.5.2

#### Additions/New Features:

* Added Erlang mode
* Added Go mode
* Added per mode option for the Tab key to indent and outdent when something is 
  selected. Defaults to on.
* Improved the Objective-C mode by adding Cocoa Touch properties and minor 
  missing functions to the autocompletion.
* Enabled support for Snow Leopard's text substitutions.

#### Changes:

* Improved handling of modes which require a higher SubEthaEngine for future 
  compatiblity.
* Switched out-of-the-box default encoding to UTF-8.

#### Fixes:

* Fixed an issue with Snow Leopard which caused continuous spell checking to 
  behave strangely.
* Fixed an issue with the live Web Preview where folded text did not appear in 
  the preview.
* Fixed an issue with the live Web Preview where some base URLs would prevent 
  the preview from updating.
* Fixed an issue with extended regex mode in which the find progress indicator 
  would not stop for certain expressions.
* Fixed issues with folding and encoding conversion.
* Fixed an issue which caused URLs containing non-ascii characters not to be 
  recognized correctly.
* Fixed an issue that caused the script menu to be missing from the context 
  menu.



### SubEthaEdit 3.5.1

#### Additions/New Features:

* Added CoreGraphic, CoreAnimation and some CoreFoundation classes and 
  functions to the Objective-C Mode.
* Added mode recognition on paste into an empty and new document, e.g. now SEE 
  switches to HTML mode if you paste an HTML page into an empty document.

#### Changes:

* Added SEEMinimumEngineVersion to Info.plist of Modes for future compatibilty 
  checking.

#### Fixes:

* Fixed a crash issue with folding in certain situations.
* Fixed an issue with Snow Leopard where authenticated saving did not work 
  properly.
* Fixed an issue with double click selection on Snow Leopard where words 
  separated with a dot were selected as whole instead of separately.
* Fixed an issue with the symbol pop-up and split views where the selection 
  could happen in the wrong text view.
* Fixed an issue with the PHP-HTML mode where inconsistent highlighting of 
  member variables could occur.
* Fixed memory leak on close that could cause the host of a document not to 
  leave the document.
* Fixed an issue with Ruby mode where folding did not work for spaceless if 
  constructs, e.g. if(a==b)
* Fixed an issue with Perl mode where HEREDOC did not highlight correctly if a 
  space was used after the initial <<
* Fixed an issue with Perl mode that did disable folding for some cases
* Fixed an issue where SubEthaEdit did not activate when using the new file 
  dock menu entries.
* Fixed an issue with mode triggers where an invalid regular expression in a 
  'content matches' trigger could cause exceptions resulting in problems on 
  save.
* Fixed an issue with code folding where AppleScript access of the contents 
  property would not return folded text. This caused e.g. "check syntax" mode 
  scripts to fail.
* Fixed an issue with javascript mode where 0 wasn't colored and added basic 
  javascript objects.
* Fixed a regression in various C-Style modes where strings in conditions were 
  not highlighted.
* Improved URL recognition behavior of the Wiki mode.


### SubEthaEdit 3.5


#### Additions/New Features:

* Code Folding - SubEthaEdit now supports code folding in all the shipping 
  modes. Even without mode support you have the ability to fold arbitrary 
  selections to gain clarity in more complicated documents.
* Document state persistence using Xtended Attributes - SubEthaEdit now saves 
  document state (mode, folding state, window position, selection and more) for 
  plain text files using a extended filesystem attribute.
* Clickable URLs - if the mode has URL recognition, URLs can now be opened with 
  a direct click in a fashion that does not interfere with editing.
* New "Tidy and Pretty Print HTML" feature

#### Changes:

* Improved the speed of Applescript based text changes in documents (e.g. the 
  commment/uncomment script in the c-modes)
* Reduced the cases where SubEthaEdit's port mapping triggers a bug in the 
  mDNSResponder causing it to produce a high cpu load when used with Airport 
  Base Stations.
* All shipped modes have been reengineered to support code folding.
* Updated the seetext file format to be more efficient and support the new 
  folding state data.
* Added additional TLS/SSL encryption mode that does not need the temporary 
  keychains anymore and is now default.
* Improved performance when using web preview with extensive javascript code 
  after web preview is closed again.

#### Fixes:

* Made network protocol more robust.
* Improved memory consumption when opening big files.
* Fixed crashes that could occur when opening files > 300 MB.
* Fixed an issue in mode definition syntax names which could lead to symbols 
  not being displayed after initially showing up.
* Fixed a crash where context clicking on an URL could lead to an application 
  hang.
* Fixed minor issues with the encoding recognition and conversion.
* Fixed minor issues to make SubEthaEdit work well with the upcoming Mac OS X 
  Snow Leopard.
* Fixed minor issues that occurred when inserting characters that do not exist 
  in the current encoding.



### SubEthaEdit 3.2.1

#### Changes:

* Implemented a partial work-around for an issue of Apple’s mDNSResponder in 
  conjunction with Airport Base Stations that causes excessive logging. If it 
  still happens, turning automatic port mapping off and on again resolves the 
  issue.

#### Fixes:

* Fixed an issue where CJK font fallbacks could cause the rest of the document 
  to be displayed in a wrong font.
* Fixed an issue that caused the Apple Scripts of the Latex Mode not to be 
  included correctly.



### SubEthaEdit 3.2

#### Additions/New Features:

* Added Objective-J Mode
* Improved Symbol recognition by adding the possibility to recognize symbols in 
  comments.

#### Changes:

* Improved syntax highlighting performance
* Drastically improved syntax highlighting speed for documents that contain 
  extremely long lines.
* Updated Sparkle to the latest version.
* Improved PHP mode.
* Improved Perl mode.
* Improved CSS mode.
* Improved Javascript mode.
* Improved Lassoscript mode.
* Improved Cold Fusion mode.
* Improved Objective-C mode (now includes UIKit).

#### Fixes:

* Fixed an issue with certain routers and port mapping by updating to the 
  lastest version of TCMPortMapper. For more details look into release notes 
  inside the Port Map Application (http://www.codingmonkeys.de/portmap/).
* Fixed an issue with the mouse insertion cursor being to dark when working 
  with dark backgrounds on leopard.
* Fixed some crashes that occurred in very specific situations.
* Fixed multiple issues with syntax parsing relating to symbols and 
  autocompletion.
* Fixed various small issues.


### SubEthaEdit 3.1

#### Additions/New Features:

* NAT-Traversal - SubEthaEdit now automatically maps its port so it can be 
  reached from anywhere on the internet.
* iChat Invites - Documents and the Connection Browser allow drag and drop of 
  iChat Buddies to invite them. (iChat invites only work on Mac OS X 10.5)
* Friendcasting - if you activate Friendcasting you get automatic connections 
  to the friends of your friends. In a typical company/group setup one publicly 
  reachable SubEthaEdit will be enough to act as friend to connect everyone to 
  each other.

#### Changes:

* The overall look of the Connection Browser has been greatly improved. SSL 
  connections now are default, a non SSL connection is shown via a crossed out 
  lock.
* You can drag and drop other people from the Connection Browser into a text 
  field (e.g. iChat) to copy their reachability see:// URL.
* Improved C++ mode and function recognition.
* Improved the LaTeX mode.

#### Fixes:

* Fixed an issue where the status of a document in the overflow tab menu was 
  not displayed correctly.
* Fixed an issue where a simultaneous join and invite to a restricted document 
  did not result in a allowed join.
* Fixed an issue where see:// document URLs did not result in a join of the 
  addressed document if there was already a connection.
* Fixed an issue with the display of subversion conflicts in the symbol popup.
* Fixed an issue with the modes preferences where users could edit read-only 
  information.
* Fixed an issue with Bonjour and Back to my Mac where the last found 
  netservice did determine which connections occured.
* Fixed an issue where your location in the window did move around and redraw 
  issues occured if others have been writing above you.
* Fixed an issue with split views and multiple views where the other windows 
  did move their position in the text if text was changed.
* Fixed an issue with "Find All" where a junk of text would be highlighted over 
  and over again if many search results are found.



### SubEthaEdit 3.0.3

#### Changes:

* Shift click/drag in the line number gutter now works as it should: now it 
  does span the current selection up to the target line.
* Updated the Objective-C mode to the current state of the API in Tiger. Some 
  methods and constants were missing.
* Added WebKit specific CSS attributes to all modes using CSS
* Deprecated support non-standard CSS single-line comments
* Made joining resizing transition smoother by using Core Animation on Leopard.

#### Fixes:

* Fixed a crash on 10.4.x that occured on quit when the application was quit 
  while being inactive after dismissing the unsaved changes dialog.
* Fixed an issue with spaces where all SubEthaEdit windows were dragged to the 
  space with the frontmost SubEthaEdit window.
* Fixed an issue with spaces where the find window did live on another space 
  than the document window it was searching in.
* Fixed an issue where the live web preview when set to update "on save" did 
  update also on autosave (that means at least every 60 seconds).
* Fixed an issue where SubEthaEdit did not respect the Appearance scroll bar 
  setting "Jump to here" if it was set while SubEthaEdit was not running.
* Fixed an issue where undo after a revert did garble the document.
* Fixed an issue with undo where the document did stay dirty after undoing 
  beyond the last save point and redoing again to it.
* Fixed an issue where C++ functions with class-qualified types did not appear 
  in the symbol popup.
* Fixed an issue where some indented C++ functions where not recognized.
* Fixed an issue where comments in #defines weren't highlighted correctly.



### SubEthaEdit 3.0.2

#### Changes:

* Encountered unexpected behaviour of the RegEx search and replace due to the 
  "find longest match" option. Starting with 3.0 this option causes only the 
  longest match(es) to be returned. We changed the naming of this option to 
  "Only longest match" and turn it off by default to clarify things.
* Merged the "Capture groups" and "Don't capture groups" as well as "Line 
  context" and "Negate single line" options to simplify user interaction and 
  mirror changes in OgreKit and Oniguruma.
* Increased performance on large documents on Leopard.

#### Fixes:

* Fixed a crash that happened sometimes when saving after a prior saving dialog 
  for that document had been canceled.
* Fixed a crash that occured without side effects on quit when the quit started 
  when the app wasn't active. (e.g. via the app switcher, dock or on shutdown)
* Fixed a crash which happened when generating a document URL and the machine 
  had no known name.
* Fixed a crash that occured if you closed a document while a long search and 
  replace operation was running.
* Fixed a crash that happend when the encoding list was changed after tabs have 
  been reordered and closed.
* Fixed a performance issue with autosave that caused SubEthaEdit to hesitate 
  on older G4 machines  on a regular basis.
* Fixed an issue where line numbering was displayed wrongly on Leopard when 
  scrolling slowly.
* Fixed an issue where printing produced unreadable very tightly packed lines 
  if the "indent wrapped lines" option was turned on for the current mode.
* Fixed an issue where the encoding setting of the mode was ignored and 
  windows-latin-2 was recognized. The mode encoding setting is now used again 
  if the encoding detector is clueless.
* Fixed an issue with the generated document URL: now when you have a valid 
  IPv6 address it also generates correct URLs, e.g. see://[::1]:6943
* Fixed an issue where link local IPv6 addresses didn't work in the Connections 
  Browser, e.g. see://[fe80::216:cbff:fe89:706e%25en1]:6942/
* Fixed an issue where the document scope popup in the find dialog initially 
  showed both entries checked
* Fixed an issue where the Javascript mode didn't recognize regular expressions 
  correctly.
* Fixed an issue where the Latex mode didn't recognize symbols.
* Fixed an issue with the C++ mode where inline member functions weren't 
  recognized.
* Fixed an issue where bracket matching in PHP-HTML didn't recognize comments 
  and strings. Now bracket matching works correctly even when in strings where 
  PHP is embedded.



### SubEthaEdit 3.0.1

#### Changes:

* Startup time has been improved.

#### Fixes:

* Fixed an issue where SubEthaEdit asked for Xcode on start if the Developer 
  Tools are not installed on the machine SubEthaEdit is running on.
* Fixed an issue where the document title in a tab and the document title 
  displayed in the statistics windows did not update if the host changed the 
  title of the doucment.
* Fixed an issue in PHP-HTML mode where <?= wasn't recognized as start of PHP 
  but was colored as an xml prologue.


### SubEthaEdit 3.0

#### Additions/New Features:

* All connections are TLS/SSL encrypted if possible.
* Persistent file format that stores collaboration metadata and history with 
  QuickLook support.
* Collaboration metadata is preserved where possible.
* Shiny new statistics window (Command-I) showing word, character and lines 
  counts as well as a user history.
* User Interface for mode recognition order and mode recognition triggers.
* Restoring document contents after a crash (including metadata).
* Highlighter supports unlimited nesting of states.
* Highlighter supports unlimited importing and linking of states in states.
* Highlighter supports transcendend named groups in states (used for e.g. 
  HEREDOC syntax).
* see command line tool now has options for selection, opening files in tabs, 
  and marking pipe in documents dirty.
* Total rewrite of the encoding guessing which now includes: meta-tag content, 
  BOMs of any kind, extended attributes and heuristical analysis.
* The user image now can be customized.
* Symbol recognition now ignores comment content.
* The participants drawer now features a follow button.
* New modes: SVNLog, SDEF, ERB (eRuby), ColdFusion and Lasso.
* New connection browser that combines the old bonjour and internet browsers 
  into one.
* New menu commands for announcing and setting the access to all open 
  documents.
* New menu commands for opening files in tabs / new window depending on the 
  user preference.
* New menu command for restoring change marks - especially useful with the new 
  file format.
* New menu command that pretty prints XML respecting the users indentation 
  settings.
* New regular expression features (look into Help->Regular Expressions) for 
  details.

#### Changes:

* Mode recognition can match extensions case-insensitivly
* Improved highlighting speed.
* Greatly improved modes which now take advanctage of the new features of the 
  highlighter: PHP/HTML, Perl, XML, XSLT, HTML, Objective-C, C++, C, Diff, 
  Python.
* Improved error reporting when loading of documents fails.
* Better auto updating experience: Open documents are restored after (next) 
  update
* New highres artwork for Leopard resolution independence.

#### Fixes:

* Improved Leopard compatibility
* Added content based mode detection for many modes.
* Parenthesis matching now knows about comments and strings.
* Autocompletion now honors the charsinautocompletion setting of the mode.
* Fixed issue with window cascading if you disconnect a screen that is on the 
  left and the last opened window was on that screen.


---

### SubEthaEdit 2.6.5

#### Fixes:

* Fixed a crash that could occur when closing a document while the web preview 
  is reloading.
* Fixed an issue where turning on wrap lines wouldn't work when there is no 
  text overflowing the current dimensions of the document window.
* Fixed an issue where sometimes when showing change marks, the change mark on 
  the last character of an edit wasn't displayed.
* Fixed an issue where the document that is created at startup would close when 
  you selected it via the window menu.


### SubEthaEdit 2.6.4

#### Additions/New Features:

* Added the AppleScript command "show" to the document. "show" will show the 
  frontmost window / tab of a document.
* Added the system wide show animation for selecting found text on Leopard
* Triple click now selects up to style boundaries. E.g. strings, variables.
* Save dialog now preselects filename without extension

#### Changes:

* Changed "Check Syntax" in all modes. It now should work with all encodings 
  and with tabs.
* Improved the syntax highlighting in Perl Mode
* Improved Objective-C Mode to include new Leopard Classes and support for 
  Objective-C 2.0
* Improved a behaviour where new windows would open across screens, now new 
  windows open on the screen of the topmost window.
* The report a bug menu item in the help menu now directly selects SubEthaEdit 
  and the correct version in our bugtracker.
* When removing a split now, instead of the cursor position of the upper text 
  view, the cursor position of the active text view is taken

#### Fixes:

* Fixed an issue where the shared find panel string did overwrite a user 
  created find string.
* Fixed an issue where the transition of the join and invitation windows wasn't 
  completed.
* Fixed an issue where the command-number keyboard shortcuts for tabs could be 
  wrong for a brief period of time after rearranging tabs inside a window.
* Fixed a crash that could be caused by using the command-number keyboard 
  shortcuts for switching between tabs in certain situations.
* Fixed a crash that could happen when the first character in a document was 
  deleted if it was a space, tabs have been turned off and you were unlucky.
* Fixed an issue where the Encoding Doctor did show the wrong button style.
* Fixed an issue where the ui on the hosting SubEthaEdit would not show that a 
  user has aborted the join.
* Fixed an network related crash that could be caused by having long modal 
  operations while joining a document, e.g. the loading of a mode that has an 
  AppleScript with an unknown application in it.
* Fixed a crash that could be caused by adding or removing encodings from the 
  encoding list after closing a tab but not the corresponding window by 
  clicking with the mouse.
* Fixed an issue with PHP and other modes which had trouble running the 
  Check-Syntax script when a Output document already was open.
* Fixed an issue where "show invisible characters" would draw big diamond 
  shapes for the space character on leopard



### SubEthaEdit 2.6.3

#### Changes:

* Made handling of remote edits more robust.
* Opening a file replacing an empty "Untitled.txt" does not increment window 
  stagger anymore.

#### Fixes:

* Fixed an issue where the connection would stay alive, but remote changes 
  would not be applied anymore.
* Fixed an issue that could lead to loosing the connection to a remote 
  SubEthaEdit without notice in rare cases.
* Fixed a crash triggered by the reconnection of a participant whose connection 
  got lost unnoticed.
* Fixed a crash triggered by canceled-in-transit connections over a high 
  latency line.
* Fixed a crash triggered by canceling the transmission of a big document while 
  the progress bar is visible.
* Fixed a bug where new documents were placed too far to the right to be shown 
  entirely on the screen.
* Fixed an issue where the cursor still was too dark to be noticable when 
  changing a document from bright to dark background.
* Improved CSS mode for better inline comments coloring.
* Improved PHP-HTML with missing PHP 5 keywords.



### SubEthaEdit 2.6.2

#### Fixes:

* Fixed a bug where the Web Preview no longer loaded resources (e.g. images).
* Fixed an issue where the Web Preview didn't run Javascript correctly.
* Fixed a bug where the Regex syntax option wasn't recognized correctly.
* Improved modes: Lua.



### SubEthaEdit 2.6.1

#### Changes:

* 'Find All' search results window is now click-trough.
* 'Find All' now selects the first search result in the editor.
* Lower latency during collaboration session by turning off the Nagle 
  algorithm.
* SubEthaEdit now registers with the system for files of type 'TEXT'.
* External changes to open documents now result in different warnings depending 
  on the edited state of the document.

#### Fixes:

* Fixed a bug where SubEthaEdit could crash on invoking the 'Check Syntax' 
  command from the toolbar.
* Fixed an issue in the network stack that could crash SubEthaEdit on Mac OS X 
  Leopard.
* Fixed a bug where the 'Always Show Tab Bar' option didn't work correctly.
* Fixed a bug where SubEthaEdit could crash on dragging around tabs with split 
  views.
* Fixed an issue where the buttons in invitation windows weren't displayed 
  correctly on Mac OS X Leopard.
* Fixed an issue where the buttons in the invitation window weren't accessible.
* Fixed a bug where a document showed an edited status after reinterpreting its 
  content with a different encoding.
* Fixed an issue where opening of HTML files were delayed.
* Fixed a bug where the editor scrolled to the left with some offset when the 
  split view was adjusted.
* Fixed a bug where the selection was destroyed on revert or reinterpretation 
  with a different encoding.
* Improved modes: Lua.



### SubEthaEdit 2.6

#### Additions/New Features:

* Editor windows can contain several documents respresented by tabs in a tab 
  bar.
* Added preference option for opening new documents in tabs.
* Added additional New menu command for creating tabs.
* Windows and tabs can be closed separately from each other.
* Added 'Always Show Tab Bar' command to show or hide the tab bar.
* A tab can be moved to a new window using the command 'Move Tab to New 
  Window'.
* All windows can be merged to a single window using the command 'Merge All 
  Windows'.
* Navigation between tabs with commands for selecting the next or previous tab.
* Added 'Go to Tab' submenu for a listing of all tabs.
* Tabs can be rearranged via drag and drop.
* Tabs can also be dragged between windows.

#### Changes:

* Find All now highlights the first search result instead of the last after 
  performing the search.
* Invitations are now placed on top of all other windows and in upper right 
  corner of the screen.
* Invitations now feature a new transparent look.

#### Fixes:

* Fixed a bug where a superfluous warning was showed when a mode file was 
  opened.
* Fixed several bugs in the German localization.
* Fixed an bug where the Lowercase and Uppercase scripts didn't handle Unicode 
  text correctly.
* Fixed an issue where the highlight color for dark backgrounds was too dark to 
  be noticable.
* Fixed a bug where modes installed for all users couldn't be loaded.
* Fixed a bug where the Open Terminal in Enclosing Folder script failed for 
  paths containing quotes.
* Fixed a bug where the line number in the status bar wasn't displayed 
  correctly.
* Improved modes: ActionScript, C, C++, HTML, Javascript, Lua, Objective-C, 
  Perl, Python.



### SubEthaEdit 2.5.1

#### Additions/New Features:

* Encoding conversion: Added assistance to identify characters that cannot be 
  represented in the new encoding. Also added option to allow lossy conversion.
* Encoding conversions are now undoable.
* Indented soft wrapping: Wrapped lines can be indented to the same amount as 
  the start of the line or more.
* A page guide can now be shown at a specific character width.
* Text which cannot be represented in the current encoding can now be inserted 
  lossy.
* New print option to include the full file path in the header.
* Added software update mechanism based on Sparkle for checking and installing 
  new version from within SubEthaEdit.
* New per-mode option to save UTF-8 encoded files with a UTF-8 BOM.
* Added built-in support for reporting crashes.

#### Changes:

* Changed the keyboard shortcut for the 'Check Syntax' command in various modes 
  to ctrl-command-b to resolve a conflict with blockediting.
* Changed the color of the insertion cursor to white when a dark background is 
  used.
* Group ownership of new files is now set to the primary group of the current 
  user.
* Clarified the naming of line endings to highlight that LF is also the 
  recommended line ending on Mac OS X.
* Use of underlying text system performance improvements when running on 
  Leopard.
* Menu items for registering and purchasing SubEthaEdit are now disabled once 
  it has been registered.
* When 'Open new document at startup' is enabled newly created unmodified 
  document windows are reused when the see command is invoked with unknown file 
  names.

#### Fixes:

* Fixed a bug where no warning was issued when line endings were converted on a 
  just opened read-only file.
* Fixed an issue where HTML export saved images to the same location as the 
  HTML file if an images folder already existed.
* Fixed an issue where an entry in the SubEthaEdit services menu hasn't been 
  localized correctly.
* Fixed a bug where no warning was issued when the reinterpration to UTF-8 of 
  file loaded with ISO Latin-2 encoding failed.
* Fixed a bug where the UTF-8 BOM of a file was not preserved.
* Fixed a bug where the 'Automatic' encoding didn't recognize files with a 
  UTF-8 BOM as UTF-8 encoded files.
* Fixed an issue where the line numbers in the gutter weren't drawn correctly.
* Fixed a bug that caused inconsistent line endings when a mode change 
  overwrite the guessed line ending.
* Fixed a bug where changing line endings weren't undoable.
* Fixed an issue where a read-only warning has been issued after a file has 
  been saved with the proper authorization.
* Fixed an issue where the document wasn't transmitted when using specific 
  encodings (e.g. celtic encoding).
* Fixed a bug where an incorrect handshake could cause a crash.
* Fixed an issue with the 'Edit/Insert HTML Color' command where the currently 
  selected color wasn't represented correctly.
* Improved modes: bash, C, C++, CSS, HTML, Java, Objective-C, Perl, PHP-HTML, 
  Python, Ruby, XML.



### SubEthaEdit 2.5

#### Additions/New Features:

* Added an application-wide AppleScript menu.
* AppleScripts can be bundled per mode. They show up in the mode menu and 
  optionally in the toolbar and context menu.
* Scriptability: Modes are exposed as AppleScript objects.
* Scriptability: Added selection properties to the application, document, and 
  window classes.
* Scriptability: Added detailed properties to most text classes.
* Scriptability: Added web preview base url property to the document class.
* Scriptability: Added colums and rows properties to the window class.
* Scriptability: Added undo grouping commands.
* Scriptability: Added clear change marks command.
* Dock icon badge indicating pending users and invitations.
* Modes can be reloaded without restarting the application.
* Hidden files can be shown in open and save dialogs.
* Click on line number selects line.
* Installation support for modes.
* Line endings not matching the document's setting are highlighted.
* Mode guessing also considers file name and content of file.
* Added toolbar item for "Show Invisible Characters".

#### Changes:

* Moved several mode settings from a mode's Info.plist to ModeSettings.xml.
* "Export to HTML" creates an image folder called '<exportname>_images'.
* Scriptability: Document objects return id-based specifier.
* Scriptability: Removed the text document class. Use the document class.


#### Fixes:

* Privileged operations are authorized per document.
* Fixed an issue where "Replace & Next" skipped occurrences.
* Fixed a bug that caused the syntax highlighter to mix up order of more than 
  eight keyword groups.
* Improved load performance of documents.
* Fixed an issue where the "Wrap line" setting was ignored when applying it to 
  open documents.
* Fixed a bug where windows weren't resized correctly on apply to open 
  documents when wrap is disabled in a document with long lines.
* Improved autoscrolling for blockedit.
* Fixed a bug where option-click during blockediting didn't behave as expected.
* Fixed a bug where the specified window size wasn't respected by the see tool.
* Fixed an issue were the see tool didn't handle empty input correctly.
* Remote document paths are displayed when a document is edited via an FTP 
  client.
* Fixed a crash which can be caused by broken modes.
* Improved line endings support by optionally enforcing the document's setting.
* Fixed a bug which enabled scripters to change access control of joined 
  documents.
* Fixed a bug where the size of the web preview wasn't remembered correctly.
* Fixed an issue where the "Editor uses tabs" preference didn't work properly.
* Fixed an issue where an image folder was created during export even when it 
  wasn't necessary.
* Fixed a bug where the window title wasn't set correctly when the see tool was 
  invoked with the title option.
* Prevents overwriting directories.
* Fixed a bug with syntax highlighter when inserting newlines.
* Fixed a bug where "Replace" didn't respect the document's file encoding.
* Fixed broken find keyboard shortcuts in find panel.
* Export dialog now clearly states its purpose.
* Improved feedback when nothing was found in the selection scope.
* Improved syntax highlighter performance when there are states with no plain 
  text strings.
* Improved modes: bash, C, C++, CSS, HTML, Java, Lua, Objective-C, Perl, PHP-HTML, Python, Ruby, SQL, XML.



### SubEthaEdit 2.3

#### Additions/New Features:

* New built-in Mode for .diff files and patches.
* Added "Close All" and "Save All" commands to the File menu.
* User Interface refresh.
* Quick access to Mode, Tabbing, Line Ending, File Encodings and Wrapping via 
  popup menus in the Bottom Status Bar as well as shortcuts (Ctrl-4 through 
  Ctrl-7).
* Position Field: Center current selection on single click, double click opens 
  goto line panel.
* Window Zoom Button: Shift-click now goes to fullscreen again, normal click 
  still keeps the width.
* Saving an associated CSS files now updates a HTML file's web preview.
* The number of files listed in the "Open Recent" submenu is now customizable.

#### Changes:

* Autocomplete can now complete natural language words. Enabled in Default and 
  Conference Mode.
* Replace all now preserves selection in both scopes.
* Adjusted synthesised bold fonts for dark backgrounds (synthesised bold fonts 
  actually looked thinner).
* More sophisticated checks on mode loading to help mode authors.
* Collaboration metadata is disabled by default in the print preferences.
* Document URLs now refer to the Bonjour name if a local IP is detected or a 
  public IP if available.
* Disabled autocomplete in Find/Replace window.
* Hide Changes and Show Changes in the view menu are now a checkmark item.

#### Fixes:

* Vastly improved speed of autocompletion.
* Disabling Syntax Highlighting in "Export as HTML" now works again.
* Fixed an issue where documents joined over network where hidden by the dock.
* Fixed a bug which printed white on white text in certain cases.
* Fixed issues with FileVault accounts.
* Fixed a bug where the Internet Browser showed the wrong status while 
  connecting.
* Inherited attributes of a mode weren't updated on "Apply to Open Documents".
* Fixed a bug which didn't displayed the last line number if this line was 
  empty.
* Drag and dropping from Safari onto the SubEthaEdit icon does not retain 
  background color and links anymore.
* Fixed an issue where changes to the editing preferences were not correctly 
  applied to open documents.
* Unicode promotion dialog is not shown while composing characters.
* Fixed an issue where user attribute changes did not propagate and redraw 
  correctly while networking.
* Fixed an issue where Internet and Bonjour browser didn't reflect a change of 
  name.
* Fixed a bug on Tiger where tabbing in the Find/Replace panel was broken when 
  regular expression were activated.
* Multiple path components are shown correctly in the window title.
* Hard links are preserved upon saving.
* Fixed a crash which occurred while converting line endings to PSEP or LSEP.
* Fixed an issue where bordereless paper formats would result in an empty 
  header when printing.
* Autocompletion delimiters can now be specified within a mode file.
* Improved the following modes by various means: ActionScript, C++, C, CSS, 
  Conference, HTML, Javascript, Lua, Objective-C, PHP-HTML, Pascal, Perl, 
  Python, Ruby.
* "End blockedit selection" is validated correctly in Edit menu.



### SubEthaEdit 2.2

#### Additions/New Features:
* Universal Binary - SubEthaEdit now runs on Intel Macs natively.
* Dragging text on app icon creates new document with dragged text.
* Extensions of untitled documents are guessed by using their mode.
* "Find All" results can now be used to navigate in the document.
* Selected lines can now be copied from a "Find All" window.

#### Changes:

* Added more classes and constants to Objective-C.mode.
* Improved PHP function recognition and added all PHP5 keywords.
* Added autocompletion of Core-API, Std-Lib and rubyonrails classes and methods 
  to the Ruby mode
* Invitation windows are placed more prominently.

#### Fixes:
* Fixed a selection display/redraw bug that happened when collaborating on 
  Tiger.
* Fixed an issue where joined documents didn't get the input focus after the 
  transfer has been completed.
* Improved keyboard navigation in "Find All".
* Fixed a bug in the syntax highlighter, where colors where not updated 
  correctly while typing, but did appear correctly after reloading the file.
* Fixed an issue where the context menu and action popup in the participants 
  drawer weren't validated correctly.
* Windows for new documents are no longer created under the dock.
* Fixed a bug where files created with "File->New->Mode" weren't resized 
  correctly, fixed the same issue when opening new files via see tool.
* Fixed a bug where the see tool didn't set the correct modes when given 
  multiple files.
* Fixed the "Wrap/Wrap lines" functionality to retain its setting.
* Fixed maximize button of document windows to behave according to HIG.
* Fixed word boundaries for autocomplete and selection to include colon (which 
  they didn't on Tiger).
* Fixed an issue where a document wasn't joined automatically though it was 
  addressed in a see:// URL.
* Fixed mode guessing upon first save to work if initial save is canceled.
* XHTML export and "Copy as XHTML" now export quotes as entities.
* see tool now conforms to the mode's encoding preference.
* see tool --mode parameter mode matching is case insensitive.
* Improved speed of "Show Invisibles" significantly.
* Fixed a bug in Perl.mode concerning POD comments.


### SubEthaEdit 2.1.2

#### Additions/New Features:

* Added Conference Kit.
* Added alternate menu item for 'Switch Mode' called 'Show In Finder', which 
  reveals the choosen mode in the Finder.
* Added change logs to the mode bundles.
* Added submenu to 'New', new files now can be created in a specific mode.

#### Fixes:

* Fixed several issues where bad Address Book entries caused crashes or 
  exceptions at startup.
* Improved overall protocol stability.
* Fixed an issue where empty mode bundles caused an exception at startup, 
  rendering SubEthaEdit unusable.
* Fixed a bug in 'Save a Copy As...' where the selected encoding was not used 
  to save the copy.
* Fixed a bug where externally changed documents weren't set modified after 
  choosing to keep the SubEthaEdit version.
* Fixed an issue where the mode of documents created using see's pipe-in was 
  not guessed on save.
* Fixed a bug where the mode of documents created using the see tool was 
  guessed again on save.
* Fixed a bug where documents which can be opened via the Help menu were opened 
  more than once.
* Fixed a bug where the scope of a 'Find All' operation wasn't respected.
* Fixed a bug where the matching brackets were only highlighted when moving the 
  cursor using the arrow keys.
* Fixed a bug where the 'Shift Left' command produced a crash when the editor 
  used tabs and activated indenting new lines.
* Fixed a bug where HTML Export didn't export style and weight if current font 
  was synthesized.
* Fixed an issue where the activiation of syntax highlighting in the print 
  options also activated it in the editor.
* Fixed various issues which occurred while using autocompletion in Blockedit 
  mode.


### SubEthaEdit 2.1.1

#### Changes:

* Changed export dialog to disable according checkboxes, if "Participants" is 
  not selected.

#### Fixes:

* Fixed a security issue where a user could receive permanent authorization for 
  privileged SubEthaEdit operations after successfully aquiring authorization 
  as an administrator in SubEthaEdit.
* Printing panel now displays localized separators for margins.
* Python mode now recognizes abbreviated class declarations.


### SubEthaEdit 2.1


#### Additions/New Features:

* Added preference pane for customizing the syntax highlighting style for 
  modes. Syntax styles can also be imported and exported.
* Documents can be exported to HTML files including collaboration metadata.
* Documents can be printed with page headers, line numbers, highlighted syntax 
  and collaboration annotations.
* A selection of text can now be copied to the clipboard as XHTML.
* A selection of text can now be copied to the clipboard while preserving font 
  styles.
* Added see command line tool for opening files in SubEthaEdit via the command 
  line.
* C++ mode adds .cc file extension to its list of supported extensions.
* Added option to open and save panels for looking into bundles.
* Added highlighting support for entities in XML and related modes.
* Documents can be opened and saved using administrator permissions.
* Non-commercial licensed copies embed watermarks into documents after 2 
  minutes of inactivity. They will disappear when SubEthaEdit is reactivated.
* Added entab and detab feature for text.
* Changes to the editing preferences can now be applied explicitly to open 
  documents.
* Added release notes document to the application.
* AppleScript: Added encoding, mode, access control, announced status and URL 
  properties to the text document class.
* Added advanced preferences for screen fonts and for synthesising bold and 
  italic font variants.
* Added menu command and keyboard shortcut for blockedit.
* Added several missing enums and constants to the Objective-C mode.
* Added French and Korean localizations.

#### Changes:

* Moved font preferences to the new Style preference pane.
* Used consistently the term "Highlight Syntax" instead of "Colorize Syntax".
* "Copy Document URL" command now works only on announced documents.
* Visibility setting is now sticky.
* SubEthaEdit no longer listens for incoming connections when internet 
  connections were prohibited and the status has been set to invisible.
* Autocompletion now takes all open documents using the same mode into account.
* AppleScript: Removed the attachments and size properties of the text class.
* System encoding is used when a file can't be read using the specified 
  encoding.
* Display preferences for status bars are now sticky per mode.
* Removed "#" image for pragma marks in Objective-C mode and for comment lines 
  in PHP mode.
* Removed out-of-date Dutch localization.
* Updated OrgeKit.


#### Fixes:

* Fixed a bug where the mode of a document was reseted to its original value 
  during a revert of the document.
* Fixed a bug where the window width display in the bottom status bar wasn't 
  correctly updated after a font change.
* Fixed bug in Perl mode where an array counter was recognized as a comment.
* Fixed a bug where a document lost its location after a revert.
* Fixed a bug where a new document was opened when SubEthaEdit was launched via 
  Xcode.
* Fixed a bug where the setup consumed 100% CPU.
* Fixed a bug where the user's initial colors weren't determined randomly.
* Fixed a bug where an external application (e.g. FTP clients) invoking 
  SubEthaEdit wasn't notified when SubEthaEdit was quitted.
* Fixed several issues regarding highlighting of regular expressions in Perl 
  mode.
* Fixed several bugs where the location of a document couldn't be determined 
  while trying to save it.
* Fixed a bug where the status of a connection wasn't displayed correctly in 
  the internet browser.
* Fixed a bug where delayed web preview didn't work in modes without symbols.
* Fixed a bug which could cause a crash when SubEthaEdit shared a document.
* Fixed a bug which could cause a crash when the web preview was closed.
* Fixed a bug where the web preview window title wasn't in sync with the 
  corresponding document window title.
* Fixed a bug which could prevent further display of changes when matching 
  brackets where highlighted while blockediting.
* Fixed "ID" symbol image in the symbol popup menu by adding transparency to 
  the image.
* Fixed a bug in LaTeX mode where highlighting failed when there were "{" or 
  "}" characters in the argument of a command.
* Fixed a bug which could result in inserting different sized tabs when using 
  tabs while blockediting.
* Fixed a bug where shift left or shift right didn't work correctly when tabs 
  were activated
* Fixed a bug where toolbar item labels where not displayed correctly.
* Fixed a bug in Lua mode where symbols appared twice.
* Fixed highlighting of variables in PHP mode.
* Fixed a bug where participants seemed to have lost their connections but were 
  still listed as participants.
* Fixed a bug in LaTeX mode which could result in wrong highlighting of escaped 
  comments.
* Fixed a bug in Perl mode which could break syntax highlighting in regexp 
  quote-like operators.
  
  
