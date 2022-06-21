# neotest-vim-test

[Neotest](https://github.com/rcarriga/neotest) adapter for vim-test.
Supports running any test runner that is supported by vim-test.
Any existing vim-test configuration should work out of the box.

Requires [vim-test](https://github.com/vim-test/vim-test/) to be installed.

It is recommended to add any filetypes that are covered by another adapter to the ignore list.

```lua
require("neotest").setup({
  adapters = {
    ..., -- Any other adapters
    require("neotest-vim-test")({ ignore_filetypes = { "python", "lua" } }),
    -- Or to only allow specified file types
    require("neotest-vim-test")({ allow_file_types = { "haskell", "elixir" } }),
  }
})
```

## Issues

This is a simple wrapper around vim-test.
There are several features lacking that more integrated adapters will have along with bugs that can't be fixed:

- No error diagnostics
- Performance issues
  - Tests are all run in separate processes
  - Has to communicate with vimscript for a lot of the functionality which requires synchronous code
- There may be false positives on what files are test files (e.g. all `.vim` files are detected as test files) due to how vim-test detects files.
- Multiple languages run in the same suite

This adapter should only be used if there is no alternative available for your test runner.
