# Neovim/tmuxのペイン配置について

Neovim,tmuxのペイン配置をキーボード操作する方法を、同じI/Fで扱えるようにする。
NOTE: Neovimでは `window` 、tmuxでは `pane` だが、紛らわしいのでともに「`Pane`ペイン」と呼ぶことにする。

<style>
.view {
    margin: 1em 0;
    display: flex;
    gap: 12px;

    > pre {
        margin-bottom: 0 !important;
    }

    .anot {
        font-size: 8pt;
        text-wrap: wrap;
    }

    div {
        font-family: monospace;
        align-self: start;
        border-radius: 6px;

        &.focus {
            box-shadow: rgba(79, 79, 117, 100%) 0 0 1px 2px;
            background-color: rgba(194, 194, 242, 100%);

            &>div:nth-child(2) {
                background-color: rgba(255, 255, 255, 40%);
            }
            &.pane {
                background-color: rgba(242, 194, 194, 100%);
            }
        }

        &.pane {
            border: 1px solid #666666;
            min-width: 8em;
            min-height: 8em;

            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;

            &.incw {
                min-width: 10em;
            }
            &.decw {
                min-width: 6em;
            }

            &.inch {
                min-height: 10em;
            }
            &.dech {
                min-height: 6em;
            }
        }

        &.H {
            display: grid;
            grid-auto-flow: row;
            grid-template-columns: auto auto;
        }

        &.V {
            display: grid;
            grid-auto-flow: column;
            grid-template-rows: auto auto;
        }
    }
}
</style>

## サポートしたい機能

- フォーカスの変更
- ペインの分割（作成）
- ペインの入れ替え
- 分割方向の変更
- 分割サイズの変更

## ペイン構造の表現方法

分割されたペイン群は、**全二分木**として表現する。
本来はn分木で表現することも可能だが、検討の結果二分木のほうが扱いやすいためそうする。

以下に例を示す。
Pane の各番号は分割ごとに新しいペインに次の順序を割り当てたものとする。

### 例1: 分割されてない状態

<div class="view">
    <div class="pane"></div>

```
-- pane
```

</div>
### 例2: ヨコに1回だけ分割した状態

<div class="view">
    <div class="H">
        <div class="pane"></div>
        <div class="pane"></div>
    </div>

```
-- H
    +- pane
    +- pane
```

</div>

### 例3: タテヨコに分割した状態

1. タテに分割
1. 上のペインをヨコに分割

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H
    |   +- pane
    |   +- pane
    |
    +- pane
```

</div>

### 例4: ヨコに2回分割した状態

1. ヨコに分割
1. 右のペインを更にヨコに分割

<div class="view">
    <div class="H">
        <div class="pane"></div>
        <div class="H">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
    </div>

```
-- H
    +- H
    |   +- pane
    |   +- pane
    |
    +- pane
```

</div>

### データ表現の形

各ペインはツリー構造で表現されるが、各ノードは以下のような構造で表現できるだろう。
（便宜上TypeScriptで表現する）

```typescript
type Node = Horizontal | Vertical | Pane

type Pane {
    kind: "pane";
    ... // その他のペインに関する情報群を持ちうる。PaneIDやWindowIDなど
}

type Horizontal {
    kind: "horizontal";
    first: Node;
    second: Node;
    ... // サイズなどの情報を持ちうる。未検討
}

type Vertical {
    kind: "vertical";
    first: Node;
    second: Node;
    ... // サイズなどの情報を持ちうる。未検討
}

var root Node
```

全ての`Horizontal`,`Vertical`の`first`/`second`が**nullableではない**点に要注意（冒頭に述べた通り、全二分木であるため、欠落はない）。

## 操作

ペインの操作は、特別なモードを設けてその中で完結させる。
以下の各操作での状態を、ペインの図（HTML）と入れ子リストで表現している。

凡例は以下の通り:

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane">pane A<span class="anot">フォーカスされた<br />ノードの最初の子</span></div>
            <div class="pane">pane B<span class="anot">フォーカスされた<br />ノードの2番目の子</span></div>
        </div>
        <div class="pane">pane C</div>
    </div>

```
-- V
    +- H           <<╮  // フォーカスされたノード
    |   +- pane A    │  // フォーカスされたノードの子孫 (1st child)
    |   +- pane B    │
    |               ─╯  // フォーカスされたノードの終端
    +- pane C
```

</div>

<div class="view">
    <div class="H">
        <div class="pane focus">pane A<span class="anot">フォーカスされた<br />末端ノード</span></div>
        <div class="pane">pane B</div>
    </div>

```
-- H
    +- pane A   <<   // フォーカスされた末端ノード
    +- pane B        // フォーカス外のノード
