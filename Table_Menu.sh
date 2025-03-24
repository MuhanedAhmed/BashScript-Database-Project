DB_NAME="$1"
PS3="$DB_NAME>> "

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
  
  # Check if the database name exists
  check_table_exists $TABLE_NAME
  
  if [ $? -eq 0 ]; then
    rm "./DBs/$DB_NAME/$TABLE_NAME.meta"
    rm "./DBs/$DB_NAME/$TABLE_NAME.data"
    echo "TABLE '$TABLE_NAME' Dropped !!!"
  else
    echo "TABLE '$TABLE_NAME' Does Not Exist !!!"
  fi
}


select input in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Exit"
do
    case $REPLY in
    1)
        create_table  
    ;;
    2)
        list_all_tables 
    ;;
    3)
        drop_table
    ;;
    4)
        
    ;;
    5)
        
    ;;
    6)
        
    ;;
    7)
        
    ;;
    8)
        echo "Thanks For Using Our DBMS"
        exit
    ;;
    esac
done