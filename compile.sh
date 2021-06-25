old_IFS=$IFS         
IFS=$'\n'
info() {
    echo "$1" 1>&2
}
SCRIPT=`realpath $0`
# info "$SCRIPT"
fileName=$(basename "$1")
cd "$(dirname "$1")"
info "Started compiling \"$fileName\"."

for line in $(cat "$fileName")
do
    if [[ "$line" == "%INCLUDE "* ]]
    then
        file=${line#%INCLUDE }
        info "Including from \"$file\"..."
        echo "# BEGIN INCLUDE FROM $file"
        "$SCRIPT" "$file"
        echo "# END INCLUDE FROM $file"
    elif [[ "$line" == *"=%READCONTENT "* ]]
    then
        var=${line%%=%READCONTENT *}
        file=${line#*=%READCONTENT }
        info "Readcontent from \"$file\" into variable \"$var\"..."
        data=$("$SCRIPT" "$file")
        printf '%s=%q\n' "$var" "$data"
    else
        echo "$line"
    fi
done

info "Finished compiling \"$fileName\"."

IFS=$old_IFS