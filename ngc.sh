#!/bin/bash

SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"

green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

show_help() {
    echo "Usage:"
    echo "  ngc <domain>       Edit or create Nginx config for domain"
    echo "  ngc run            Link all, test once, and reload Nginx"
    echo "  ngc -r <domain>    Remove domain config and symlink"
    echo "  ngc -l             List all domains and their status"
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

    [ -f "$CONF_FILE" ] && rm "$CONF_FILE" && echo -e "${green}Removed $CONF_FILE${reset}"
    [ -L "$LINK_FILE" ] && rm "$LINK_FILE" && echo -e "${green}Removed symlink $LINK_FILE${reset}"
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

# Entry point
case "$1" in
    run)
        run_all_configs
        ;;
    -r)
        [ -n "$2" ] && remove_config "$2" || show_help
        ;;
    -l)
        list_configs
        ;;
    *)
        [ -n "$1" ] && edit_config "$1" || show_help
        ;;
esac
