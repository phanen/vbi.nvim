if not vim.o.ve:match('[ba]') then
  print('[vbi] `:se ve=block` or `:se ve=all`')
  return
end
local api, fn = vim.api, vim.fn
local autocmd = api.nvim_create_autocmd
local ns = api.nvim_create_namespace('u.vbi')
local group = api.nvim_create_augroup('u.vbi', { clear = true })
local auid ---@type integer?

local pos ---@type [integer, integer, integer, integer, integer]
local update_pos = function() pos = fn.getcurpos() end
local is_eol = function() return pos[5] == vim.v.maxcol end

local last_key ---@type string
local attach_key = function() -- currently only consider v-block->insert
  vim.on_key(function(k, _) last_key = k end, ns)
end
local detach_key = function() vim.on_key(nil, ns) end
local is_append = function() return last_key == 'A' end
local is_change = function() return last_key and last_key:find('[scC]') and true or false end

local detach = function()
  if auid then
    api.nvim_del_autocmd(auid)
    auid = nil
  end
  api.nvim_buf_clear_namespace(0, ns, 0, -1)
  detach_key()
end

local ctrl_c = api.nvim_replace_termcodes('<c-c>', true, true, true)
local attach_ctrl_c = function()
  vim.on_key(function(key)
    if key == ctrl_c then detach() end
  end)
end

local attach = function(ev)
  detach()
  attach_ctrl_c()
  local append = is_append()
  local vspos, vepos = fn.getpos("'<"), fn.getpos("'>")
  local vsrow, vscol, verow, vecol = vspos[2], vspos[3], vepos[2], vepos[3]
  local nov2i = ev.match == 'no\022:i' -- c<c-q>xx can never append to eol
  local no2i = ev.match == 'no:i'
  local eol = not no2i and not nov2i and is_eol() and append -- `<c-q>$jjjc` is not "eol"
  if no2i and last_key ~= 'v' or vsrow == 0 then return end -- cgv
  local change = is_change() or nov2i or no2i
  local icol ---@type integer
  if eol then -- <c-q>j$Axx
    icol = api.nvim_win_get_cursor(0)[2] + 1
  elseif append then -- vscol/vecol may clamp to the end (when cursor at left-top, right-bot)
    local region = fn.getregionpos(vspos, vepos, { type = '\022' })
    icol = math.max(vscol, vecol, region[1][2][3], region[#region][2][3]) + 1
  elseif nov2i or change then
    icol = math.min(vscol, vecol)
  else -- when min start clamp to the end, we use max start
    local region = fn.getregionpos(vspos, vepos, { type = '\022' })
    icol = math.min(vscol, vecol)
    local m = math.min(region[1][1][3], region[#region][1][3])
    if icol > m then
      icol = math.max(region[1][1][3], region[#region][1][3])
      for i = 1, #region do
        if icol ~= m then break end
        icol = math.max(icol, region[i][1][3])
      end
    end
  end
  local hl = 'Substitute'
    or (function()
      local ctx = vim.inspect_pos()
      return vim.tbl_get(ctx, 'semantic_tokens', 1, 'opts', 'hl_group_link')
        or vim.tbl_get(ctx, 'treesitter', 1, 'hl_group_link')
        or '@variable'
    end)()
  local line = api.nvim_buf_get_lines(0, vsrow - 1, vsrow, true)[1]
  local scol = api.nvim_win_get_cursor(0)[2]
  local marks = {} ---@type { [integer]: integer? }
  ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
  auid = autocmd({ 'TextChangedI', 'CursorMovedI' }, {
    group = group,
    callback = function()
      local newline = api.nvim_get_current_line()
      local text = newline:sub(icol, #newline - #line + scol)
      local srow = math.max(fn.line('w0'), vsrow)
      local erow = math.min(fn.line('w$') - 1, verow - 1)
      for row = srow, erow do
        local idx = row - srow
        local r ---@type integer?
        if not eol then
          r = vim.F.npcall(api.nvim_buf_set_extmark, 0, ns, row, icol - 1, {
            id = marks[idx],
            virt_text = { { text, hl } },
            virt_text_pos = 'inline',
          })
        end
        if not r and append then -- handle "cliff" or eol
          local ecol = api.nvim_buf_get_lines(0, row, row + 1, true)[1]:len()
          local pad = eol and '' or (' '):rep(icol - ecol - 1)
          if #text > 0 then
            r = assert(api.nvim_buf_set_extmark(0, ns, row, ecol, {
              id = marks[idx],
              virt_text = { { pad .. text, hl } },
              virt_text_pos = 'inline',
            }))
          end
        end
        if not r and marks[idx] then api.nvim_buf_del_extmark(0, ns, marks[idx]) end
        marks[idx] = r
      end
    end,
  })
end

autocmd('ModeChanged', { pattern = '\022:i', group = group, callback = attach })
autocmd('ModeChanged', { pattern = 'no\022:i', group = group, callback = attach }) -- NOTE: with this, last_key may be nil
autocmd('ModeChanged', { pattern = 'no:i', group = group, callback = attach }) -- ME TOO
autocmd('ModeChanged', { pattern = '*:\022', group = group, callback = attach_key })
autocmd('ModeChanged', { pattern = '*:no', group = group, callback = attach_key })
autocmd('ModeChanged', { pattern = '\022:*', group = group, callback = detach_key })
autocmd('ModeChanged', { pattern = 'no:*', group = group, callback = detach_key })
autocmd('InsertLeave', { pattern = '*', group = group, callback = detach })
autocmd('CursorMoved', { pattern = '*', group = group, callback = update_pos })
vim.schedule(update_pos)
