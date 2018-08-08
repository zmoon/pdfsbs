#!/bin/bash

nrows=8
ncols=8

a='a.pdf'
b='b.pdf'

# build row by row
for (( j=1 ; j<=$nrows ; j++ )); do
    
    jmod=$(( $j % 2 ))

    for (( i=1 ; i<=$ncols ; i++ )); do

        imod=$(( $i % 2 ))

        # first in a row
        if [[ "$i" == 1 ]]; then
            # alternate starting image in the row
            if [[ "$jmod" == 0 ]]; then
                cp $a curr_row.pdf
            else
                cp $b curr_row.pdf
            fi
        # after the first in a row
        else
            ijmod=$(( (i+j) % 2 ))
            if [[ "$ijmod" == 0 ]]; then
                ../pdfsbs.sh -a curr_row.pdf -b $b -o curr_row.pdf
            else
                ../pdfsbs.sh -a curr_row.pdf -b $a -o curr_row.pdf
            fi
        fi
    done

    # if not the first row, combine current row with previous row
    if [[ "$j" > 1 ]]; then
        ../pdfsbs.sh -a curr_row.pdf -b prev_rows.pdf -v -o prev_rows.pdf
    else
        mv curr_row.pdf prev_rows.pdf
    fi
done

# clean up
mv prev_rows.pdf fun.pdf
rm curr_row.pdf

