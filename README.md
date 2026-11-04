# vim-draft

Buffers to write text in that aren't files:

- A **draft** is opened by another plugin (a comment, a reply, an ask) and
  hands its text on to that plugin when it closes.
- A **scratch** is opened by you and has nowhere to send its text: closing it
  drops it.

Either can be written to a file with `:DraftSave`, which leaves the buffer as
it was.

## Install

Requires [vim-fugitive](https://github.com/tpope/vim-fugitive), which finds
the git directory.

```vim
Plug 'tpope/vim-fugitive'
Plug 'roumail/vim-draft'
```

## Commands

| Command | What it does |
| --- | --- |
| `:Scratch[!]` | New scratch in a vertical split (`!`: in the current window). |
| `:ScratchFrom {cmd}` | Scratch in the current window with the output of a shell command. |
| `:[range]ScratchBuf[!] [buffer\|file]` | Copy a buffer (or the range of the current one), or a file that isn't open, into a new scratch, keeping its filetype. |
| `:DraftSave[!] [path\|dir/]` | Write the draft or scratch, as it is now, to a file. See [Saving](#saving). |
| `:DraftList` | Saved drafts of the current repository, or outside one of the current directory, and saved scratches, newest first, in the location list (each with its first line). |

`:ScratchFrom` pairs well with the quickfix list: `:ScratchFrom rg --vimgrep pattern`,
trim the lines, then `:cgetbuffer`.

## A draft

It works as a git commit message:

| | |
| --- | --- |
| `:w` | Save it; nothing is handed on yet. |
| `:wq` (or `:q` after `:w`) | Close it and hand on what was last saved. |
| `:q!` before any `:w` | Drop it. To drop a saved draft, empty it and `:wq`. |

Closing a draft never quits Vim, which would lose the text: when it is the
last window (after `:only`), the buffer it was opened from opens beside it.

## Saving

`:DraftSave` writes the buffer's text as it is now, `:w` or not, to a file
and leaves the buffer as it was: a draft still hands on what `:w` last saved
when it closes, and a scratch is still dropped when it closes.

| Argument | Written to |
| --- | --- |
| a path | That file (`!` to overwrite a file it didn't write). |
| a directory (existing, or ending in `/`) | A new file in it, named for the time. |
| none, saved before | The file it was last saved to. |
| none | A new file, named for the time, in the save directory. |

The save directory of a scratch is `g:roumail_draft_save_dir`, or, when it
isn't set, `vim-draft/` in the XDG state directory. That of a draft is
`vim-draft/` where plugins keep their files (see
[`roumail_draft#dir()`](#for-other-plugins)): the git directory of the
repository it was opened from, else outside a repository, for the current
directory. Files end in `.md` when the buffer
is markdown, else `.txt`.

## Settings

| Variable | Default |
| --- | --- |
| `g:roumail_draft_save_dir` | Unset: saved scratches, and what plugins keep outside a repository, go in the XDG state directory (`$XDG_STATE_HOME`, else `~/.local/state`). Set it, e.g. to `~/scratch`, to keep them there. |
| `g:roumail_draft_insert` | `0`: a draft opens in normal mode at the end of its text; `1` starts in insert mode there. |

## For other plugins

```vim
call roumail_draft#open('my-plugin://note', ['first line'],
      \ {text -> MyPluginSend(text)},
      \ {'split': 'botright vnew', 'saved': 'Note saved: closing sends it'})
```

`roumail_draft#open(name, lines, OnClose [, opts])` opens the draft named
`name` (with `/<bufnr>` added when a buffer has that name), starting with
`lines`, and leaves it the current buffer, with the cursor at the end of its
last line. Once it closes with text saved, `OnClose(text)` gets that text
without the blank lines around it.

| Option | Default |
| --- | --- |
| `split` | `'belowright new'`: the command that opens its window |
| `saved` | `'Draft saved: closing hands it on'`, echoed on `:w` |
| `empty` | `'Draft empty: closing hands nothing on'`, echoed on `:w` with no text |

The plugin that opens a draft sets what is its own on the buffer afterwards:
its `filetype`, its buffer variables and its `statusline`. The rest is
vim-draft's: `buftype`, `bufhidden`, the draft's autocommands and
`b:roumail_draft`, which a plugin neither sets nor reads.

A plugin that keeps files (saves, prompts) asks vim-draft where, and finds
no git dir and picks no directory of its own:
`roumail_draft#dir(name [, opts])` returns the directory, created if
missing, the first of:

1. `<git dir>/<name>` in a git repository, found by vim-fugitive: the git
   dir shared by all work trees, so the files outlive a work tree and are
   never committed.
2. `<g:roumail_draft_save_dir>/<place>/<name>` outside a repository, when it
   is set.
3. `<$XDG_STATE_HOME>/<place>/<name>` (`~/.local/state/<place>/<name>`)
   otherwise.

Outside a repository, `<place>` keeps each directory's files apart, as a
repository's git dir does: the current directory's name and a short hash of
its path, e.g. `notes-1a2b3c4d`.

`roumail_draft#place([bufnr])` is where a plugin is working, as
`{dir, repo}`: the work tree of the buffer's repository (default: the
current buffer), else of the current directory's, with `repo` 1; else the
current directory, with `repo` 0. Paths a plugin shows or keeps are relative
to `dir`.

| Option | Default |
| --- | --- |
| `bufnr` | The current buffer: whose repository it is. A buffer that isn't a file (a list, a draft) is in the current directory's. |
| `worktree` | `0`. `1`: the work tree's own git dir, which git removes with the work tree, for files of no use after it. |

A plugin names its directory after itself, e.g.
`roumail_draft#dir('my-plugin/notes', {'worktree': 1})`.

## Tests

```sh
vim -Nu NONE -i NONE -Es -S test/run.vim
```
