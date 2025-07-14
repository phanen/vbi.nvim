local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd
local ns = api.nvim_create_namespace('u.vbi')
local group = api.nvim_create_augroup('u.vbi', { clear = true })
local auid

local pos
local update_pos = function() pos = fn.getcurpos() end
local is_eol = function() return pos[5] == vim.v.maxcol end

local last_key
local attach_key = function()
  vim.on_key(function(k, _) last_key = k end, ns)
end
local detach_key = function() vim.on_key(nil, ns) end
local is_append = function() return last_key == 'A' end

local detach = function()
  if auid then
    api.nvim_del_autocmd(auid)
    auid = nil
  end
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  detach_key()
end

local attach = function()
  detach()
  local append = is_append()
  local start_pos, end_pos = fn.getpos("'<"), fn.getpos("'>")
  local start_row, start_col, end_row, end_col =
    start_pos[2], start_pos[3], end_pos[2] - 1, end_pos[3]
  local col = append and end_col or start_col
  -- local cursor = api.nvim_win_get_cursor(0)
  -- local origin_line = api.nvim_get_current_line()
  local hl = 'Substitute'
    or (function()
      local ctx = vim.inspect_pos()
      return vim.tbl_get(ctx, 'semantic_tokens', 1, 'opts', 'hl_group_link')
        or vim.tbl_get(ctx, 'treesitter', 1, 'hl_group_link')
        or '@variable'
    end)()
  local marks = {}
  ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
  auid = autocmd({ 'TextChangedI', 'CursorMovedI' }, {
    group = group,
    callback = function(ev)
      local line = api.nvim_get_current_line()
      -- TODO: diff? what's the actual behavior when feed <left>/<right>
      local ccol = api.nvim_win_get_cursor(0)[2]
      local eol = is_eol()
      local text = line:sub(col, ccol)
      local pos_type = eol and 'overlay' or 'inline'
      for row = math.max(fn.line('w0'), start_row), math.min(fn.line('w$') - 1, end_row) do
        local idx = row - start_row
        if not append then
          marks[idx] = vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, col - 1, {
            id = marks[idx],
            virt_text = { { text, hl } },
            virt_text_pos = pos_type,
          })
        elseif append then
          marks[idx] = vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, col + 3, {
            id = marks[idx],
            virt_text = { { text, hl } },
            virt_text_pos = pos_type,
          })
          -- local ecol = api.nvim_buf_get_lines(0, row, row + 1, true)[1]:len()
          -- local pad = eol and '' or (' '):rep(col - ecol - 2)
          -- local col0 = eol and ecol - 1 or ecol
          -- marks[idx] = assert(vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, col0 + 1, {
          --   id = marks[idx],
          --   virt_text = { { pad .. text, hl } },
          --   virt_text_pos = 'overlay',
          -- }))
        end
      end
    end,
  })
end

autocmd('ModeChanged', { pattern = '\022:i', group = group, callback = attach })
autocmd('ModeChanged', { pattern = '*:\022', group = group, callback = attach_key })
autocmd('InsertLeave', { pattern = '*', group = group, callback = detach })
autocmd('CursorMoved', { pattern = '*', group = group, callback = update_pos })
vim.schedule(update_pos)
