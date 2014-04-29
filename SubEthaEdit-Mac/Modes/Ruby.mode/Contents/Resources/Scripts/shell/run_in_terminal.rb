#!/usr/bin/env ruby

require 'fileutils'

scriptToRun = ARGV[1]
tmpBase = ARGV[0]



filepath = File.join(tmpBase, "see_tmp_run.command")

File.open(filepath, 'w') { |file|
	file.write(scriptToRun)
	}

%x[chmod u+x #{filepath};]
# %x[attr -d com.apple.quarantine #{filepath};] # the quarantine is what makes this approach not work
%x[open -a terminal #{filepath}]
