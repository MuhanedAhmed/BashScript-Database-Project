# ---------------------------- Table Functions ---------------------------- #

create_table_structure() {
  local TABLE_NAME="$1"
  clear
  info "=== Creating Table '$TABLE_NAME' Structure ==="
  info "----------------------------------------------"
  echo ""
  info "Available Datatypes are [num , str , date]"
  echo ""

  # Array to store columns names and types
  local -A TB_COLUMNS
  local -a COLUMNS_ORDER

  read -r -p "How many columns ? : " NUM_OF_COLUMNS

  # Check the number of columns
  until check_nonzero_positive_integer $NUM_OF_COLUMNS; do
    error "Error: Invalid Number of Columns !!!"
    echo ""
    read -r -p "How many columns ? : " NUM_OF_COLUMNS
  done

  echo ""
    
  # Create each column
  for (( i=0; i<$NUM_OF_COLUMNS; i++ ))
  do
    
    # Check the column name
    read -r -p "Enter Column ($((i + 1))) Name: " COLUMN_NAME
    until validate_structure_name "Column" $COLUMN_NAME; do
      echo ""
      read -r -p "Enter Column ($((i + 1))/$((NUM_OF_COLUMNS + 1))) Name: " COLUMN_NAME
    done

    # Check if the column name already exists
    until [[ -z "${TB_COLUMNS[$COLUMN_NAME]}" ]]; do
        error "Error: Column '$COLUMN_NAME' Already Exists !!!"
        echo ""
        read -r -p "Enter Column ($((i + 1))/$((NUM_OF_COLUMNS + 1))) Name: " COLUMN_NAME
    done
    
    # Check the column type
    read -r -p "Enter Column ($COLUMN_NAME) Type [num , str , date]: " COLUMN_TYPE
    until validate_column_type $COLUMN_TYPE; do
      echo ""
      read -r -p "Enter Column ($COLUMN_NAME) Type [num , str , date]: " COLUMN_TYPE
    done
    echo ""

    COLUMNS_ORDER+=($COLUMN_NAME)
    TB_COLUMNS[$COLUMN_NAME]=$COLUMN_TYPE
  done

  # Check if the user needs a primary key
  read -r -p "Do you need a Primary Key ? [y/n]: " NEED_PRIMARY_KEY
  if [ "$NEED_PRIMARY_KEY" == "y" -o "$NEED_PRIMARY_KEY" == "Y" ]; then
    
    read -r -p "Enter Primary Key: " PRIMARY_KEY
    
    # Check the primary key
    until [[ -n "${TB_COLUMNS[$PRIMARY_KEY]}" ]]; do
      error "Error: Column '$PRIMARY_KEY' does not exist. Please enter a valid column name."
      echo ""
      read -r -p "Enter Primary Key: " PRIMARY_KEY
    done
  fi

  # Formatting columns names and types
  local keys=$(IFS=":"; echo "${COLUMNS_ORDER[*]}")
  local values=""
  for key in "${COLUMNS_ORDER[@]}"; do
    if [[ -z "$values" ]]; then
        values="${TB_COLUMNS[$key]}"
    else
        values+=":${TB_COLUMNS[$key]}"
    fi
  done

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
    error "Error: Table Structure Creation Failed !!!"
    return 1
  fi
}

create_table() {
  info "=== Creating a table ==="
  info "------------------------"
  echo ""

  read -r -p "Enter the Table Name: " TABLE_NAME

  # Check the table name
  until validate_structure_name "Table" $TABLE_NAME; do
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')

  # Check if the table name already exists
  until ! check_table_exists $TABLE_NAME; do
    error "Error: Table '$TABLE_NAME' Already Exists !!!"
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done

  # Create table structure
  create_table_structure $TABLE_NAME

  if [ $? -eq 0 ]; then
    clear
    success "Table '$TABLE_NAME' Created Successfully !!!"
    return 0
  else
    error "Error: Table Creation Failed !!!"
    read -r
    return 1
  fi
}

