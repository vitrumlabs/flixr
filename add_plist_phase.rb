require 'xcodeproj'

PROJECT_PATH = File.expand_path('../flixr.xcodeproj', __FILE__)
project = Xcodeproj::Project.open(PROJECT_PATH)

PHASE_NAME = 'Select GoogleService-Info.plist for configuration'

target = project.targets.find { |t| t.name == 'flixr' }
raise 'flixr target not found' unless target

if target.shell_script_build_phases.any? { |p| p.name == PHASE_NAME }
  puts "Phase already exists, skipping."
  exit 0
end

phase = target.new_shell_script_build_phase(PHASE_NAME)

phase.shell_script = <<~'SHELL'
  # Overwrite GoogleService-Info.plist with the environment-specific one.
  # Debug builds use flixr/GoogleService-Info.plist (auto-bundled via file sync).
  # Release builds require Config/Release/GoogleService-Info.plist (prod project, gitignored).
  if [ "${CONFIGURATION}" = "Release" ]; then
    PLIST_SRC="${SRCROOT}/Config/Release/GoogleService-Info.plist"
    PLIST_DEST="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
    if [ ! -f "${PLIST_SRC}" ]; then
      echo "error: Missing Config/Release/GoogleService-Info.plist"
      echo "error: Download it from Firebase Console for vitrumlabs-flixr-prod and place it at Config/Release/"
      exit 1
    fi
    cp "${PLIST_SRC}" "${PLIST_DEST}"
  fi
SHELL

phase.input_paths = []
phase.output_paths = []

# Move the new phase to run after Resources but before Crashlytics
# Build phase order: Check Pods Lock, Sources, Frameworks, Resources, Embed Pods, Copy Pods Resources, [new], Crashlytics
crashlytics_phase = target.shell_script_build_phases.find { |p| p.name == 'ShellScript' }
if crashlytics_phase
  phases = target.build_phases
  phases.move(phase, phases.index(crashlytics_phase))
end

project.save
puts "Added '#{PHASE_NAME}' build phase to flixr target."
