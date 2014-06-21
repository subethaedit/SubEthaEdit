# Swift.seemode - shell scripts

Normally this would be a place where shell scripts or binaries are put which are used in AppleScripts that are accessed directly from SubEthaEdit's Mode menu. However, it is also possible to but scripts in here that might help the users of your mode.

#### swiftc.sh

`swiftc.sh` solves an issue when using

```bash
#!/usr/bin/env xcrun swift -i 
```

The interactive mode of swift currently either sends you all the command line parameters that the swift command gets, or if you use -- as first parameter of your written shell tool only the ones after the --. Both behaviours are different from a compiled version of your script. To mitigate this you can use

(see also [particalswift](http://practicalswift.com/2014/06/07/swift-scripts-how-to-write-small-command-line-scripts-in-swift/) for more information on this)

```bash
#!/usr/bin/env swiftc.sh
```

as shebang in your scripts after you put `swiftc.sh` in your path.

This way when you execute your `.swift` script, it first gets compiled and placed next to it as `.swift.o` file and then the `.swift.o` file is executed with all the parameters given. This also has the benefit of always adding the OS X sdk in a sane way, which sadly isn't possible with a normal shebang call. And of course your scripts run at native compiled speed instead of getting interpreted on every run.

 