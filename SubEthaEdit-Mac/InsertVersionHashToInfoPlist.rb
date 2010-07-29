#!/usr/bin/env ruby

amount_to_add_to_rev = 4000

# get version - also remove the mac osx deployment target as it confuses python #doh
hash, rev = %x[cd #{ENV['SOURCE_ROOT']}; unset MACOSX_DEPLOYMENT_TARGET; /usr/bin/env hg id -i -n].chomp.split(' ')

modified = hash[-1] == ?+

rev = rev.to_i + amount_to_add_to_rev
rev = rev.to_s + "+" if modified

new_version = rev + ":" + hash

#convert already preprocessed plist from binary format
plist_file = "#{ENV['BUILT_PRODUCTS_DIR']}/#{ENV['INFOPLIST_PATH']}"

%x[/usr/libexec/PlistBuddy -c "Set :CFBundleVersion #{rev}" '#{plist_file}']
%x[/usr/libexec/PlistBuddy -c "Set :TCMRevisionHash #{new_version}" '#{plist_file}']

print "Updated plist with this version: ",new_version
