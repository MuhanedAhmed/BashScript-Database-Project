Current_DB=$1
PS3="$Current_DB>> "
function create_table()
{
    echo "=== Creating a Table ==="
    echo "-------------------------"
    echo ""

    read -p "Enter the Table Name: " Table_NAME
    flag=False
    source Utils.sh check_table_exists $Current_DB $Table_NAME
    if [ $? -eq 0 ]; then
        echo "Table '$Table_NAME' Already Exists !!!"
    else
        touch "./DBs/$Current_DB/$Table_NAME"
        touch "./DBs/$Current_DB/$Table_NAME.meta"
        read -p "Enter the Number of Columns: " COLUMNS
        read -p "Do you want to add Primary key to the table (y/n): " primary
        if [ $primary == "y" ]
        then
            read -p "Enter Column Name: " colname
            read -p "Enter Column Datatype: " coltype
            echo -n "$colname:$coltype:PK:" >> "./DBs/$Current_DB/$Table_NAME.meta"
            flag=True
        fi
        for ((i=1; i<=$COLUMNS; i++))
        do
            read -p "Enter Column Name: " colname
            read -p "Enter Column Datatype: " coltype
            echo -n "$colname:$coltype:" >> "./DBs/$Current_DB/$Table_NAME.meta"
        done
        if [ $flag == "False" ]
        then
            echo "WeakEntity" >> "./DBs/$Current_DB/$Table_NAME.meta"
        fi
        echo "Table '$Table_NAME' Created !!!"
    fi

}
function list_tables()
{
    echo "=== Listing All Tables ==="
    echo "-------------------------"
    echo ""

    AVAILABLE_Tables=($(source Utils.sh get_tables $Current_DB))

    if [ ${#AVAILABLE_Tables} -eq 0 ]; then
        echo "No Tables Available !!!"
    else
        echo "The Available Tables are : "
        echo "---------------------------"
        echo ""

        for Table in "${AVAILABLE_Tables[@]}"; do
        echo "$Table"
        done
    fi

}
function drop_table()
{
    echo "=== Dropping a Table ==="
    echo "---------------------------"
    echo ""

    read -p "Enter the Table Name: " Table_NAME
    
    source Utils.sh check_table_exists $Current_DB $Table_NAME
    
    if [ $? -eq 0 ]; then
        rm -r "./DBs/$Current_DB/$Table_NAME"
        rm -r "./DBs/$Current_DB/$Table_NAME.meta"
        echo "Table '$Table_NAME' Dropped !!!"
    else
        echo "Table '$Table_NAME' Does Not Exist !!!"
    fi 
}
select input in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Exit"
do
    case $REPLY in
    1)
        create_table
    ;;
    2)
        list_tables
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
        echo "Exiting..."
        return 0
    ;;
    esac
done