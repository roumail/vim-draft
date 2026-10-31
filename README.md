# vim-draft

A buffer to write text in before it goes somewhere, opened by other plugins.
It works as a git commit message:

| | |
| --- | --- |
| `:w` | Save it; nothing is handed on yet. |
| `:wq` (or `:q` after `:w`) | Close it and hand on what was last saved. |
| `:q!` before any `:w` | Drop it. To drop a saved draft, empty it and `:wq`. |

Closing a draft never quits Vim, which would lose the text: when it is the
last window (after `:only`), the buffer it was opened from opens beside it.

## Install

```vim
Plug 'roumail/vim-draft'
```

## Use

```vim
call roumail_draft#open('my-plugin://note', ['first line'],
      \ {text -> MyPluginSend(text)},
      \ {'split': 'botright vnew', 'saved': 'Note saved: closing sends it'})
```

`roumail_draft#open(name, lines, OnClose [, opts])` opens the draft named
`name` (with `/<bufnr>` added when a buffer has that name), starting with
`lines`, and leaves it the current buffer, to set its filetype, folds or
statusline. Once it closes with text saved, `OnClose(text)` gets that text
without the blank lines around it.

| Option | Default |
| --- | --- |
| `split` | `'belowright new'`: the command that opens its window |
| `saved` | `'Draft saved: closing hands it on'`, echoed on `:w` |
| `empty` | `'Draft empty: closing hands nothing on'`, echoed on `:w` with no text |
