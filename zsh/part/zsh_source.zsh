function() source_zsh_plugins() {
  setopt localoptions
  setopt noglob
  IFS=:
  for s in $zsh_sources""; do
    source $s
  done
}
source_zsh_plugins
