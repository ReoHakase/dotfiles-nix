export GPG_TTY=$(tty)

if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)"
fi

# Nix の CLI を Homebrew より優先（sessionPath と二重にならないよう path を一意化）
typeset -U path PATH
path=(
  /etc/profiles/per-user/$USER/bin
  /nix/var/nix/profiles/default/bin
  $path
)
