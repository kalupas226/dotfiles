#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

# shellcheck source=/dev/null
source "${REPO_ROOT}/scripts/lib/ui.sh"

GWT="${REPO_ROOT}/packages/bin/.local/bin/gwt"

fail() {
    warn "$*"
    exit 1
}

meta_file_for_task() {
    local repo_root="$1"
    local task="$2"

    printf '%s/.worktrees/.gwt/tasks/%s.tsv\n' \
        "$repo_root" \
        "$(printf '%s' "$task" | shasum | awk '{print $1}')"
}

setup_repo() {
    local repo_root="$1"

    repo_root="$(cd "$repo_root" && pwd -P)"
    git init -q "$repo_root"
    git -C "$repo_root" config user.name "Test User"
    git -C "$repo_root" config user.email "test@example.com"

    printf 'base\n' >"${repo_root}/README.md"
    git -C "$repo_root" add README.md
    git -C "$repo_root" commit -qm "Initial commit"
}

write_codex_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$wrapper_path"
}

write_new_window_tmux_wrapper() {
    local wrapper_path="$1"
    local tmux_log="$2"
    local session_name="$3"
    local root_label="$4"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cmd="\${1:-}"
shift || true
printf '%s' "\$cmd" >>"${tmux_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${tmux_log}"
done
printf '\n' >>"${tmux_log}"

case "\$cmd" in
    has-session)
        exit 1
        ;;
    new-session)
        exit 0
        ;;
    list-windows)
        printf '%%root\t%s\t\n' "${root_label}"
        ;;
    new-window)
        printf '%%1\n'
        ;;
    list-panes)
        printf '%%2\n'
        ;;
    split-window)
        printf '%%3\n'
        ;;
    set-option|rename-window|select-layout|send-keys|select-pane|select-window|attach-session|switch-client)
        exit 0
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "\$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

write_existing_window_tmux_wrapper() {
    local wrapper_path="$1"
    local tmux_log="$2"
    local task="$3"
    local agent="$4"
    local worktree="$5"
    local root="$6"

    cat >"$wrapper_path" <<EOF
#!/usr/bin/env bash
set -euo pipefail

cmd="\${1:-}"
shift || true
printf '%s' "\$cmd" >>"${tmux_log}"
for arg in "\$@"; do
    printf ' %s' "\$arg" >>"${tmux_log}"
done
printf '\n' >>"${tmux_log}"

case "\$cmd" in
    has-session)
        exit 0
        ;;
    list-windows)
        if [[ "\$*" == *"#{window_name}"* ]]; then
            printf '%%root\tproject@root\t\n'
            printf '%%1\t%s\t%s\n' "${task}" "${task}"
        else
            printf '%%root\t\n'
            printf '%%1\t%s\n' "${task}"
        fi
        ;;
    show-options)
        if [[ "\$*" == *"@gwt_agent_pane"* ]]; then
            printf '%%2\n'
            exit 0
        fi
        if [[ "\$*" == *"@gwt_shell_pane"* ]]; then
            printf '%%3\n'
            exit 0
        fi
        if [[ "\$*" == *"@gwt_agent"* ]]; then
            printf '%s\n' "${agent}"
            exit 0
        fi
        exit 1
        ;;
    display-message)
        if [[ "\$*" == *"#{pane_tty}"* ]]; then
            printf '/dev/ttys999\n'
            exit 0
        fi
        exit 1
        ;;
    list-panes)
        printf '%%2\n%%3\n'
        ;;
    set-option|rename-window|select-layout|select-pane|select-window|switch-client|attach-session)
        exit 0
        ;;
    *)
        printf 'unexpected tmux command: %s\n' "\$cmd" >&2
        exit 1
        ;;
esac
EOF
    chmod +x "$wrapper_path"
}

write_ps_wrapper() {
    local wrapper_path="$1"

    cat >"$wrapper_path" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' 'codex'
EOF
    chmod +x "$wrapper_path"
}

