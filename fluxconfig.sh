#!/bin/bash

help_description()
{
  echo "Example of usage :"
  echo "./fluxconfig.sh -c <path_to_config_file>"
  echo ""
  echo "Arguments description :"
  echo "<path_to_config_file> - path to FluxConfig .cfg file"
  echo "To learn about it's structure visit https://github.com/FluxConfig/Deployment/blob/master/README.md"
}

boot_script()
{
  # Parse CLI Arguments
  ########
  while getopts "c:h" opt
    do
      case "$opt" in
        c ) local pathToConfig="$OPTARG" ;;
        h ) 
          help_description
          exit 0  ;;
        ? ) 
          help_description
          exit 1  ;;
      esac
  done
    
  if [ -z "$pathToConfig" ]; then 
    echo "Missing -c CLI argument."
    help_description
    exit 1
  fi
  ########
  
  # Check docker installation
  ########
  if ! command -v docker 2>&1 >/dev/null
    then
        echo "Docker could not be found. Install Docker first."
        exit 1
  fi
    
  if ! command -v docker-compose 2>&1 >/dev/null
    then
        echo "Docker-compose could not be found. Install Docker-compose first."
        exit 1
  fi
  ########
  
  # Fetching compose file
  ########
  local COMPOSE_URL="https://raw.githubusercontent.com/FluxConfig/Deployment/refs/heads/master/docker-compose.yml"
  echo "Fetching docker-compose.yml..."
  
  curl -fsSL -o docker-compose.yml "$COMPOSE_URL"
  
  if [ $? -ne 0 ]; then
    echo "Failed to fetch docker-compose.yml:"
    echo "  - HTTP Error or network failure"
    exit 1
  elif [ ! -f "docker-compose.yml" ]; then
    echo "Download failed - no file created"
    exit 1
  elif [ ! -s "docker-compose.yml" ]; then
    echo "Download failed - empty file received"
    exit 1
  fi
  
  echo "docker-compose.yml successfully downloaded"
  echo ""
  ########
  
  
  # Check config file existence and download if needed
  ########
  if [ ! -f "$pathToConfig" ]
  then
    local downloadAc
    echo "Config file not found. Do you want to download template file? y/n"
    read downloadAc
    if [ "$downloadAc" == "y" ]; then
      local TEMPLATE_URL="https://raw.githubusercontent.com/FluxConfig/Deployment/refs/heads/master/fluxconfig.template.cfg"
      echo ""
      echo "Fetching fluxconfig.template.cfg..."
      
      curl -fsSL -o fluxconfig.template.cfg "$TEMPLATE_URL"
        
      if [ $? -ne 0 ]; then
        echo "Failed to fetch docker-compose.yml:"
        echo "  - HTTP Error or network failure"
        exit 1
      elif [ ! -f "docker-compose.yml" ]; then
        echo "Download failed - no file created"
        exit 1
      elif [ ! -s "docker-compose.yml" ]; then
        echo "Download failed - empty file received"
        exit 1
      fi
      
      echo "fluxconfig.template.cfg successfully downloaded"
      echo "Please fill the configuration file and run this script again."
      echo ""
      exit 0
    fi
    exit 1;
  fi
  ########
  
  # Load cfg variables to .env
  ########
  if [ ! -f ".env" ]
  then
    touch ".env"
  fi
  truncate -s 0 ".env"
  
  echo "Reading .cfg file..."
  while IFS= read -r line || [[ -n "$line" ]]; do
      if [[ "$line" =~ ^#.*$ || -z "$line" ]]; then
          continue
      fi
  
      key=$(echo "$line" | cut -d '=' -f 1)
      value=$(echo "$line" | cut -d '=' -f 2-)
  
      key=$(echo "$key" | xargs)
      value=$(echo "$value" | xargs)
      
      if [ "$key" == "PG_USER" ] && [ -z "$value" ]; then
        echo ""
        echo "Generating value for PG_USER"
        value="u$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')"
      fi

      if [ "$key" == "PG_PSWD" ] && [ -z "$value" ]; then
        echo ""
        echo "Generating value for PG_PSWD"
        value=$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')
      fi

      if [ "$key" == "MONGO_USERNAME" ] && [ -z "$value" ]; then
        echo ""
        echo "Generating value for MONGO_USERNAME"
        value="u$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')"
      fi

      if [ "$key" == "MONGO_PASSWORD" ] && [ -z "$value" ]; then
        echo ""
        echo "Generating value for MONGO_PASSWORD"
        value=$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')
      fi
    
      printf "$key=$value\n" >> .env
      echo "Loaded: $key=$value"
  done < "$pathToConfig"
  ########
  
  # Generating pg credentials for internal usage
  ########
  postgres_users_vars=("PG_FCM_APP_USER" "PG_MIGRATION_USER")
  pguv_descriptions=("Postgres FCM application User" "Postgres migration User")
  postgres_pswd_vars=("PG_FCM_APP_PSWD" "PG_MIGRATION_PSWD")
  pgpswd_descriptions=("Postgres FCM application Password" "Postgres migration Password")
  
  # users
  echo ""
  for i in "${!postgres_users_vars[@]}"; do
    var="${postgres_users_vars[$i]}"
    desc="${pguv_descriptions[$i]}"
    if ! grep -q "^$var=" .env; then
      value="u$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')"
      echo "$var=$value" >> .env
    fi
  done
  
  #passwords
  for i in "${!postgres_pswd_vars[@]}"; do
      var="${postgres_pswd_vars[$i]}"
      desc="${pgpswd_descriptions[$i]}"
      if ! grep -q "^$var=" .env; then
        value=$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')
        echo "$var=$value" >> .env
      fi
    done
  ########

  # Genetaing internal api-key
  iakvalue=$(uuidgen | tr -d '-' | tr '[:upper:]' '[:lower:]')
  printf "FC_API_KEY=$iakvalue\n" >> .env

  # Mapping ports and addresses
  printf "FCM_BASE_URL=http://fc-management:7070\n" >> .env
  printf "FCS_BASE_URL=https://fc-storage:7077\n" >> .env

  if ! grep -q '^MANAGEMENT_API_PORT=' .env; then
    echo "MANAGEMENT_API_PORT=7070" >> .env
  fi
  if ! grep -q '^STORAGE_API_PORT=' .env; then
    echo "STORAGE_API_PORT=7077" >> .env
  fi
  if ! grep -q '^FC_CLIENT_PORT=' .env; then
    echo "FC_CLIENT_PORT=3000" >> .env
  fi

  source .env

  printf "FCWC_URL=http://localhost:$FC_CLIENT_PORT\n" >> .env
  printf "CFCM_BASE_URL=http://localhost:$MANAGEMENT_API_PORT\n" >> .env

  # Booting
  ########
  echo ""
  echo "Starting FluxConfig System..."
  docker-compose up -d
  exit 0
  ########
}


boot_script "$@"