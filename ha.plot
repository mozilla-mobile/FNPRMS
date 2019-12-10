set term png
set output 'ha-results.png'
set datafile separator ','
set timefmt "%Y.%m.%d"
set xtics rotate by 45 right
set title "Startup To Home Activity"
set xlabel "Date"
set format x "%Y/%m/%d"
stats 'ha-results.csv' using 2 name "A"
set xdata time
set yrange [A_min-0.1:A_max+0.1]
plot 'ha-results.csv' using 1:2 notitle with lines
