#!/usr/bin/env bash
# Replace TOOL with the actual name of the tool you're integrating with.
# WARNING: Sed is used here and does not create backups! If you make a mistake, reset with Git.
# WARNING: Must be run from the root directory of the project.
set -euo pipefail

new_name=${1:-}

if [ -z "$new_name" ]; then
	echo "No string provided"
	exit 1
fi

# Replace all instances of TOOL in the files.
find lua -type f -exec sed -i '' "s/TOOL/${new_name}/g" {} +

mv lua/TOOL/TOOL.lua "lua/TOOL/$new_name.lua"
mv lua/TOOL "lua/$new_name"

echo "Renamed TOOl to $new_name"
echo "Remember to delete .git/"
