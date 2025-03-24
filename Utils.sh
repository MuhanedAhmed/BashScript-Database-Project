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

check_nonzero_positive_integer() {
  if [[ "$1" =~ ^[1-9][0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

# ---------------------------- Validation Functions ---------------------------- #

validate_database_name() {
  DATABASE_NAME="$1"

  # Check if the database name is empty
  if [[ -z $DATABASE_NAME ]]; then
    echo "Error: Database name cannot be empty !!!"
    return 1
  fi

  # Check if the database name is greater than 12 characters
  if [[ ${#DATABASE_NAME} -gt 12 ]]; then
    echo "Error: Database name cannot exceed 12 characters !!!"
    return 1
  fi

  # Check for invalid characters in the database name
  if [[ ! $DATABASE_NAME =~ ^[a-zA-Z0-9_#@$]*$ ]]; then
    echo "Error: Database name can only contain alphabets, numbers and [ '$' , '#' , '@' ] !!!"
    return 1
  fi

  # Check the start of the database name (only alphabets)
  if [[ ! $DATABASE_NAME =~ ^[a-zA-Z] ]]; then
    echo "Error: Database name must start with an alphabet !!!"
    return 1
  fi

  return 0
}

validate_table_name() {
  TABLE_NAME="$1"

  # Check if the table name is empty
  if [[ -z $TABLE_NAME ]]; then
    echo "Error: Table name cannot be empty !!!"
    return 1
  fi

  # Check if the table name is greater than 12 characters
  if [[ ${#TABLE_NAME} -gt 12 ]]; then
    echo "Error: Table name cannot exceed 12 characters !!!"
    return 1
  fi

  # Check for invalid characters in the table name
  if [[ ! $TABLE_NAME =~ ^[a-zA-Z0-9_#@$]*$ ]]; then
    echo "Error: Table name can only contain alphabets, numbers and [ '$' , '#' , '@' ] !!!"
    return 1
  fi

  # Check the start of the table name (only alphabets)
  if [[ ! $TABLE_NAME =~ ^[a-zA-Z] ]]; then
    echo "Error: Table name must start with an alphabet !!!"
    return 1
  fi

  return 0
}

validate_column_name() {
  COLUMN_NAME="$1"

  # Check if the column name is empty
  if [[ -z $COLUMN_NAME ]]; then
    echo "Error: Column name cannot be empty !!!"
    return 1
  fi

  # Check if the column name is greater than 12 characters
  if [[ ${#COLUMN_NAME} -gt 12 ]]; then
    echo "Error: Column name cannot exceed 12 characters !!!"
    return 1
  fi

  # Check for invalid characters in the column name
  if [[ ! $COLUMN_NAME =~ ^[a-zA-Z0-9_#@$]*$ ]]; then
    echo "Error: Column name can only contain alphabets, numbers and [ '$' , '#' , '@' ] !!!"
    return 1
  fi

  # Check the start of the column name (only alphabets)
  if [[ ! $COLUMN_NAME =~ ^[a-zA-Z] ]]; then
    echo "Error: Column name must start with an alphabet !!!"
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

validate_number_input() {
  NUMBER="$1"

  # Check if the number is empty
  if [[ -z $NUMBER ]]; then
    echo "Error: Number cannot be empty !!!"
    return 1
  fi

  # Check if the number is (integer or float, positive, negative, or zero)
  if [[ $NUMBER =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
    return 0
  else
    echo "Error: Invalid Number Format !!!"
    return 1
  fi
}

validate_date_input() {
  DATE="$1"

  # Check if the date is empty
  if [[ -z $DATE ]]; then
    echo "Error: Date cannot be empty !!!"
    return 1
  fi

  # Check if the date is in the format DD-MM-YYYY
  if [[ $DATE =~ ^(0[1-9]|[12][0-9]|3[01])-(0[1-9]|1[0-2])-[0-9]{4}$ ]]; then
    return 0
  else
    echo "Error: Invalid Date Format !!!"
    echo "Date Format: DD-MM-YYYY"
    return 1
  fi
}