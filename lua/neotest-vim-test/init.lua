local async = require("neotest.async")
local parse = require("neotest-vim-test.parse")
local lib = require("neotest.lib")

---@type neotest.Adapter
local VimTestNeotestAdapter = { name = "neotest-vim-test" }

local get_root = function()
  return vim.g["test#project_root"]
end

VimTestNeotestAdapter.root = get_root

function VimTestNeotestAdapter.is_test_file(file_path)
  return async.fn["test#test_file"](file_path) == 1
end

local function in_project_root(func)
  local cwd = async.fn.getcwd()
  local root = get_root()
  if root then
    vim.cmd("cd " .. root)
  end
  local res = func()
  if root then
    vim.cmd("cd " .. cwd)
  end
  return res
end

local get_runner = function(file)
  return in_project_root(function()
    return async.fn["test#determine_runner"](file)
  end)
end

---@param test neotest.Position
local function build_cmd(test)
  return in_project_root(function()
    local runner = get_runner(test.path)
    local executable = async.fn["test#base#executable"](runner)

    local base_args = async.fn["test#base#build_position"](
      runner,
      "nearest",
      { file = test.path, line = test.range[1] + 1, col = test.range[2] + 1 }
    )
    local args = async.fn["test#base#options"](runner, base_args)
    args = async.fn["test#base#build_args"](runner, args, "ultest")

    local cmd = vim.list_extend(vim.split(executable, " ", { trimempty = true }), args)

    cmd = lib.func_util.filter_list(function(val)
      return val ~= ""
    end, cmd)
    async.util.scheduler()
    if vim.g["test#transformation"] then
      cmd = vim.g["test#custom_transformations"][vim.g["test#transformation"]](cmd)
    end
    return cmd
  end)
end

local function get_patterns(file_name)
  local runner = get_runner(file_name)
  if type(runner) == "number" then
    return {}
  end
  local file_type = vim.split(runner, "#", { plain = true })[1]
  local _, patterns = pcall(function()
    return vim.g["test#" .. runner .. "#patterns"] or vim.g["test#" .. file_type .. "#patterns"]
  end)
  return patterns
end

---@async
---@return Tree | nil
function VimTestNeotestAdapter.discover_positions(path)
  local patterns = get_patterns(path)
  if not patterns then
    return
  end
  return parse(path, patterns)
end

---@async
---@param args neotest.RunArgs
---@return neotest.RunSpec
function VimTestNeotestAdapter.build_spec(args)
  local position = args.tree:data()
  if position.type ~= "test" then
    return
  end
  local command = build_cmd(position)
  return {
    command = command,
    context = {
      pos_id = position.id,
    },
  }
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@return table<string, neotest.Result>
function VimTestNeotestAdapter.results(spec, result)
  local pos_id = spec.context.pos_id
  return { [pos_id] = {
    status = result.code == 0 and "passed" or "failed",
  } }
end

setmetatable(VimTestNeotestAdapter, {
  __call = function()
    return VimTestNeotestAdapter
  end,
})

return VimTestNeotestAdapter
