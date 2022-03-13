# neotest-vim-test

[Neotest](https://github.com/rcarriga/neotest) adapter for vim-test.
Supports running any test runner that is supported by vim-test.
Any existing vim-test configuration should work out of the box.

Since this adapter will likely overlap with other adapters on files, it is advised to place it last in your neotest adapters list so that it will take lowest priority.

```lua
require("neotest").setup({
  adapters = {
    ..., -- Any other adapters
    require("neotest-vim-test")
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
