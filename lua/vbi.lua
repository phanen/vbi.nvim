local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd
local ns = api.nvim_create_namespace('u.vbi')
local group = api.nvim_create_augroup('u.vbi', { clear = true })
local auid

local pos
local update_pos = function() pos = fn.getcurpos() end
local is_eol = function() return pos[5] == vim.v.maxcol end

local attach = function()
  local start_pos = fn.getpos("'<")
  local end_pos = fn.getpos("'>")
  local start_row, start_col, end_row, _ = start_pos[2], start_pos[3], end_pos[2] - 1, end_pos[3]
  local cursor = api.nvim_win_get_cursor(0)
  local origin_line = api.nvim_get_current_line()
  local hl = (function()
    local ctx = vim.inspect_pos()
    return vim.tbl_get(ctx, 'semantic_tokens', 1, 'opts', 'hl_group_link')
      or vim.tbl_get(ctx, 'treesitter', 1, 'hl_group_link')
      or '@variable'
  end)()
  local marks = {}
  if auid then api.nvim_del_autocmd(auid) end
  auid = autocmd({ 'TextChangedI', 'CursorMovedI' }, {
    group = group,
    callback = function(ev)
      local line = api.nvim_get_current_line()
      -- TODO: diff? what's the actual behavior when feed <left>/<right>
      local col = api.nvim_win_get_cursor(0)[2]
      local text = line:sub(start_col, col)
      local eol = is_eol()
      local pos_type = eol and 'eol' or 'inline'
      for row = start_row, end_row do
        local idx = row - start_row
        local r = vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, start_col - 1, {
          id = marks[idx],
          virt_text = { { text, hl } },
          virt_text_pos = pos_type,
        })
        if r then
          marks[idx] = r
        else -- TODO: virtualedit=all?
          assert(not eol)
          local len = api.nvim_buf_get_lines(0, row, row + 1, true)[1]:len()
          local pad = (' '):rep(start_col - len - 1)
          marks[idx] = assert(vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, len, {
            id = marks[idx],
            virt_text = { { pad .. text, hl } },
            virt_text_pos = 'eol',
          }))
        end
      end
    end,
  })
end

local detach = function()
  if auid then
    api.nvim_del_autocmd(auid)
    auid = nil
  end
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
end

autocmd('ModeChanged', { pattern = '\022:i', group = group, callback = attach })
autocmd('InsertLeave', { pattern = '*', group = group, callback = detach })
autocmd('CursorMoved', { pattern = '*', group = group, callback = update_pos })
vim.schedule(update_pos)
