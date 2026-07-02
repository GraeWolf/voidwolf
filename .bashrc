#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

source ~/.local/share/voidwolf/bash/rc

# NVIDIA symlink fix for Distrobox
fix_nvidia_symlink() {
    local link_name="$1"
    local target_name="$2"
    if [ ! -e "${target_name}" ]; then return 1; fi
    if { [ -L "${link_name}" ] && [ ! -e "${link_name}" ]; } || \
       { [ -f "${link_name}" ] && [ ! -s "${link_name}" ]; } || \
       [ ! -e "${link_name}" ]; then
        sudo rm -f "${link_name}"
        sudo ln -sf "${target_name}" "${link_name}" && NEEDS_LDCONFIG=1
    fi
}

NEEDS_LDCONFIG=0
fix_nvidia_symlink "/usr/lib64/libcuda.so" "/usr/lib64/libcuda.so.1"
fix_nvidia_symlink "/usr/lib64/libnvcuvid.so" "/usr/lib64/libnvcuvid.so.1"
if [ "$NEEDS_LDCONFIG" -eq 1 ]; then
    sudo ldconfig
fi
