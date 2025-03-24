#! /bin/bash

# ---------------------------- Checking Databases Directory ---------------------------- #

if [ ! -d "./DBs" ]
then
  mkdir ./DBs
fi

# ---------------------------- Sourcing Utils.sh ---------------------------- #

if [ -f ./Utils.sh ]; then
  source ./Utils.sh
else
  echo "Error: Utils.sh not found !!!"
  exit 1
fi

# ---------------------------- Database Functions ---------------------------- #

create_database() {
  echo "=== Creating a database ==="
  echo "----------------------------"
  echo ""

  read -p "Enter the Database Name: " DB_NAME

  # Check the database name
  validate_structure_name "Database" $DB_NAME
  if [ $? -ne 0 ]; then
    return 1
  fi

  # Replace white spaces with _
  DB_NAME=$(echo $DB_NAME | tr ' ' '_')

  # Check if the database name already exists 
  check_database_exists $DB_NAME
  if [ $? -eq 0 ]; then
    echo "Database '$DB_NAME' Already Exists !!!"
    return 1
  fi

  # Create database directory
  mkdir "./DBs/$DB_NAME"

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
  
  # Replace white spaces with _
  DB_NAME=$(echo $DB_NAME | tr ' ' '_')

  # Check if the database name exists
  check_database_exists $DB_NAME
  
  if [ $? -eq 0 ]; then
    rm -r "./DBs/$DB_NAME"
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

  # Replace white spaces with _
  DB_NAME=$(echo $DB_NAME | tr ' ' '_')

  # Check if the database name exists
  check_database_exists $DB_NAME

  if [ $? -eq 0 ]; then
    source Table_Menu.sh $DB_NAME
  else
    echo "Database '$DB_NAME' Does Not Exist !!!"
  fi
}

# ---------------------------- Start of the main program ---------------------------- #
PS3=">> "
select input in "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit"
do
  case $REPLY in
    1)
      clear
      create_database
      ;;
    2)
      clear
      list_all_databases
      ;;
    3)
      clear
      connect_database
      ;;
    4)
      clear
      drop_database
      ;;
    5)
      clear
      echo "Thanks For Using Our DBMS"
      exit
      ;;
    *)
      clear
      echo "Invalid Option Selected !!!"
      ;;
  esac
done