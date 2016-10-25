#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
HELPERS_DIR="$CURRENT_DIR/helpers"

source "$HELPERS_DIR/plugin_functions.sh"
source "$HELPERS_DIR/utility.sh"

if [ "$1" == "--tmux-echo" ]; then # tmux-specific echo functions
	source "$HELPERS_DIR/tmux_echo_functions.sh"
else # shell output functions
	source "$HELPERS_DIR/shell_echo_functions.sh"
fi

clone() {
	# TODO
	#  1) Check for the amount of arguments
	#  2) If 1:
	#      Just clone!
	#  3) If 2:
	#      Clone and then checkout the repository to the correct version tag provided by $2
	local plugin="$1"
	if [ "$#" -eq 1 ] || [ "$#" -eq 2 ]; then
		cd "$(tpm_path)" &&	
		GIT_TERMINAL_PROMPT=0 git clone --recursive "$plugin" >/dev/null 2>&1
		if [ "$#" -eq 2 ]; then
			local version="$2"
			local path="$(tpm_path)$(plugin_remove_version $plugin)"
			cd "$path" && GIT_TERMINAL_PROMPT=0 git checkout -b "$version" >/dev/null 2>&1 # Check how to retrieve the directory name!
		fi
	fi
}

# tries cloning:
# 1. plugin name directly - works if it's a valid git url
# 2. expands the plugin name to point to a github repo and tries cloning again
clone_plugin() {
	local plugin="$1"
	clone "$plugin" ||
		clone "https://git::@github.com/$plugin"
}

# clone plugin and produce output
install_plugin() {
	local plugin="$1"
	local plugin_name="$(plugin_name_helper "$plugin")"

	if plugin_already_installed "$plugin"; then
		echo_ok "Already installed \"$plugin_name\""
	else
		echo_ok "Installing \"$plugin_name\""
		clone_plugin "$plugin" &&
			echo_ok "  \"$plugin_name\" download success" ||
			echo_err "  \"$plugin_name\" download fail"
	fi
}

install_plugins() {
	local plugins="$(tpm_plugins_list_helper)"
	for plugin in $plugins; do
		install_plugin "$plugin"
	done
}

verify_tpm_path_permissions() {
	local path="$(tpm_path)"
	# check the write permission flag for all users to ensure
	# that we have proper access
	[ -w "$path" ] ||
		echo_err "$path is not writable!"
}

main() {
	ensure_tpm_path_exists
	verify_tpm_path_permissions
	install_plugins
	exit_value_helper
}
main
