func_name=$1
funct_param=$2
function validateDBName() {
    if [[ ! $funct_param =~ ^[A-Za-z][A-Za-z0-9#$@_]{7}$ ]]; then
        return 0
    else
        return 1
        
    fi
}
if [ $func_name == "validateDBName" ]
then
    validateDBName $funct_param
fi