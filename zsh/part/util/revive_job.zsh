# 中断ジョブの復帰
function revive_job() {
    jobs | fzf | awk '{print $1}' | perl -pe 's/\[(\d+)\]/%$1/g' | xargs -n1 -r fg
}
zle -N revive_job
bindkey '^Z' revive_job
