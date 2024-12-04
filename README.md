# ninja-qf

This is a rather simple plugin meant to go with a version of [Ninja](https://github.com/ninja-build/ninja) that spits compile errors at neovim through RPC: [nvimja](https://github.com/konradmagnusson/nvimja).


## Installation

### Lazy

```lua
return {
    "konradmagnusson/ninja-qf",
    dependencies = { "rcarriga/nvim-notify" },  -- I'm not actually sure about this, I just haven't tested without it (and won't).
    opts = {}                                   -- Nothing is actually configurable yet, but there's stuff on the roadmap
}
```
Note that you either have to explicitly specify an empty `opts` for Lazy to initialize the plugin properly. Otherwise, you need to explicitly call `require("ninja-qf").setup({})`.

This plugin of course also requires the aforementioned `nvimja` to be used. The package provides a drop-in replacement for regular Ninja; a binary by the same name as the original package.
If `nvimja` isn't used, obviously nothing will show up in the quickfix window.



## TODO:

- [ ] Make the quickfix window format (and highlight) configurable. Column order and padding, text justification, etc.

- [ ] Write some documentation maybe
