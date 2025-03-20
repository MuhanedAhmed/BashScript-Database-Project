Current_DB=$1
PS3="$Current_DB>>"
select input in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Exit"
do
    case $REPLY in
    1)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
            echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    2)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
            echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    3)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
            echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    4)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
           echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    5)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
            echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    6)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
            echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    7)
        read -p "Enter Table Name: " tablename
        if [ -f "./DBs/$Current_DB/$tablename" ]
        then
            echo "zy fol"
        else
            echo "Table Not Found"
        fi
    ;;
    8)
        echo "Thanks For Using Our DBMS"
        exit
    ;;
    esac
done