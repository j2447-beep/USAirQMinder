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

project_dir = File.expand_path('..', __FILE__)
proj_path = File.join(project_dir, 'USAirQMinder.xcodeproj')

FileUtils.rm_rf(proj_path)
project = Xcodeproj::Project.new(proj_path)

target = project.new_target(:application, 'USAirQMinder', :ios, '17.0')

target.build_configurations.each do |config|
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.usairqminder.app'
  config.build_settings['INFOPLIST_FILE'] = 'USAirQMinder/Info.plist'
  config.build_settings['SWIFT_VERSION'] = '5.0'
  config.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  config.build_settings['CODE_SIGN_STYLE'] = 'Automatic'
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['CURRENT_PROJECT_VERSION'] = '1'
  config.build_settings['MARKETING_VERSION'] = '1.0'
  config.build_settings['LD_RUNPATH_SEARCH_PATHS'] = '$(inherited) @executable_path/Frameworks'
  config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
end

project.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.0'
end

source_dir = File.join(project_dir, 'USAirQMinder')
main_group = project.main_group.new_group('USAirQMinder', 'USAirQMinder')

def add_files_recursive(group, dir_path, target)
  Dir.entries(dir_path).sort.each do |entry|
    next if entry.start_with?('.')
    full_path = File.join(dir_path, entry)

    if File.directory?(full_path)
      sub_group = group.new_group(entry, entry)
      add_files_recursive(sub_group, full_path, target)
    elsif entry.end_with?('.swift')
      file_ref = group.new_file(entry)
      target.source_build_phase.add_file_reference(file_ref)
    elsif entry.end_with?('.plist')
      group.new_file(entry)
    end
  end
end

add_files_recursive(main_group, source_dir, target)

project.save
puts "Wrote #{proj_path}"