list_all_tables() {
  info "=== Listing Tables ==="
  info "----------------------"
  echo ""

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES} -eq 0 ]; then
    success "No Tables Available !!!"
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
  info "=== Dropping a Table ==="
  info "------------------------"
  echo ""

  if [ -z "$(get_tables)" ]; then
    success "No Tables Available To Drop !!!"
    return 0
  fi

  read -r -p "Enter the Table Name: " TABLE_NAME
  
  # Replace white spaces with _
  TABLE_NAME=$(echo "$TABLE_NAME" | tr ' ' '_')

  # Check if the table name exists
  until check_table_exists "$TABLE_NAME"; do
    error "Error: Table '$TABLE_NAME' Does Not Exist !!!"
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done

  echo ""
  read -r -p "Are you sure you want to drop '$TABLE_NAME' table ??? [y/n] : " CHOICE
  if [ "$CHOICE" != 'y' -a "$CHOICE" != 'Y' ]; then
    echo ""
    echo "OK, Good choice :) ..."
    return 0
  fi
  
  echo ""
  read -r -p "THIS IS THE LAST CHANCE !!! Are you sure you want to drop '$TABLE_NAME' table ??? [y/n] : " CHOICE
  if [ "$CHOICE" != 'y' -a "$CHOICE" != 'Y' ]; then
    echo ""
    echo "OK, I thought so :) ..."
    return 0
  else
    rm "./DBs/$DB_NAME/$TABLE_NAME.meta"
    rm "./DBs/$DB_NAME/$TABLE_NAME.data"
    success "TABLE '$TABLE_NAME' Dropped !!!"
  fi
}

