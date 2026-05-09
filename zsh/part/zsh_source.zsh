function() source_zsh_plugins() {
  setopt localoptions
  setopt noglob
  parts=(${(s/:/)ZSH_SOURCES})
  for s in $parts; do
    source $s
  done
}
source_zsh_plugins
