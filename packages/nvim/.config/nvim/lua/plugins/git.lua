return {
  -- Git integration
  {
    "airblade/vim-gitgutter",
    config = function()
      vim.g.gitgutter_sign_removed = "-"
      vim.cmd([[
        highlight GitGutterAdd guifg=#009900 ctermfg=2
        highlight GitGutterChange guifg=#bbbb00 ctermfg=3
        highlight GitGutterDelete guifg=#ff2222 ctermfg=1
      ]])
    end,
  },

  -- Git commit
  {
    "rhysd/committia.vim",
    ft = "gitcommit",
  },
}