log=~/.cdlog

cd() {
    makelog "refresh"

    if [ -d "$1" ]; then
        builtin cd "$1"
    else
        interface "$1"
    fi

    makelog "assemble"
}

interface() {
    if ! type peco >/dev/null; then
        builtin cd "$1"
        return 0
    fi

    if [[ -z "$1" ]]; then
        target=$(
            {
                echo "$HOME"
                reverse $log
            } | unique | peco
        )
        [[ -n "$target" ]] && builtin cd "$target"
    else
        c=$(count "$1")
        if [[ "$c" -eq 0 ]]; then
            echo "$1: no such file or directory"
            return 1
        elif [[ "$c" -eq 1 ]]; then
            builtin cd $(narrow "$1")
        else
            builtin cd $(narrow "$1"| peco)
        fi
    fi
    return 0
}

unique() {
    awk '!a[$0]++' "${1:--}"
}

list() {
    reverse $log | unique
}

narrow() {
    list | awk '/\/.?'"$1"'[^\/]*$/{print $0}'
}

count() {
    narrow "$1" | grep -c ""
}

reverse() {
    ex -s "$1" <<-EOF
g/^/mo0
%p
EOF
}

enumrate() {
    touch "$log"
    target=$PWD
    file=$(
    for ((i=1; i<${#target}+1; i++))
    do
        if [[ ${target:0:$i+1} =~ /$ ]]; then
            echo ${target:0:$i}
        fi
    done
    find $target -maxdepth 1 -type d | grep -v "\/\."
    )
    echo "${file[@]}"
}

#if [ "$0" != "${BASH_SOURCE:-}" ]; then
#    autoload -Uz add-zsh-hook
#    add-zsh-hook chpwd afterlog
#fi

refresh() {
    touch "$log"

    while read line
    do
        [ -d "$line" ] && echo $line
    done <"$log"
}

makelog() {
    $1 >/tmp/log.$$
    rm "$log"
    mv /tmp/log.$$ "$log"
}

assemble() {
    enumrate
    cat "$log"
    pwd
}

afterlog() {
    makelog "assemble"
}