insert_data() {
  local TB_NAME="$1" 
  META_FILE="./DBs/$DB_NAME/$TB_NAME.meta"
  
  # Check if the meta file exists
  if [ ! -f "$META_FILE" ]; then
    error "Error: Unable to find '$TB_NAME'.meta file !!!"
    return 1
  fi

  # Extracts the metadata from the file
  TABLE_COLUMNS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  COLUMNS_TYPES=($(awk -F':' 'NR==2 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  PRIMARY_KEY=$(awk -F':' 'NR==3 { sub(/^PRIMARY_KEY:/, ""); print }' "$META_FILE")

  # Check if number of columns and types match
  [[ ${#TABLE_COLUMNS[@]} -eq ${#COLUMNS_TYPES[@]} ]] || {
    error "Error: Number of columns and types do not match !!!"
    return 1
  }

  # Start inserting data dialog
  while true
  do
    clear
    info "=== Inserting into '$TB_NAME' table ==="
    info "------------------------------------------"
    echo ""
    
    # Ask user for data
    local -a DATA=()
    
    for ((i=0; i<${#TABLE_COLUMNS[@]}; i++)); do
      read -r -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
      # Check the data type
      if [ "${COLUMNS_TYPES[i]}" == "str" ]; then
        until validate_string_input "$VALUE"; do
          echo ""
          read -r -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      elif [ "${COLUMNS_TYPES[i]}" == "num" ]; then
        until validate_number_input "$VALUE"; do
          echo ""
          read -r -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      elif [ "${COLUMNS_TYPES[i]}" == "date" ]; then
        until validate_date_input "$VALUE"; do
          echo ""
          read -r -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      fi

      # Check if the primary key is unique
      if [ -n "$PRIMARY_KEY" ] && [ "${TABLE_COLUMNS[i]}" == "$PRIMARY_KEY" ]; then
        until check_primary_key $TB_NAME $((i + 1)) $VALUE; do
          echo ""
          read -r -p "Enter ${TABLE_COLUMNS[i]} : " VALUE
        done
      fi

      DATA+=("$VALUE")
      echo ""
    done

    # Add data to the table
    echo $(IFS=":"; echo "${DATA[*]}") >> "./DBs/$DB_NAME/$TB_NAME.data"
    
    clear
    if [ $? -eq 0 ]; then
      success "Data Inserted Successfully !!!"
    else
      error "Error: Data Insertion Failed !!!"
    fi

    echo ""
    read -r -p "Do you want to insert more data ? [y/n]: " CHOICE
    if [ "$CHOICE" != "y" -a "$CHOICE" != "Y" ]; then
      return 0
    fi
  done
}

insert_into_table() {
  info "=== Inserting into a table ==="
  info "------------------------------"
  echo ""

  local TABLE_NAME=""
  read -r -p "Enter the Table Name: " TABLE_NAME

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  
  # Check if the table name exists
  until check_table_exists $TABLE_NAME; do
    error "Error: Table '$TABLE_NAME' Does Not Exist !!!"
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done
  
  insert_data $TABLE_NAME

  if [ $? -eq 0 ]; then
    clear
    return 0
  else
    error "Error: Data Insertion Failed !!!"
    read -r
    return 1
  fi
}

select_from_table() {
  info "=== Selecting from a table ==="
  info "------------------------------"
  echo ""
  read -r -p "Enter the Table Name: " TABLE_NAME

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')

  # Check if the table name exists
  until check_table_exists $TABLE_NAME; do
    error "Error: Table '$TABLE_NAME' Does Not Exist !!!"
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done

  # Fetching table's columns names
  TABLE_HEADERS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) print $i }' "./DBs/$DB_NAME/$TABLE_NAME.meta"))
 
  declare -a Selected_Columns
  clear
  info "=== Selecting from '$TABLE_NAME' table ==="
  info "------------------------------------------"
  echo ""
  read -r -p "Enter the Columns Names to Select or write '*' for all: " -a Selected_Columns
  
  if [ "${Selected_Columns[0]}" == "*" ]; then
    Selected_Columns=("${TABLE_HEADERS[@]}")
  fi
  # Check if the selected columns exist
  for i in "${!Selected_Columns[@]}"; do
      col="${Selected_Columns[i]}"
      until check_column_exists "${TABLE_HEADERS[@]}" "$col"; do
          error "Error: Column '$col' does not exist !!!"
          read -r -p "Enter the Correct Column Name to Select: " col
      done
      Selected_Columns[i]="$col"
  done

  clear 

  echo "Selected Columns: ${Selected_Columns[@]}"
  echo ""

  awk_print=""
  for col in "${Selected_Columns[@]}"; do
    col_index=-1
    for i in "${!TABLE_HEADERS[@]}"; do
        if [[ "${TABLE_HEADERS[i]}" == "$col" ]]; then
          col_index=$((i + 1))
          break
        fi
    done
    if [[ $col_index -ne -1 ]]; then
        [[ -n "$awk_print" ]] && awk_print+=", "
        awk_print+='$'"$col_index"
    fi
  done

  declare -A Filters
  read -r -p "Do you want to Filter the Data ? [y/n]: " CHOICE
  echo ""
  if [ "$CHOICE" == "y" -o "$CHOICE" == "Y" ]; then
    while true;
    do
      read -r -p "Enter the Column Name to Filter: " COLUMN_NAME
      echo ""
      until check_column_exists "${TABLE_HEADERS[@]}" "$COLUMN_NAME"; do
          echo ""
          error "Error: Column '$COLUMN_NAME' does not exist !!!"
          echo ""
          read -r -p "Enter the Correct Column Name to Select: " COLUMN_NAME
      done
      read -r -p "Enter the Value to Filter: " VALUE
      Filters[$COLUMN_NAME]=$VALUE
      echo ""
      read -r -p "Do you want to Filter more data ? [y/n]: " CHOICE
      echo ""
      if [ "$CHOICE" != "y" -a "$CHOICE" != "Y" ]; then
        break
      fi
    done
    #print key-pair
    awk_cond=""
    for key in "${!Filters[@]}"; do
        col_index=-1
        for i in "${!TABLE_HEADERS[@]}"; do
          if [[ "${TABLE_HEADERS[i]}" == "$key" ]]; then
              col_index=$((i + 1))
              break
          fi
        done
        if [[ -n "$col_index" ]]; then
          [[ -n "$awk_cond" ]] && awk_cond+=" && "
            awk_cond+='$'"${col_index} == \"${Filters[$key]}\""
        fi
    done
    # Check if the condition is empty
    if [[ -n "$awk_cond" && -n "$awk_print" ]]; then
      result=$(awk -F':' 'BEGIN { OFS="\t" } { if ('"$awk_cond"') print '"$awk_print"' }' "./DBs/$DB_NAME/$TABLE_NAME.data")
    fi
  else
    # Check if the condition is empty
    if [[ -n "$awk_print" ]]; then
      result=$(awk -F':' 'BEGIN { OFS="\t" } { print '"$awk_print"' }' "./DBs/$DB_NAME/$TABLE_NAME.data")
    fi
  fi
  num_rows=$(echo "$result" | grep . | wc -l)
  if [ $num_rows -eq 0 ]; then
    clear
    success "No Data Found, try again !!!"
  else
    echo -e "$(IFS=$'\t'; echo "${Selected_Columns[*]}")" | column -t
    echo "----------------------------------"
    echo "$result" | column -t  
    echo ""
    success "$num_rows Row Returned !!!" 
  fi
}

update_table() {
  info "=== Updating '$TABLE_NAME' table ==="
  info "------------------------------------------"
  echo ""
  read -r -p "Enter the Table Name: " TABLE_NAME
  
  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  
  # Check if the table name exists
  until check_table_exists $TABLE_NAME; do
    error "Error: Table '$TABLE_NAME' Does Not Exist !!!"
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done
  
  # Fetching table's columns names
  TABLE_HEADERS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) print $i }' "./DBs/$DB_NAME/$TABLE_NAME.meta"))

  while true;
  do
    clear
    info "=== Updating '$TABLE_NAME' table ==="
    info "------------------------------------------"
    echo ""
    read -r -p "Enter the Column Name to Filter: " COLUMN_NAME
    echo ""
    until check_column_exists "${TABLE_HEADERS[@]}" "$COLUMN_NAME"; do
        echo ""
        error "Error: Column '$COLUMN_NAME' does not exist!"
        echo ""
        read -r -p "Enter the Correct Column Name to Select: " COLUMN_NAME
    done
    
    # Find the column index
    for ((i=0; i<${#TABLE_HEADERS[@]}; i++)); do
      if [ "${TABLE_HEADERS[i]}" == "$COLUMN_NAME" ]; then
        COL_INDEX_TO_UPDATE=$((i + 1))
        break
      fi
    done
    
    # Get the data from the column
    mapfile -t Selected_COL_DATA < <(awk -F':' '{print $'"$COL_INDEX_TO_UPDATE"'}' ./DBs/$DB_NAME/$TABLE_NAME.data)
    
    echo "Available Data in '$COLUMN_NAME' Column:"
    echo "========================================="
    
    for ((i=0; i<${#Selected_COL_DATA[@]}; i++)); do
      echo "$((i + 1))) ${Selected_COL_DATA[i]}"
    done
    
    echo ""

    read -r -p "Enter a value to update: " OLD_VALUE
    
    #get index of OLD Value
    INDEX=$(awk -F':' -v value="$OLD_VALUE" -v col="$COL_INDEX_TO_UPDATE" '{
      if ($col == value) {
        print NR
        exit
      }
    }' ./DBs/$DB_NAME/$TABLE_NAME.data)

    until [ -n "$INDEX" ]; do
      
      error "Value is not selected"
      
      read -r -p "Enter a value to update: " OLD_VALUE
      #get index of OLD Value
      INDEX=$(awk -F':' -v value="$OLD_VALUE" -v col="$COL_INDEX_TO_UPDATE" '{
        if ($col == value) {
          print NR
          exit
        }
      }' ./DBs/$DB_NAME/$TABLE_NAME.data)
    done

    read -r -p "Enter the New Value: " NEW_VALUE
    
    until [[ -n "$NEW_VALUE" ]]; do
      error "Error: Value cannot be empty !!!"
      echo ""
      read -r -p "Enter the New Value: " NEW_VALUE
    done
    
    result=$(awk '
      BEGIN { FS = ":"; OFS = ":" }
      {
        if (NR == '$INDEX') {
          $'$COL_INDEX_TO_UPDATE' = "'$NEW_VALUE'"
        }
        print $0
      }
    ' ./DBs/$DB_NAME/$TABLE_NAME.data >> ./DBs/$DB_NAME/$TABLE_NAME.data.tmp && mv ./DBs/$DB_NAME/$TABLE_NAME.data.tmp ./DBs/$DB_NAME/$TABLE_NAME.data)
    clear
    if [ $? -ne 0 ]; then    
      clear  
      success "No Data Found, try again !!!"
    else
      clear
      success "Data Updated Successfully !!!"
    fi
    echo ""
    read -r -p "Do you want to Update more data ? [y/n]: " CHOICE
    if [ "$CHOICE" != "y" -a "$CHOICE" != "Y" ]; then
      return 0
    fi
  done
}

delete_rows() {
  TB_NAME="$1"
  ALL_ROWS="$2"

  # Check if the user wants to delete all rows
  if [ -n "$ALL_ROWS" ]; then
    echo ""
    read -r -p "Are you sure you want to delete ALL rows ??? [y/n] : " CHOICE
    if [ "$CHOICE" != 'y' -a "$CHOICE" != 'Y' ]; then
      echo "OK, Good choice :) ..."
      read -r -t 3
      return 0
    fi
    
    echo ""
    read -r -p "THIS IS THE LAST CHANCE !!! Are you sure you want to delete ALL ROWS ??? [y/n] : " CHOICE
    if [ "$CHOICE" != 'y' -a "$CHOICE" != 'Y' ]; then
      echo "OK, I thought so :) ..."
      read -r -t 3
      return 0
    else
      echo "" > "./DBs/$DB_NAME/$TB_NAME.data"
      clear
      success "All rows were deleted successfully !!!"
      return 0
    fi
  fi

  META_FILE="./DBs/$DB_NAME/$TB_NAME.meta"
  DATA_FILE="./DBs/$DB_NAME/$TB_NAME.data"

  # Prompt the user for a specific deletion criteria
  clear
  info "=== Deleting Specific Rows From '$TB_NAME' Table ==="
  info "----------------------------------------------------"
  echo ""

  # Extract column names from the metadata file
  TABLE_COLUMNS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))

  echo "Available Columns:"
  echo "=================="
  for ((i=0; i<${#TABLE_COLUMNS[@]}; i++)); do
    echo "$((i + 1))) ${TABLE_COLUMNS[i]}"
  done

  echo ""

  # Validate the column name
  read -r -p "Enter the column name to filter rows for deletion: " COLUMN_NAME
  until check_column_exists "${TABLE_COLUMNS[@]}" "$COLUMN_NAME"; do
    error "Error: Invalid column name !!!"
    echo ""
    read -r -p "Enter the column name to filter rows for deletion: " COLUMN_NAME
  done
  
  # Find the column index
  for ((i=0; i<${#TABLE_COLUMNS[@]}; i++)); do
    if [ "${TABLE_COLUMNS[i]}" == "$COLUMN_NAME" ]; then
      # Index in awk starts with 1
      COL_INDEX=$((i + 1))
      break
    fi
  done

  # Delete rows matching the criteria
  echo ""
  read -r -p "Enter the value to match for deletion: " VALUE

  # Check if the value is empty
  until [[ -n "$VALUE" ]]; do
    error "Error: Value cannot be empty !!!"
    echo ""
    read -r -p "Enter the value to match for deletion: " VALUE
  done

  echo ""
  read -r -p "Should the match be exact? [y/n]: " EXACT_MATCH
  
  ORIGINAL_LINES_COUNT=$(wc -l < "$DATA_FILE")
  
  if [[ "$EXACT_MATCH" =~ ^[yY] ]]; then
    # Exact match: only delete if the entire field matches VALUE
    awk -F':' -v col="$COL_INDEX" -v val="$VALUE" '$col == val {next} {print}' "$DATA_FILE" > "${DATA_FILE}.tmp"
  else
    # Partial match: delete if VALUE is anywhere in the column
    awk -F':' -v col="$COL_INDEX" -v val="$VALUE" 'index($col, val) == 0 {print}' "$DATA_FILE" > "${DATA_FILE}.tmp"
  fi

  # Overwrite the original file with the filtered result
  mv "${DATA_FILE}.tmp" "$DATA_FILE"

  NEW_LINES_COUNT=$(wc -l < "$DATA_FILE")

  clear
  success "$((ORIGINAL_LINES_COUNT - NEW_LINES_COUNT)) rows were deleted successfully !!!"
}

delete_from_table() {
  info "=== Delete from a table ==="
  info "---------------------------"
  echo ""

  read -r -p "Enter the Table Name: " TABLE_NAME

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')
  
  # Check if the table name exists
  until check_table_exists $TABLE_NAME; do
    error "Error: Table '$TABLE_NAME' Does Not Exist !!!"
    echo ""
    read -r -p "Enter the Table Name: " TABLE_NAME
  done

  while true; do
    clear
    echo "=== Deleting from '$TABLE_NAME' table ==="
    echo "-----------------------------------------"
    echo ""
    echo "1) Delete Specific Rows"
    echo "2) Delete All Rows"
    echo ""

    read -r -p "$TABLE_NAME>> " CHOICE
    case $CHOICE in 
      1)
        delete_rows $TABLE_NAME
        return 0
        ;;
      2)
        delete_rows $TABLE_NAME "all"
        return 0
        ;;
      *)
        ;;
    esac
  done
}

# ---------------------------- Table Menu Function ---------------------------- #

start_table_menu() {

  # Check if the database name is set
  if [ -z "$DB_NAME" ]; then
    error "Error: Database name is not set !!!"
    return 1
  fi
  
  while true
  do 
    clear
    info "********** Connected to '$DB_NAME' **********"
    info "---------------------------------------------"
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
    read -r -p "$DB_NAME>> " CHOICE
    case $CHOICE in 
      1)
        clear
        create_table
        read -r -t 3
        ;;
      2)
        clear
        list_all_tables
        read -r
        ;;
      3)
        clear
        drop_table
        read -r -t 3
        ;;
      4)
        clear
        insert_into_table
        success "Data Insertion Finished !!!"
        read -r -t 3
        ;;
      5)
        clear
        select_from_table
        read -r
        ;;
      6)
        clear
        delete_from_table
        read -r
        ;;
      7)
        clear
        update_table
        read -r
        ;;
      8)
        clear
        success "Disconnecting from '$DB_NAME' ..."
        return 0
        ;;
      *)
        clear
        ;;
    esac
  done
}