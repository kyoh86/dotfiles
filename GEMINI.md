# Gemini向けリポジトリガイドライン

このドキュメントは、このリポジトリを操作する上でのGemini向けガイドラインです。

## 基本方針

- あなたとのやり取りは、特に指定がない限り日本語で行います。
- このリポジトリは、様々なツールやアプリケーションの設定ファイル（dotfiles）を管理するものです。変更を加える際は、既存の構造やスタイルを尊重してください。

## プロジェクト構造

- `nvim/`: Neovimの設定が含まれます。
    - `denops/`: Deno/TypeScriptで書かれたdenopsプラグインのソースコードとテスト。
    - `lua/`: Luaモジュールとプラグイン設定。
- `setup/`: OS固有の初期設定スクリプト（`arch`, `ubuntu24`, `darwin`など）。
- `bin/`: 小さなヘルパースクリプト。
- `dotfiles-agent/`: GitHubの認証情報ヘルパーとして機能するDockerイメージをビルドします。
- その他（`zsh`, `wezterm`, `git`, `gh`など）: 各ツールの設定ファイルが格納されています。新しい設定を追加する場合は、関連するツールのディレクトリに配置してください。

## ビルド、テスト、開発コマンド

- **TypeScript/Deno (`nvim/`ディレクトリで実行):**
    - `deno task fmt`: TypeScript/JSONCのフォーマット。
    - `deno task lint`: 静的解析。
    - `deno task check`: 型チェック。
    - `deno task test`: denopsのテスト実行（`vim`/`nvim`が`PATH`に必要）。
    - `deno task update`: denopsの依存関係を更新。

- **Lua:**
    - `stylua --config stylua/stylua.toml nvim/**/*.lua`: NeovimのLuaファイルをフォーマット。

## コーディングスタイル

- **TypeScript:** Denoのデフォルトスタイルに従います（2スペースインデント、ESモジュール）。テストファイルは `_test.ts` サフィックスを使用します。
- **Lua:** 2スペースインデントを使用します（`stylua/stylua.toml`参照）。
- **ファイル名:** 小文字のスネークケースまたはケバブケースを使用し、既存の命名規則に従ってください。

## テストのガイドライン

- テストは `nvim/denops/**/*_test.ts` に配置します。
- 変更をプッシュする前に `deno task test` を実行してください。CIと同様に、`DENOPS_TEST_*` 環境変数でVim/Neovimのバイナリパスを指定する必要がある場合があります。

## コミットとプルリクエスト

- コミットメッセージは短く、命令形で記述します（例: `feat: 新機能を追加`, `fix: denopsの環境変数を修正`）。
- プルリクエストを作成する前に、フォーマット (`deno task fmt`, `stylua`)、リント (`deno task lint`)、型チェック (`deno task check`)、テスト (`deno task test`) を実行してください。
- プルリクエストの概要では、変更範囲、影響を受けるプラットフォーム（WSL, macOSなど）、手動での手順（`setup/`のスクリプト実行など）を記述してください。
