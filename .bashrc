# User specific aliases and functions
PATH=$PATH:$HOME/.local/bin:$HOME/bin:/snap/bin
PS1="$ "
alias vi='vim'

# ripgrep
function rgp() {
    rg --pretty "$@" | less -R
}
