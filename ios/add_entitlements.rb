#!/usr/bin/env ruby

require 'xcodeproj'

project_path = 'Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'Runner' }

if target
  # Add entitlements file to build settings
  target.build_configurations.each do |config|
    config.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
  end
  
  # Save the project
  project.save
  
  puts "Entitlements added to project successfully!"
else
  puts "Target 'Runner' not found!"
end