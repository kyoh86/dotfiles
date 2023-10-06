IFS=:; set -o noglob
for s in $zsh_sources""; do
  source $s
done
