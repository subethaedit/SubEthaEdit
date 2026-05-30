#!/usr/bin/env ruby
# frozen_string_literal: true

# Edits SubEthaEdit.xcodeproj's localization wiring via the `xcodeproj` gem.
#
#   ruby add_localizations.rb rewire-de
#       Phase 1: repoint the 9 modernized de variant-group children from
#       <Name>.xib to <Name>.strings (file.xib -> text.plist.strings).
#
#   ruby add_localizations.rb add-languages
#       Phase 2: add sv/nb/nn/da/fi to knownRegions and a localized child file
#       reference to every variant group (Base .xib groups get a .strings child).
#
# Idempotent: skips children that already exist / regions already present.

require "xcodeproj"

PROJECT_PATH = File.expand_path("../../SubEthaEdit.xcodeproj", __dir__)

# The 9 interface files modernized from duplicated de .xib to de .strings.
REWIRE = %w[
  Export FindReplace MainMenu OpenPanelAccessory OpenURLViewController
  PlainTextLoadProgress PrintOptions SavePanelAccessory SelectEncodingsPanel
].freeze

NEW_LANGS = %w[sv nb nn da fi].freeze

def variant_groups(project)
  project.objects.select { |o| o.isa == "PBXVariantGroup" }
end

def child_named(group, name)
  group.children.find { |c| c.name == name || c.display_name == name }
end

# Basename + UTI for a language child of `group`.
#   Foo.xib        -> Foo.strings        (Base Internationalization)
#   Bar.strings    -> Bar.strings
#   Baz.stringsdict-> Baz.stringsdict    (mirror Base child's UTI)
def language_file_for(group)
  name = group.name
  base = child_named(group, "Base")
  if name.end_with?(".xib")
    [name.sub(/\.xib\z/, ".strings"), "text.plist.strings"]
  elsif name.end_with?(".stringsdict")
    [name, base&.last_known_file_type || "text.plist.xml"]
  else
    [name, base&.last_known_file_type || "text.plist.strings"]
  end
end

def rewire_de(project)
  changed = 0
  variant_groups(project).each do |group|
    stem = group.name.sub(/\.xib\z/, "")
    next unless REWIRE.include?(stem)

    de = child_named(group, "de")
    unless de
      warn "  ! #{group.name}: no de child found"
      next
    end
    de.path = "de.lproj/#{stem}.strings"
    de.last_known_file_type = "text.plist.strings"
    changed += 1
    puts "  rewired #{group.name} -> de.lproj/#{stem}.strings"
  end
  changed
end

def add_languages(project)
  root = project.root_object
  added_regions = NEW_LANGS - root.known_regions
  root.known_regions += added_regions
  puts "  knownRegions += #{added_regions.inspect}" unless added_regions.empty?

  added = 0
  variant_groups(project).each do |group|
    filename, uti = language_file_for(group)
    NEW_LANGS.each do |lang|
      next if child_named(group, lang)

      ref = project.new(Xcodeproj::Project::Object::PBXFileReference)
      ref.name = lang
      ref.path = "#{lang}.lproj/#{filename}"
      ref.source_tree = "<group>"
      ref.last_known_file_type = uti
      group.children << ref
      added += 1
    end
  end
  puts "  added #{added} localized file references across #{variant_groups(project).count} groups"
  added
end

command = ARGV[0]
project = Xcodeproj::Project.open(PROJECT_PATH)

case command
when "rewire-de"
  puts "Phase 1: rewiring de .xib references to .strings"
  rewire_de(project)
when "add-languages"
  puts "Phase 2: adding #{NEW_LANGS.join(', ')}"
  add_languages(project)
else
  abort "usage: ruby add_localizations.rb [rewire-de|add-languages]"
end

project.save
puts "Saved #{PROJECT_PATH}"