test_add_applies_main_pane_height_for_new_windows() {
    local repo_root
    local wrapper_dir
    local tmux_log
    local task="task-add-new"
    local session_name
    local root_label

    repo_root="$(mktemp -d /tmp/gwt-add-new.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-add-new-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"
    tmux_log="$(mktemp /tmp/gwt-add-new-log.XXXXXX)"

    setup_repo "$repo_root"
    session_name="$(basename "$repo_root" | tr -c '[:alnum:]_-' '-' | sed 's/^[-_]*//; s/[-_]*$//')-$(printf '%s' "$repo_root" | shasum | awk '{print substr($1, 1, 10)}')"
    root_label="$(basename "$repo_root" | tr -c '[:alnum:]_-' '-' | sed 's/^[-_]*//; s/[-_]*$//')@root"

    write_new_window_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log" "$session_name" "$root_label"
    write_codex_wrapper "${wrapper_dir}/codex"

    (cd "$repo_root" && PATH="${wrapper_dir}:$PATH" "$GWT" add --agent codex "$task")

    grep -F "set-option -w -t %1 main-pane-height 75%" "$tmux_log" >/dev/null ||
        fail "expected add to set main-pane-height for new windows"
    grep -F "set-option -p -t %2 @pane_label codex" "$tmux_log" >/dev/null ||
        fail "expected add to label the agent pane"
    grep -F "set-option -p -t %3 @pane_label shell" "$tmux_log" >/dev/null ||
        fail "expected add to label the shell pane"

    rm -rf "$repo_root" "$wrapper_dir" "$tmux_log"
}

test_open_applies_main_pane_height_when_reusing_windows() {
    local repo_root
    local wrapper_dir
    local tmux_log
    local task="task-open-existing"
    local branch="task-open-existing"
    local worktree
    local metadata_file

    repo_root="$(mktemp -d /tmp/gwt-open-existing.XXXXXX)"
    repo_root="$(cd "$repo_root" && pwd -P)"
    wrapper_dir="$(mktemp -d /tmp/gwt-open-existing-wrapper.XXXXXX)"
    wrapper_dir="$(cd "$wrapper_dir" && pwd -P)"
    tmux_log="$(mktemp /tmp/gwt-open-existing-log.XXXXXX)"

    setup_repo "$repo_root"
    worktree="${repo_root}/.worktrees/${task}"
    git -C "$repo_root" worktree add -q -b "$branch" "$worktree"
    mkdir -p "${repo_root}/.worktrees/.gwt/tasks"
    metadata_file="$(meta_file_for_task "$repo_root" "$task")"
    printf '%s\t%s\t%s\t%s\t%s\n' \
        "$task" \
        "codex" \
        "$worktree" \
        "$branch" \
        "$repo_root" >"$metadata_file"

    write_existing_window_tmux_wrapper "${wrapper_dir}/tmux" "$tmux_log" "$task" "codex" "$worktree" "$repo_root"
    write_codex_wrapper "${wrapper_dir}/codex"
    write_ps_wrapper "${wrapper_dir}/ps"

    (cd "$repo_root" && TMUX=1 PATH="${wrapper_dir}:$PATH" "$GWT" open "$task")

    grep -F "set-option -w -t %1 main-pane-height 75%" "$tmux_log" >/dev/null ||
        fail "expected open to reapply main-pane-height for reused windows"
    grep -F "set-option -p -t %2 @pane_label codex" "$tmux_log" >/dev/null ||
        fail "expected open to label the agent pane"
    grep -F "set-option -p -t %3 @pane_label shell" "$tmux_log" >/dev/null ||
        fail "expected open to label the shell pane"

    rm -rf "$repo_root" "$wrapper_dir" "$tmux_log"
}

main() {
    step "Running gwt add/open layout tests"
    test_add_applies_main_pane_height_for_new_windows
    ok "add applies the managed main pane height for new windows"
    test_open_applies_main_pane_height_when_reusing_windows
    ok "open reapplies the managed main pane height for reused windows"
}

main "$@"
