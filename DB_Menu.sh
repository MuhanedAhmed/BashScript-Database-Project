#! /bin/bash

# ---------------------------- Setting the current working directory for the script ---------------------------- #

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# ---------------------------- Checking Databases Directory ---------------------------- #

if [ ! -d "./DBs" ]
then
  mkdir ./DBs
fi

# ---------------------------- Sourcing needed scripts ---------------------------- #

if [ -f "./Utils.sh" ]; then
  source ./Utils.sh
else
  echo "Error: Utils.sh not found !!!"
  exit 1
fi

if [ -f "./Table_Menu.sh" ]; then
  source ./Table_Menu.sh
else
  echo "Error: Table_Menu.sh not found !!!"
  exit 1
fi

# ---------------------------- Database Functions ---------------------------- #

create_database() {
  echo "=== Creating a database ==="
  echo "---------------------------"
  echo ""

  read -p "Enter the Database Name: " DB_NAME

  # Check the database name
  until validate_structure_name "Database" $DB_NAME; do
    echo ""
    read -p "Enter the Database Name: " DB_NAME
  done

  # Replace white spaces with _
  DB_NAME=$(echo "$DB_NAME" | tr ' ' '_')

  # Check if the database name already exists
  until ! check_database_exists "$DB_NAME"; do
    echo "Database '$DB_NAME' Already Exists !!!"
    echo ""
    read -p "Enter the Database Name: " DB_NAME
  done

  # Create database directory
  mkdir "./DBs/$DB_NAME"

  if [ $? -eq 0 ]; then
    clear
    echo "Database '$DB_NAME' Created Successfully !!!"
    return 0
  else
    clear
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
  
  # Replace white spaces with _
  DB_NAME=$(echo "$DB_NAME" | tr ' ' '_')

  # Check if the database name exists
  until check_database_exists "$DB_NAME"; do
    echo "Database '$DB_NAME' Does Not Exist !!!"
    echo ""
    read -p "Enter the Database Name: " DB_NAME
  done

  echo ""
  read -p "Are you sure you want to drop '$DB_NAME' database ??? [y/n] : " CHOICE
  if [ "$CHOICE" != 'y' -a "$CHOICE" != 'Y' ]; then
    echo ""
    echo "OK, Good choice :) ..."
    return 0
  fi
  
  echo ""
  read -p "THIS IS THE LAST CHANCE !!! Are you sure you want to drop '$DB_NAME' database ??? [y/n] : " CHOICE
  if [ "$CHOICE" != 'y' -a "$CHOICE" != 'Y' ]; then
    echo ""
    echo "OK, I thought so :) ..."
    return 0
  else
    rm -rf "./DBs/$DB_NAME"
  fi
  

  clear
  if [ $? -eq 0 ]; then
    echo "Database '$DB_NAME' Dropped Successfully !!!"
    return 0
  else
    echo "Error: Database Dropping Failed !!!"
    return 1
  fi
}

connect_database() {
  echo "=== Connecting to a database ==="
  echo "--------------------------------"
  echo ""

  read -p "Enter the Database Name: " DB_NAME

  # Replace white spaces with _
  DB_NAME=$(echo $DB_NAME | tr ' ' '_')

  # Check if the database name exists
  until check_database_exists "$DB_NAME"; do
    echo "Database '$DB_NAME' Does Not Exist !!!"
    echo ""
    read -p "Enter the Database Name: " DB_NAME
  done

  start_table_menu

  return 0
}

# ---------------------------- Start of the main program ---------------------------- #

while true
do 
  clear
  echo "********** Welcome to the Database Engine **********"
  echo "----------------------------------------------------"
  echo ""
  echo "1) Create Database"
  echo "2) List All Databases"
  echo "3) Connect To Database"
  echo "4) Drop Database"
  echo ""
  echo "5) Exit"
  echo ""
  read -p ">> " CHOICE
  case $CHOICE in 
    1)
      clear
      create_database
      read -t 3
      ;;
    2)
      clear
      list_all_databases
      read
      ;;
    3)
      clear
      connect_database
      read -t 3
      ;;
    4)
      clear
      drop_database
      read -t 3
      ;;
    5)
      clear
      echo "****** Thanks For Using Our DBMS ******"
      read -t 3
      clear
      exit 0
      ;;
    *)
      ;;
  esac
done