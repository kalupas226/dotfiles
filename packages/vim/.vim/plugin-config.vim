" Plugin configurations

" === ALE (Asynchronous Lint Engine) ===
let g:ale_disable_lsp = 1
let g:ale_lint_on_text_changed = 1
let g:ale_sign_error = '✗'
let g:ale_sign_warning = '⚠'

" === vim-airline ===
let g:airline_theme = 'wombat'
set laststatus=2
let g:airline#extensions#tabline#enabled = 1
let g:ariline#extensions#tabline#formatter = 'default'
let g:airline#extensions#branch#enabled = 1
let g:airline#extensions#wordcount#enabled = 1
let g:airline#extensions#default#layout = [['a', 'b', 'c'], ['x', 'y', 'z']]
let g:airline_section_c = '%t'
let g:airline_section_x = '%{&filetype}'
let g:airline_section_z = '%3l:%2v %{airline#extensions#ale#get_warning()} %{airline#extensions#ale#get_error()}'
let g:airline#extensions#ale#error_symbol = ''
let g:airline#extensions#ale#warning_symbol = ''
let g:airline#extensions#default#section_truncate_width = {}
let g:airline#extensions#whitespace#enabled = 1

" === vim-gitgutter ===
let g:gitgutter_sign_removed = '-'
highlight GitGutterAdd guifg=#009900 ctermfg=2
highlight GitGutterChange guifg=#bbbb00 ctermfg=3
highlight GitGutterDelete guifg=#ff2222 ctermfg=1

" === fzf.vim ===
set rtp+=/opt/homebrew/opt/fzf