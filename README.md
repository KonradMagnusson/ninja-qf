# ninja-qf

This is a rather simple plugin meant to go with a version of [Ninja](https://github.com/ninja-build/ninja) that spits compile errors at neovim through RPC: [nvimja](https://github.com/konradmagnusson/nvimja).


## Installation

### Lazy

```lua
return {
    "konradmagnusson/ninja-qf",

    dependencies = { "rcarriga/nvim-notify" },  -- I'm not actually sure about this, I just haven't tested without it (and won't).

    opts = {
	    qf_format = "{type:=7}|{file:>35}|L{line:>5}|C{col:>3}|  {text}" -- syntax: {(category):[justification](padding)}
        -- note: only one category per column is supported for now. Columns are separated by |
        -- The final column doesn't need a width set - it'll adapt to the window.
        -- Making any arbitrary column variable width is a bigger headache than I care to deal with right now 😅

        -- The highlight groups are mapped like so:
        --      type → ninjaQfType
        --      (keyword) error → DiagnosticError
        --      (keyword) warning → DiagnosticWarning
        --      (keyword) note → DiagnosticNote
        --      text → ninjaQfText → Normal
        --      file → ninjaQfFileName → qfFileName
        --      col → ninjaQfColNr → qfLineNr
        --      line → ninjaQfLineNr → qfLineNr
        --      (match) '|' → qfSeparator
    }
}
```
Note that you either have to explicitly specify an empty `opts` for Lazy to initialize the plugin properly. Otherwise, you need to explicitly call `require("ninja-qf").setup({})`.

This plugin of course also requires the aforementioned `nvimja` to be used. The package provides a drop-in replacement for regular Ninja; a binary by the same name as the original package.
If `nvimja` isn't used, obviously nothing will show up in the quickfix window.



## TODO:

- [x] Make the quickfix window format configurable. Column order and padding, text justification, etc.

- [x] Add configurable quickfix window highlight that adapts to the format string

- [ ] Do some proper error handling to make sure things don't crash and burn if e.g. an incompatible `qf_format` is configured. Truncate?

- [ ] Improve formatting flexibility and options

- [ ] Write some documentation maybe
