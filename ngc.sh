#!/bin/bash

SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"

green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

show_help() {
    echo "Usage:"
    echo "  ngc <domain>          Edit or create Nginx config for domain"
    echo "  ngc run               Link all, test once, and reload Nginx"
    echo "  ngc rm <domain>       Remove domain config and symlink"
    echo "  ngc list              List all domains and their status"
    echo "  ngc listbak           List all backed up (.bak) configs"
    echo "  ngc restore <domain>  Restore a config from a .bak file"
    echo "  ngc ren <old> <new>   Rename a config file (both available and enabled)"
}

edit_config() {
    DOMAIN="$1"
    CONF_FILE="${SITES_AVAILABLE}/${DOMAIN}"

    if [ ! -f "$CONF_FILE" ]; then
        echo -e "# Nginx config for $DOMAIN\n" > "$CONF_FILE"
        echo -e "${green}Created config at $CONF_FILE${reset}"
    fi

    nano "$CONF_FILE"
}

run_all_configs() {
    echo "Ensuring symlinks exist for all configs..."
    for CONF_FILE in "$SITES_AVAILABLE"/*; do
        DOMAIN=$(basename "$CONF_FILE")

        [[ "$DOMAIN" == *.bak ]] && continue

        LINK_FILE="${SITES_ENABLED}/${DOMAIN}"
        if [ ! -L "$LINK_FILE" ]; then
            ln -s "$CONF_FILE" "$LINK_FILE"
            echo -e "${green}Linked $DOMAIN${reset}"
        fi
    done

    echo "Testing all configs with nginx -t..."
    if nginx -t; then
        echo -e "${green}All configs valid. Reloading Nginx...${reset}"
        systemctl reload nginx && echo -e "${green}Nginx reloaded.${reset}"
    else
        echo -e "${red}Config test failed. Check output above.${reset}"
        exit 1
    fi
}

remove_config() {
    DOMAIN="$1"
    CONF_FILE="${SITES_AVAILABLE}/${DOMAIN}"
    LINK_FILE="${SITES_ENABLED}/${DOMAIN}"

    if [ -f "$CONF_FILE" ]; then
        mv "$CONF_FILE" "${CONF_FILE}.bak"
        echo -e "${green}Backed up $CONF_FILE to ${CONF_FILE}.bak${reset}"
    else
        echo -e "${red}Config file $CONF_FILE does not exist.${reset}"
        exit 1
    fi

    if [ -L "$LINK_FILE" ]; then
        rm "$LINK_FILE"
        echo -e "${green}Removed symlink $LINK_FILE${reset}"
    else
        echo -e "${red}Symlink $LINK_FILE does not exist.${reset}"
    fi
}

list_configs() {
    echo "Nginx config overview:"
    for CONF_FILE in "$SITES_AVAILABLE"/*; do
        DOMAIN=$(basename "$CONF_FILE")

        [[ "$DOMAIN" == *.bak ]] && continue

        LINK_FILE="${SITES_ENABLED}/${DOMAIN}"
        STATUS="${red}Not linked${reset}"
        [ -L "$LINK_FILE" ] && STATUS="${green}Linked${reset}"

        echo -e "$DOMAIN: $STATUS"
    done

    nginx_status=$(systemctl is-active nginx)
    echo -e "\nNginx service status: ${green}$nginx_status${reset}"
}

list_bak_configs() {
    echo "Backed up Nginx configs:"
    for CONF_FILE in "$SITES_AVAILABLE"/*.bak; do
        DOMAIN=$(basename "$CONF_FILE" .bak)
        echo -e "$DOMAIN: ${green}Backed up${reset}"
    done
}

restore_config() {
    DOMAIN="$1"
    BAK_FILE="${SITES_AVAILABLE}/${DOMAIN}.bak"
    CONF_FILE="${SITES_AVAILABLE}/${DOMAIN}"

    if [ -f "$BAK_FILE" ]; then
        mv "$BAK_FILE" "$CONF_FILE"
        echo -e "${green}Restored $CONF_FILE from $BAK_FILE${reset}"
    else
        echo -e "${red}Backup file $BAK_FILE does not exist.${reset}"
        exit 1
    fi
}

rename_config() {
    OLD_DOMAIN="$1"
    NEW_DOMAIN="$2"
    OLD_CONF_FILE="${SITES_AVAILABLE}/${OLD_DOMAIN}"
    NEW_CONF_FILE="${SITES_AVAILABLE}/${NEW_DOMAIN}"
    OLD_LINK_FILE="${SITES_ENABLED}/${OLD_DOMAIN}"
    NEW_LINK_FILE="${SITES_ENABLED}/${NEW_DOMAIN}"

    if [ ! -f "$OLD_CONF_FILE" ]; then
        echo -e "${red}Config file $OLD_CONF_FILE does not exist.${reset}"
        exit 1
    fi

    if [ -f "$NEW_CONF_FILE" ]; then
        echo -e "${red}Config file $NEW_CONF_FILE already exists. Aborting to avoid overwriting.${reset}"
        exit 1
    fi

    if [ -L "$NEW_LINK_FILE" ]; then
        echo -e "${red}Symlink $NEW_LINK_FILE already exists. Aborting to avoid overwriting.${reset}"
        exit 1
    fi

    mv "$OLD_CONF_FILE" "$NEW_CONF_FILE"
    echo -e "${green}Renamed $OLD_CONF_FILE to $NEW_CONF_FILE${reset}"

    if [ -L "$OLD_LINK_FILE" ]; then
        rm "$OLD_LINK_FILE"
        echo -e "${green}Removed old symlink $OLD_LINK_FILE${reset}"
    fi

    echo -e "${green}Use 'ngc run' to ensure changes are applied.${reset}"
}

# Entry point
case "$1" in
    run)
        run_all_configs
        ;;
    rm)
        [ -n "$2" ] && remove_config "$2" || show_help
        ;;
    list)
        list_configs
        ;;
    listbak)
        list_bak_configs
        ;;
    restore)
        [ -n "$2" ] && restore_config "$2" || show_help
        ;;
    ren)
        [ -n "$3" ] && rename_config "$2" "$3" || show_help
        ;;
    *)
        [ -n "$1" ] && edit_config "$1" || show_help
        ;;
esac
