export GPG_TTY=$(tty)

if command -v uv >/dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)"
fi

# Nix profile を Homebrew /システムより優先（sessionPath と二重にならないよう path を一意化）
typeset -U path PATH
path=(
  "$HOME/.nix-profile/bin"
  /nix/var/nix/profiles/default/bin
  $path
)
