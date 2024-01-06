function update_deno_dependencies() {
  # projectのあるディレクトリに移動する
  pushd ~/Projects/github.com/kyoh86

  # 各ddu-*のディレクトリの中で、dirtyでなければgit pullを実行する。
  # pullした時点でもdirtyでなければ、deno dependenciesの更新を実行する。
  for dir in {ddu,denops}-*; do
    if [ -d "$dir" ]; then
      echo "\e[1m\e[31mUpdating $dir...\e[0m"
      if [ -n "$(git -C "$dir" status --porcelain)" ]; then
        echo "\e[31mThere're changes in $dir\e[0m"
        continue
      fi
      echo "Pulling $dir..."
      git -C "$dir" pull
      if [ -n "$(git -C "$dir" status --porcelain)" ]; then
        echo "\e[31mThere're changes in $dir\e[0m"
        continue
      fi
      echo "No dirty changes in $dir"
      if ! NO_COLOR=1 udd "./$dir/"**/*.ts; then
        echo "\e[31mFailed to update dependencies in $dir\e[0m"
        continue
      fi
      if [ -z "$(git -C "$dir" status --porcelain)" ]; then
        echo "There's no update in $dir"
        continue
      fi
      if ! NO_COLOR=1 deno cache "./$dir/"**/*.ts; then
        echo "\e[31mFailed to cache in $dir\e[0m"
        continue
      fi
      if ! NO_COLOR=1 deno lint "./$dir/"**/*.ts; then
        echo "\e[31mThere're lints in $dir\e[0m"
        continue
      fi
      if [[ -n "./$dir/"**/*_test.ts(#qN) ]]; then
        if ! NO_COLOR=1 deno test "./$dir/"**/*_test.ts; then
          echo "\e[31mFailed to test $dir\e[0m"
          continue
        fi
      fi
      if ! git -C "$dir" add .; then
        echo "\e[31mFailed to stage changes in $dir\e[0m"
        continue
      fi
      if ! git -C "$dir" commit -m "Update dependencies"; then
        echo "\e[31mFailed to commit changes in $dir\e[0m"
        continue
      fi
      if ! git -C "$dir" push; then
        echo "\e[31mFailed to push changes in $dir\e[0m"
        continue
      fi
    fi
  done

  git-statuses

  popd
}
