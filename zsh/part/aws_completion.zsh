aws_completion() {
  if [ ! command -v mise >/dev/null 2>&1 ]; then
    return 0
  fi

  dirname=$(dirname "$(mise which aws)")
  complete -C "${dirname}/aws_completer" aws
}
aws_completion
