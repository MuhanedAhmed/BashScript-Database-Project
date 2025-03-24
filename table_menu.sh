#!/bin/bash

DB_NAME=$1

# ---------------------------- Table Functions ---------------------------- #

create_table_structure() {
  local TABLE_NAME="$1"
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
    until validate_structure_name "Column" $COLUMN_NAME; do
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

  # Creating the table metadata file
  echo "$keys" >> ./DBs/$DB_NAME/$TABLE_NAME.meta
  echo "$values" >> ./DBs/$DB_NAME/$TABLE_NAME.meta

  if [ -n "$PRIMARY_KEY" ]; then
    echo "PRIMARY_KEY:$PRIMARY_KEY" >> ./DBs/$DB_NAME/$TABLE_NAME.meta
  else
    echo "PRIMARY_KEY:" >> ./DBs/$DB_NAME/$TABLE_NAME.meta
  fi

  # Creating the table data file
  touch ./DBs/$DB_NAME/$TABLE_NAME.data

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
  until validate_structure_name "Table" $TABLE_NAME; do
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
  
  # Check if the table name exists
  check_table_exists $TABLE_NAME
  
  if [ $? -eq 0 ]; then
    rm "./DBs/$DB_NAME/$TABLE_NAME.meta"
    rm "./DBs/$DB_NAME/$TABLE_NAME.data"
    echo "TABLE '$TABLE_NAME' Dropped !!!"
  else
    echo "TABLE '$TABLE_NAME' Does Not Exist !!!"
  fi
}

insert_data() {
  TB_NAME="$1" 
  META_FILE="./DBs/$DB_NAME/$TB_NAME.meta"
  
  # Check if the meta file exists
  if [ ! -f "$META_FILE" ]; then
    echo "Error: Unable to find '$TB_NAME'.meta file !!!"
    return 1
  fi

  # Extracts the metadata from the file
  TABLE_COLUMNS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  COLUMNS_TYPES=($(awk -F':' 'NR==2 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  PRIMARY_KEY=$(awk -F':' 'NR==3 { sub(/^PRIMARY_KEY:/, ""); print }' "$META_FILE")

  # Check if number of columns and types match
  [[ ${#TABLE_COLUMNS[@]} -eq ${#COLUMNS_TYPES[@]} ]] || {
    echo "Error: Number of columns and types do not match !!!"
    return 1
  }

  # Start inserting data dialog
  while true
  do
    clear
    echo "=== Inserting into '$TB_NAME' table ==="
    echo "------------------------------------------"
    echo ""
    
    # Ask user for data
    declare -A DATA
    
    for ((i=0; i<${#TABLE_COLUMNS[@]}; i++)); do
      read -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
      # Check the data type
      if [ "${COLUMNS_TYPES[i]}" == "num" ]; then
        until validate_number_input $VALUE; do
          echo ""
          read -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      elif [ "${COLUMNS_TYPES[i]}" == "date" ]; then
        until validate_date_input $VALUE; do
          echo ""
          read -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      fi

      # Check if the primary key is unique
      if [ -n "$PRIMARY_KEY" ] && [ "${TABLE_COLUMNS[i]}" == "$PRIMARY_KEY" ]; then
        until check_primary_key $TB_NAME $((i + 1)) $VALUE; do
          echo ""
          read -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      fi

      DATA[${TABLE_COLUMNS[i]}]=$VALUE
      echo ""
    done

    # Add data to the table
    echo $(IFS=":"; echo "${DATA[*]}") >> "./DBs/$DB_NAME/$TB_NAME.data"
    
    clear
    if [ $? -eq 0 ]; then
      echo "Data Inserted Successfully !!!"
    else
      echo "Error: Data Insertion Failed !!!"
    fi

    echo ""
    read -p "Do you want to insert more data ? [y/n]: " CHOICE
    if [ "$CHOICE" != "y" -a "$CHOICE" != "Y" ]; then
      return 0
    fi
  done
}

insert_into_table() {
  echo "=== Inserting into a table ==="
  echo "------------------------------"
  echo ""

  read -p "Enter the Table Name: " TABLE_NAME

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  
  # Check if the table name exists
  until check_table_exists $TABLE_NAME; do
    echo "Error: Table '$TABLE_NAME' Does Not Exist !!!"
    echo ""
    read -p "Enter the Table Name: " TABLE_NAME
  done
  
  insert_data $TABLE_NAME

  if [ $? -eq 0 ]; then
    clear
    return 0
  else
    echo "Error: Data Insertion Failed !!!"
    read
    return 1
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
      insert_into_table
      echo ""
      echo "Finished inserting into the table ..."
      read -t 3
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