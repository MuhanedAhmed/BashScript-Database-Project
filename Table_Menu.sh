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
  declare -A TB_COLUMNS

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

    TB_COLUMNS[$COLUMN_NAME]=$COLUMN_TYPE
  done

  # Check if the user needs a primary key
  read -p "Do you need a Primary Key ? [y/n]: " NEED_PRIMARY_KEY
  if [ "$NEED_PRIMARY_KEY" == "y" -o "$NEED_PRIMARY_KEY" == "Y" ]; then
    
    read -p "Enter Primary Key: " PRIMARY_KEY
    
    # Check the primary key
    until [[ -n "${TB_COLUMNS[$PRIMARY_KEY]}" ]]; do
      echo "Error: Column '$PRIMARY_KEY' does not exist. Please enter a valid column name."
      read -p "Enter Primary Key: " PRIMARY_KEY
    done
  fi

  # Formatting columns names and types
  keys=$(IFS=":"; echo "${!TB_COLUMNS[*]}")
  values=$(IFS=":"; echo "${TB_COLUMNS[*]}")

  # Creating the table metadata file
  echo "$keys" >> $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta
  echo "$values" >> $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta

  if [ -n "$PRIMARY_KEY" ]; then
    echo "PRIMARY_KEY:$PRIMARY_KEY" >> $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta
  else
    echo "PRIMARY_KEY:" >> $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta
  fi

  # Creating the table data file
  touch $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data

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
    rm "$SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta"
    rm "$SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data"
    echo "TABLE '$TABLE_NAME' Dropped !!!"
  else
    echo "TABLE '$TABLE_NAME' Does Not Exist !!!"
  fi
}

insert_data() {
  TB_NAME="$1" 
  META_FILE="$SCRIPT_DIR/DBs/$DB_NAME/$TB_NAME.meta"
  
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
    echo $(IFS=":"; echo "${DATA[*]}") >> "$SCRIPT_DIR/DBs/$DB_NAME/$TB_NAME.data"
    
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
select_from_table()
{
  read -p "Enter the Table Name: " TABLE_NAME
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  check_table_exists $TABLE_NAME
  if [ $? -eq 1 ]; then
    echo "Table '$TABLE_NAME' Does Not Exist !!!"
    return 1
  fi
  TABLE_HEADERS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) print $i }' "$SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta"))
  declare -A COL_INDEX
  for i in "${!TABLE_HEADERS[@]}"; do
    COL_INDEX["${TABLE_HEADERS[$i]}"]=$((i+1))
  done
  declare -a Selected_Columns
  echo "=== Selecting from '$TABLE_NAME' table ==="
  echo "------------------------------------------"
  echo ""
  read -p "Enter the Columns Names to Select or write '*' for all: " -a Selected_Columns
  if [ "${Selected_Columns[0]}" == "*" ]; then
    Selected_Columns=("${TABLE_HEADERS[@]}")
  fi
  for i in "${!Selected_Columns[@]}"; do
    if [[ -z "${COL_INDEX[${Selected_Columns[$i]}]}" ]]; then
      echo "Error: Column '${Selected_Columns[$i]}' does not exist!"
      continue
    fi
  done
  echo "Selected Columns: ${Selected_Columns[@]}"
  awk_print=""
  for col in "${Selected_Columns[@]}"; do
    col_index=${COL_INDEX[$col]}
    if [[ -n "$col_index" ]]; then
        [[ -n "$awk_print" ]] && awk_print+=", "
        awk_print+='$'"$col_index"
    fi
  done

  declare -A Filters
  read -p "Do you want to Filter the Data ? [y/n]: " CHOICE
  if [ "$CHOICE" == "y" -o "$CHOICE" == "Y" ]; then
    while true;
    do
      read -p "Enter the Column Name to Filter: " COLUMN_NAME
      if [[ -z "${COL_INDEX[$COLUMN_NAME]}" ]]; then
        echo "Error: Column '$COLUMN_NAME' does not exist!"
        continue
      fi
      read -p "Enter the Value to Filter: " VALUE
      Filters[$COLUMN_NAME]=$VALUE
      read -p "Do you want to Filter more data ? [y/n]: " CHOICE
      if [ "$CHOICE" != "y" -a "$CHOICE" != "Y" ]; then
        break
      fi
    done
    awk_cond=""
    for key in "${!Filters[@]}"; do
        col_index=${COL_INDEX[$key]}
        if [[ -n "$col_index" ]]; then
          [[ -n "$awk_cond" ]] && awk_cond+=" && "
            awk_cond+='$'"${col_index} == \"${Filters[$key]}\""
        fi
    done
    if [[ -n "$awk_cond" && -n "$awk_print" ]]; then
      awk -F':' 'BEGIN { OFS=":" } { if ('"$awk_cond"') print '"$awk_print"' }' "$SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data"
    fi
    if [ $? -eq 0 ]; then
      echo "Data Selected Successfully !!!"
    else
      echo "No Data Found With The Given Conditions !!!"
    fi
  else
    if [[ -n "$awk_print" ]]; then
      awk -F':' 'BEGIN { OFS=":" } { print '"$awk_print"' }' "$SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data"
    fi
    if [ $? -eq 0 ]; then
      echo "Data Selected Successfully !!!"
    else
      echo "No Data Found With The Given Conditions !!!"
    fi
  fi
}
update_table()
{
  read -p "Enter the Table Name: " TABLE_NAME_
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  check_table_exists $TABLE_NAME
  if [ $? -eq 1 ]; then
    echo "Table '$TABLE_NAME' Does Not Exist !!!"
    return 1
  fi
  TABLE_HEADERS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) print $i }' "$SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.meta"))
  declare -A COL_INDEX
  for i in "${!TABLE_HEADERS[@]}"; do
    COL_INDEX["${TABLE_HEADERS[$i]}"]=$((i+1))
  done  
  while true;
  do
    echo "=== Updating '$TABLE_NAME' table ==="
    echo "------------------------------------------"
    echo ""
    read -p "Enter the Column Name to Update: " COLUMN_NAME
    if [[ -z "${COL_INDEX[$COLUMN_NAME]}" ]]; then
      echo "Error: Column '$COLUMN_NAME' does not exist!"
      continue
    fi
    COL_INDEX_TO_UPDATE="${COL_INDEX[$COLUMN_NAME]}"
    read -p "Enter the Row Index to Update: " INDEX
    if ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then
      echo "Error: Invalid row index!"
      continue
    fi
    read -p "Enter the New Value: " NEW_VALUE
    awk '
      BEGIN { FS = ":"; OFS = ":" }
      {
        if (NR == '$INDEX') {
          $'$COL_INDEX_TO_UPDATE' = "'$NEW_VALUE'"
        }
        print $0
      }
    ' $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data > $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data.tmp && mv $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data.tmp $SCRIPT_DIR/DBs/$DB_NAME/$TABLE_NAME.data
    if [ $? -eq 0 ]; then
      echo "Data Updated Successfully !!!"
    else
      echo "Error: Data Update Failed !!!"
    fi
    echo ""
    read -p "Do you want to Update more data ? [y/n]: " CHOICE
    if [ "$CHOICE" != "y" -a "$CHOICE" != "Y" ]; then
      return 0
    fi
  done
}
# ---------------------------- Start of Table Menu ---------------------------- #

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
        insert_into_table
    ;;
    5)
        select_from_table  
    ;;
    6)
        
    ;;
    7)
        update_table
        
    ;;
    8)
        echo "Thanks For Using Our DBMS"
        exit
    ;;
    esac
done