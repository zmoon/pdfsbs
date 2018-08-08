#!/bin/bash
# ----------------------------------------------------------------------
# bash function to tile two or three pdf pages next to each other
#   horizontally or vertically
#   using pdflatex 
# 
# positional arguments:
#   -a|--pdf_a     add input filename after this flag
#   -b|--pdf_b     add input filename after this flag
#   -c|--pdf_c     add input filename after this flag if desired
#   -v|--vertical  if this flag is present, vertical instead of horizontal
#   -o|--outfile   add name of output file after this flag, otherwise 'out.pdf'
#
# example usage:
#   to produce a combined pdf, 'ab.pdf', with pdfs a and b arranged horizontally:
#     pdfsbs.sh -a a.pdf -b b.pdf -o ab.pdf
#   to arrange vertically instead:
#     pdfsbs.sh -a a.pdf -b b.pdf -v -o ab.pdf 
#
# Zach Moon
# 30 Jun 2016: initial version, for two only
# ----------------------------------------------------------------------

# log stdout
logfile=pdfsbs.log
exec 7>&1  # link file descriptor #7 with stdout
exec > $logfile  # log stdout to this log file
echo '                pdfsbs logfile                 '
echo '-----------------------------------------------'
echo -ne 'date: '; date
echo 

SAVEIFS=IFS
IFS=$(echo -en "\n\b")

# some relevant places:
#   cwd -- where this is being run
#   homed -- where this lives (with the template tex file)
cwd=$(pwd)
homed=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# options
#pad_between=20       # padding between the pdfs
pad_between=4
pad_other=8          # padding in the non-between direction
outfilename=out.pdf  # default output file name
vert=0               # horizontal by default
# read in the arguments
echo 'recognized flags:'
while [[ $# > 1 ]]; do

    key="$1"
    echo $key

    case $key in 
        -a|--pdf_a)
        pdf_a="$2"
        shift
        ;;
        -b|--pdf_b)
        pdf_b="$2"
        shift
        ;;
        -c|--pdf_c)
        pdf_c="$2"
        shift
        ;;
        -v|--vertical=true)
        vert=1
        ;;
        -o|--outfile)
        outfilename="$2"
        shift
        ;;

        *)
        # spot for unknown options

        ;;
    esac
    shift
done


files=( $pdf_a $pdf_b )

# fist, determine some page size parameters:
#   total width and height
#   largest individual width and height
w_tot=0
h_tot=0
w_largest=0
h_largest=0
echo -e '\nnow looping through files...'
for f in ${files[*]}; do 
    
    w=$(identify -format "%[fx:w]" $f)
    h=$(identify -format "%[fx:h]" $f)

    w_tot=$( echo "$w_tot + $w" | bc )
    h_tot=$( echo "$h_tot + $h" | bc )

    if (( $(bc <<< "$w_largest < $w") == 1 )); then
        w_largest=$w
    fi
    if (( $(bc <<< "$h_largest < $h") == 1 )); then
        h_largest=$h
    fi

    # trace
    echo this file, $f:  $w  x  $h
    echo w_tot: $w_tot
    echo h_tot: $h_tot
    echo w_largest: $w_largest
    echo h_largest: $h_largest
done

# create custom LaTeX script from the template
echo vert: $vert
fudge_factor=5
if [[ "$vert" == 1 ]]; then
    w_new=$( echo "$w_largest + $pad_other" | bc )
    h_new=$( echo "$h_tot + $pad_between + $fudge_factor" | bc )
    latex_template=pdfsbs_vx2.tex    
else
    w_new=$( echo "$w_tot + $pad_between + $fudge_factor" | bc )
    h_new=$( echo "$h_largest + $pad_other" | bc )
    latex_template=pdfsbs_hx2.tex
fi
echo
echo the combined file, "'$outfilename'", will be:  $w_new  x  $h_new
sed -e "s/WIDTH/$w_new/" \
    -e "s/HEIGHT/$h_new/" \
    -e "s/PADDING/$pad_between/" \
    -e "s/FILE1/$pdf_a/" \
    -e "s/FILE2/$pdf_b/" \
    ${homed}/$latex_template > tmp.tex

# run the custom LaTeX script with pdflatex
echo -e '\nnow running pdflatex, based on the template latex file '$latex_template'...'
pdflatex tmp.tex
mv tmp.pdf $outfilename
mv tmp.* ${homed}/lastrun/
mv $logfile ${homed}/lastrun/

# restore stdout and close file descriptor #7
exec 1>&7 7>&-

IFS=$SAVEIFS

