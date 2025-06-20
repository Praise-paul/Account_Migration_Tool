#!/bin/bash
# Exit on errors
set -e
# Colors
cyan="\033[0;36m"
green="\033[0;32m"
red="\033[0;31m"
yellow="\033[1;33m"
reset="\033[0m"
# Function to list users
get_users() {
echo "Please run brew install rsync before proceeding further...."
  ls /Users | grep -vE 'Shared|Guest|root|^\.|^daemon|^nobody' | grep -vE '^\s*$'
}
users=($(get_users))
if [[ ${#users[@]} -lt 2 ]]; then
  echo -e "${red}:warning: Not enough user profiles found for migration. Exiting.${reset}"
  exit 1
fi
echo -e "${cyan}\nAvailable User Profiles:${reset}"
for i in "${!users[@]}"; do
  echo "[$i] ${users[$i]}"
done
# Prompt for source
read -p $'\nEnter number for the \033[1mSOURCE\033[0m user (copy from): ' src_index
source_user="${users[$src_index]}"
# Prompt for destination
read -p $'\nEnter number for the \033[1mDESTINATION\033[0m user (copy to): ' dst_index
dest_user="${users[$dst_index]}"
echo -e "\n${green}Migrating data from '$source_user' to '$dest_user'...${reset}"
sleep 2
# Directories to copy
folders=("Desktop" "Documents" "Downloads" "Pictures" "Music" "Movies")
for folder in "${folders[@]}"; do
  src="/Users/$source_user/$folder"
  dst="/Users/$dest_user/$folder"
  if [[ -d "$src" ]]; then
    echo -e "\n${yellow}:open_file_folder: Copying: $folder${reset}"
    sudo /opt/homebrew/bin/rsync -aE --progress "$src/" "$dst/"
    echo -e "${cyan}:closed_lock_with_key: Fixing permissions...${reset}"
    sudo chown -R "$dest_user:staff" "$dst"
  else
    echo -e "${red}:fast_forward: Skipping $folder (not found).${reset}"
  fi
done
# Optional: VS Code and Slack config
read -p $'\nMigrate VS Code and Slack config too? (y/n): ' copy_apps
if [[ "$copy_apps" =~ ^[Yy]$ ]]; then
  apps=("Code" "Slack")
  for app in "${apps[@]}"; do
    src="/Users/$source_user/Library/Application Support/$app"
    dst="/Users/$dest_user/Library/Application Support/$app"
    if [[ -d "$src" ]]; then
      echo -e "\n${yellow}:gear: Copying $app data${reset}"
      sudo rsync -aE "$src/" "$dst/"
      sudo chown -R "$dest_user:staff" "$dst"
    fi
  done
  # VS Code extensions
  if [[ -d "/Users/$source_user/.vscode" ]]; then
    echo -e "\n${yellow}:jigsaw: Copying VS Code extensions${reset}"
    sudo rsync -aE "/Users/$source_user/.vscode/" "/Users/$dest_user/.vscode/"
    sudo chown -R "$dest_user:staff" "/Users/$dest_user/.vscode"
  fi
fi
echo -e "\n${green}:white_check_mark: Migration complete!${reset}"
