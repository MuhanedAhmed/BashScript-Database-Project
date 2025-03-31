# ---------------------------- Table Functions ---------------------------- #

create_table_structure() {

  local -i NUM_OF_COLUMNS=0
  local -A COLUMNS
  local -a COLUMNS_ORDER
  local PRIMARY_KEY=""

  while true; do
    # Show Zenity form for column input
    COLUMN_DATA=$(zenity --forms --title="Create Table '$TABLE_NAME' Structure" --text="Enter Column $((NUM_OF_COLUMNS + 1)) Info:" \
      --add-entry="Column Name" \
      --add-combo="Column Type" --combo-values="num|str|date" \
      --width=400 --height=300 \
      --ok-label="Add Column" --cancel-label="Cancel" \
      --separator=":")
    
    if [ $? -eq 1 ]; then
      zenity --question --title="Cancel" --text="Do you want to cancel the table creation ?" --width=300
      if [ $? -eq 0 ]; then
        return 1
      fi
    fi

    COLUMN_NAME=$(echo "$COLUMN_DATA" | cut -d ':' -f 1)
    COLUMN_TYPE=$(echo "$COLUMN_DATA" | cut -d ':' -f 2)

    # Check column name
    if ! $(validate_structure_name "Column" "$COLUMN_NAME"); then
      continue
    fi

    # Check column type
    if [[ "$COLUMN_TYPE" == " " ]]; then
      zenity --error --text "Column type are required"
      continue
    fi

    # Check if column already exists
    if [[ -n "${COLUMNS[$COLUMN_NAME]}" ]]; then
        zenity --error --text "Column '$COLUMN_NAME' already exists!"
        continue
    fi

    # Store column
    COLUMNS["$COLUMN_NAME"]="$COLUMN_TYPE"
    COLUMNS_ORDER+=("$COLUMN_NAME")
    NUM_OF_COLUMNS=$((NUM_OF_COLUMNS + 1))

    # Ask if user wants to add more columns
    zenity --question --title="Column Added" --text "Column '$COLUMN_NAME' of type '$COLUMN_TYPE' added successfully !!!\n\nDo you want to add more columns ?"
    if [ $? -eq 1 ]; then
      break
    fi
  done

  zenity --question --title="Primary Key" --text "Do you need a Primary Key ?"
  if [ $? -eq 0 ]; then
    PRIMARY_KEY=$(zenity --list --title="Primary Key" --text="Choose the Primary Key:" \
      --column="Columns" "${COLUMNS_ORDER[@]}" --width=400 --ok-label="Select" --cancel-label="No Primary Key")
    
    if [ $? -eq 0 ] ;then
      until [ -n "$PRIMARY_KEY" ]; do
        zenity --error --text "Primary Key is not selected"
        PRIMARY_KEY=$(zenity --list --title="Primary Key" --text="Choose the Primary Key:" \
          --column="Columns" "${COLUMNS_ORDER[@]}" --width=400 --ok-label="Select" --cancel-label="No Primary Key")
      done
    fi    
  fi

  # Formatting columns names and types
  local keys=$(IFS=":"; echo "${COLUMNS_ORDER[*]}")
  local values=""
  for key in "${COLUMNS_ORDER[@]}"; do
    if [[ -z "$values" ]]; then
        values="${COLUMNS[$key]}"
    else
        values+=":${COLUMNS[$key]}"
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
    return 1
  fi
}

create_table() {

  local TABLE_NAME=""

  TABLE_NAME=$(zenity --entry --title="Create Table" --text="Enter the Table Name:" --width=400 --ok-label="Next")
  if [ $? -ne 0 ]; then return 1; fi

  # Check the table name
  until validate_structure_name "Table" $TABLE_NAME; do
    TABLE_NAME=$(zenity --entry --title="Create Table" --text="Enter the Table Name:" --width=400 --ok-label="Next")
    if [ $? -ne 0 ]; then return 1; fi
  done

  # Replace white spaces with _
  TABLE_NAME=$(echo $TABLE_NAME | tr ' ' '_')

  # Check if the table name already exists
  until ! check_table_exists $TABLE_NAME; do
    zenity --error --title="Error" --text="Table '$TABLE_NAME' Already Exists" --width=300
    TABLE_NAME=$(zenity --entry --title="Create Table" --text="Enter the Table Name:" --width=400 --ok-label="Next")
    if [ $? -ne 0 ]; then return 1; fi
  done

  # Create table structure
  create_table_structure $TABLE_NAME

  if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="Table '$TABLE_NAME' Created Successfully !!!" --width=300
    return 0
  else
    zenity --error --title="Error" --text="Table Creation Failed" --width=300
    return 1
  fi
}

