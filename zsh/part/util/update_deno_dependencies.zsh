function _update_deno_dependencies() {
  pushd "$1"
  _update_deno_dependencies_core "$1"
  popd
}

function _update_deno_dependencies_core() {
  local dir="$1"
  echo "\e[1m\e[31mUpdating $dir...\e[0m"
  if [ -n "$(git status --porcelain)" ]; then
    echo "\e[31mThere're changes in $dir\e[0m"
    return
  fi
  echo "Pulling $dir..."
  git pull
  if [ -n "$(git status --porcelain)" ]; then
    echo "\e[31mThere're changes in $dir\e[0m"
    return
  fi
  echo "No dirty changes in $dir"
  if ! NO_COLOR=1 udd ./**/*.ts; then
    echo "\e[31mFailed to update dependencies in $dir\e[0m"
    return
  fi
  if [ -z "$(git status --porcelain)" ]; then
    echo "There's no update in $dir"
    return
  fi
  if ! NO_COLOR=1 deno cache ./**/*.ts; then
    echo "\e[31mFailed to cache in $dir\e[0m"
    return
  fi
  if ! NO_COLOR=1 deno task lint; then
    echo "\e[31mThere're lints in $dir\e[0m"
    return
  fi
  if [[ -n ./**/*_test.ts(#qN) ]]; then
    if ! NO_COLOR=1 deno task test; then
      echo "\e[31mFailed to test $dir\e[0m"
      return
    fi
  fi
  if ! git add .; then
    echo "\e[31mFailed to stage changes in $dir\e[0m"
    return
  fi
  if ! git commit -m "Update dependencies"; then
    echo "\e[31mFailed to commit changes in $dir\e[0m"
    return
  fi
  if ! git push; then
    echo "\e[31mFailed to push changes in $dir\e[0m"
    return
  fi
}

function update_deno_dependencies() {
  # projectのあるディレクトリに移動する
  pushd ~/Projects/github.com/kyoh86

  # 各ddu-*のディレクトリの中で、dirtyでなければgit pullを実行する。
  # pullした時点でもdirtyでなければ、deno dependenciesの更新を実行する。
  _update_deno_dependencies denops-util
  for dir in {ddu,denops}-*; do
    if [ -d "$dir" ]; then
      _update_deno_dependencies "$dir"
    fi
  done

  git-statuses

  popd
}
