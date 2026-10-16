" kavel.vim — autoload half. Talks to https://www.kavel.ai with curl.
"
" Without g:kavel_api_key a call runs on Kavel's free anonymous allowance (text to
" image only). With a key it runs on your Kavel account: your credits and plan models.

let s:base = get(g:, 'kavel_base_url', 'https://www.kavel.ai')
let s:anon_model = 'kavel-image-v1'

function! s:key() abort
  let l:k = get(g:, 'kavel_api_key', '')
  return empty(l:k) ? $KAVEL_API_KEY : l:k
endfunction

" One anonymous id per Vim session, the way a browser keeps one.
function! s:anon_id() abort
  if !exists('s:anon')
    let s:anon = 'vim-' . printf('%08x%08x', localtime(), rand())
  endif
  return s:anon
endfunction

function! s:curl(method, path, body) abort
  let l:cmd = ['curl', '-sS', '--max-time', '60', '-X', a:method,
        \ '-H', 'Content-Type: application/json',
        \ '-H', 'User-Agent: kavel-vim/0.1']
  let l:key = s:key()
  if empty(l:key)
    let l:cmd += ['-H', 'x-anon-id: ' . s:anon_id()]
  else
    let l:cmd += ['-H', 'Authorization: Bearer ' . l:key]
  endif
  if a:body isnot v:null
    let l:cmd += ['-d', json_encode(a:body)]
  endif
  let l:cmd += [s:base . a:path]
  let l:out = system(join(map(l:cmd, 'shellescape(v:val)'), ' '))
  if v:shell_error
    return {'code': -1, 'message': 'curl failed: ' . trim(l:out)}
  endif
  try
    return json_decode(l:out)
  catch
    return {'code': -1, 'message': 'unexpected reply from Kavel'}
  endtry
endfunction

function! s:say(msg) abort
  redraw | echomsg 'kavel: ' . a:msg
endfunction

function! kavel#image(args, line1, line2, range) abort
  let l:prompt = a:args
  if empty(l:prompt) && a:range > 0
    let l:prompt = join(getline(a:line1, a:line2), ' ')
  endif
  let l:prompt = trim(l:prompt)
  if empty(l:prompt)
    call s:say('give a prompt: :KavelImage a paper-cut fox in a moonlit forest')
    return
  endif
  if !executable('curl')
    call s:say('curl is required')
    return
  endif

  let l:key = s:key()
  let l:model = empty(l:key) ? s:anon_model : get(g:, 'kavel_model', s:anon_model)
  let l:reply = s:curl('POST', '/api/ai/generate', {
        \ 'provider': 'kie', 'mediaType': 'image', 'model': l:model,
        \ 'scene': 'text-to-image', 'prompt': l:prompt,
        \ 'options': {'aspect_ratio': get(g:, 'kavel_aspect_ratio', '1:1')}})
  if get(l:reply, 'code', -1) != 0
    call s:say(get(l:reply, 'message', 'request refused'))
    return
  endif
  let l:data = get(l:reply, 'data', {})
  if get(l:data, 'wall', v:false)
    call s:say('the free allowance is spent — set g:kavel_api_key (create one at '
          \ . s:base . '/settings/apikeys)')
    return
  endif
  let l:task = get(l:data, 'id', '')
  if empty(l:task)
    call s:say('Kavel returned no task id')
    return
  endif

  let s:jobs = get(s:, 'jobs', {})
  let s:jobs[l:task] = {'prompt': l:prompt, 'buf': bufnr('%'), 'line': line('.'),
        \ 'keyed': !empty(l:key), 'tries': 0}
  call s:say('generating… keep editing, the link lands here when it is ready')
  call timer_start(5000, function('s:poll', [l:task]))
endfunction

function! s:poll(task, timer) abort
  let l:job = get(s:jobs, a:task, {})
  if empty(l:job)
    return
  endif
  let l:job.tries += 1
  if l:job.keyed
    let l:reply = s:curl('POST', '/api/ai/query', {'taskId': a:task})
  else
    let l:reply = s:curl('GET', '/api/ai/anon-query?taskId=' . a:task
          \ . '&provider=kie&mediaType=image', v:null)
  endif
  let l:data = get(l:reply, 'data', {})
  let l:imgs = get(l:data, 'cleanImages', get(l:data, 'images', []))
  if type(l:imgs) == v:t_list && !empty(l:imgs)
    let l:url = type(l:imgs[0]) == v:t_dict ? get(l:imgs[0], 'url', '') : l:imgs[0]
    call remove(s:jobs, a:task)
    call s:done(l:job, l:url)
    return
  endif
  if get(l:data, 'status', '') ==# 'failed'
    call remove(s:jobs, a:task)
    call s:say('generation failed — try another prompt')
    return
  endif
  if l:job.tries >= 72
    call remove(s:jobs, a:task)
    call s:say('still running after 6 minutes; task ' . a:task)
    return
  endif
  call timer_start(5000, function('s:poll', [a:task]))
endfunction

function! s:done(job, url) abort
  let l:link = printf('![%s](%s)', substitute(a:job.prompt, '[][]', '', 'g'), a:url)
  call setreg('"', a:url)
  if get(g:, 'kavel_insert_link', 1) && bufexists(a:job.buf)
    call appendbufline(a:job.buf, a:job.line, l:link)
    call s:say('image ready — link inserted below line ' . a:job.line . ', URL in ""')
  else
    call s:say('image ready: ' . a:url)
  endif
endfunction
