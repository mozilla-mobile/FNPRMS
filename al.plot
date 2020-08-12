# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
set terminal svg noenhanced
set datafile separator ','
set timefmt "%Y.%m.%d"
set format x "%Y/%m/%d"
set xdata time
set xtics 1 rotate by 90 right nomirror font "SourceCodePro-Light,3"
set xlabel "DATE" font "SourceCodePro,9" offset 0,4
set ylabel "TIME (s)" font "SourceCodePro,9" offset 2,0

set key font "SourceCodePro-Light,4"
set key outside;
set key spacing 0.75
set key right top;

set autoscale y
set ytics font "SourceCodePro,6"

set title "STARTUP FROM APPLINK" font "SourceCodePro,12"
set output 'al-results.svg'
FILES = system("find /opt/mozilla/FNPRMS_results -type f -name '*-al-results.csv' | sort")
TITLES = system("find /opt/mozilla/FNPRMS_results -type f -name '*-al-results.csv' -printf '%f\n' | sort | sed -e 's/-al-results.csv//' -e 's|^\./||' ")

plot for [i=1:words(FILES)] word(FILES,i) u 1:2:xticlabels(sprintf('%s', stringcolumn(1))) with linespoints pointsize 0.25 title word(TITLES,i)
