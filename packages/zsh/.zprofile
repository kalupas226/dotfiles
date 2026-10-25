if command -v brew >/dev/null 2>&1; then
  eval "$(brew shellenv)"
elif [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

if [ -n "${HOMEBREW_PREFIX:-}" ] && [ -d "${HOMEBREW_PREFIX}/opt/curl/bin" ]; then
  export PATH="${HOMEBREW_PREFIX}/opt/curl/bin:${PATH}"
fi
