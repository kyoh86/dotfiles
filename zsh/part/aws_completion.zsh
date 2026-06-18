aws_completion() {
  if command -v mise >/dev/null 2>&1; then
    dirname=$(dirname "$(mise which aws)")
    complete -C "${dirname}/aws_completer" aws
  fi
}
aws_completion
