require 'xcodeproj'

project = Xcodeproj::Project.new('TeenHealth.xcodeproj')

# Main target
app_target = project.new_target(:application, 'TeenHealth', :ios, '17.0')

# Add main group
main_group = project.main_group
sources_group = main_group.new_group('TeenHealth', 'TeenHealth')

# File references
files = Dir.glob('TeenHealth/**/*.swift').sort

files.each do |path|
  ref = sources_group.new_file(path)
  app_target.add_file_references([ref])
end

# Info.plist
plist_ref = sources_group.new_file('TeenHealth/Info.plist')
app_target.build_configurations.each do |config|
  config.build_settings['SWIFT_VERSION'] = '5.9'
  config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'
  config.build_settings['INFOPLIST_FILE'] = 'TeenHealth/Info.plist'
  config.build_settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.pauldon.TeenHealth'
end

# Frameworks
%w[HealthKit UserNotifications].each do |fw|
  ref = project.frameworks_group.new_file("System/Library/Frameworks/#{fw}.framework")
  app_target.frameworks_build_phase.add_file_reference(ref)
end

project.save
puts "✅ Project created"
