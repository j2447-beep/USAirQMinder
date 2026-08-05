#!/usr/bin/env ruby
# Regenerates USAirQMinder.xcodeproj from the sources on disk.
#
# The project file is generated rather than hand-edited so adding a Swift file
# means dropping it in the right folder and re-running this.
#
#   ruby create_project.rb
#
require 'xcodeproj'
require 'fileutils'

APP = 'USAirQMinder'.freeze
WIDGET = 'USAirQMinderWidget'.freeze
BUNDLE_ID = 'com.usairqminder.app'.freeze
DEPLOYMENT_TARGET = '17.0'.freeze

project_dir = File.expand_path('..', __FILE__)
proj_path = File.join(project_dir, "#{APP}.xcodeproj")

FileUtils.rm_rf(proj_path)
project = Xcodeproj::Project.new(proj_path)

def common_settings(config, deployment_target)
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end

# --- App target -------------------------------------------------------------

app_target = project.new_target(:application, APP, :ios, DEPLOYMENT_TARGET)
app_target.build_configurations.each do |config|
  common_settings(config, DEPLOYMENT_TARGET)
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  config.build_settings['INFOPLIST_FILE'] = "#{APP}/Info.plist"
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "#{APP}/#{APP}.entitlements"
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  config.build_settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
end

# --- Widget extension target ------------------------------------------------

widget_target = project.new_target(:app_extension, WIDGET, :ios, DEPLOYMENT_TARGET)
widget_target.build_configurations.each do |config|
  common_settings(config, DEPLOYMENT_TARGET)
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = "#{BUNDLE_ID}.widget"
  config.build_settings['INFOPLIST_FILE'] = "#{WIDGET}/Info.plist"
  # The widget's plist carries only NSExtension and NSWidgetWantsLocation;
  # Xcode merges the identity keys (CFBundleIdentifier and friends) in. With
  # this off, the bundle identifier resolves to empty and embedding fails.
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'YES'
  config.build_settings['INFOPLIST_KEY_CFBundleDisplayName'] = 'Air Quality'
  config.build_settings['CODE_SIGN_ENTITLEMENTS'] = "#{WIDGET}/#{WIDGET}.entitlements"
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['SKIP_INSTALL'] = 'YES'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] =
    '$(inherited) @executable_path/Frameworks @executable_path/../../Frameworks'
end

project.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

# --- Sources ----------------------------------------------------------------

def add_files_recursive(group, dir_path, target, project)
  Dir.entries(dir_path).sort.each do |entry|
    next if entry.start_with?('.')
    full_path = File.join(dir_path, entry)

    if entry.end_with?('.xcassets')
      file_ref = group.new_file(entry)
      target.resources_build_phase.add_file_reference(file_ref)
    elsif File.directory?(full_path)
      sub_group = group.new_group(entry, entry)
      add_files_recursive(sub_group, full_path, target, project)
    elsif entry.end_with?('.swift')
      file_ref = group.new_file(entry)
      target.source_build_phase.add_file_reference(file_ref)
    elsif entry.end_with?('.plist') || entry.end_with?('.entitlements')
      group.new_file(entry)
    end
  end
end

app_group = project.main_group.new_group(APP, APP)
add_files_recursive(app_group, File.join(project_dir, APP), app_target, project)

widget_group = project.main_group.new_group(WIDGET, WIDGET)
add_files_recursive(widget_group, File.join(project_dir, WIDGET), widget_target, project)

# The widget needs the shared model types. Compiling the same sources into both
# targets keeps one definition of the AQI bands and the AirNow decoding, without
# the ceremony of a framework for two files.
['Models/AQI.swift', 'Models/SharedDefaults.swift'].each do |relative_path|
  ref = app_group.find_subpath(relative_path, false)
  raise "missing shared source #{relative_path}" if ref.nil?
  widget_target.source_build_phase.add_file_reference(ref)
end

# --- Embed the extension in the app ----------------------------------------

embed_phase = project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
embed_phase.name = 'Embed Foundation Extensions'
embed_phase.symbol_dst_subfolder_spec = :plug_ins
app_target.build_phases << embed_phase

build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
build_file.file_ref = widget_target.product_reference
build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
embed_phase.files << build_file

app_target.add_dependency(widget_target)

project.save
puts "Wrote #{proj_path}"
puts "  #{APP} (#{BUNDLE_ID})"
puts "  #{WIDGET} (#{BUNDLE_ID}.widget)"
