" =============================================================================
" init.vim — Raphael's Neovim config
" Place at: dotfiles/nvim/.config/nvim/init.vim
" Managed via GNU Stow
" =============================================================================

" -----------------------------------------------------------------------------
" Plugin declarations (vim-plug)
" -----------------------------------------------------------------------------
call plug#begin('~/.local/share/nvim/plugged')

" --- Editing & motion
Plug 'tpope/vim-surround'           " cs/ds/ys for surrounding pairs
Plug 'tpope/vim-commentary'         " gcc / gc{motion} to toggle comments
Plug 'tpope/vim-repeat'             " make . work with plugin maps
Plug 'wellle/targets.vim'           " more text objects: ci, ca, cin,

" --- File navigation
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'             " :Files :Rg :Buffers :GFiles

" --- Git
Plug 'tpope/vim-fugitive'           " :Git, :Gdiff, :GBlame
Plug 'lewis6991/gitsigns.nvim'      " gutter signs + hunk nav/stage

" --- LSP + completion
Plug 'neovim/nvim-lspconfig'        " LSP client configs
Plug 'hrsh7th/nvim-cmp'             " completion engine
Plug 'hrsh7th/cmp-nvim-lsp'         " LSP source for nvim-cmp
Plug 'hrsh7th/cmp-buffer'           " buffer words source
Plug 'hrsh7th/cmp-path'             " path completion source
Plug 'L3MON4D3/LuaSnip'             " snippet engine
Plug 'saadparwaiz1/cmp_luasnip'     " LuaSnip source for nvim-cmp

" --- Syntax / Treesitter
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" --- Filetypes relevant to your stack
Plug 'pearofducks/ansible-vim'      " Ansible playbook / task detection
Plug 'Glench/Vim-Jinja2-Syntax'     " Jinja2 / .j2 templates
Plug 'stephpy/vim-yaml'             " better YAML highlighting
Plug 'ekalinin/Dockerfile.vim'      " Dockerfile syntax

" --- UI
Plug 'nvim-lualine/lualine.nvim'    " statusline
Plug 'nvim-tree/nvim-web-devicons'  " icons (needs Nerd Font)
Plug 'sainnhe/gruvbox-material'     " theme — easy on the eyes over SSH
Plug 'lukas-reineke/indent-blankline.nvim' " indent guides

call plug#end()

" -----------------------------------------------------------------------------
" Core settings
" -----------------------------------------------------------------------------
set termguicolors
set background=dark
let g:gruvbox_material_background = 'medium'
let g:gruvbox_material_better_performance = 1
colorscheme gruvbox-material

set number relativenumber           " hybrid line numbers
set cursorline
set signcolumn=yes                  " always show — prevents layout shift
set scrolloff=8
set sidescrolloff=8

set expandtab tabstop=2 shiftwidth=2 softtabstop=2
set smartindent
set wrap linebreak                  " soft wrap at word boundaries

set ignorecase smartcase            " case-insensitive unless uppercase used
set incsearch hlsearch

set splitright splitbelow           " sane split directions
set hidden                          " allow unsaved buffers in background

set updatetime=250                  " faster gitsigns / CursorHold
set timeoutlen=400

set undofile                        " persistent undo
set undodir=~/.local/share/nvim/undo

" Disable netrw (we're not using it, avoids conflicts)
let g:loaded_netrw = 1
let g:loaded_netrwPlugin = 1

