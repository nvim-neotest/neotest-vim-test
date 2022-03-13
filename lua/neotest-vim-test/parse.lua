local Tree = require("neotest.types").Tree
local async = require("neotest.async")

local function find_match(patterns, text)
  for _, pattern in ipairs(patterns) do
    local matches = async.fn.matchlist(text, pattern)
    if matches[1] then
      return matches[2] or matches[1]
    end
  end
end

local function parse_buf_positions(file_path, patterns, lines)
  local line_no = 1
  local namespace_indent = -1
  async.util.scheduler()
  local function parse_position_tree(cur_namesspaces)
    local namespace_positions = {}
    while line_no <= #lines do
      local line = lines[line_no]
      local test_name = find_match(patterns.test, line)
      local namespace_name = find_match(patterns.namespace, line)
      line_no = line_no + 1
      if test_name or namespace_name then
        local pos_type = test_name and "test" or "namespace"
        local name = test_name or namespace_name
        local pos_id = (table.concat(cur_namesspaces, "::") .. "::" .. name)
        local line_indent = find_match({ [[\v^(\s*)]] }, line)
        -- Gone out of the current namespace, drop found position and exit
        if #line_indent <= namespace_indent then
          line_no = line_no - 1
          return namespace_positions
        end
        local pos = {
          id = pos_id,
          type = pos_type,
          name = name,
          path = file_path,
          range = { line_no - 2, 0 }, -- Will update range later
        }
        if pos_type == "namespace" then
          local next_namespaces = vim.list_extend(vim.list_extend({}, cur_namesspaces), { name })
          local prev_indent = namespace_indent
          namespace_indent = #line_indent
          local children = parse_position_tree(next_namespaces)
          namespace_indent = prev_indent
          if #children > 0 then
            table.insert(namespace_positions, vim.list_extend({ pos }, children))
          end
        else
          table.insert(namespace_positions, pos)
        end
      end
    end
    return namespace_positions
  end
  local parsed = parse_position_tree({ file_path })
  table.insert(parsed, 1, {
    type = "file",
    path = file_path,
    name = async.fn.fnamemodify(file_path, ":t"),
    id = file_path,
    range = { 0, 0, #lines, 0 },
  })
  local tree = Tree.from_list(parsed, function(pos)
    return pos.id
  end)
  local pos_end = #lines - 1
  local reversed = {}
  for _, pos in tree:iter() do
    table.insert(reversed, 1, pos)
  end
  for _, pos in ipairs(reversed) do
    if pos.type ~= "file" then
      pos.range[3] = pos_end
      pos.range[4] = vim.str_utfindex(lines[pos_end + 1])
      pos_end = pos.range[1] - 1
    end
  end
  return tree
end

return function(file_path, patterns)
  local lines = require("neotest.lib").files.read_lines(file_path)
  if #lines == 0 then
    return
  end
  local result = parse_buf_positions(file_path, patterns, lines)
  return result
end
