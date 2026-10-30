" vim-draft: a buffer to write text in before it goes somewhere, for other
" plugins (vim-review's :CommentDraft, vim-prompts' :AiDraft). No commands;
" see roumail_draft#open().
if exists('g:loaded_roumail_draft')
  finish
endif
let g:loaded_roumail_draft = 1