" -----------------------------------------------------------------------------
" Filetype overrides
" -----------------------------------------------------------------------------
augroup filetype_overrides
  autocmd!
  " YAML / Ansible: 2-space, no tab
  autocmd FileType yaml,yml setlocal ts=2 sw=2 sts=2 expandtab
  " Jinja2 templates
  autocmd BufNewFile,BufRead *.j2 set filetype=jinja2
  " Ansible: detect roles/playbook dirs
  autocmd BufNewFile,BufRead */tasks/*.yml,*/handlers/*.yml,
        \*/roles/**/*.yml,*/playbooks/*.yml set filetype=yaml.ansible
  " Python
  autocmd FileType python setlocal ts=4 sw=4 sts=4 expandtab
  " Git commit: wrap at 72 chars
  autocmd FileType gitcommit setlocal textwidth=72 colorcolumn=73
augroup END

" Trim trailing whitespace on save (not for binary-adjacent types)
augroup trim_whitespace
  autocmd!
  autocmd BufWritePre *.py,*.yml,*.yaml,*.j2,*.sh,*.vim,*.lua,*.md
        \ %s/\s\+$//e
augroup END

" -----------------------------------------------------------------------------
" Key mappings
" -----------------------------------------------------------------------------
let mapleader = " "

" -- Quick escapes
inoremap jk <Esc>
inoremap kj <Esc>

" -- Clear search highlight
nnoremap <leader><leader> :nohlsearch<CR>

" -- Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <leader>bl :ls<CR>

" -- Split navigation (no Ctrl-W prefix needed)
nnoremap <C-h> <C-w>h
nnoremap <C-l> <C-w>l
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k

" -- Resize splits
nnoremap <M-h> :vertical resize -3<CR>
nnoremap <M-l> :vertical resize +3<CR>
nnoremap <M-j> :resize -3<CR>
nnoremap <M-k> :resize +3<CR>

" -- fzf
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :GFiles<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fr :Rg<CR>
nnoremap <leader>fh :History<CR>

" -- Git (fugitive)
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gl :Git log --oneline<CR>

" -- LSP (set after LspAttach — see lua section below)

" -- Move lines up/down in visual mode
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" -- Yank to system clipboard
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>Y "+Y

" -- Paste without losing register
vnoremap <leader>p "_dP

" -- Quick edit / reload config
nnoremap <leader>ve :edit $MYVIMRC<CR>
nnoremap <leader>vr :source $MYVIMRC<CR>

" -----------------------------------------------------------------------------
" Lua configuration block
" (LSP, nvim-cmp, lualine, gitsigns, treesitter, indent-blankline)
" -----------------------------------------------------------------------------
lua << EOF

-- ── gitsigns ──────────────────────────────────────────────────────────────
require('gitsigns').setup({
  signs = {
    add          = { text = '▎' },
    change       = { text = '▎' },
    delete       = { text = '▁' },
    topdelete    = { text = '▔' },
    changedelete = { text = '▎' },
  },
  on_attach = function(bufnr)
    local gs = package.loaded.gitsigns
    local map = function(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
    end
    -- Hunk navigation
    map('n', ']h', gs.next_hunk,        'Next hunk')
    map('n', '[h', gs.prev_hunk,        'Prev hunk')
    -- Stage / reset hunks
    map('n', '<leader>hs', gs.stage_hunk,   'Stage hunk')
    map('n', '<leader>hr', gs.reset_hunk,   'Reset hunk')
    map('n', '<leader>hu', gs.undo_stage_hunk, 'Undo stage hunk')
    map('n', '<leader>hb', function() gs.blame_line({ full = true }) end, 'Blame line')
    map('n', '<leader>hd', gs.diffthis,    'Diff this')
  end
})

-- ── Treesitter ────────────────────────────────────────────────────────────
require('nvim-treesitter.configs').setup({
  ensure_installed = {
    'bash', 'python', 'yaml', 'json', 'lua', 'vim', 'regex',
    'dockerfile', 'markdown', 'markdown_inline', 'toml',
  },
  highlight    = { enable = true },
  indent       = { enable = true },
  auto_install = true,
})

-- ── nvim-cmp ──────────────────────────────────────────────────────────────
local cmp      = require('cmp')
local luasnip  = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args) luasnip.lsp_expand(args.body) end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>']     = cmp.mapping.abort(),
    ['<CR>']      = cmp.mapping.confirm({ select = false }),
    ['<Tab>']     = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
      else fallback() end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then luasnip.jump(-1)
      else fallback() end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  }),
})

-- ── LSP ───────────────────────────────────────────────────────────────────
local lspconfig    = require('lspconfig')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Key mappings applied when any LSP attaches
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end
    map('gd',         vim.lsp.buf.definition,      'Go to definition')
    map('gD',         vim.lsp.buf.declaration,     'Go to declaration')
    map('gr',         vim.lsp.buf.references,      'References')
    map('gi',         vim.lsp.buf.implementation,  'Implementation')
    map('K',          vim.lsp.buf.hover,            'Hover docs')
    map('<leader>rn', vim.lsp.buf.rename,           'Rename')
    map('<leader>ca', vim.lsp.buf.code_action,      'Code action')
    map('<leader>e',  vim.diagnostic.open_float,    'Diagnostic float')
    map('[d',         vim.diagnostic.goto_prev,     'Prev diagnostic')
    map(']d',         vim.diagnostic.goto_next,     'Next diagnostic')
  end,
})

-- Python: pip install pyright
lspconfig.pyright.setup({ capabilities = capabilities })

-- Bash: npm i -g bash-language-server
lspconfig.bashls.setup({ capabilities = capabilities })

-- YAML + schema store: npm i -g yaml-language-server
lspconfig.yamlls.setup({
  capabilities = capabilities,
  settings = {
    yaml = {
      schemaStore = { enable = true, url = '' },
      schemas = {
        -- Ansible schemas (requires yaml-language-server schema store)
        ['https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/tasks.json'] = '*/tasks/*.yml',
        ['https://raw.githubusercontent.com/ansible/ansible-lint/main/src/ansiblelint/schemas/playbook.json'] = '*/playbooks/*.yml',
      },
      validate  = true,
      format    = { enable = true },
      completion = true,
    },
  },
})

-- Lua (for editing this config): brew install lua-language-server
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime     = { version = 'LuaJIT' },
      diagnostics = { globals = { 'vim' } },
      workspace   = { library = vim.api.nvim_get_runtime_file('', true), checkThirdParty = false },
      telemetry   = { enable = false },
    },
  },
})

-- ── lualine ───────────────────────────────────────────────────────────────
require('lualine').setup({
  options = {
    theme                = 'gruvbox-material',
    globalstatus         = true,
    section_separators   = { left = '', right = '' },
    component_separators = { left = '│', right = '│' },
  },
  sections = {
    lualine_a = { 'mode' },
    lualine_b = { 'branch', 'diff', 'diagnostics' },
    lualine_c = { { 'filename', path = 1 } },   -- relative path
    lualine_x = { 'encoding', 'fileformat', 'filetype' },
    lualine_y = { 'progress' },
    lualine_z = { 'location' },
  },
})

-- ── indent-blankline ──────────────────────────────────────────────────────
require('ibl').setup({
  indent = { char = '▏' },
  scope  = { enabled = true },
})

EOF
" =============================================================================
" End of init.vim
" =============================================================================
