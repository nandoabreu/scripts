#! /bin/bash

docx_path=~/Documents/Arbeit
docx_file=AbreuF-IT_CV-202005
#docx_file+="-descriptive"

#docx_path=/tmp
#docx_file=CV-Europass-20200517-Duarte-EN

#set -x
IFS=$'\n'

unoconv -f txt ${docx_path}/${docx_file}.docx

echo -e "Dictionary words from your docx document will now be parsed."
echo -e "You will be able to review and ajust the words and add terms."
echo -e "Each line of the file must have a term with at least two alphabetic characters and:"
echo -e "  - a term like 'marketing communication' (to find 'marketing' and 'communication' in the same line);"
echo -e "  - a word like 'communicator' (which will search for both 'communicator' and 'communicators'); or"
echo -e "  - an abbreviation like 'efficien' (to search for: 'effiency, efficient, efficiently, coefficient')."

cat ${docx_path}/${docx_file}.txt | tr 'A-Z' 'a-z' | tr '[, /;:]' '\n' \
| grep -v -e '\w@\w' -e '\w\.\w' -e '[@+]' \
| sed 's/[^a-z0-9 ]//g' | sed -e 's/^ \+//' -e 's/ \+$//' | sed 's/ \+/ /g' \
| grep -v -w -E 'jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec' \
| grep -v -w -E 'an|and|as|at|end|for|in|of|on|or|the|to' \
| grep -v -e '^$' -e '^[a-z]$' -e '^[0-9]' \
> /tmp/CV-0-words-raw.$$.txt

for word in $(cat /tmp/CV-0-words-raw.$$.txt); do
    [ ${#word} -lt 5 ] && echo "$word" && continue

    [ $word == manager ] && echo "manage" && continue
    [ $word == taxes ] && echo "tax" && continue

    [[ $word =~ ^coordinators?$ ]] && echo "coordinat" && continue
    [[ $word =~ ^solutions?$ ]] && echo "solution" && continue
    [[ -n $(echo "various" | grep -w $word) ]] && echo "$word" && continue

    new_word=$word
    [[ $new_word =~ ies$ ]] && new_word=$(echo $new_word | sed 's/ies$//') # commodities -> commodit
    [[ $new_word =~ ments?$ ]] && new_word=$(echo $new_word | sed 's/ments\?$//') # achievement -> achieve
    [[ $new_word =~ ests?$ ]] && new_word=$(echo $new_word | sed 's/ests\?$//') # smoothest -> smooth
    [[ $new_word =~ in[dg]$ ]] && new_word=$(echo $new_word | sed 's/in[dg]$//') # driving -> driv
    [[ $new_word =~ (at)?ions?$ ]] && new_word=$(echo $new_word | sed 's/\(at\)\?ions\?$/\1/')
    [[ $new_word =~ s$ ]] && new_word=$(echo $new_word | sed 's/s$//')
    [[ $new_word =~ [ntyz]ed$ ]] && new_word=$(echo $new_word | sed 's/\([ntyz]\)ed$/\1/')
    [[ $new_word =~ ed$ ]] && new_word=$(echo $new_word | sed 's/ed$//') # played -> play

    [[ $new_word =~ mm$ ]] && new_word=$(echo $new_word | sed 's/mm$/m/') # programmer -> programm -> program

    [ ${#new_word} -lt 4 ] && echo "$word" || echo "$new_word"
done | sort -u > /tmp/CV-1-words.$$.txt
file_to_analyse=/tmp/CV-1-words.$$.txt

echo; read -p "Would you like to review and ajust the found terms? [y|n] " review
if [[ $review =~ [y|Y] ]]; then
    echo -n "After editing the file, save it and close it and we will continue. "
    read -p "Hit Enter to proceed..."
    cp /tmp/CV-1-words.$$.txt /tmp/CV-2-terms-edited.$$.txt
    gedit /tmp/CV-2-terms-edited.$$.txt
    file_to_analyse=/tmp/CV-2-terms-edited.$$.txt
fi

echo "Analysing terms from dictionary..."
for term in $(cat $file_to_analyse \
    | sed 's/[^a-z0-9 ]//g' | sed -e 's/^ \+//' -e 's/ \+$//' | sed 's/ \+/ /g' \
    | grep -v -e '^$' -e '^[a-z]$' -e '^[0-9]' | sort -u)
do
    search=$(echo "$term" | tr ' ' '.*')
    res=$(grep -i -o -w "$search" ${docx_path}/${docx_file}.txt)
    count=$(echo "$res" | wc -l)
    echo -e "$count\t$term"

    for word in $(echo $term | tr ' ' '\n'); do
        [ ${#word} -le 5 ] && continue
        echo ${word:0:5} | tr 'A-Z' 'a-z' >> /tmp/CV-3-radicals-raw.$$.txt
    done
done | sort -nr > /tmp/CV-4-search-terms.$$.txt

echo "Creating a more amplified analysis..."
sort -u /tmp/CV-3-radicals-raw.$$.txt > /tmp/CV-3-radicals.$$.txt
for radical in $(cat /tmp/CV-3-radicals.$$.txt); do
    words=$radical
    for line in $(grep "$radical" $file_to_analyse); do
        words+=", $line"
    done

    res=$(grep -i -o "$radical" ${docx_path}/${docx_file}.txt)
    count=$(echo "$res" | wc -l)
    echo -e "$count\t$words"
    for line in $res; do
        echo $res
    done
done | sort -nr > /tmp/CV-5-search-radicals.$$.txt

echo -n "Analysis concluded. "
read -p "Hit Enter to print main results..."
clear


echo "Printing most frequent terms:"
echo "-----------------------------"
echo

for line in $(head -5 /tmp/CV-4-search-terms.$$.txt); do
    count=$(echo $line | cut -f1)
    phrase=$(echo $line | cut -f2)

    label=occurence; [ $count -gt 1 ] && label+=s
    echo "# $count $label: $phrase ###"

    grep --color=always -i -w $(echo $line | cut -f2) ${docx_path}/${docx_file}.txt
    echo
done
echo

echo "Printing most frequent terms over amplified analysis:"
echo "-----------------------------------------------------"
echo

for line in $(head -5 /tmp/CV-5-search-radicals.$$.txt); do
    count=$(echo $line | cut -f1)
    phrase=$(echo $line | cut -f2)

    label=occurence; [ $count -gt 1 ] && label+=s
    echo "# $count $label: $phrase ###"

    grep --color=always -i $(echo $line | cut -f2 | cut -d',' -f1) ${docx_path}/${docx_file}.txt
    echo
done
echo

exit

for line in $(cat /tmp/CV_Analysis.$$.txt | sort -nr); do
#
    count=$(echo $line | cut -f1)
    term=$(echo $line | cut -f2)
    label="occurences"; [ $count -le 1 ] && label="occurence"
    echo -e "\n##### ${term}: ${count} ${label} ###############"

#    for line in $(echo -e "$res"); do
#        echo "$line" | tr '\t' ' ' | sed 's/^ \+//' | sed 's/^\([A-Za-z0-9]\)/  \1/' | grep -i "$search"
#    done
done

