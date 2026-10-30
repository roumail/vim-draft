" vim-draft: a buffer used as a git commit message: :w saves, closing it
" hands on the text last saved, and an empty one (or :q! before any :w)
" hands on nothing. Closing it never quits Vim, which would lose the text.

" roumail_draft#open(name, lines, OnClose [, opts]): a draft named name
" (made unique), starting with lines, in a split made by opts.split (default
" 'belowright new'). Once it closes, OnClose(text) gets the text last saved,
" without blank lines around it. :w echoes opts.saved, or opts.empty when
" there is no text. The draft is the current buffer on return.
function! roumail_draft#open(name, lines, OnClose, ...) abort
  let l:opts = extend({'split': 'belowright new',
        \ 'saved': 'Draft saved: closing hands it on',
        \ 'empty': 'Draft empty: closing hands nothing on'}, get(a:, 1, {}))
  let l:from = bufnr()
  execute l:opts.split
  setlocal buftype=acwrite bufhidden=wipe noswapfile
  execute 'silent file' fnameescape(bufexists(a:name) ? a:name . '/' . bufnr() : a:name)
  call setline(1, a:lines)
  setlocal nomodified
  let b:roumail_draft = {'text': '', 'OnClose': a:OnClose, 'from': l:from,
        \ 'saved': l:opts.saved, 'empty': l:opts.empty}
  augroup roumail_draft
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call s:save()
    autocmd QuitPre <buffer> call s:keep_vim()
    autocmd BufWipeout <buffer> call s:close(getbufvar(str2nr(expand('<abuf>')), 'roumail_draft'))
  augroup END
endfunction

" BufWriteCmd: keeps the text for when it closes
function! s:save() abort
  let l:lines = getline(1, '$')
  while !empty(l:lines) && l:lines[-1] =~# '^\s*$'
    call remove(l:lines, -1)
  endwhile
  while !empty(l:lines) && l:lines[0] =~# '^\s*$'
    call remove(l:lines, 0)
  endwhile
  let b:roumail_draft.text = join(l:lines, "\n")
  setlocal nomodified
  echo empty(l:lines) ? b:roumail_draft.empty : b:roumail_draft.saved
endfunction

" QuitPre: when the draft is the last window, opens the buffer it was opened
" from beside it, so that closing the draft closes only its window
function! s:keep_vim() abort
  if len(getwininfo()) > 1
    return
  endif
  let l:from = b:roumail_draft.from
  execute 'topleft' (bufexists(l:from) ? 'sbuffer ' . l:from : 'new')
  wincmd p
endfunction

" BufWipeout: hands on the text last saved
function! s:close(draft) abort
  if empty(a:draft) || empty(a:draft.text)
    return
  endif
  call a:draft.OnClose(a:draft.text)
endfunction
