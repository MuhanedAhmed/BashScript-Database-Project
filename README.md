# Bash Shell Script Database Management System (DBMS)

## Overview
This project is a simple Database Management System (DBMS) implemented using Bash shell scripting. It provides a Command Line Interface (CLI) and a Graphical User Interface (GUI) using `Zenity` for managing databases and tables.

## Features
- Create, List, Drop Databases
- Create, List, Drop Tables
- Insert, Select, Update, Delete Records
- Data Validation (Strings, Numbers, Dates, Primary Keys, etc.)
- Error Handling and User-Friendly Messages
- CLI and GUI Support (via Zenity)

## Project Structure
```
DBMS-Project/
├── CLI-Version/
│   ├── Main_Menu.sh    # Main menu script for CLI version
│   ├── Table_Menu.sh   # Table operations menu
│   ├── Utils.sh        # Helper functions for validation and database handling
├── GUI-Version/
│   ├── Main_Menu.sh    # Main menu script for GUI version (Zenity-based)
│   ├── Table_Menu.sh   # Table operations menu for GUI
│   ├── Utils.sh        # Shared helper functions
├── DBs/                # Directory storing databases and tables
│   ├── <DatabaseName>/
│   │   ├── <TableName>.meta  # Table schema definition
│   │   ├── <TableName>.data  # Table records storage
└── README.md           # Project documentation
```

## Requirements
- Linux/macOS
- Bash 4+
- `Zenity` (for GUI version)

## Installation
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd DBMS-Project
   ```
2. Ensure execution permissions:
   ```bash
   chmod +x CLI-Version/*.sh GUI-Version/*.sh
   ```

## Usage
### CLI Version
Run the main menu:
```bash
./CLI-Version/Main_Menu.sh
```

### GUI Version
Run the GUI version using `Zenity`:
```bash
./GUI-Version/Main_Menu.sh
```

## Database Operations
### Creating a Database
- In CLI: Choose `Create Database` from the main menu and enter a name.
- In GUI: Enter the database name in the prompt.

### Creating a Table
- Define table name, columns, and primary key.
- Supported data types: `num`, `str`, `date`.

### Inserting Data
- Records must match the table schema.
- Primary keys must be unique.

### Selecting Data
- Supports full table selection or filtering by column values.

### Updating & Deleting Data
- Users can update or delete records based on column conditions.

## Validation Rules
- Database/Table names must start with a letter and can contain `[a-zA-Z0-9_#@$]`.
- String inputs cannot be empty or contain `:`.
- Numbers must be integers or floats.
- Dates must follow the `DD-MM-YYYY` format.

## Contribution
Feel free to contribute by submitting pull requests or reporting issues.

## License
This project is licensed under the MIT License.

## Contributors

This project was developed by:

- [Shahd Fayez](https://github.com/shahd77fayez)
- [Mohaned Ahmed](https://github.com/MuhanedAhmed)  
