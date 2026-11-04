# vim-draft

Buffers to write text in that aren't files:

- A **draft** is opened by another plugin (a comment, a reply, an ask) and
  hands its text on to that plugin when it closes.
- A **scratch** is opened by you and has nowhere to send its text: closing it
  drops it.

Either can be written to a file with `:DraftSave`, which leaves the buffer as
it was.

## Install

```vim
Plug 'roumail/vim-draft'
```

## Commands

| Command | What it does |
| --- | --- |
| `:Scratch[!]` | New scratch in a vertical split (`!`: in the current window). |
| `:ScratchFrom {cmd}` | Scratch in the current window with the output of a shell command. |
| `:[range]ScratchBuf[!] [buffer\|file]` | Copy a buffer (or the range of the current one), or a file that isn't open, into a new scratch, keeping its filetype. |
| `:DraftSave[!] [path\|dir/]` | Write the draft or scratch, as it is now, to a file. See [Saving](#saving). |
| `:DraftList` | Saved files of the current repository and of the save directory, newest first, in the location list (each with its first line). |

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

The save directory of a draft is `vim-draft/` in the git directory of the
repository the draft was opened from (the one shared by all its work trees,
so saves outlive a work tree and are never committed). For a scratch, or a
draft opened outside a repository, it is `g:roumail_draft_save_dir`. Files
end in `.md` when the buffer is markdown, else `.txt`.

## Settings

| Variable | Default |
| --- | --- |
| `g:roumail_draft_save_dir` | `~/scratch` |
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

## Tests

```sh
vim -Nu NONE -i NONE -Es -S test/run.vim
```
