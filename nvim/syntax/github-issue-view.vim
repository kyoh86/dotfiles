" Clear all existing syntax
syntax clear

syntax include @Markdown syntax/markdown.vim

" ---------------------------------------------
"  タイトル部分
"  例: #1234 [open] Title of the Issue
syntax region githubIssueTitle start=/\m\(^\)\@<=TITLE:>=\+$/ end=/\m^\(META:>=\+$\)\@=/
      \ keepend
      \ contains=githubIssueTitleMarkerStart,githubIssueNumber,githubIssueStateOpen,githubIssueStateClosed
      \ nextgroup=githubIssueMeta
syntax match githubIssueTitleMarkerStart /^TITLE:>=\+/
      \ contained
syntax match githubIssueNumber /^#\d\+/ 
      \ contained
      \ nextgroup=githubIssueStateOpen,githubIssueStateClosed
syntax match githubIssueStateOpen /\[open\]/
      \ contained
syntax match githubIssueStateClosed /\[closed\]/
      \ contained

" ---------------------------------------------
"  メタ情報
syntax region githubIssueMeta start=/\m\(^\)\@<=META:>=\+$/ end=/\m^\(BODY:>=\+$\)\@=/
      \ contains=githubIssueMetaMarkerStart,githubIssueMetaKey,githubIssueMetaDelimiter,githubIssueMetaValue
      \ keepend
      \ nextgroup=githubIssueBody
syntax match githubIssueMetaMarkerStart /^META:>=\+$/
      \ contained
" RepositoryなどのKey:Value行
syntax match githubIssueMetaKey /\m^\[[^\]]*\]/
      \ contained
      \ nextgroup=githubIssueMetaDelimiter
syntax match githubIssueMetaDelimiter /\m\s:\s/
      \ contained
      \ nextgroup=githubIssueMetaValue
syntax match githubIssueMetaValue /\( : \)\@<=.*$/
      \ containedin=githubIssueMeta

" ---------------------------------------------
"  ボディ
syntax region githubIssueBody start=/\m\(^\)\@<=BODY:>=\+$/ end=/\m^\(COMMENTS (\d\+):>=\+$\)\@=/
    \ contains=githubIssueBodyMarkerStart,@Markdown
    \ keepend
syntax match githubIssueBodyMarkerStart /^BODY:>=\+/ contained

" ---------------------------------------------
"  コメント
syntax match githubIssueCommentMarkerStart /^COMMENTS (\d\+):>=\+$/ 
      \ contains=githubIssueCommentCount
syntax match githubIssueCommentCount /\(^COMMENTS (\)\@<=\d\+\():>=\+$\)\@=/

" コメントブロック識別
syntax region githubIssueComment start=/\m\(^\)\@<=-- C-#\d\+ / end=/\m\(^\)\@<=: /
      \ contains=githubIssueCommentMeta,@Markdown
      \ keepend
syntax match githubIssueCommentMeta /^-- C-#\d\+ @[^ ]\+ \d\{4,\}-\d\d-\d\d \d\d:\d\d\( \[[a-zA-Z]\+\(, [a-zA-Z]\+\)*\]\)\? -\+$/
      \ contained
      \ contains=githubIssueCommentMetaNumber,githubIssueCommentMetaAuthor,githubIssueCommentFlag

syntax match githubIssueCommentMetaNumber  /#\d\+/ contained
syntax match githubIssueCommentMetaAuthor  /@[^ ]\+/ contained

syntax region githubIssueCommentFlag start="\[" end="\]"
      \ contained
      \ contains=githubIssueCommentFlagEdited,githubIssueCommentFlagAuthor,githubIssueCommentFlagOwner

syntax keyword githubIssueCommentFlagEdited Edited contained
syntax keyword githubIssueCommentFlagAuthor Author contained
syntax keyword githubIssueCommentFlagOwner  Owner  contained

" ---------------------------------------------
"  ハイライト

" タイトルセクション関連
highlight link githubIssueTitle              Title
highlight link githubIssueTitleMarkerStart   Label

highlight link githubIssueNumber             Number
highlight link githubIssueStateOpen          Normal
highlight link githubIssueStateClosed        WarningMsg

" メタ情報セクション関連
highlight link githubIssueMeta               Normal
highlight link githubIssueMetaMarkerStart    Label
highlight link githubIssueMetaKey            Define
highlight link githubIssueMetaDelimiter      Delimiter
highlight link githubIssueMetaValue          String

" 本文セクション関連
highlight link githubIssueBody               Normal
highlight link githubIssueBodyMarkerStart    Label

" コメントセクション関連
highlight link githubIssueCommentMarkerStart Label
highlight link githubIssueCommentCount       Number
highlight link githubIssueCommentMeta        Label
highlight link githubIssueCommentMetaNumber  Number
highlight link githubIssueCommentMetaAuthor  Identifier
highlight link githubIssueCommentFlag        Type
highlight link githubIssueCommentFlagEdited  Keyword
highlight link githubIssueCommentFlagAuthor  Keyword
highlight link githubIssueCommentFlagOwner   Keyword
