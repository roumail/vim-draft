function! s:mark() abort
  let b:roumail_draft = {'kind': 'scratch', 'path': ''}
endfunction

function! roumail_draft#scratch#new(bang) abort
  if !a:bang
    vsplit
  endif
  noswapfile hide enew
  setlocal buftype=nofile bufhidden=wipe
  let l:idx = 1
  while bufexists('scratch' . l:idx)
    let l:idx += 1
  endwhile
  execute 'file scratch' . l:idx
  call s:mark()
endfunction

function! roumail_draft#scratch#from(cmd) abort
  enew
  setlocal buftype=nofile bufhidden=wipe noswapfile
  call setline(1, systemlist(a:cmd))
  call s:mark()
endfunction

function! roumail_draft#scratch#buf(bang, line1, line2, buf) abort
  if empty(a:buf) || a:buf ==# '%'
    let l:src = bufnr('%')
    let l:lines = getline(a:line1, a:line2)
  else
    let l:src = a:buf =~# '^\d\+$' ? str2nr(a:buf) : bufnr(a:buf)
    if l:src < 1 || !bufexists(l:src)
      " Not a buffer: a file path, read without opening it
      let l:path = expand(a:buf)
      if !filereadable(l:path)
        echoerr 'ScratchBuf: no buffer or file matching ' . a:buf
        return
      endif
      call roumail_draft#scratch#new(a:bang)
      call setline(1, readfile(l:path))
      execute 'doautocmd filetypedetect BufRead' fnameescape(l:path)
      return
    endif
    call bufload(l:src)
    let l:lines = getbufline(l:src, 1, '$')
  endif
  let l:ft = getbufvar(l:src, '&filetype')

  call roumail_draft#scratch#new(a:bang)
  call setline(1, l:lines)
  let &l:filetype = l:ft
endfunction

" The command, then files, as a shell would
function! roumail_draft#scratch#complete_from(arglead, cmdline, cursorpos) abort
  let l:words = split(a:cmdline[: a:cursorpos - 1], '\s\+', 1)
  return getcompletion(a:arglead, len(l:words) <= 2 ? 'shellcmd' : 'file')
endfunction

function! roumail_draft#scratch#complete_buf(arglead, cmdline, cursorpos) abort
  let l:bufs = getcompletion(a:arglead, 'buffer')
  return l:bufs + filter(getcompletion(a:arglead, 'file'), 'index(l:bufs, v:val) < 0')
endfunction
