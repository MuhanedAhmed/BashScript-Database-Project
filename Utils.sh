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
get_tables() {
  DATABASE_NAME=$1
  TABLES=()
  for ITEM in ./DBs/$DATABASE_NAME/*; do
    if [ -f "$ITEM" ]; then
      TABLES+=("$(basename "$ITEM")")
    fi
  done
  echo "${TABLES[@]}"
}

check_database_exists() {
  DATABASE_NAME=$1
  AVAILABLE_DATABASES=($(get_databases))
  for DATABASE in ${AVAILABLE_DATABASES[@]}; do
    if [ "$DATABASE" == "$DATABASE_NAME" ]; then
      return 0
    fi
  done
  return 1
}
check_table_exists() {
  DATABASE_NAME=$1
  TABLE_NAME=$2
  AVAILABLE_TABLES=($(get_tables $DATABASE_NAME))
  for TABLE in ${AVAILABLE_TABLES[@]}; do
    if [ "$TABLE" == "$TABLE_NAME" ]; then
      return 0
    fi
  done
  return 1
}

# ---------------------------- Validation Functions ---------------------------- #

validate_database_name() {
  DATABASE_NAME=$1

  # Check if the database name is empty
  if [[ -z $DATABASE_NAME ]]; then
    echo "Error: Database name cannot be empty !!!"
    return 1
  fi

  # Check if the database name is greater than 64 characters
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

# ---------------------------- Function Determination ---------------------------- #

function_name=$1
function_params=$2

case $function_name in
  "get_databases")
    get_databases
    ;;
  "check_database_exists")
    check_database_exists "$function_params"
    ;;
  "validate_database_name")
    validate_database_name "$function_params"
    ;;
  "get_tables")
    get_tables "$function_params"
    ;;
  "check_table_exists")
    check_table_exists $2 $3
    ;;
    
esac