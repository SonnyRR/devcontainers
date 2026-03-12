if [[ $- == *i* ]]; then
  if command -v fnm >/dev/null 2>&1; then
    eval "$(fnm env --use-on-cd --shell bash)"
  fi
fi
