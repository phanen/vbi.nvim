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
  local start_row, start_col, end_row, end_col = start_pos[2], start_pos[3], end_pos[2], end_pos[3]
  local eol = is_eol()
  u.pp({ start_row, start_col }, { end_row, end_col })
  if not eol and start_col > end_col then
    start_col, end_col = end_col, start_col
  end
  local col = append and end_col + 1 or start_col
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
    callback = function()
      -- TODO: diff? what's the actual behavior when feed <left>/<right>
      local ccol = api.nvim_win_get_cursor(0)[2]
      local text = api.nvim_get_current_line():sub(col, ccol)
      local pos_type = eol and 'overlay' or 'inline'
      u.pp(text, col, ccol, start_col, end_col)
      for row = math.max(fn.line('w0'), start_row), math.min(fn.line('w$') - 1, end_row - 1) do
        local idx = row - start_row
        local r = vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, col - 1, {
          id = marks[idx],
          virt_text = { { text, hl } },
          virt_text_pos = pos_type,
        })
        if not append then
          if not r and marks[idx] then api.nvim_buf_del_extmark(0, ns, marks[idx]) end
          marks[idx] = r
        elseif append then
          marks[idx] = r
            or (function()
              local ecol = api.nvim_buf_get_lines(0, row, row + 1, true)[1]:len()
              local pad = eol and '' or (' '):rep(col - ecol - 1)
              if #text > 0 then
                return assert(vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, ecol, {
                  id = marks[idx],
                  virt_text = { { pad .. text, hl } },
                  virt_text_pos = 'overlay',
                }))
              elseif marks[idx] then
                api.nvim_buf_del_extmark(0, ns, marks[idx])
              end
            end)()
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
