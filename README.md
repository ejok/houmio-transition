# Basics

    npm install -g coffee-script
    npm install
    export HOUMIO_SITEKEY=<yoursecretsitekey>
    ./houmio-transition "All off" 30 # Pass scene name and duration in minutes

# Examples

## Wake up light

Transition from darkness to daylights, starting at 0700, daylights on at 0730.

Execute in terminal:

    at 0700 <<EOF
    ./houmio-transition "Daylights" 30
    EOF

Note: The computer running this script must be powered and online.

Note: To enable `at` on OSX, you need to execute `sudo launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist`.
