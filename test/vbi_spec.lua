---@diagnostic disable: invisible
local n = require('nvim-test.helpers')
local Screen = require('nvim-test.screen')
local exec_lua = n.exec_lua

describe('main', function()
  local screen --- @type test.screen
  before_each(function()
    n.clear()
    screen = Screen.new(30, 5)
    screen:attach()
    screen:set_default_attr_ids({
      [1] = { background = Screen.colors.NvimLightYellow, foreground = Screen.colors.NvimDarkGrey1 },
      [2] = { foreground = Screen.colors.NvimDarkGreen },
      [3] = { foreground = Screen.colors.NvimLightGray1, background = Screen.colors.NvimDarkYellow },
    })
    exec_lua(function() ---@diagnostic disable-next-line: duplicate-set-field
      vim.opt.rtp:append('.')
      vim.o.ve = 'block'
      vim.o.sol = false -- this change `<c-q>G` behavior
      vim.cmd.runtime { 'plugin/vbi.lua', bang = true }
    end)
    n.api.nvim_buf_set_lines(0, 0, -1, false, {
      'aaaaa',
      'bbbbbbbbbbbb',
      'cccccccccccccc',
      'ddd',
    })
  end)
  it('chore', function()
    n.feed('<c-q>GIabc')
    screen:expect {
      grid = [[
        abc^aaaaa                      |
        {1:abc}bbbbbbbbbbbb               |
        {1:abc}cccccccccccccc             |
        {1:abc}ddd                        |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        ^abcaaaaa                      |
        abcbbbbbbbbbbbb               |
        abccccccccccccccc             |
        abcddd                        |
                                      |
      ]],
    }

    n.feed('dgv..')
    screen:expect {
      grid = [[
        ^aaaaa                         |
        bbbbbbbbbbbb                  |
        cccccccccccccc                |
        ddd                           |
                                      |
      ]],
    }

    n.feed('<c-q>G$Axyz')
    screen:expect {
      grid = [[
        aaaaaxyz^                      |
        bbbbbbbbbbbb{1:xyz}               |
        cccccccccccccc{1:xyz}             |
        ddd{1:xyz}                        |
        {2:-- INSERT --}                  |
      ]],
    }

    n.feed('<esc>')
    screen:expect {
      grid = [[
        ^aaaaaxyz                      |
        bbbbbbbbbbbbxyz               |
        ccccccccccccccxyz             |
        dddxyz                        |
                                      |
      ]],
    }

    n.feed('gofy<c-q>GAA')
    screen:expect {
      grid = [[
        aaaaaxyA^z                     |
        bbbbbbb{1:A}bbbbbxyz              |
        ccccccc{1:A}cccccccxyz            |
        dddxyz{1: A}                      |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        aaaaax^yAz                     |
        bbbbbbbAbbbbbxyz              |
        cccccccAcccccccxyz            |
        dddxyz A                      |
                                      |
      ]],
    }

    n.feed('gv3lo3lII')
    screen:expect {
      grid = [[
        aaaaaxyAzI^                    |
        bbbbbbbAb{1:I}bbbbxyz             |
        cccccccAc{1:I}ccccccxyz           |
        dddxyz A                      |
        {2:-- INSERT --}                  |
      ]],
    }

    n.feed('<esc>')
    screen:expect {
      grid = [[
        aaaaaxyAz^I                    |
        bbbbbbbAbIbbbbxyz             |
        cccccccAcIccccccxyz           |
        dddxyz A                      |
                                      |
      ]],
    }
  end)
  it('c<c-q>G', function()
    n.feed('c<c-q>Gabc')
    screen:expect {
      grid = [[
        abc^aaaa                       |
        {1:abc}bbbbbbbbbbb                |
        {1:abc}ccccccccccccc              |
        {1:abc}dd                         |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        ab^caaaa                       |
        abcbbbbbbbbbbb                |
        abcccccccccccccc              |
        abcdd                         |
                                      |
      ]],
    }
  end)

  it('c<c-q>/', function()
    -- c<c-q>gn, c<c-q>gv don't work...
    -- not useful: c<c-q>%, c<c-q>}
    n.feed('c<c-q>ipabc<esc>')
    screen:expect {
      grid = [[
        ab^caaaa                       |
        abcbbbbbbbbbbb                |
        abcccccccccccccc              |
        abcdd                         |
                                      |
      ]],
    }
    n.feed('goc<c-q>/d<cr>kaka')
    screen:expect {
      grid = [[
        kaka^aaa                       |
        {1:kaka}bbbbbbbbbb                |
        {1:kaka}cccccccccccc              |
        {1:kakad}                         |
        {2:-- INSERT --}                  |
      ]],
    }

    n.feed('<esc>')
    screen:expect {
      grid = [[
        kak^aaaa                       |
        kakabbbbbbbbbb                |
        kakacccccccccccc              |
        kaka{1:d}                         |
        /d                     [1/2]  |
      ]],
    }
  end)

  it('<c-q>c', function()
    n.feed('$<c-q>Gckkk')
    screen:expect {
      grid = [[
        aaakkk^                        |
        bbb{1:kkk}                        |
        ccc{1:kkk}                        |
        ddd{1:kkk}                        |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        aaakk^k                        |
        bbbkkk                        |
        ccckkk                        |
        dddkkk                        |
                                      |
      ]],
    }

    n.feed('go<c-q>GC')
    screen:expect {
      grid = [[
        ^                              |
                                      |
                                      |
                                      |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('foo')
    screen:expect {
      grid = [[
        foo^                           |
        {1:foo}                           |
        {1:foo}                           |
        {1:foo}                           |
        {2:-- INSERT --}                  |
      ]],
    }

    n.feed('<c-c>')
    screen:expect {
      grid = [[
        fo^o                           |
                                      |
                                      |
                                      |
                                      |
      ]],
    }
  end)

  it('<c-c>', function()
    n.feed('<c-q>GIabc')
    screen:expect {
      grid = [[
        abc^aaaaa                      |
        {1:abc}bbbbbbbbbbbb               |
        {1:abc}cccccccccccccc             |
        {1:abc}ddd                        |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<c-c><esc>')
    screen:expect {
      grid = [[
        ab^caaaaa                      |
        bbbbbbbbbbbb                  |
        cccccccccccccc                |
        ddd                           |
                                      |
      ]],
    }
  end)

  it('cgv', function()
    n.feed('cgv')
    screen:expect { -- no error msg
      grid = [[
        ^aaaaa                         |
        bbbbbbbbbbbb                  |
        cccccccccccccc                |
        ddd                           |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')

    n.feed('$cgv')
    screen:expect { -- no error msg
      grid = [[
        aaaa^                          |
        bbbbbbbbbbbb                  |
        cccccccccccccc                |
        ddd                           |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>u_') -- idk, it eat a char

    n.feed('<c-q>G<esc>cgvabc')
    screen:expect {
      grid = [[
        abc^aaaa                       |
        {1:abc}bbbbbbbbbbb                |
        {1:abc}ccccccccccccc              |
        {1:abc}dd                         |
        {2:-- INSERT --}                  |
      ]],
    }

    n.feed('<esc>C')
    screen:expect {
      grid = [[
        ab^                            |
        abcbbbbbbbbbbb                |
        abcccccccccccccc              |
        abcdd                         |
        {2:-- INSERT --}                  |
      ]],
    }
  end)
end)
