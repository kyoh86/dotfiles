function update_deno_dependencies() {
  # projectのあるディレクトリに移動する
  pushd ~/Projects/github.com/kyoh86

  # 各ddu-*のディレクトリの中で、git pullを実行する。
  # pullした時点で、dirtyでなければ、deno dependenciesの更新を実行する。
  for dir in {ddu,denops}-*; do
    if [ -d "$dir" ]; then
      echo "Updating $dir..."
      git -C "$dir" pull
      if [ -z "$(git -C "$dir" status --porcelain)" ]; then
        echo "No changes in $dir"
        udd "./$dir/"**/*.ts | tee /tmp/udd_log.txt
        deno cache "./$dir/"**/*.ts | tee /dev/null
        git -C "$dir" add .
        git -C "$dir" commit -m "Update dependencies"
        git -C "$dir" push
      else
        echo "Changes in $dir"
      fi
    fi
  done

  git-statuses

  popd
}
