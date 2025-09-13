function list_vga(){
    lspci -nn | grep -e VGA
}

function count_vga(){
    list_vga | wc -l
}

function check_single_pt(){
    if [ $(count_vga) -ne 1 ]; then
        return
    fi

    if list_vga | grep "${1}:${2}" > /dev/null 2>&1; then
        if list_vga | grep NVIDIA > /dev/null 2>&1; then
            echo nvidia
        elif list_vga | grep AMD > /dev/null 2>&1; then
            echo amd
        elif list_vga | grep Intel > /dev/null 2>&1; then
            echo intel
        else
            echo ""
        fi
    else
        echo ""
    fi
}

echo $(check_single_pt 10de 28e0)
