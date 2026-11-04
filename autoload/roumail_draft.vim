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
  let b:roumail_draft = {'kind': 'draft', 'path': '', 'text': '', 'OnClose': a:OnClose,
        \ 'from': l:from, 'saved': l:opts.saved, 'empty': l:opts.empty}
  augroup roumail_draft
    autocmd! * <buffer>
    autocmd BufWriteCmd <buffer> call s:save()
    autocmd QuitPre <buffer> call s:keep_vim()
    autocmd BufWipeout <buffer> call s:close(getbufvar(str2nr(expand('<abuf>')), 'roumail_draft'))
  augroup END
  normal! G$
  " Takes effect once the caller has set the draft up
  if get(g:, 'roumail_draft_insert', 0)
    startinsert!
  endif
endfunction

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

function! s:keep_vim() abort
  " Quitting Vim would lose the text
  if len(getwininfo()) > 1
    return
  endif
  let l:from = b:roumail_draft.from
  execute 'topleft' (bufexists(l:from) ? 'sbuffer ' . l:from : 'new')
  wincmd p
endfunction

function! s:close(draft) abort
  if empty(a:draft) || empty(a:draft.text)
    return
  endif
  call a:draft.OnClose(a:draft.text)
endfunction

" Writes the text as it is now to a file, leaving the buffer as it was: a
" draft still hands on what :w last saved when it closes
function! roumail_draft#save(bang, arg) abort
  let l:draft = get(b:, 'roumail_draft', {})
  if empty(l:draft)
    echoerr 'DraftSave: not a draft or a scratch'
    return
  endif
  let l:path = s:target(l:draft, a:arg)
  if filereadable(l:path) && !a:bang && l:path !=# l:draft.path
    echoerr 'DraftSave: ' . fnamemodify(l:path, ':~') . ' exists (add ! to overwrite)'
    return
  endif
  call mkdir(fnamemodify(l:path, ':h'), 'p')
  if writefile(getline(1, '$'), l:path) != 0
    echoerr 'DraftSave: cannot write ' . fnamemodify(l:path, ':~')
    return
  endif
  let l:draft.path = l:path
  echo 'DraftSave: wrote ' . fnamemodify(l:path, ':~')
endfunction

