log=~/.cdlog

cd() {
    makelog

    if [ -z "$1" ]; then
        target=$(
            {
                echo "$HOME"
                reverse $log
            } | duplicate - | peco
        )
        [[ -n "$target" ]] && builtin cd "$target"
    else
        if [ -d "$1" ]; then
            builtin cd "$1"
        else
            extend_cd "$1"
        fi
    fi
}

extend_cd() {
    c=$(count "$1")
    if [[ "$c" -eq 0 ]]; then
        echo "$1: no such file or directory"
        return 1
    elif [[ "$c" -eq 1 ]]; then
        builtin cd $(narrow "$1")
    else
        builtin cd $(narrow "$1"| peco)
    fi
    return 0
}

duplicate() {
    awk '!a[$0]++' "$1"
}

narrow() {
    list | awk '/\/.?'"$1"'[^\/]*$/{print $0}'
}

list() {
    reverse $log | duplicate -
}

count() {
    narrow "$1" | grep -c ""
}

reverse() {
$(which ex) -s $1 <<-EOF
g/^/mo0
%p
EOF
}

log() {
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
    echo "${file[@]}" >>"$log"
}

autoload -Uz add-zsh-hook
add-zsh-hook chpwd log

refresh() {
    cat "$log" | while read line
    do
        [ -d "$line" ] && echo $line
    done
}

makelog() {
    refresh >/tmp/log.$$
    rm "$log"
    mv /tmp/log.$$ "$log"
}
