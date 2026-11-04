" vim-draft: buffers to write text in that aren't files. A draft is opened
" by another plugin and hands its text on when it closes; a scratch is
" opened by you and has nowhere to send it. Either can be saved to a file.
if exists('g:loaded_roumail_draft')
  finish
endif
let g:loaded_roumail_draft = 1

" Where a scratch, or a draft from outside a git repository, is saved when
" :DraftSave is given no path
let g:roumail_draft_save_dir = get(g:, 'roumail_draft_save_dir', expand('~/scratch'))

" New scratch in a vertical split (!: in the current window)
command! -bang Scratch call roumail_draft#scratch#new(<bang>0)

" Scratch in the current window with the output of a shell command
command! -nargs=+ -complete=customlist,roumail_draft#scratch#complete_from ScratchFrom
      \ call roumail_draft#scratch#from(<q-args>)

" Copy a buffer into a new scratch, keeping its filetype.
" No argument or %: current buffer, limited to the range if one is given.
" Otherwise: that whole buffer (name, number or #), or else that file, read
" without opening it (<Tab> completes both).
command! -bang -range=% -nargs=? -complete=customlist,roumail_draft#scratch#complete_buf ScratchBuf
      \ call roumail_draft#scratch#buf(<bang>0, <line1>, <line2>, <q-args>)

" Write the draft or scratch to a file, which it stays apart from: the given
" path, a new timestamped file in the given directory, else the file it was
" last saved to, else a new one in the save directory
command! -bang -nargs=? -complete=file DraftSave call roumail_draft#save(<bang>0, <q-args>)

" Saved files of the current repository and g:roumail_draft_save_dir, newest
" first, in the location list
command! -bar DraftList call roumail_draft#list()