list_all_tables() {

  local -a AVAILABLE_TABLES=()

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES[@]} -eq 0 ]; then
    zenity --info --title="No Tables" --text="No Tables Available To List !!!" --width=300
    return 0
  fi

  zenity --list --title="Available Tables" --text="The available tables are:" \
    --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300 --ok-label="Ok" --cancel-label="Back"

  return 0
}

drop_table() {

  local TABLE_NAME=""
  local -a AVAILABLE_TABLES=()

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES[@]} -eq 0 ]; then
    zenity --info --title="No Tables" --text="No Tables Available To Drop !!!" --width=300
    return 0
  fi
  
  TABLE_NAME=$(zenity --list --title="Drop Table" --text="Select table to drop:" \
    --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
  
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  until [ -n "$TABLE_NAME" ]; do
    zenity --error --text "Table name is not selected"
    TABLE_NAME=$(zenity --list --title="Drop Table" --text="Select table to drop:" \
      --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done
  
  # Confirm deletion
  zenity --question --title="Confirm" --text="Are you sure you want to drop '$TABLE_NAME' table ???" 
  if [ $? -ne 0 ]; then
    zenity --info --title="Cancelled" --text="OK, Good choice :) ..." --width=300
    return 0
  fi
  
  # Final confirmation
  zenity --question --title="Final Confirmation" \
    --text="THIS IS THE LAST CHANCE !!! Are you sure you want to drop '$TABLE_NAME' table ???" \
    --width=400 --ok-label="Yes, Drop It" --cancel-label="No, Keep It"
  if [ $? -ne 0 ]; then
    zenity --info --title="Cancelled" --text="OK, I thought so :) ..." --width=300
    return 0
  fi
  
  rm "./DBs/$DB_NAME/$TABLE_NAME.meta"
  rm "./DBs/$DB_NAME/$TABLE_NAME.data"
  if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="Table '$TABLE_NAME' Dropped Successfully !!!" --width=300
  else
    zenity --error --title="Error" --text="Table Dropping Failed" --width=300
  fi
}

insert_data() {
  local TB_NAME="$1" 
  META_FILE="./DBs/$DB_NAME/$TB_NAME.meta"
  
  # Check if the meta file exists
  if [ ! -f "$META_FILE" ]; then
  zenity --error --title="Error" --text="Unable to find '$TB_NAME'.meta file !!!" --width=300
    return 1
  fi

  # Extracts the metadata from the file
  TABLE_COLUMNS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  COLUMNS_TYPES=($(awk -F':' 'NR==2 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  PRIMARY_KEY=$(awk -F':' 'NR==3 { sub(/^PRIMARY_KEY:/, ""); print }' "$META_FILE")

  # Check if number of columns and types match
  [[ ${#TABLE_COLUMNS[@]} -eq ${#COLUMNS_TYPES[@]} ]] || {
    zenity --error --title="Error" --text="Number of columns and types do not match !!!" --width=300
    return 1
  }

  while true; do

    # Show Zenity form
    USER_INPUT=$(zenity --forms --title="Insert Into '$TB_NAME'" \
      --text="Enter values for each column:" --separator="|" \
      $(for ((i=0; i<${#TABLE_COLUMNS[@]}; i++)); do echo "--add-entry='${TABLE_COLUMNS[i]}'"; done) \
      --width=400 --height=300)
    
    if [ $? -ne 0 ]; then return 0; fi # User cancelled

    IFS='|' read -r -a USER_INPUT_ARRAY <<< "$USER_INPUT"
    
    # Validate data types
    for ((i=0; i<${#TABLE_COLUMNS[@]}; i++)); do
      VALUE="${USER_INPUT_ARRAY[i]}"
      if [ "${COLUMNS_TYPES[i]}" == "str" ]; then
        if ! validate_string_input "$VALUE"; then
          continue 2
        fi
      elif [ "${COLUMNS_TYPES[i]}" == "num" ]; then
        if ! validate_number_input "$VALUE"; then
          continue 2
        fi
      elif [ "${COLUMNS_TYPES[i]}" == "date" ]; then
        if ! validate_date_input "$VALUE"; then
          continue 2
        fi
      fi
      
      # Validate primary key uniqueness
      if [ -n "$PRIMARY_KEY" ] && [ "${TABLE_COLUMNS[i]}" == "$PRIMARY_KEY" ]; then
        if ! check_primary_key "$TB_NAME" $((i + 1)) "$VALUE"; then
          continue 2
        fi
      fi
    done

    # Insert data into the table
    echo "${USER_INPUT}" >> "./DBs/$DB_NAME/$TB_NAME.data"
    zenity --info --title="Success" --text="Data Inserted Successfully !!!" --width=300

    # Ask if the user wants to insert more data
    zenity --question --title="Insert More?" --text="Do you want to insert more data?" --width=300
    if [ $? -ne 0 ]; then return 0; fi
  done
}

insert_into_table() {

  local TABLE_NAME=""
  local -a AVAILABLE_TABLES=()

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES[@]} -eq 0 ]; then
    zenity --info --title="No Tables" --text="No Tables Available To Insert !!!" --width=300
    return 0
  fi
  
  TABLE_NAME=$(zenity --list --title="Insert Into Table" --text="Select table to insert:" \
    --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
  
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  until [ -n "$TABLE_NAME" ]; do
    zenity --error --text "Table name is not selected"
    TABLE_NAME=$(zenity --list --title="Insert Into Table" --text="Select table to insert:" \
      --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done

  
  insert_data $TABLE_NAME

  if [ $? -eq 0 ]; then
    zenity --info --title="Success" --text="Data Inserted Successfully !!!" --width=300
    return 0
  else
    zenity --error --title="Error" --text="Data Insertion Failed" --width=300
    return 1
  fi
}

select_from_table() {

  local TABLE_NAME=""
  local -a AVAILABLE_TABLES=()

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES[@]} -eq 0 ]; then
    zenity --info --title="No Tables" --text="No Tables Available To Select From !!!" --width=300
    return 0
  fi
  
  TABLE_NAME=$(zenity --list --title="Insert Into Table" --text="Select a table to select from:" \
    --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
  
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  until [ -n "$TABLE_NAME" ]; do
    zenity --error --text "Table name is not selected"
    TABLE_NAME=$(zenity --list --title="Insert Into Table" --text="Select a table to select from:" \
      --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done

  # Fetching table's columns names
  TABLE_HEADERS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) print $i }' "./DBs/$DB_NAME/$TABLE_NAME.meta"))

  # Column Selection
  SELECTED_COLUMNS=$(zenity --list --title "Select Columns" --text "Choose columns to select:" \
    --checklist --column "Select" --column "Column Name" \
    $(for col in "${TABLE_HEADERS[@]}"; do echo "FALSE" "$col"; done) \
    --separator="|" --width=400 --height=300 --extra-button='Select All' \
    --ok-label="Select" --cancel-label="Cancel")

  echo "SELECTED_COLUMNS : $SELECTED_COLUMNS"

  if [ "$SELECTED_COLUMNS" == "Select All" ]; then
    SELECTED_COLUMNS=$(IFS="|"; echo "${TABLE_HEADERS[@]}")
  fi
  echo "SELECTED_COLUMNS : $SELECTED_COLUMNS"

  # Convert selected columns into an array
  IFS='|' read -r -a SELECTED_COLUMNS_ARRAY <<< "$SELECTED_COLUMNS"

  echo "SELECTED_COLUMNS_ARRAY : $SELECTED_COLUMNS_ARRAY"

  # Building awk print pattern
  awk_print=""
  for col in "${SELECTED_COLUMNS_ARRAY[@]}"; do
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

  echo "AWK PRINT VALUE : $awk_print"

  declare -A Filters
  
  # Ask if user wants to filter data
  zenity --question --title "Filter Data?" --text "Do you want to filter the data?" 
  
  if [ $? -eq 0 ]; then
    while true; do
      # Select Column for Filtering
      FILTER_COLUMN=$(zenity --list --title "Select Filter Column" --text "Choose a column to filter by:" \
          --radiolist --column "Select" --column "Column Name" \
          $(for col in "${TABLE_HEADERS[@]}"; do echo "FALSE" "$col"; done))

      if [[ -z "$FILTER_COLUMN" ]]; then
          zenity --error --text "No column selected for filtering!"
          continue
      fi

      # Enter filter value
      FILTER_VALUE=$(zenity --entry --title "Enter Filter Value" --text "Enter the value for column '$FILTER_COLUMN':")

      Filters["$FILTER_COLUMN"]="$FILTER_VALUE"

      # Ask if user wants to add another filter
      FILTER_MORE=$(zenity --question --title "Add More Filters?" --text "Do you want to add another filter?" --ok-label="Yes" --cancel-label="No" && echo "y" || echo "n")
      [[ "$FILTER_MORE" != "y" ]] && break
    done
  fi

  # Build awk condition for filtering
  awk_cond=""
  for key in "${!Filters[@]}"; do
    col_index=-1
    for i in "${!TABLE_HEADERS[@]}"; do
      if [[ "${TABLE_HEADERS[i]}" == "$key" ]]; then
        col_index=$((i + 1))
        break
      fi
    done
    [[ -n "$awk_cond" ]] && awk_cond+=" && "
    awk_cond+='$'"${col_index} == \"${Filters[$key]}\""
  done

  # Apply filtering and selection
  if [[ -n "$awk_cond" && -n "$awk_print" ]]; then
      result=$(awk -F':' 'BEGIN { OFS="\t" } { if ('"$awk_cond"') print '"$awk_print"' }' "./DBs/$DB_NAME/$TABLE_NAME.data")
  elif [[ -n "$awk_print" ]]; then
      result=$(awk -F':' 'BEGIN { OFS="\t" } { print '"$awk_print"' }' "./DBs/$DB_NAME/$TABLE_NAME.data")
  fi

  # Display result
  echo "Result : $result"
  num_rows=$(echo "$result" | grep . | wc -l)
  if [[ $num_rows -eq 0 ]]; then
      zenity --warning --text "No data found! Try again."
  else
      zenity --list --title "Query Results" --text "Rows Returned: $num_rows" \
          --column "${Selected_Columns[*]}" $(echo "$result" | tr '\n' ' ')
  fi
}

update_table() {
  local TABLE_NAME=""
  local -a AVAILABLE_TABLES=()

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES[@]} -eq 0 ]; then
    zenity --info --title="No Tables" --text="No Tables Available To Update From !!!" --width=300
    return 0
  fi

  TABLE_NAME=$(zenity --list --title="Insert Into Table" --text="Select a table to select from:" \
    --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
  
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  # Check if the table name exists
  until [ -n "$TABLE_NAME" ]; do
    zenity --error --text "Table name is not selected"
    TABLE_NAME=$(zenity --list --title="Insert Into Table" --text="Select a table to select from:" \
      --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done

  # Fetching table's columns names
  TABLE_HEADERS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) print $i }' "./DBs/$DB_NAME/$TABLE_NAME.meta"))
  while true;
  do
    COLUMN_NAME=$(zenity --list --title="Update From Table '$TB_NAME'" --text="Select a column to update:" \
    --column="Available Columns" "${TABLE_COLUMNS[@]}" --width=400 --height=300 --ok-label="Update")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
    until [ -n "$COLUMN_NAME" ]; do
    zenity --error --text "Column name is not selected"
    COLUMN_NAME=$(zenity --list --title="Update From Table '$TB_NAME'" --text="Select a column to Upadte" \
      --column="Available Columns" "${TABLE_COLUMNS[@]}" --width=400 --height=300 --ok-label="Update")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
    done
    # Find the column index
    for ((i=0; i<${#TABLE_HEADERS[@]}; i++)); do
      if [ "${TABLE_HEADERS[i]}" == "$COLUMN_NAME" ]; then
        COL_INDEX_TO_UPDATE=$((i + 1))
        break
      fi
    done
    INDEX=$(zenity --entry --title="update From Table '$TB_NAME'" --text="Enter the Row Index to Update:" \
    --width=400 --ok-label="update")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
    until [ -n "$INDEX" ]; do
      zenity --error --text "Value can not be empty"
      INDEX=$(zenity --entry --title="update From Table '$TB_NAME'" --text="Enter the Row Index to Update:" \
        --width=400 --ok-label="update")
      if [ $? -ne 0 ]; then return 0; fi  # User canceled
    done
    if ! [[ "$INDEX" =~ ^[0-9]+$ ]]; then
      zenity --warning --text "Error: Invalid row index!"
    fi
    NEW_VALUE=$(zenity --entry --title="update From Table '$TB_NAME'" --text="Enter the New Value to update field:" \
    --width=400 --ok-label="update")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
    until [ -n "$NEW_VALUE" ]; do
      zenity --error --text "Value can not be empty"
      NEW_VALUE=$(zenity --entry --title="update From Table '$TB_NAME'" --text="Enter the New Value to update field :" \
        --width=400 --ok-label="update")
      if [ $? -ne 0 ]; then return 0; fi  # User canceled
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
    if [ $? -ne 0 ]; then    
      zenity --warning --text "No Data Found,try again !!!"  
    else
      zenity --info --title="Success" --text="Data Updated Successfully " --width=300
    fi
    done
}

delete_rows() {
  TB_NAME="$1"
  ALL_ROWS="$2"

  # Check if the user wants to delete all rows
  if [ -n "$ALL_ROWS" ]; then
    # Confirm deletion
    zenity --question --title="Confirm" --text="Are you sure you want to delete ALL data from '$TB_NAME' table ???" 
    if [ $? -ne 0 ]; then
      zenity --info --title="Cancelled" --text="OK, Good choice :) ..." --width=300
      return 0
    fi
    
    # Final confirmation
    zenity --question --title="Final Confirmation" \
      --text="THIS IS THE LAST CHANCE !!! Are you sure you want to delete ALL data from '$TB_NAME' table ???" \
      --width=400 --ok-label="Yes, Delete All" --cancel-label="No, Keep It"
    if [ $? -ne 0 ]; then
      zenity --info --title="Cancelled" --text="OK, I thought so :) ..." --width=300
      return 0
    fi
      echo "" > "./DBs/$DB_NAME/$TB_NAME.data"
      zenity --info --title="Success" --text="All Rows Deleted Successfully !!!" --width=300
      return 0
  fi

  # Prompt the user for a specific deletion criteria

  META_FILE="./DBs/$DB_NAME/$TB_NAME.meta"
  DATA_FILE="./DBs/$DB_NAME/$TB_NAME.data"

  # Extract column names from the metadata file
  TABLE_COLUMNS=($(awk -F':' 'NR==1 { for (i=1; i<=NF; i++) printf "%s\n", $i }' "$META_FILE"))
  
  COLUMN_NAME=$(zenity --list --title="Delete From Table '$TB_NAME'" --text="Select a column to filter rows for deletion:" \
    --column="Available Columns" "${TABLE_COLUMNS[@]}" --width=400 --height=300 --ok-label="Select")
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  until [ -n "$COLUMN_NAME" ]; do
    zenity --error --text "Column name is not selected"
    COLUMN_NAME=$(zenity --list --title="Delete From Table '$TB_NAME'" --text="Select a column to filter rows for deletion:" \
      --column="Available Columns" "${TABLE_COLUMNS[@]}" --width=400 --height=300 --ok-label="Select")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
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
  VALUE=$(zenity --entry --title="Delete From Table '$TB_NAME'" --text="Enter the value to match for deletion:" \
    --width=400 --ok-label="Delete")
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  until [ -n "$VALUE" ]; do
    zenity --error --text "Value can not be empty"
    VALUE=$(zenity --entry --title="Delete From Table '$TB_NAME'" --text="Enter the value to match for deletion:" \
    --width=400 --ok-label="Delete")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done

  zenity --question --title="Exact Matching" --text="Should the match be exact ?"
  EXACT_MATCH=$?
  
  ORIGINAL_LINES_COUNT=$(wc -l < "$DATA_FILE")
  
  if [[ "$EXACT_MATCH" -eq 0 ]]; then
    # Exact match: only delete if the entire field matches VALUE
    awk -F':' -v col="$COL_INDEX" -v val="$VALUE" '$col == val {next} {print}' "$DATA_FILE" > "${DATA_FILE}.tmp"
  else
    # Partial match: delete if VALUE is anywhere in the column
    awk -F':' -v col="$COL_INDEX" -v val="$VALUE" 'index($col, val) == 0 {print}' "$DATA_FILE" > "${DATA_FILE}.tmp"
  fi

  # Overwrite the original file with the filtered result
  mv "${DATA_FILE}.tmp" "$DATA_FILE"

  NEW_LINES_COUNT=$(wc -l < "$DATA_FILE")

  zenity --info --title="Success" --text="$((ORIGINAL_LINES_COUNT - NEW_LINES_COUNT)) rows were deleted successfully !!!" --width=300
  
  return 0
}

delete_from_table() {

  local TABLE_NAME=""
  local -a AVAILABLE_TABLES=()

  AVAILABLE_TABLES=($(get_tables))

  if [ ${#AVAILABLE_TABLES[@]} -eq 0 ]; then
    zenity --info --title="No Tables" --text="No Tables Available To Delete From !!!" --width=300
    return 0
  fi
  
  TABLE_NAME=$(zenity --list --title="Delete From Table" --text="Select table to delete from:" \
    --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
  
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  
  until [ -n "$TABLE_NAME" ]; do
    zenity --error --text "Table name is not selected"
    TABLE_NAME=$(zenity --list --title="Delete From Table" --text="Select table to delete from:" \
      --column="Table Name" "${AVAILABLE_TABLES[@]}" --width=400 --height=300)
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done

  # Prompt the user for a specific deletion criteria
  OPTION=$(zenity --list --title="Delete From Table '$TABLE_NAME'" --text="Select an option:" \
    --column="Delete Options" \
    "Delete Specific Rows" \
    "Delete All Rows" \
    --width=400 --height=300 --ok-label="Select" --cancel-label="Back")
  if [ $? -ne 0 ]; then return 0; fi  # User canceled
  until [ -n "$OPTION" ]; do
    zenity --error --text "Option is not selected"
    OPTION=$(zenity --list --title="Delete From Table '$TABLE_NAME'" --text="Select an option:" \
      --column="Delete Options" \
      "Delete Specific Rows" \
      "Delete All Rows" \
      --width=400 --height=300 --ok-label="Select" --cancel-label="Back")
    if [ $? -ne 0 ]; then return 0; fi  # User canceled
  done
  
  # Check if the user wants to delete all rows
  if [ "$OPTION" == "Delete All Rows" ]; then
    delete_rows $TABLE_NAME "all"
    return 0
  else
    delete_rows $TABLE_NAME
    return 0
  fi
}

# ---------------------------- Table Menu Function ---------------------------- #

start_table_menu() {
  
  # Check if the database name is set
  if [ -z "$DB_NAME" ]; then
    zenity --error --title="Error" --text="Database name is not set !!!" --width=300
    return 1
  fi
  
  while true; 
  do
    CHOICE=$(zenity --list --title="Connected to '$DB_NAME'" --text="Select an option:"\
      --column="Table Menu" \
      "Create Table" \
      "List All Tables" \
      "Drop Table" \
      "Insert Into Table" \
      "Select From Table" \
      "Delete From Table" \
      "Update Table" \
      --width=500 --height=300 --cancel-label="Disconnect" --ok-label="Select")
      
    # Check if the user clicked "Disconnect" or closed the dialog
    if [ $? -ne 0 ]; then
      zenity --question --text="Do you want to Disconnect?"
      if [[ $? -eq 0 ]]; then
        return 0
      else
        continue
      fi
    fi
    
    case $CHOICE in
      "Create Table")
        create_table
        ;;
      "List All Tables")
        list_all_tables
        ;;
      "Drop Table")
        drop_table
        ;;
      "Insert Into Table")
        insert_into_table
        ;;
      "Select From Table")
        select_from_table
        ;;
      "Delete From Table")
        delete_from_table
        ;;
      "Update Table")
        update_table
        ;;
      *)
        zenity --error --title="Error" --text="Invalid option selected!" --width=300
        ;;
    esac
  done
}