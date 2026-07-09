-- scriptr: extract code cells tagged with `#| filename:` to standalone script files.
--
-- Quarto's `filename` cell option is consumed into a `DecoratedCodeBlock` custom
-- AST node that only wraps the *first* source fragment of a cell -- when a chunk's
-- later top-level expressions auto-print (e.g. several statements each producing
-- console output), knitr splits the remaining source into separate sibling
-- CodeBlocks with no link back to the `filename` value. So extraction happens in
-- two passes: first record `filename` by the decorated node's custom id, then walk
-- the enclosing `cell` Div (which still holds every fragment, decorated or not) to
-- reassemble the full original source in order.

local filename_by_id = {}

local function ensure_parent_dir(path)
  local dir = path:match("^(.*)/[^/]+$")
  if dir and dir ~= "" then
    pandoc.system.make_directory(dir, true)
  end
end

local function collect_code(blocks, pieces)
  for _, block in ipairs(blocks) do
    if block.tag == "CodeBlock" and block.classes:includes("cell-code") then
      table.insert(pieces, block.text)
    elseif block.content then
      collect_code(block.content, pieces)
    end
  end
end

return {
  {
    DecoratedCodeBlock = function(node)
      if node.filename and node.filename ~= "" then
        local id = node.__quarto_custom_node.attr.attributes["__quarto_custom_id"]
        filename_by_id[id] = node.filename
      end
      return node
    end
  },
  {
    Div = function(div)
      if not div.classes:includes("cell") then
        return nil
      end

      local first = div.content[1]
      local id = first and first.tag == "Div" and first.attributes["__quarto_custom_id"]
      local filename = id and filename_by_id[id]
      if not filename then
        return nil
      end

      local pieces = {}
      collect_code(div.content, pieces)
      ensure_parent_dir(filename)
      pandoc.system.write_file(filename, table.concat(pieces, "\n"))

      filename_by_id[id] = nil
      return nil
    end
  }
}
