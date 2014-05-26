##Known Bugs:

### Objective-C

`40-OpenFileInProject.scpt`

* Matches partial - encountering names matching the import it is looking fore -> false positives possible
* if it does not find the file fast enough/at all it is possible that weird stuff happens


`Lookup in AppKiDo.scpt`

* Does open AppKiDo but does not actually search for the selection


#####Need the `helper/xcodePathHelper.scpt`:
The helper script location is hardcoded into the scripts themselves - placing it somewhere else should result in changing the scripts - otherwise they stop working -
this is done like that anyway because there is actually less code that would need fixing in multiple scripts.

* `40-OpenFileInProject.scpt`
* `45-OpenXcodeProject.scpt`
* `50-CompileUsingXcode.scpt`



### Multiple Scripts are affected
`Open Counterpart` scripts do not tell the user if it does not find a counterpart.