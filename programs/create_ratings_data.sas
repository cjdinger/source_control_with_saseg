data ratings;
length stars 8 rating $ 15;
infile datalines dsd;
input stars rating;
datalines;
1, Hatet den
2, Likte den dårlig
3, Likte den
4, Likte den godt
5, Elsket den
;