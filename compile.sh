old_IFS=$IFS         
IFS=$'\n'
info() {
    >&2 echo "$1"
}
outputWrite() {
    cat >&"$1"
}
noOutput() {
    :
}

codeFile=/dev/null
dependencyFile=/dev/null
inputFile=

while [ $# -ge 1 ]
do
    opt="$1"
    case "$opt" in
        "-o" | "-d" | "-i")
            shift
            if [ $# -le 0 ]; then
                info "Missing file after parameter \"$opt\"."
                exit 1
            fi
            value="$1"
            case "$opt" in
                "-o")
                    codeFile="$value"
                ;;
                "-d")
                    dependencyFile="$value"
                ;;
                "-i")
                    inputFile="$value"
                ;;
            esac
        ;;
        *)
            info "Unrecognized parameter \"$opt\"."
            exit 1
    esac
    shift
done

if [ -z "$inputFile" ]
then
    info "You must specify one input file."
    exit 1
fi

exec 3>"$codeFile"
exec 4>"$dependencyFile"

alias codeOutputWrite="outputWrite 3"
alias dependencyOutputWrite="outputWrite 4"

SCRIPT=`realpath $0`
# info "$SCRIPT"
inputPath="$(dirname "$inputFile")"
info "Started compiling \"$inputFile\"."

for line in $(cat "$inputFile")
do
    if [[ "$line" == "%INCLUDE "* ]]
    then
        file=$(realpath --relative-to "$PWD" -s "$inputPath/${line#%INCLUDE }")
        
        info "Including from \"$file\"..."
        codeOutputWrite <<< "# BEGIN INCLUDE FROM \"$file\""
        dependencyOutputWrite <<< "\"$file\""
        
        "$SCRIPT" -i "$file" -o >(codeOutputWrite) -d >(dependencyOutputWrite)

        codeOutputWrite <<< "# END INCLUDE FROM $file"
    elif [[ "$line" == *"=%READCONTENT "* ]]
    then
        var=${line%%=%READCONTENT *}
        file=$(realpath --relative-to "$PWD" -s "$inputPath/${line#*=%READCONTENT }")
        info "Readcontent from \"$file\" into variable \"$var\"..."
        data=$("$SCRIPT" -i "$file" -o >(cat) -d >(dependencyOutputWrite))
        codeOutputWrite <<< "$(printf '%s=%q\n' "$var" "$data")"
        dependencyOutputWrite <<< "\"$file\""
    else
        codeOutputWrite <<< "$line"
    fi
done

exec 3>&-
exec 4>&-

info "Finished compiling \"$inputFile\"."

IFS=$old_IFS