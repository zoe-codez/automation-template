#!/bin/bash
# Reset
NC='\033[0m' # No Color

# Regular Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

# Bold
BOLD='\033[1m'
BOLD_GREEN='\033[1;32m'
BOLD_YELLOW='\033[1;33m'
BOLD_BLUE='\033[1;34m'
BOLD_PURPLE='\033[1;35m'

prompt_yes_no() {
  while true; do
    read -p "$1 (yes/no)? " yn
    case $yn in
      [Yy]* ) result="yes"; break;;
      [Nn]* ) result="no"; break;;
      * ) echo "Please answer yes or no.";;
    esac
  done
  echo "$result"
}

update_config() {
  local key="$1"
  local new_value="$2"
  local file_path="$3"

  sed -i "/^\s*${key}\s*=/c\\${key}=${new_value}" "$file_path"
}

echo -e "${BOLD_GREEN}quick setup${NC}"
default_folder_name="./home_automation"

valid=0
while [ $valid -eq 0 ]; do
  read -r -p "Enter the folder name to build the project in (default: home_automation): " folder_name
  folder_name=${folder_name:-home_automation}
  folder_name=${folder_name//[-]/_}

  # Check if the folder name starts with a letter or underscore and contains only letters, numbers, or underscores
  if [[ $folder_name =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]]; then
    valid=1
  else
    echo "The folder name must start with a letter or underscore and contain only letters, numbers, or underscores."
    echo "Please enter a valid folder name."
  fi
done


if [ ! -d "$folder_name" ]; then
  wget https://github.com/zoe-codez/automation-template/archive/refs/heads/main.zip
  unzip main.zip
  mv automation-template-main "$folder_name"
fi

cd "$folder_name" || exit


# Customize the code based on the folder name!
# Variable replacements in code
if [ "$folder_name" != "$default_folder_name" ]; then
  new_name=$(basename "$folder_name")

  sed -i "s/home_automation/$new_name/g" package.json
  sed -i "s/home_automation/$new_name/g" automation.code-workspace
  sed -i "s/home_automation/$new_name/g" README.md
  sed -i "s/home_automation/$new_name/g" ./addon/config.yaml
  find ./src -type f -name "*.ts" -exec sed -i "s/home_automation/$new_name/g" {} \;

  # Rename .home_automation to .{new_name} if it exists
  if [ -d ".home_automation" ]; then
    mv .home_automation ."$new_name"
  fi
fi

read -r -p "Would you like to create a configuration file? (yes/no): " create_conf
if [[ $create_conf =~ ^[Yy] ]]; then
  read -r -p "Enter the base_url (default: http://homeassistant.local:8123): " base_url
  base_url=${base_url:-http://homeassistant.local:8123}

  echo -n "Enter long lived access token: "
  read -r -s token
  echo

  config_file=".$(jq -r '.name' package.json)"

  update_config "BASE_URL" "$base_url" "$config_file"
  update_config "TOKEN" "$token" "$config_file"
  update_config "BASE_URL" "$base_url" ".type_writer"
  update_config "TOKEN" "$token" ".type_writer"

  zsh ./scripts/environment.sh "/config/$folder_name" || exit 1
else
  echo "Skipping configuration file creation."
  zsh ./scripts/environment.sh "/config/$folder_name" --quick || exit 1
fi

if [ -f "/config" ]; then
    FNM_DIR="/config/.fnm"
else
    FNM_DIR="$HOME/.fnm"
fi

zsh ./scripts/update_deps.sh


export PATH="./node_modules/figlet-cli/bin/:$FNM_DIR:$PATH"
eval "$(fnm env --shell=zsh)"

if [ -f "/config" ]; then
  figlet -f "Pagga" "Deploy" | npx lolcatjs
  zsh ./scripts/addon.sh
# else
  # todo: something with pm2 probably
fi

echo
echo -e "${BOLD_GREEN}done!"
figlet -f "Pagga" "Next Steps" | npx lolcatjs
echo
echo
echo -e "${BOLD_YELLOW}1.${NC} ${BOLD}open the provided code workspace"
echo -e "  ${BLUE}-${NC} less clutter"
echo -e "  ${BLUE}-${NC} easy access to ${CYAN}package.json${NC} scripts"
echo -e "  ${BLUE}-${NC} from cli: ${GREEN}code ${folder_name}/automation.code-workspace"
echo
echo -e "${BOLD_YELLOW}2.${NC} ${BOLD}write your code"
echo -e "  ${BLUE}-${NC} ${CYAN}src/main.ts${NC} is the application entry point"
echo
echo -e "${BOLD_YELLOW}3.${NC} ${BOLD}run code"
echo -e "  ${BLUE}-${NC} see ${CYAN}package.json${NC} for listing of all options"
echo
