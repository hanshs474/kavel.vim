# kavel.vim

Kavel is a free AI video generator and AI image generator — 4K clips with sound, and images you can run without an account or a card. This plugin brings the image side into Vim and Neovim: type a prompt, keep editing, and the finished image's Markdown link lands under your cursor.

```vim
:KavelImage a paper-cut fox in a moonlit forest
```

About a minute later the line below the cursor reads:

```markdown
![a paper-cut fox in a moonlit forest](https://cdn.kavel.ai/uploads/…/….webp)
```

and the bare URL is in the unnamed register, ready for `p`.

- Select lines and run `:'<,'>KavelImage` to use them as the prompt.
- Generation runs on a timer, so Vim never blocks while you wait.
- No key needed for a first try: calls run on Kavel's free allowance.

## Install

Any plugin manager, for example:

```vim
Plug 'hanshs474/kavel.vim'          " vim-plug
```

```lua
{ 'hanshs474/kavel.vim' }           -- lazy.nvim
```

Requires Vim 8.2+ or Neovim 0.5+, and `curl` on your `PATH`.

## Past the free allowance

Create an API key on your Kavel account at https://www.kavel.ai/settings/apikeys and set it once:

```vim
let g:kavel_api_key = 'sk-…'     " or export KAVEL_API_KEY
let g:kavel_model   = 'gpt-image-2'
```

With a key the call runs on your account: your credits, and the image models your [plan](https://www.kavel.ai/pricing) includes.

## Options

| Variable | Default | What it does |
| --- | --- | --- |
| `g:kavel_api_key` | `$KAVEL_API_KEY` | Run on your Kavel account |
| `g:kavel_model` | free model | Model to use when a key is set |
| `g:kavel_aspect_ratio` | `1:1` | `16:9`, `9:16`, `4:3`, … |
| `g:kavel_insert_link` | `1` | `0` only echoes the URL |

## More from Kavel

Editing a photo instead of starting from a prompt? Kavel keeps a page per edit — [hairstyle](https://www.kavel.ai/image/ai-hairstyle-changer?utm_source=vim), [outfit](https://www.kavel.ai/image/ai-outfit-generator?utm_source=vim) and the rest under [AI image tools](https://www.kavel.ai/image?utm_source=vim). Video lives under [AI video tools](https://www.kavel.ai/video?utm_source=vim).

MIT licensed.
