#!/usr/bin/env ruby

amount_to_add_to_rev = 4000

# get version - also remove the mac osx deployment target as it confuses python #doh
hash = %x[cd #{ENV['SOURCE_ROOT']}; git rev-parse HEAD;].strip
rev = %x[cd #{ENV['SOURCE_ROOT']}; git rev-list HEAD | wc -l;].strip.to_i
modified = %x[cd #{ENV['SOURCE_ROOT']}; git status -s --porcelain -uno | wc -l;].strip.to_i
hash = "+" + hash unless modified == 0
rev_number = (rev + amount_to_add_to_rev)
rev = rev_number.to_s
rev = rev + "+" unless modified == 0
new_version = rev + ":" + hash

#convert already preprocessed plist from binary format
plist_file = "#{ENV['BUILT_PRODUCTS_DIR']}/#{ENV['INFOPLIST_PATH']}"

bundle_version = %x[/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" '#{plist_file}'].chomp
new_bundle_version = bundle_version + "." + rev
%x[/usr/libexec/PlistBuddy -c "Set :CFBundleVersion #{new_bundle_version}" '#{plist_file}']
%x[/usr/libexec/PlistBuddy -c "Set :TCMRevisionHash #{new_version}" '#{plist_file}']

print "Updated plist with this version: ",new_version, " ",bundle_version, " ",new_bundle_version
