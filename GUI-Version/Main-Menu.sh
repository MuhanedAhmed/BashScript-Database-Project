#!/bin/bash

# ---------------------------- Setting the current working directory for the script ---------------------------- #

cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

# ---------------------------- Checking Databases Directory ---------------------------- #

if [ ! -d "./DBs" ]; then
  mkdir ./DBs
fi

# ---------------------------- Sourcing needed scripts ---------------------------- #

if [ -f "./Utils.sh" ]; then
  source ./Utils.sh
else
  zenity --error --title="Error" --text="Utils.sh not found !!!" --width=300
  exit 1
fi

if [ -f "./Table_Menu.sh" ]; then
  source ./Table_Menu.sh
else
  zenity --error --title="Error" --text="Table_Menu.sh not found !!!" --width=300
  exit 1
fi

# ---------------------------- Database Functions ---------------------------- #

create_database() {
  DB_NAME=$(zenity --entry --title="Create Database" --text="Enter the Database Name:" --width=400 --ok-label="Create")
  if [ $? -ne 0 ]; then return 1; fi

  # Check the database name
  until validate_structure_name "Database" $DB_NAME; do
    DB_NAME=$(zenity --entry --title="Create Database" --text="Enter the Database Name:" --width=400 --ok-label="Create")
    if [ $? -ne 0 ]; then return 1; fi
  done

  # Replace white spaces with _
  DB_NAME=$(echo "$DB_NAME" | tr ' ' '_')

  # Check if the database name already exists
  until ! check_database_exists "$DB_NAME"; do
    zenity --error --title="Error" --text="Database '$DB_NAME' Already Exists" --width=300
    DB_NAME=$(zenity --entry --title="Create Database" --text="Enter the Database Name:" --width=400 --ok-label="Create")
    if [ $? -ne 0 ]; then return 1; fi
  done

  # Create database directory
  mkdir "./DBs/$DB_NAME"

  if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="Database '$DB_NAME' Created Successfully !!!" --width=300
    return 0
  else
    zenity --error --title="Error" --text="Database Creation Failed" --width=300
    return 1
  fi
}

list_all_databases() {
  AVAILABLE_DATABASES=($(get_databases))

  if [ ${#AVAILABLE_DATABASES[@]} -eq 0 ]; then
    zenity --info --title="No Databases" --text="No Databases Available To List !!!" --width=300
    return 0
  fi

  DB_NAME=$(zenity --list --title="Available Databases" --text="The available databases are:" \
    --column="Database Name" "${AVAILABLE_DATABASES[@]}" --width=400 --height=300 --ok-label="Connect" --cancel-label="Back")

  if [ $? -ne 0 ] || [ -z "$DB_NAME" ]; then return 0; fi  # User canceled

  zenity --question --title="Connect to Database" \
    --text="Do you want to connect to '$DB_NAME' database ???" \
    --width=400 --ok-label="Connect" --cancel-label="Cancel"

  if [ $? -eq 0 ]; then
    start_table_menu
    if [ $? -ne 0 ]; then
      zenity --error --title="Error" --text="Failed to connect to database '$DB_NAME'" --width=300
      return 1
    fi
    return 0
  fi
}

drop_database() {
  AVAILABLE_DATABASES=($(get_databases))
  
  if [ ${#AVAILABLE_DATABASES[@]} -eq 0 ]; then
    zenity --info --title="No Databases" --text="No Databases Available To Drop !!!" --width=300
    return 0
  fi
  
  DB_NAME=$(zenity --list --title="Drop Database" --text="Select database to drop:" \
    --column="Database Name" "${AVAILABLE_DATABASES[@]}" --width=400 --height=300)
  
  if [ $? -ne 0 ] ]; then return 0; fi  # User canceled

  until [ -n "$TABLE_NAME" ]; do
    zenity --error --text "database name is not selected"
    DB_NAME=$(zenity --list --title="Drop Database" --text="Select database to drop:" \
    --column="Database Name" "${AVAILABLE_DATABASES[@]}" --width=400 --height=300)
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done
  
  # Confirm deletion
  zenity --question --title="Confirm" --text="Are you sure you want to drop '$DB_NAME' database ???" 
  if [ $? -ne 0 ]; then
    zenity --info --title="Cancelled" --text="OK, Good choice :) ..." --width=300
    return 0
  fi
  
  # Final confirmation
  zenity --question --title="Final Confirmation" \
    --text="THIS IS THE LAST CHANCE !!! Are you sure you want to drop '$DB_NAME' database ???" \
    --width=400 --ok-label="Yes, Drop It" --cancel-label="No, Keep It"
  if [ $? -ne 0 ]; then
    zenity --info --title="Cancelled" --text="OK, I thought so :) ..." --width=300
    return 0
  fi
  
  rm -rf "./DBs/$DB_NAME"
  if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="Database '$DB_NAME' Dropped Successfully !!!" --width=300
  else
    zenity --error --title="Error" --text="Database Dropping Failed" --width=300
  fi
}

connect_database() {
  AVAILABLE_DATABASES=($(get_databases))
  
  if [ ${#AVAILABLE_DATABASES[@]} -eq 0 ]; then
    zenity --info --title="No Databases" --text="No Databases Available To Connect !!!" --width=300
    return 0
  fi
  
  DB_NAME=$(zenity --list --title="Connect to Database" --text="Select database to connect:" \
    --column="Database Name" "${AVAILABLE_DATABASES[@]}" --width=400 --height=300)
  if [ $? -ne 0 ] || [ -z "$DB_NAME" ]; then return 0; fi  # User canceled
  
  start_table_menu
}

# ---------------------------- Start of the main program ---------------------------- #

while true; 
do
  CHOICE=$(zenity --list --title="Database Engine" --text="Welcome to the Database Engine" \
    --column="Main Menu" \
    "Create Database" \
    "List All Databases" \
    "Connect To Database" \
    "Drop Database" \
    --width=500 --height=300 --cancel-label="Exit" --ok-label="Select")
    
  # Check if the user clicked "Cancel" or closed the dialog
  if [ $? -ne 0 ]; then
    zenity --question --text="Do you want to quit?"
    if [[ $? -eq 0 ]]; then
      zenity --info --title="Goodbye" --text="Thanks For Using Our DBMS" --width=300
      exit 0
    else
      continue
    fi
  fi
  
  case $CHOICE in
    "Create Database")
      create_database
      ;;
    "List All Databases")
      list_all_databases
      ;;
    "Connect To Database")
      connect_database
      ;;
    "Drop Database")
      drop_database
      ;;
    *)
      zenity --error --title="Error" --text="Invalid option selected!" --width=300
      ;;
  esac
done