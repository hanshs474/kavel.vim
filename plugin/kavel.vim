" kavel.vim — generate an AI image from Vim and drop its Markdown link at the cursor.
" Maintainer: Kavel <support@kavel.ai>
" License: MIT

if exists('g:loaded_kavel') || &compatible
  finish
endif
let g:loaded_kavel = 1

" :KavelImage {prompt}      generate an image from the prompt
" :'<,'>KavelImage          use the selected lines as the prompt
command! -range -nargs=* KavelImage call kavel#image(<q-args>, <line1>, <line2>, <range>)
