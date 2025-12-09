#!/usr/bin/env sh

# Shared UI helpers for scripts. Keep POSIX-ish so bash/zsh can source.
# Idempotent: sourcing twice is safe.

if [ -z "${UI_HELPERS_INIT:-}" ]; then
    UI_HELPERS_INIT=1

    # Colors (TTY + NO_COLOR disabled) via tput if available
    if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && command -v tput >/dev/null 2>&1 && tput colors >/dev/null 2>&1; then
        RESET="$(tput sgr0)"
        BOLD="$(tput bold)"
        CYAN="$(tput setaf 6)"
        GREEN="$(tput setaf 2)"
        YELLOW="$(tput setaf 3)"
        BLUE="$(tput setaf 4)"
        MAGENTA="$(tput setaf 5)"
    else
        RESET=""
        BOLD=""
        CYAN=""
        GREEN=""
        YELLOW=""
        BLUE=""
        MAGENTA=""
    fi

    # Lines/icons (overrideable)
    LINE_HYPHEN=${LINE_HYPHEN:-"------------------------------------------------------------"}
    LINE_EQUAL=${LINE_EQUAL:-"============================================================"}

    STEP_ICON=${STEP_ICON:-"🚀"}
    NOTE_ICON=${NOTE_ICON:-"🔧"}
    WARN_ICON=${WARN_ICON:-"⚠️ "}
    OK_ICON=${OK_ICON:-"✅"}
    SKIP_ICON=${SKIP_ICON:-"[skip]"}

    section_line() { printf "%s%s%s\n" "${BOLD}" "${LINE_HYPHEN}" "${RESET}"; }
    step() {
        printf "\n%s%s%s\n" "${BOLD}" "${LINE_EQUAL}" "${RESET}"
        printf "%s%s %s%s\n" "${CYAN}" "${STEP_ICON}" "$*" "${RESET}"
        printf "%s%s%s\n" "${BOLD}" "${LINE_EQUAL}" "${RESET}"
    }
    note() { printf "%s%s %s%s\n" "${YELLOW}" "${NOTE_ICON}" "$*" "${RESET}"; }
    warn() { printf "%s%s %s%s\n" "${YELLOW}" "${WARN_ICON}" "$*" "${RESET}"; }
    ok() { printf "%s%s %s%s\n" "${GREEN}" "${OK_ICON}" "$*" "${RESET}"; }
    skip() { printf "%s%s %s%s\n" "${BLUE}" "${SKIP_ICON}" "$*" "${RESET}"; }
fi
