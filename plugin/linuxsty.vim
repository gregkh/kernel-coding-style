" Vim plugin to fit the Linux kernel coding style and help kernel development
" Maintainer:   Greg Kroah-Hartman <gregkh@linuxfoundation.org>
" License:      Distributed under the same terms as Vim itself.
"
" Originally developed by Vivien Didelot <vivien.didelot@savoirfairelinux.com>
"
" This script is inspired from an article written by Bart:
" http://www.jukie.net/bart/blog/vim-and-linux-coding-style
" and various user comments.
"
" For those who want to apply these options conditionally, you can define an
" array of patterns in your vimrc and these options will be applied only if
" the buffer's path matches one of the pattern. In the following example,
" options will be applied only if "/linux/" or "/kernel" is in buffer's path.
"
"   let g:linuxsty_patterns = [ "/linux/", "/kernel/" ]
"
" If you want to save the current file's directory and automatically call
" LinuxCodingStyle next time, you can define the following option in your
" vimrc:
"
"   let g:linuxsty_save_path = 1
"
" To override the default text width for C kernel files define the following
" option in your vimrc:
"
"   let g:linuxsty_text_width = 80

if exists("g:loaded_linuxsty")
    finish
endif
let g:loaded_linuxsty = 1

let g:linuxsty_save_path = get(g:, 'linuxsty_save_path', 0)
let g:linuxsty_text_width = get(g:, 'linuxsty_text_width', 100)

set wildignore+=*.ko,*.mod.c,*.order,modules.builtin

augroup linuxsty
    autocmd!

    autocmd FileType c,cpp call s:LinuxConfigure()
    autocmd FileType diff setlocal ts=8
    autocmd FileType rst setlocal ts=8 sw=8 sts=8 noet
    autocmd FileType kconfig setlocal ts=8 sw=8 sts=8 noet
    autocmd FileType dts setlocal ts=8 sw=8 sts=8 noet
    autocmd FileType make setlocal ts=8 sw=8 sts=8 noet
augroup END

function s:LinuxConfigure()
    let apply_style = 0

    if exists("g:linuxsty_patterns")
        let path = expand('%:p')
        for p in g:linuxsty_patterns
            if path =~ p
                let apply_style = 1
                break
            endif
        endfor
    else
        let apply_style = 1
    endif

    if apply_style
        call s:LinuxCodingStyle()
    endif
endfunction

command! LinuxCodingStyle call s:LinuxCodingStyle()

function! s:LinuxCodingStyle()
    call s:LinuxFormatting()
    call s:LinuxKeywords()
    call s:LinuxHighlighting()
    call s:LinuxSavePath()
endfunction

function s:LinuxFormatting()
    setlocal tabstop=8
    setlocal shiftwidth=8
    setlocal softtabstop=8
    execute "setlocal textwidth=" . g:linuxsty_text_width
    setlocal noexpandtab

    setlocal cindent
    setlocal cinoptions=:0,l1,t0,g0,(0
endfunction

function s:LinuxKeywords()
    syn keyword cStatement fallthrough
    syn keyword cStorageClass noinline __always_inline __must_check
    syn keyword cStorageClass __pure __weak __noclone
    syn keyword cStorageClass __free __cleanup
    syn keyword cStorageClass __used __always_unused __maybe_unused
    syn keyword cOperator likely unlikely
    syn keyword cType u8 u16 u32 u64 s8 s16 s32 s64
    syn keyword cType __u8 __u16 __u32 __u64 __s8 __s16 __s32 __s64
    syn keyword cType __le16 __le32 __le64 __be16 __be32 __be64
endfunction

function s:LinuxHighlighting()
    highlight default link LinuxError ErrorMsg

    syn match LinuxError / \+\ze\t/     " spaces before tab
    syn match LinuxError /\%>100v[^()\{\}\[\]<>]\+/ " virtual column 101 and more

    " __deprecated should not be used anymore, please see
    " include/linux/compiler_attributes.h for why.
    syn match LinuxError /\<__deprecated\>/

    " Highlight trailing whitespace, unless we're in insert mode and the
    " cursor's placed right after the whitespace. This prevents us from having
    " to put up with whitespace being highlighted in the middle of typing
    " something
    autocmd InsertEnter * match LinuxError /\s\+\%#\@<!$/
    autocmd InsertLeave * match LinuxError /\s\+$/
endfunction

function s:PathExistInCacheFile(cache_file, path)
    if !filereadable(a:cache_file)
        return 0
    endif

    let lines = readfile(a:cache_file)
    for line in lines
        if line == a:path
            return 1
        endif
    endfor

    return 0
endfunction

" $HOME/.vim/.linuxsty
let s:path_cache_file = split(&runtimepath, ',')[0] . '/.linuxsty'
let s:path = fnamemodify(expand('%:p'), ':h')

function s:LinuxSavePath()
    if g:linuxsty_save_path
        if !s:PathExistInCacheFile(s:path_cache_file, s:path)
            call writefile([s:path], s:path_cache_file, 'a')
        endif
    endif
endfunction

if g:linuxsty_save_path
    if s:PathExistInCacheFile(s:path_cache_file, s:path)
        call s:LinuxCodingStyle()
    endif
endif

" vim: ts=4 et sw=4