```

</div>

### 操作モードの開始

操作モードに入ると、操作を開始したペインにそのままフォーカスされた状態から始まる。

<div class="view">
    <div class="H">
        <div class="pane"></div>
        <div class="pane focus"></div>
    </div>

```
-- H
    +- pane
    +- pane    <<
```

</div>

### フォーカスの変更: 親 (u: parent)

親のあるノードがフォーカスされているとき、親ノードへフォーカスを変更できる。
また、さらにその親ノードへと繰り返し（親がなくなるまで）フォーカスを変更できる。

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane"></div>
            <div class="pane focus"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H
    |   +- pane
    |   +- pane   <<
    |
    +- pane
```

</div>

親ノードへフォーカスを変更した場合:

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H         <<╮
    |   +- pane    │
    |   +- pane    │
    |             ─╯
    +- pane
```

</div>

さらに親ノードへフォーカスを変更した場合:

<div class="view">
    <div class="V focus">
        <div class="H">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V             <<╮
    +- H           │
    |   +- pane    │
    |   +- pane    │
    |              │
    +- pane        │
                  ─╯
```

</div>

### フォーカスの変更: 子 (1/2: child)

子を持つノードがフォーカスされているとき、1つ目の子ノード、2つ目の子ノードにそれぞれ直接フォーカスを変更することができる。

<div class="view">
    <div class="V focus">
        <div class="H">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V             <<╮
    +- H           │
    |   +- pane    │
    |   +- pane    │
    |              │
    +- pane        │
                  ─╯
```

</div>

1つ目の子にフォーカスを変更した場合:

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H         <<╮
    |   +- pane    │
    |   +- pane    │
    |             ─╯
    +- pane
```

</div>

2つ目の子にフォーカスを変更した場合:

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane focus"></div>
    </div>

```
-- V
    +- H
    |   +- pane
    |   +- pane
    +- pane       <<
```

</div>

### フォーカスの変更: 兄弟 (o: sibling)

親のあるノードがフォーカスされているとき、兄弟要素へフォーカスを変更できる。
もう一度同じ操作を行えば、元のノードにフォーカスが戻る（全二分木なので、兄弟は常に2つである）

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane"></div>
            <div class="pane focus"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H
    |   +- pane
    |   +- pane   <<
    +- pane
```

</div>

1回目の変更:

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane focus"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H
    |   +- pane   <<
    |   +- pane
    +- pane
```

</div>

2回目の変更:

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane"></div>
            <div class="pane focus"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H
    |   +- pane
    |   +- pane   <<
    +- pane
```

</div>

フォーカス中のノードが末端のペインでなく子を持つノードだったとしても、同じ親を持つ兄弟間でフォーカスを変更できる。
もう一度操作すれば元のフォーカスに戻るのも同様である。

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H         <<╮
    |   +- pane    │
    |   +- pane    │
    |             ─╯
    +- pane
```

</div>

1回目の変更:

<div class="view">
    <div class="V">
        <div class="H">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane focus"></div>
    </div>

```
-- V
    +- H
    |   +- pane
    |   +- pane
    |
    +- pane       <<
```

</div>

2回目の変更:

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
        <div class="pane"></div>
    </div>

```
-- V
    +- H         <<╮
    |   +- pane    │
    |   +- pane    │
    |             ─╯
    +- pane
```

</div>

### ペインの分割 (v/s + Enter: split)

末端のノード（＝ペイン）がフォーカスされている時、タテまたはヨコに分割することができる。

<div class="view">
    <div class="pane focus"></div>

```
-- pane   <<
```

</div>

ヨコに分割した場合:

<div class="view">
    <div class="H">
        <div class="pane focus"></div>
        <div class="pane"></div>
    </div>

```
-- H
    +- pane   <<
    +- pane
```

</div>

タテに分割した場合:

<div class="view">
    <div class="V">
        <div class="pane focus"></div>
        <div class="pane"></div>
    </div>

```
-- V
    +- pane   <<
    +- pane
```

</div>

子があるノードにフォーカスしているときは、この操作はできないものとする。

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane"></div>
            <div class="pane"></div>
        </div>
    </div>

```
-- V
    +- H         <<╮
        +- pane    │
        +- pane    │
                  ─╯
```

</div>

→分割できない

### ペインの入れ替え (f: flip)

子を持つノードがフォーカスされているとき、子ノード同士を入れ替えることができる。

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

入れ替え後:

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane">pane B</div>
            <div class="pane">pane A</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane B    │
        +- pane A    │
                    ─╯
```

</div>

直接の子が末端ノード（ペイン）でなくても、入れ替え可能である。

<div class="view">
    <div class="V focus">
        <div class="H">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
        <div class="pane">pane C</div>
    </div>

```
-- V               <<╮
    +- H             │
    |   +- pane A    │
    |   +- pane B    │
    |                │
    +- pane C        │
                    ─╯
