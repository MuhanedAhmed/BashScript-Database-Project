#! /bin/bash

# ---------------------------- Helper Functions ---------------------------- #

get_databases() {
  DATABASES=()
  for ITEM in "$SCRIPT_DIRECTORY_FULLPATH"/*; do
    if [ -d "$ITEM" ]; then
      DATABASES+=("$(basename "$ITEM")")
    fi
  done
  echo "${DATABASES[@]}"
}

check_database_exists() {
  DATABASE_NAME=$1
  AVAILABLE_DATABASES=($(get_databases))
  for DATABASE in ${AVAILABLE_DATABASES[@]}; do
    if [ "$DATABASE" == "$DATABASE_NAME" ]; then
      return 0
    fi
  done
  return 1
}

validate_database_name() {
  DATABASE_NAME=$1

  # Check if the database name is empty
  if [[ -z $DATABASE_NAME ]]; then
    echo "Error: Database name cannot be empty !!!"
    return 1
  fi

  # Check if the database name is greater than 64 characters
  if [[ ${#DATABASE_NAME} -gt 64 ]]; then
    echo "Error: Database name cannot exceed 64 characters !!!"
    return 1
  fi

  # Check for invalid characters in the database name
  if [[ ! $DATABASE_NAME =~ ^[a-zA-Z0-9_-]*$ ]]; then
    echo "Error: Database name can only contain alphabets, numbers, dashes and underscores !!!"
    return 1
  fi

  # Check the start of the database name (only alphabets or underscore)
  if [[ ! $DATABASE_NAME =~ ^[a-zA-Z_] ]]; then
    echo "Error: Database name must start with an alphabet or underscore !!!"
    return 1
  fi

  # Check the end of the database name (only alphabets, numbers or underscore)
  if [[ ! $DATABASE_NAME =~ [a-zA-Z0-9_]$ ]]; then
    echo "Error: Database name must end with an alphabet, number or underscore !!!"
    return 1
  fi

  return 0
}

# ---------------------------- Database Functions ---------------------------- #

create_database() {
  echo "=== Creating a database ==="
  echo "----------------------------"
  echo ""

  read -p "Enter the Database Name: " DB_NAME

  # Check the database name
  validate_database_name $DB_NAME
  if [ $? -ne 0 ]; then
    return 1
  fi

  # Check if the database name already exists 
  check_database_exists $DB_NAME
  if [ $? -eq 0 ]; then
    echo "Database '$DB_NAME' Already Exists !!!"
    return 1
  fi

  # Create database directory
  mkdir "$SCRIPT_DIRECTORY_FULLPATH/$DB_NAME"

  if [ $? -eq 0 ]; then
    echo "Database '$DB_NAME' Created Successfully !!!"
    return 0
  else
    echo "Error: Database Creation Failed !!!"
    read
    return 1
  fi
}

list_all_databases() {
  echo "=== Listing databases ==="
  echo "-------------------------"
  echo ""

  AVAILABLE_DATABASES=($(get_databases))

  if [ ${#AVAILABLE_DATABASES} -eq 0 ]; then
    echo "No Databases Available !!!"
  else
    echo "The Available Databases are : "
    echo ""
    for DATABASE in "${AVAILABLE_DATABASES[@]}"; do
      echo "$DATABASE"
    done
  fi
  
  return 0
}

drop_database() {
  echo "=== Dropping a database ==="
  echo "---------------------------"
  echo ""

  read -p "Enter the Database Name: " DB_NAME
  
  # Check if the database name exists
  check_database_exists $DB_NAME
  
  if [ $? -eq 0 ]; then
    rm -r "$SCRIPT_DIRECTORY_FULLPATH/$DB_NAME"
    echo "Database '$DB_NAME' Dropped !!!"
  else
    echo "Database '$DB_NAME' Does Not Exist !!!"
  fi
}

connect_database() {
  echo "=== Connecting to a database ==="
  echo "--------------------------------"
  echo ""

  read -p "Enter the Database Name: " DB_NAME

  # Check if the database name exists
  check_database_exists $DB_NAME

  if [ $? -eq 0 ]; then
    cd "$SCRIPT_DIRECTORY_FULLPATH/$DB_NAME"
    echo "Database '$DB_NAME' Connected !!!"
    echo "The current working directory is : $(pwd)"
  else
    echo "Database '$DB_NAME' Does Not Exist !!!"
  fi
}

# ---------------------------- Start of the main program ---------------------------- #

# Get the full path of the script directory
SCRIPT_DIRECTORY_FULLPATH=$(dirname "$(realpath "$0")")

# Main Menu
while true
do 
  clear
  echo "********** Welcome to the Database Engine **********"
  echo "----------------------------------------------------"
  echo ""
  echo "1) Create Database"
  echo "2) List All Databases"
  echo "3) Drop Database"
  echo "4) Connect To Database"
  echo ""
  echo "5) Exit"
  echo ""
  read -p ">> " CHOICE
  case $CHOICE in 
    1)
      clear
      create_database
      read
      ;;
    2)
      clear
      list_all_databases
      read
      ;;
    3)
      clear
      drop_database
      read
      ;;
    4)
      clear
      connect_database
      read
      ;;
    5)
      clear
      echo "Bye Bye !!!"
      read
      clear
      exit
      ;;
    *)
      clear
      echo "Invalid Choice !!!"
      read
      ;;
  esac
done