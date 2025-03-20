if [ -d "./DBs" ]
then
    echo "Database Directory Exist"
else
    mkdir ./DBs
    echo "Database Directory Created"
fi
function create_datbase(){
    read -p "Enter Database Name: " dbname
    dbname=`echo $dbname | tr ' ' '_'`
    source validateInput.sh validateDBName $dbname
    if [ $? -eq 0 ]
    then
        echo "Invalid database name. Only alphanumeric characters and underscores are allowed."
    else 
            if [ -d "./DBs/$dbname" ]
            then
                echo "Database Already Exist"
            else
                mkdir ./DBs/$dbname
                echo "Database Created"
            fi
    fi
}
function list_database(){
     if [[ -d "./DBs" ]]
    then
        ls -F ./DBs | grep / | tr '/' ' '
    else
        echo "No Database Found"
    fi
}
function connect_to_database(){
    read -p "Enter Database Name: " dbname
    dbname=`echo $dbname | tr ' ' '_'`
    source validateInput.sh validateDBName $dbname
    if [ $? -eq 0 ]
    then
        echo "Invalid database name. Only alphanumeric characters and underscores are allowed."
    else
        if [ -d "./DBs/$dbname" ]
        then
            echo "Database Connected"
            source Table_menu.sh $dbname
        else
            echo "Database Not Found"
        fi
    fi
}
function Drop_Database()
{
    read -p "Enter Database Name: " dbname
    source validateInput.sh validateDBName $dbname
    if [ $? -eq 0 ]
    then
        echo "Invalid database name. Only alphanumeric characters and underscores are allowed."
    else
        if [ -d "./DBs/$dbname" ]
        then
            rm -r ./DBs/$dbname
            echo "Database Dropped"
        else
            echo "Database Not Found"
        fi
    fi
}
#####################################################################################################################
select input in "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit"
do 
    case $REPLY in
        1)
            create_datbase
        ;;
        2)
            list_database
        ;;
        3)
            connect_to_database
        ;;
        4)
            Drop_Database
        ;;
        5)
            echo "Thanks For Using Our DBMS"
            exit
        ;;
    esac
done