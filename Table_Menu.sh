Current_DB=$1
PS3="$Current_DB>> "
select input in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Exit"
do
    case $REPLY in
    1)
        
    ;;
    2)
        
    ;;
    3)
        
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