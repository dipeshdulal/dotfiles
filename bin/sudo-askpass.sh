#!/bin/sh
# Askpass helper so `sudo` can prompt graphically instead of requiring a TTY.
# Used by sudo via $SUDO_ASKPASS + SUDO_ASKPASS_REQUIRE=force (see zshenv).
#
# Uses zenity on Wayland.
#
# GTK_IM_MODULE is cleared for the dialog: an IME module in a password prompt
# is undesirable, and a module that is configured but not installed makes GTK
# complain on stderr.
#
# WHY THIS RE-PROMPTS INSTEAD OF EXITING ON AN EMPTY ANSWER
# ------------------------------------------------------
# This machine has pam_faillock enabled in /etc/pam.d/system-auth with the
# built-in defaults from /etc/security/faillock.conf (that file is entirely
# commented out): deny=3, fail_interval=900, unlock_time=600.
#
# sudo retries three times on any failed authentication, and an empty answer
# from askpass counts as a failure. So an askpass helper that gives up as soon
# as the dialog is dismissed/cancelled burns all three strikes instantly, and
# pam_faillock then locks the account for 10 minutes -- during which
# pam_faillock.so preauth rejects even the correct password, in terminals and
# everywhere else. A single stray Escape can therefore lock you out of sudo.
#
# So: keep asking until we actually get a password. Only give up after
# SUDO_ASKPASS_MAX_TRIES (default 10) cancellations.
#
# Callers that drive sudo non-interactively should run `sudo -n true` first
# and abort if it fails -- that makes no authentication attempt at all, versus
# `sudo -v` which still spends strikes on failure.

MAX_TRIES="${SUDO_ASKPASS_MAX_TRIES:-10}"

ask_pass() {
	unset GTK_IM_MODULE
	zenity --password --title="sudo: $1"
}

# No graphical prompt is pointless if nobody can see it, so bail out early
# rather than looping through dialogs that can never be answered.
if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ]; then
	echo "sudo-askpass: no display available (WAYLAND_DISPLAY and DISPLAY are unset)" >&2
	exit 1
fi

i=0
while [ "$i" -lt "$MAX_TRIES" ]; do
	i=$((i + 1))
	# stderr is deliberately NOT hidden: it previously swallowed the real
	# reason a prompt could not be shown, which made this look like a wrong
	# password rather than a failed dialog.
	pass=$(ask_pass "authentication")

	if [ -n "$pass" ]; then
		printf '%s\n' "$pass"
		exit 0
	fi

	if [ "$i" -lt "$MAX_TRIES" ]; then
		echo "sudo-askpass: no password entered; please try again ($i/$MAX_TRIES)" >&2
	fi
done

echo "sudo-askpass: giving up after $MAX_TRIES attempts." >&2
echo "sudo-askpass: note that pam_faillock (deny=3) counts each failed sudo" >&2
echo "sudo-askpass: attempt, so this may have locked the account temporarily." >&2
exit 1