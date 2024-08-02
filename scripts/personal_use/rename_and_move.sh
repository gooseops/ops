#!/bin/bash
function f_usage () {
    printf "USAGE: %s -i /path/to/file.mkv -o /path/to/new/directory/location
\t-i Path to file to be renamed and moved
\t-o Path to the output directory where file will be moved to" "$(basename "${0}")"
    exit 0
}

function f_selectTitle () {
    local _title
    PS3='Select a title: '
    select _title in ABORT $(cat movie_list.txt); do
        case "${_title}" in
            ABORT) printf "ABORTING..." && exit 1 ;;
            *) echo "${_title}" && break ;;
        esac
    done
}

############ BEGIN MAIN ############

OUTPUT_DIR="00_movies"
TITLE=$(f_selectTitle)

while getopts i:o: o; do
    case "${o}" in
        i) INPUT_DIR="${OPTARG}" ;;
        o) OUTPUT_DIR="${OPTARG}" ;;
        *) f_usage
    esac
done

mv "${INPUT_DIR}"/*.mp4 "${OUTPUT_DIR}/${TITLE}" || { echo "errors present.  Exiting..." ; exit 1; }
rm -rf "${INPUT_DIR}"