```

</div>

入れ替え後:

<div class="view">
    <div class="V focus">
        <div class="pane">pane C</div>
        <div class="H">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
    </div>

```
-- V               <<╮
    +- pane C        │
    |                │
    +- H             │
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

末端ノード（ペイン）を選択しているときは、入れ替え操作はできないものとする。

### 分割方向の変更 (t: toggle)

子を持つノードがフォーカスされているとき、分割の方向を変更することができる。

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

入れ替え後:

<div class="view">
    <div class="V">
        <div class="V focus">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
    </div>

```
-- V
    +- V           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

もう一度変更すれば、もとに戻る:

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

末端ノード（ペイン）を選択しているときは、分割方向の変更操作はできないものとする。

### 分割サイズの変更 ([/]: grow)

子を持つノードがフォーカスされているとき、子ノード同士のサイズを変えることができる。
1つ目のノードを大きくするか、2つ目のノードを大きくするかの2択となる。
（区切り線を上下左右に動かすイメージ）

<div class="view">
    <div class="V">
        <div class="H focus">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

1つ目のノードを拡大した場合:

<div class="view">
    <div class="V">
        <div class="H focus inc1">
            <div class="pane incw">pane A</div>
            <div class="pane decw">pane B</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

2つ目のノードを拡大した場合:

<div class="view">
    <div class="V">
        <div class="H focus inc2">
            <div class="pane decw">pane A</div>
            <div class="pane incw">pane B</div>
        </div>
    </div>

```
-- V
    +- H           <<╮
        +- pane A    │
        +- pane B    │
                    ─╯
```

</div>

フォーカスしたノードの直接の子が末端ノード（ペイン）でなくても、リサイズ可能である。

<div class="view">
    <div class="V focus">
        <div class="H">
            <div class="pane">pane A</div>
            <div class="pane">pane B</div>
        </div>
        <div class="pane">pane C</div>
    </div>

```
-- V               <<╮
    +- H             │
    |   +- pane A    │
    |   +- pane B    │
    |                │
    +- pane C        │
                    ─╯
```

</div>

1つ目のノードを拡大した場合:

<div class="view">
    <div class="V focus">
        <div class="H">
            <div class="pane inch">pane A</div>
            <div class="pane inch">pane B</div>
        </div>
        <div class="pane dech">pane C</div>
    </div>

```
-- V               <<╮
    +- H             │
    |   +- pane A    │
    |   +- pane B    │
    |                │
    +- pane C        │
                    ─╯
```

</div>

2つ目のノードを拡大した場合:

<div class="view">
    <div class="V focus">
        <div class="H">
            <div class="pane dech">pane A</div>
            <div class="pane dech">pane B</div>
        </div>
        <div class="pane inch">pane C</div>
    </div>

```
-- V               <<╮
    +- H             │
    |   +- pane A    │
    |   +- pane B    │
    |                │
    +- pane C        │
                    ─╯
```

</div>

末端ノード（ペイン）を選択しているときは、分割サイズの変更操作はできないものとする。

## キーバインド

### 仕様にある機能

| キー | 操作 | 条件 |
|------|------|------|
| `u` | 親へフォーカス移動 | 親が存在 |
| `1` | 1つ目の子へフォーカス移動 | 子が存在 |
| `2` | 2つ目の子へフォーカス移動 | 子が存在 |
| `o` | 兄弟へフォーカス移動 | 親が存在 |
| `v` + `Enter` | 縦に分割 | 末端ノードのみ |
| `s` + `Enter` | 横に分割 | 末端ノードのみ |
| `f` | 入れ替え (flip) | 子を持つノード |
| `t` | 分割方向の変更 (H ↔ V) | 子を持つノード |
| `[` | 1つ目の子を拡大 | 子を持つノード |
| `]` | 2つ目の子を拡大 | 子を持つノード |

### 追加機能（実用的な拡張）

| キー | 操作 | 説明 |
|------|------|------|
| `h`/`j`/`k`/`l` | 隣接ペイン移動 | 幾何学的な位置に基づいて移動 |
| `r` | 回転 (rotate) | 分割方向を変更しつつ子を入れ替え |
| `.` | フォーカスを選択 | 現在のフォーカス位置を選択 |
| `q`, `C-c`, `Esc` | モード終了 | 操作モードを終了 |

### モード開始

- **Neovim**: `<C-w><C-w>` でモードに入る
- **tmux**: `prefix + C-w` でモードに入る

### 注意事項

- `h`/`j`/`k`/`l` は仕様にはないが、実用的な UX 向上として実装されている
- Neovim と tmux で同等の操作感を目指している
- 一部の機能（rotate 等）は Neovim の API 制限により「best-effort」実装となっている
