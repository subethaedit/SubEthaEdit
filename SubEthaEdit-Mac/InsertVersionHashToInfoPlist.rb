#!/usr/bin/env ruby
require "open3"


def replace_string_value_of_key(plist_string, key, newValue)
  plist_string.gsub!(/(<key>#{key}<\/key>\s*<string>)[^<]*(<\/string>)/,"\\1" + newValue + "\\2")
end

# get version - also remove the mac osx deployment target as it confuses python #doh
version_hash, version_revision = %x[cd #{ENV['SOURCE_ROOT']}; unset MACOSX_DEPLOYMENT_TARGET; /usr/bin/env hg id -i -n].chomp.split(' ')
# this created a string with <rev>:<revisionhash>

# special see treat : add 4000 to the revision to also upgrade from old ones
version_revision = (version_revision.to_i + 4000).to_s + /[^\d]+/.match(version_revision).to_s


#convert already preprocessed plist from binary format
plist_file = "#{ENV['BUILT_PRODUCTS_DIR']}/#{ENV['INFOPLIST_PATH']}"
info_plist_content = %x[/usr/bin/env plutil -convert xml1 -o - #{plist_file}]

replace_string_value_of_key(info_plist_content,"CFBundleVersion",version_revision)
replace_string_value_of_key(info_plist_content,"TCMRevisionHash",version_hash)

# this step is for iphone only
# #convert_back
# myin, myout, myerr = Open3.popen3 '/usr/bin/env plutil -convert binary1 -o - -'
# myin.puts info_plist_content
# myin.close
# new_binary_plist_content = myout.read


#overwrite the info.plist
File.open(plist_file, 'w') {|f| f.write(info_plist_content) }

print "Updated plist with this version: ",version_revision, ":", version_hash
