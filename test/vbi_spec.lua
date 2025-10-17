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
      [1] = { background = Screen.colors.NvimLightYellow, foreground = Screen.colors.NvimDarkGray1 },
      [2] = { foreground = Screen.colors.NvimDarkGreen },
      [3] = { foreground = Screen.colors.NvimLightGrey1, background = Screen.colors.NvimDarkYellow },
      [4] = { foreground = Screen.colors.NvimLightGrey4 },
    })
    exec_lua(function() ---@diagnostic disable-next-line: duplicate-set-field
      vim.opt.rtp:append('.')
      -- vim.o.ve = 'block'
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

    if n.fn.has('nvim-0.12') ~= 1 then
      pending('https://github.com/vim/vim/commit/cb27992c', function() end)
    end
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

    n.api.nvim_command('se ve=block')
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

    if n.fn.has('nvim-0.12') ~= 1 then pending('idk', function() end) end
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
    if n.fn.has('nvim-0.12') ~= 1 then
      pending('https://github.com/vim/vim/commit/cb27992c', function() end)
    end
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

    -- $<c-q>G<esc>cgv
    n.feed('<esc>')
    screen:expect {
      grid = [[
        a^b                            |
        abcbbbbbbbbbbb                |
        abcccccccccccccc              |
        abcdd                         |
                                      |
      ]],
    }
    n.feed('$<c-q>G<esc>cgvxyz')
    screen:expect {
      grid = [[
        axyz^                          |
        a{1:xyz}                          |
        a{1:xyz}                          |
        a{1:xyz}                          |
        {2:-- INSERT --}                  |
      ]],
    }

    n.feed('<esc>')
    -- the above test make no sense
    n.api.nvim_buf_set_lines(0, 0, -1, false, {
      'aaaaaaaaaaaaaaa',
      'bb',
      'ccc',
      'ddddddd',
    })
    n.feed('$<c-q>G<esc>cgvxyz')
    screen:expect {
      grid = [[
        aaaaaaaxyz^                    |
        bb{1:     xyz}                    |
        ccc{1:    xyz}                    |
        ddddddd{1:xyz}                    |
        {2:-- INSERT --}                  |
      ]],
    }
  end)

  it('<c-w>', function()
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
    n.feed('<c-w>')
    screen:expect {
      grid = [[
        ^aaaaa                         |
        bbbbbbbbbbbb                  |
        cccccccccccccc                |
        ddd                           |
        {2:-- INSERT --}                  |
      ]],
    }
  end)

  it('insert at eol', function()
    n.feed('G$gg<c-q>GIabc')
    screen:expect {
      grid = [[
        aaaabc^aa                      |
        bbb{1:abc}bbbbbbbbb               |
        ccc{1:abc}ccccccccccc             |
        ddd{1:abc}                        |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        aaa^abcaa                      |
        bbbabcbbbbbbbbb               |
        cccabcccccccccccc             |
        dddabc                        |
                                      |
      ]],
    }
  end)

  it('insert newline', function()
    n.feed('dd<c-q>GI<c-r>"xxx')
    screen:expect {
      grid = [[
        aaaaa                         |
        xxx^bbbbbbbbbbbb               |
        cccccccccccccc                |
        ddd                           |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        aaaaa                         |
        xx^xbbbbbbbbbbbb               |
        cccccccccccccc                |
        ddd                           |
                                      |
      ]],
    }
  end)

  it('S', function()
    n.feed('$<c-q>GSxyz')
    screen:expect { -- no error msg
      grid = [[
        xyz^                           |
        {4:~                             }|
        {4:~                             }|
        {4:~                             }|
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    if n.fn.has('nvim-0.12') ~= 1 then pending('idk', function() end) end
    screen:expect {
      grid = [[
        xy^z                           |
        {4:~                             }|
        {4:~                             }|
        {4:~                             }|
        3 fewer lines                 |
      ]],
    }
  end)

  it('tab', function()
    n.feed('$<c-q>GI<c-q><c-i>xyz')
    screen:expect {
      grid = [[
        aaa     xyz^aa                 |
        bbb{1:        xyz}bbbbbbbbb       |
        ccc{1:        xyz}ccccccccccc     |
        ddd{1:        xyz}                |
        {2:-- INSERT --}                  |
      ]],
    }
    n.feed('<esc>')
    screen:expect {
      grid = [[
        aaa    ^ xyzaa                 |
        bbb     xyzbbbbbbbbb          |
        ccc     xyzccccccccccc        |
        ddd     xyz                   |
                                      |
      ]],
    }
  end)
end)
