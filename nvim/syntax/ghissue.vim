" Clear all existing syntax
syntax clear

syntax include @Markdown syntax/markdown.vim

" ---------------------------------------------
"  タイトル部分
"  例: #1234 [open] Title of the Issue
syntax region ghIssueTitle start=/^TITLE:>=\+$/ end=/^\(META:>=\+$\)\@=/
    \ contains=ghIssueTitleMarkerStart,ghIssueNumber,ghIssueStateOpen,ghIssueStateClosed
    \ keepend
syntax match ghIssueTitleMarkerStart /^TITLE:>=\+/ contained
syntax match ghIssueNumber /^#\d\+/ contained nextgroup=ghIssueStateOpen,ghIssueStateClosed
syntax match ghIssueStateOpen /\[open\]/ contained
syntax match ghIssueStateClosed /\[closed\]/ contained

" ---------------------------------------------
"  メタ情報
syntax region ghIssueMeta start=/\(^\)\@<=META:>=\+$/ end=/^\(BODY:>=\+$\)\@=/
    \ contains=ghIssueMetaMarkerStart,ghIssueMetaKey,ghIssueMetaDelimiter
    \ keepend
syntax match ghIssueMetaMarkerStart /^META:>=\+$/ contained
" RepositoryなどのKey:Value行
syntax match ghIssueMetaKey /\v^\[[^\]]*\]/ contained nextgroup=ghIssueMetaDelimiter
syntax match ghIssueMetaDelimiter /\v\s:\s/ contained nextgroup=ghIssueMetaValue

" ---------------------------------------------
"  ボディ
syntax region ghIssueBody start=/\(^\)\@<=BODY:>=\+$/ end=/^\(COMMENTS (\d\+):>=\+$\)\@=/
    \ contains=ghIssueBodyMarkerStart,@Markdown
    \ keepend
syntax match ghIssueBodyMarkerStart /^BODY:>=\+/ contained

" ---------------------------------------------
"  コメント
syntax region ghIssueComment start=/^COMMENTS (\d\+):>=\+$/ end=/^<:COMMENTS$/
    \ contains=ghIssueCommentMarkerStart,ghIssueCommentMeta
    \ keepend
syntax match ghIssueCommentMarkerStart /^COMMENTS (\d\+):>=\+$/ 
      \ contained
      \ contains=ghIssueCommentCount
syntax match ghIssueCommentCount /\(^COMMENTS (\)\@<=\d\+\():>=\+$\)\@=/

" コメントブロック識別
syntax match ghIssueCommentMeta /^-- #\d\+ @[^ ]\+ \d\{4,\}-\d\d-\d\d \d\d:\d\d\( \[[a-zA-Z]\+\(, [a-zA-Z]\+\)*\]\)\? -\+$/
      \ contained
      \ contains=ghIssueCommentMetaNumber,ghIssueCommentMetaAuthor,ghIssueCommentFlag

syntax match ghIssueCommentMetaNumber  /#\d\+/ contained
syntax match ghIssueCommentMetaAuthor  /@[^ ]\+/ contained

syntax region ghIssueCommentFlag start="\[" end="\]"
      \ contained
      \ contains=ghIssueCommentFlagEdited,ghIssueCommentFlagAuthor,ghIssueCommentFlagOwner

syntax keyword ghIssueCommentFlagEdited Edited contained
syntax keyword ghIssueCommentFlagAuthor Author contained
syntax keyword ghIssueCommentFlagOwner  Owner  contained

" ---------------------------------------------
"  ハイライト

" タイトルセクション関連
highlight link ghIssueTitle              Title
highlight link ghIssueTitleMarkerStart   Label

highlight link ghIssueNumber             Number
highlight link ghIssueStateOpen          Normal
highlight link ghIssueStateClosed        WarningMsg

" メタ情報セクション関連
highlight link ghIssueMeta               Normal
highlight link ghIssueMetaMarkerStart    Label
highlight link ghIssueMetaKey            Define
highlight link ghIssueMetaDelimiter      Delimiter
highlight link ghIssueMetaValue          String

" 本文セクション関連
highlight link ghIssueBody               Normal
highlight link ghIssueBodyMarkerStart    Label

" コメントセクション関連
highlight link ghIssueComment            Normal
highlight link ghIssueCommentMarkerStart Label
highlight link ghIssueCommentCount       Number
highlight link ghIssueCommentMeta        Label
highlight link ghIssueCommentMetaNumber  Number
highlight link ghIssueCommentMetaAuthor  Identifier
highlight link ghIssueCommentFlag        Type
highlight link ghIssueCommentFlagEdited  Keyword
highlight link ghIssueCommentFlagAuthor  Keyword
highlight link ghIssueCommentFlagOwner   Keyword
