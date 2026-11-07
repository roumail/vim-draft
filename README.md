# vim-draft

Buffers to write text in that aren't files:

- A **draft** is opened by another plugin (a comment, a reply, an ask) and
  hands its text on to that plugin when it closes.
- A **scratch** is opened by you and has nowhere to send its text: closing it
  drops it.

`:DraftSave` writes either to a file and leaves the buffer as it was. In any
other buffer, such as a plugin's output, it saves the text as a draft.

## Install

The core is vim-draft on its own:

```vim
Plug 'roumail/vim-draft'
```

That gives you drafts for other plugins, the scratch commands, and
`:DraftSave` of a scratch, or of any buffer to a path or directory you give.

Each row below adds a module on top of the core, and **Needs** is the whole
set of plugins it takes besides the core:

| Needs | Module | Adds |
| --- | --- | --- |
| [vim-place](https://github.com/roumail/vim-place) + [vim-fugitive](https://github.com/tpope/vim-fugitive) | Drafts kept per repository | `:DraftSave` without a path of a draft, into the repository it was opened from, or of any other buffer but a scratch, into its own; `:DraftList` |

All of it:

```vim
Plug 'tpope/vim-fugitive'
Plug 'roumail/vim-place'
Plug 'roumail/vim-draft'
```

## Commands

| Command | What it does |
| --- | --- |
| `:Scratch[!]` | New scratch in a vertical split (`!`: in the current window). |
| `:ScratchFrom {cmd}` | Scratch in the current window with the output of a shell command. |
| `:[range]ScratchBuf[!] [buffer\|file]` | Copy a buffer (or the range of the current one), or a file that isn't open, into a new scratch, keeping its filetype. |
| `:DraftSave[!] [path\|dir/]` | Write the buffer, as it is now, to a file: a scratch as a scratch, any other buffer as a draft. See [Saving](#saving). |
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

When the plugin fails to take the text it is handed, the text is kept in a
new file where `:DraftSave` would put it (in the unnamed register if it
can't be written), and the error says where.

## Saving

`:DraftSave` writes the buffer's text as it is now, `:w` or not, to a file
and leaves the buffer as it was: a draft still hands on what `:w` last saved
when it closes, and a scratch is still dropped when it closes. Any other
buffer, such as a plugin's output, is saved as a draft opened from itself.

| Argument | Written to |
| --- | --- |
| a path | That file (`!` to overwrite a file it didn't write). |
| a directory (existing, or ending in `/`) | A new file in it, named for the time. |
| none, saved before | The file it was last saved to. |
| none | A new file, named for the time, in the save directory. |

The save directory of a scratch is `g:roumail_draft_save_dir`, or, when it
isn't set, `vim-draft/` in the XDG state directory. That of a draft is
`vim-draft/` where [vim-place](https://github.com/roumail/vim-place) keeps
plugins' files: the git directory of the repository it was opened from (for
a buffer that isn't a file, the current directory's), else outside a
repository, for the current directory. Files end in `.md` when the
buffer is markdown, else `.txt`.

## Settings

| Variable | Default |
| --- | --- |
| `g:roumail_draft_save_dir` | Unset: saved scratches go in `vim-draft/` in the XDG state directory (`$XDG_STATE_HOME`, else `~/.local/state`). Set it, e.g. to `~/scratch`, to keep them there. |
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

A plugin that keeps files, or shows paths, asks
[vim-place](https://github.com/roumail/vim-place) where.

## Tests

```sh
vim -Nu NONE -i NONE -Es -S test/run.vim
```

vim-place and vim-fugitive come from `$VIM_PLACE` and `$FUGITIVE`, else
vim-plug's copies.