" The file last written, unless the argument names another file or a
" directory to write a new one in
function! s:target(draft, arg) abort
  if empty(a:arg)
    return empty(a:draft.path) ? s:new_file(s:save_dir(a:draft)) : a:draft.path
  endif
  let l:path = fnamemodify(a:arg =~# '^[~$]' ? expand(a:arg) : a:arg, ':p')
  return isdirectory(l:path) || l:path =~# '/$'
        \ ? s:new_file(substitute(l:path, '/\+$', '', '')) : l:path
endfunction

" Named for the time, so they sort
function! s:new_file(dir) abort
  let l:base = a:dir . '/' . strftime('%Y%m%d-%H%M%S')
  let l:ext = &filetype ==# 'markdown' ? '.md' : '.txt'
  let l:path = l:base . l:ext
  let l:n = 1
  while filereadable(l:path)
    let l:n += 1
    let l:path = l:base . '-' . l:n . l:ext
  endwhile
  return l:path
endfunction

" Where a plugin keeps its files, named name: in the git dir of the
" repository, else in g:roumail_draft_save_dir, else in the XDG state
" directory, so every plugin keeps its files the same way. The directory is
" created. opts:
"   bufnr     whose repository (default: the current buffer's, else the
"             current directory's)
"   worktree  1: the work tree's own git dir, which git removes with the work
"             tree, for files of no use after it (default: the git dir shared
"             by all work trees, so files outlive the work tree)
function! roumail_draft#dir(name, ...) abort
  let l:opts = get(a:, 1, {})
  let l:git_dir = s:git_dir(get(l:opts, 'bufnr', -1), get(l:opts, 'worktree', 0))
  if empty(l:git_dir)
    " Each directory's files apart, as a repository's are in its git dir
    let l:place = roumail_draft#place(get(l:opts, 'bufnr', bufnr())).dir
    let l:git_dir = s:outside() . '/' . fnamemodify(l:place, ':t') . '-' . sha256(l:place)[:7]
  endif
  let l:dir = l:git_dir . '/' . a:name
  call mkdir(l:dir, 'p')
  return l:dir
endfunction

" Where files go outside a repository
function! s:outside() abort
  let l:dir = get(g:, 'roumail_draft_save_dir', '')
  if !empty(l:dir)
    return expand(l:dir)
  endif
  return (empty($XDG_STATE_HOME) ? expand('~/.local/state') : $XDG_STATE_HOME)
endfunction

" A scratch is saved outside any repository; a draft, as a plugin's files
" are, in the repository of the buffer it was opened from
function! s:save_dir(draft) abort
  return a:draft.kind ==# 'draft' ? roumail_draft#dir('vim-draft', {'bufnr': a:draft.from})
        \ : s:scratch_dir()
endfunction

" g:roumail_draft_save_dir itself when it is set, so scratches are files of
" yours; else vim-draft's XDG state directory
function! s:scratch_dir() abort
  let l:dir = empty(get(g:, 'roumail_draft_save_dir', ''))
        \ ? s:outside() . '/vim-draft' : expand(g:roumail_draft_save_dir)
  call mkdir(l:dir, 'p')
  return l:dir
endfunction

" The work tree of the buffer's repository, else of the current directory's,
" else the current directory
function! roumail_draft#place(...) abort
  for l:gitdir in [FugitiveGitDir(get(a:, 1, bufnr())), FugitiveExtractGitDir(getcwd())]
    let l:tree = empty(l:gitdir) ? '' : FugitiveWorkTree(l:gitdir)
    if !empty(l:tree)
      return {'dir': l:tree, 'repo': 1}
    endif
  endfor
  return {'dir': getcwd(), 'repo': 0}
endfunction

" Found by fugitive: the buffer's, else, for a buffer that isn't a file,
" the current directory's
function! s:git_dir(bufnr, worktree) abort
  let l:bufnr = a:bufnr < 0 ? bufnr() : a:bufnr
  let l:dir = a:bufnr < 0 ? FugitiveGitDir() : FugitiveGitDir(l:bufnr)
  if empty(l:dir)
    " Fugitive sets a buffer's git dir once it is current: else by its path
    let l:file = empty(bufname(l:bufnr)) || !empty(getbufvar(l:bufnr, '&buftype'))
          \ ? getcwd() : fnamemodify(bufname(l:bufnr), ':p')
    let l:dir = FugitiveExtractGitDir(l:file)
  endif
  return empty(l:dir) || a:worktree ? l:dir : FugitiveCommonDir(l:dir)
endfunction

" Saved drafts of this repository or directory, and saved scratches, newest
" first, in the location list
function! roumail_draft#list() abort
  let l:draft = get(b:, 'roumail_draft', {})
  let l:from = get(l:draft, 'kind', '') ==# 'draft' ? l:draft.from : bufnr()
  let l:dirs = uniq(sort([roumail_draft#dir('vim-draft', {'bufnr': l:from}), s:scratch_dir()]))
  let l:files = []
  for l:dir in filter(l:dirs, '!empty(v:val)')
    call extend(l:files, filter(glob(l:dir . '/*', 1, 1), 'filereadable(v:val)'))
  endfor
  if empty(l:files)
    echo 'DraftList: nothing saved in ' . join(map(l:dirs, 'fnamemodify(v:val, ":~")'), ' or ')
    return
  endif
  call sort(l:files, {a, b -> getftime(b) - getftime(a)})
  call setloclist(0, [], ' ', {
        \ 'title': 'DraftList',
        \ 'items': map(l:files, '{"filename": v:val, "lnum": 1, "text": get(readfile(v:val, "", 1), 0, "")}'),
        \ })
  lopen
endfunction
