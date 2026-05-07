export GPG_TTY=$(tty)

# ユーザ site-packages（~/.local/lib/python*）を読ませない（venv / システム Python の混線防止）
export PYTHONNOUSERSITE=1

if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)"
fi

if (( $+functions[compdef] )); then
  compdef _cd z
fi
