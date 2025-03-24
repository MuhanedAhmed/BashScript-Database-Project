#!/bin/bash

DB_NAME=$1

# ---------------------------- Helper Functions ---------------------------- #

get_tables() {
  TABLES=()
  for ITEM in ./DBs/$DB_NAME/*; do
    if [ -f "$ITEM" ]; then
      TABLES+=("$(basename "$ITEM")")
    fi
  done
  echo "${TABLES[@]}"
}

check_table_exists() {
  TABLE_NAME=$1
  AVAILABLE_TABLES=($(get_tables))
  for TABLE in ${AVAILABLE_TABLES[@]}; do
    if [ "$TABLE" == "$TABLE_NAME" ]; then
      return 0
    fi
  done
  return 1
}

check_nonzero_positive_integer() {
  if [[ $1 =~ ^[1-9][0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

validate_table_name() {
  if [ -z $1 ]; then
    echo "Error: Table Name Cannot Be Empty !!!"
    return 1
  fi

  if [[ $1 =~ [^a-zA-Z0-9_] ]]; then
    echo "Error: Table Name Can Only Contain Alphabets, Numbers, and Underscores !!!"
    return 1
  fi

  return 0
}

validate_column_name() {
  if [ -z $1 ]; then
    echo "Error: Column Name Cannot Be Empty !!!"
    return 1
  fi

  if [[ $1 =~ [^a-zA-Z0-9_] ]]; then
    echo "Error: Column Name Can Only Contain Alphabets, Numbers, and Underscores !!!"
    return 1
  fi

  return 0
}

validate_column_type() {
  if [ -z $1 ]; then
    echo "Error: Column Type Cannot Be Empty !!!"
    return 1
  fi

  if [ "$1" != "num" -a "$1" != "str" -a "$1" != "date" ]; then
    echo "Error: Invalid Column Type !!!"
    return 1
  fi

  return 0
}

# ---------------------------- Table Functions ---------------------------- #

create_table_structure() {
  TABLE_NAME=$1
  clear
  echo "=== Creating Table '$TABLE_NAME' Structure ==="
  echo "----------------------------------------------"
  echo ""
  echo "Available Datatypes are [num , str , date]"
  echo ""

  # Array to store columns names and types
  declare -A COLUMNS

  read -p "How many columns ? : " NUM_OF_COLUMNS

  # Check the number of columns
  until check_nonzero_positive_integer $NUM_OF_COLUMNS; do
    echo "Error: Invalid Number of Columns !!!"
    echo ""
    read -p "How many columns ? : " NUM_OF_COLUMNS
  done

  echo ""
    
  # Create each column
  for (( i=1; i<=$NUM_OF_COLUMNS; i++ ))
  do

    # Check the column name
    read -p "Enter Column ($i) Name: " COLUMN_NAME
    until validate_column_name $COLUMN_NAME; do
      echo ""
      read -p "Enter Column ($i) Name: " COLUMN_NAME
    done
    
    # Check the column type
    read -p "Enter Column ($i) Type [num , str , date]: " COLUMN_TYPE
    until validate_column_type $COLUMN_TYPE; do
      echo ""
      read -p "Enter Column ($i) Type [num , str , date]: " COLUMN_TYPE
    done
    echo ""

    COLUMNS[$COLUMN_NAME]=$COLUMN_TYPE
  done

  # Check if the user needs a primary key
  read -p "Do you need a Primary Key ? [y/n]: " NEED_PRIMARY_KEY
  if [ "$NEED_PRIMARY_KEY" == "y" -o "$NEED_PRIMARY_KEY" == "Y" ]; then
    
    read -p "Enter Primary Key: " PRIMARY_KEY
    
    # Check the primary key
    until [[ -n "${COLUMNS[$PRIMARY_KEY]}" ]]; do
      echo "Error: Column '$PRIMARY_KEY' does not exist. Please enter a valid column name."
      read -p "Enter Primary Key: " PRIMARY_KEY
    done
  fi

  # Formatting columns names and types
  keys=$(IFS=":"; echo "${!COLUMNS[*]}")
  values=$(IFS=":"; echo "${COLUMNS[*]}")

  # Create the table file
  echo "$keys" >> ./DBs/$DB_NAME/$TABLE_NAME
  echo "$values" >> ./DBs/$DB_NAME/$TABLE_NAME

  if [ -n "$PRIMARY_KEY" ]; then
    echo "PRIMARY_KEY:$PRIMARY_KEY" >> ./DBs/$DB_NAME/$TABLE_NAME
  else
    echo "PRIMARY_KEY:" >> ./DBs/$DB_NAME/$TABLE_NAME
  fi

  if [ $? -eq 0 ]; then
    return 0
  else
    echo "Error: Table Structure Creation Failed !!!"
    return 1
  fi
}

create_table() {
  echo "=== Creating a table ==="
  echo "------------------------"
  echo ""

  read -p "Enter the Table Name: " TABLE_NAME

  # Check the table name
  until validate_table_name $TABLE_NAME; do
    echo ""
    read -p "Enter the Table Name: " TABLE_NAME
  done

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')

  # Check if the table name already exists 
  check_table_exists $TABLE_NAME
  if [ $? -eq 0 ]; then
    echo "Table '$TABLE_NAME' Already Exists !!!"
    return 1
  fi

  # Create table structure
  create_table_structure $TABLE_NAME

  if [ $? -eq 0 ]; then
    clear
    echo "Table '$TABLE_NAME' Created Successfully !!!"
    return 0
  else
    echo "Error: Table Creation Failed !!!"
    read
    return 1
  fi
}

list_all_tables() {
  echo "=== Listing Tables ==="
  echo "----------------------"
  echo ""

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES} -eq 0 ]; then
    echo "No Tables Available !!!"
  else
    echo "The Available Tables are : "
    echo ""
    for TABLE in "${AVAILABLE_TABLES[@]}"; do
      echo "$TABLE"
    done
  fi
  
  return 0
}

drop_table() {
  echo "=== Dropping a Table ==="
  echo "------------------------"
  echo ""

  read -p "Enter the Table Name: " TABLE_NAME

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  
  # Check if the database name exists
  check_table_exists $TABLE_NAME
  
  if [ $? -eq 0 ]; then
    rm -r "./DBs/$DB_NAME/$TABLE_NAME"
    echo "TABLE '$TABLE_NAME' Dropped !!!"
  else
    echo "TABLE '$TABLE_NAME' Does Not Exist !!!"
  fi
}

# ---------------------------- Start of Table Menu ---------------------------- #

# Table Menu
while true
do 
  clear
  echo "********** Connected to '$DB_NAME' **********"
  echo "---------------------------------------------"
  echo ""
  echo "1) Create Table"
  echo "2) List All Tables"
  echo "3) Drop Table"
  echo "4) Insert Into Table"
  echo "5) Select From Table"
  echo "6) Delete From Table"
  echo "7) Update Table"
  echo ""
  echo "8) Disconnect"
  echo ""
  read -p "$DB_NAME>> " CHOICE
  case $CHOICE in 
    1)
      clear
      create_table
      read -t 3
      ;;
    2)
      clear
      list_all_tables
      read
      ;;
    3)
      clear
      drop_table
      read -t 3
      ;;
    4)
      clear
      read
      ;;
    5)
      clear
      read
      ;;
    6)
      clear
      read
      ;;
    7)
      clear
      read
      ;;
    8)
      clear
      echo "Disconnecting from '$DB_NAME' ..."
      break
      ;;
    *)
      clear
      ;;
  esac
done