#!/bin/bash

# Estilos
TX_BOLD="\e[1m"
TX_RESET="\e[0m"

# Colores de texto
TX_RED="\e[31m"
TX_GREEN="\e[32m"
TX_YELLOW="\e[33m"
TX_BLUE="\e[34m"
TX_MAGENTA="\e[35m"
TX_CYAN="\e[36m"
TX_WHITE="\e[37m"

# Estilos especiales
TX_INFO="${TX_BOLD}${TX_CYAN}"
TX_WARNING="${TX_BOLD}${TX_YELLOW}"
TX_ERROR="${TX_BOLD}${TX_RED}"
TX_SUCCESS="${TX_BOLD}${TX_GREEN}"

function echo_info(){
    if [ -n "${DEBUG_MSG}" ] && [ "${DEBUG_MSG}" -eq 1 ]; then
        echo -e "${TX_INFO}[i]${TX_RESET} ${TX_INFO}${@}${TX_RESET}"
    fi
}

function echo_warning(){
    if [ -n "${DEBUG_MSG}" ] && [ "${DEBUG_MSG}" -eq 1 ]; then
        echo -e "${TX_WARNING}[!]${TX_RESET} ${TX_WARNING}${@}${TX_RESET}"
    fi
}

function echo_error(){
    if [ -n "${DEBUG_MSG}" ] && [ "${DEBUG_MSG}" -eq 1 ]; then
        echo -e "${TX_ERROR}[x]${TX_RESET} ${TX_ERROR}${@}${TX_RESET}"
    fi
}

function echo_success(){
    if [ -n "${DEBUG_MSG}" ] && [ "${DEBUG_MSG}" -eq 1 ]; then
        echo -e "${TX_SUCCESS}[✔︎]${TX_RESET} ${TX_SUCCESS}${@}${TX_RESET}"
    fi
}