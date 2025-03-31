#! /bin/bash

# ---------------------------- Helper Functions ---------------------------- #

get_databases() {
  DATABASES=()
  for ITEM in ./DBs/*; do
    if [ -d "$ITEM" ]; then
      DATABASES+=("$(basename "$ITEM")")
    fi
  done
  echo "${DATABASES[@]}"
}

check_database_exists() {
  DATABASE_NAME="$1"
  AVAILABLE_DATABASES=($(get_databases))
  for DATABASE in ${AVAILABLE_DATABASES[@]}; do
    if [ "$DATABASE" == "$DATABASE_NAME" ]; then
      return 0
    fi
  done
  return 1
}

get_tables() {
  TABLES=()
  for ITEM in ./DBs/$DB_NAME/*.meta; do
    if [ -f "$ITEM" ]; then
      TABLES+=("$(basename "$ITEM" .meta)")
    fi
  done
  echo "${TABLES[@]}"
}

check_table_exists() {
  TABLE_NAME="$1"
  AVAILABLE_TABLES=($(get_tables))
  for TABLE in ${AVAILABLE_TABLES[@]}; do
    if [ "$TABLE" == "$TABLE_NAME" ]; then
      return 0
    fi
  done
  return 1
}

check_column_exists() {
  local COLUMNS_NAMES=("$@")
  local SEARCH_COLUMN="${COLUMNS_NAMES[-1]}"
  unset 'COLUMNS_NAMES[-1]'
  
  for COLUMN in ${COLUMNS_NAMES[@]}; do
    if [ "$COLUMN" == "$SEARCH_COLUMN" ]; then
      return 0
    fi
  done
  return 1
}

check_nonzero_positive_integer() {
  if [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

check_primary_key() {
  local TABLE_NAME="$1"
  local FIELD_NUMBER="$2"
  local PRIMARY_KEY_VALUE="$3"

  DATA_FILE="./DBs/$DB_NAME/$TABLE_NAME.data"

  # Check if the data file exists
  if [[ ! -f "$DATA_FILE" ]]; then
    zenity --error --title="Error" --text="Enable to find '$TABLE_NAME'.data file" --width=300
    return 1
  fi

  # Check if the primary key value already exists
  if awk -F':' -v field="$FIELD_NUMBER" -v pk_value="$PRIMARY_KEY_VALUE" '
    {
      if ($field == pk_value) {
        exit 1  # Found duplicate
      }
    }
  ' "$DATA_FILE"; then
    return 0
  else
    zenity --error --title="Error" --text="Primary key value '$PRIMARY_KEY_VALUE' already exists" --width=300
    return 1
  fi
}

# ---------------------------- Validation Functions ---------------------------- #

validate_structure_name() {
  STRUCTURE_TYPE="$1"
  STRUCTURE_NAME="$2"

  # Check if the structure name is empty
  if [[ -z $STRUCTURE_NAME ]]; then
    zenity --error --title="Error" --text="$STRUCTURE_TYPE name cannot be empty" --width=300
    return 1
  fi

  # Check if the structure name is greater than 12 characters
  if [[ ${#STRUCTURE_NAME} -gt 12 ]]; then
    zenity --error --title="Error" --text="$STRUCTURE_TYPE name cannot exceed 12 characters" --width=300
    return 1
  fi

  # Check for invalid characters in the structure name
  if [[ ! $STRUCTURE_NAME =~ ^[a-zA-Z0-9_#@$]*$ ]]; then
    zenity --error --title="Error" --text="$STRUCTURE_TYPE name can only contain alphabets, numbers and [ '$' , '#' , '@' ]" --width=300
    return 1
  fi

  # Check the start of the structure name (only alphabets)
  if [[ ! $STRUCTURE_NAME =~ ^[a-zA-Z] ]]; then
    zenity --error --title="Error" --text="$STRUCTURE_TYPE name must start with an alphabet" --width=300
    return 1
  fi

  return 0
}

validate_column_type() {
  if [ -z "$1" ]; then
    echo "Error: Column Type Cannot Be Empty !!!"
    return 1
  fi

  if [ "$1" != "num" -a "$1" != "str" -a "$1" != "date" ]; then
    echo "Error: Invalid Column Type !!!"
    return 1
  fi

  return 0
}

validate_string_input() {
  STRING="$1"

  # Check if the string is empty
  if [[ -z $STRING ]]; then
    zenity --error --title="Error" --text="String cannot be empty" --width=300
    return 1
  fi

  # Check if the string contains ':' character
  if [[ "$STRING" =~ : ]]; then
    zenity --error --title="Error" --text="String cannot contain ':' character" --width=300
    return 1
  fi

  return 0
}

validate_number_input() {
  NUMBER="$1"

  # Check if the number is empty
  if [[ -z $NUMBER ]]; then
    zenity --error --title="Error" --text="Number cannot be empty" --width=300
    return 1
  fi

  # Check if the number is (integer or float, positive, negative, or zero)
  if [[ $NUMBER =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    return 0
  else
    zenity --error --title="Error" --text="Invalid Number Format" --width=300
    return 1
  fi
}

validate_date_input() {
  DATE="$1"

  # Check if the date is empty
  if [[ -z $DATE ]]; then
    zenity --error --title="Error" --text="Date cannot be empty" --width=300
    return 1
  fi

  # Check if the date is in the format DD-MM-YYYY
  if [[ $DATE =~ ^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-[0-9]{4}$ ]]; then
    return 0
  else
    zenity --error --title="Error" --text="Invalid Date Format\n\nDate Format: DD-MM-YYYY" --width=300
    return 1
  fi
}