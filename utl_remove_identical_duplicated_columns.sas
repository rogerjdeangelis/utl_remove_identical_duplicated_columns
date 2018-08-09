Remove Identical Columns

github
https://github.com/rogerjdeangelis/utl_remove_identical_duplicated_columns

   Two solutions

      1. Proc IML/R
      2. Voodoo macro on end of post
         (part of https://github.com/rogerjdeangelis/voodoo)


StackOverflow
https://tinyurl.com/ybn2u5dn
https://stackoverflow.com/questions/51686794/remove-identical-columns-while-keeping-one-from-each-group

Sbha profile
https://stackoverflow.com/users/3058123/sbha



INPUT (X1 and X3 are dups)
===========================

 SD1.HAVE total obs=5

          Dup Columns
        dup         dup
         |           |
         V           V
 Obs    X1    X2    X3    X4    X5

  1      1     2     1     2     2
  2      2     3     2     3     3
  3      3     5     3     4     5
  4      4     6     4     4     6
  5      5     3     5     4     3


EXAMPLE OUTPUT
--------------

   1. proc IML/R

      WANT total obs=5

       X1    X2    X4

        1     2     2
        2     3     3
        3     5     4
        4     6     4
        5     3     4

   2. voodoo macro

      WORK._VVEQL total obs=7

                     BATCH

      Variables with All Equal Values

      Variable  Type  Len   Compare   Len

      X1        NUM     8   X3          8
      X2        NUM     8   X5          8


PROCESS
=======

  1. proc IML/R

     proc iml;
     submit / R;
        library(haven)
        have<-read_sas("d:/sd1/have.sas7bdat")
        want<-have[!duplicated(as.list(have))]
        want;
     endsubmit;
     run importdatasetfromr("work.want", "want");
     run;quit;

     proc print data=want;
     run;quit;

  2. Voodoo macro on end of post

     %_vdo_dupcol( lib=sd1 ,mem=have ,typ=num );

     proc print data=_vveql;
     run;quit;

*                _               _       _
 _ __ ___   __ _| | _____     __| | __ _| |_ __ _
| '_ ` _ \ / _` | |/ / _ \   / _` |/ _` | __/ _` |
| | | | | | (_| |   <  __/  | (_| | (_| | || (_| |
|_| |_| |_|\__,_|_|\_\___|   \__,_|\__,_|\__\__,_|

;

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
 input x1-x5;
cards4;
1 2 1 2 2
2 3 2 3 3
3 5 3 4 5
4 6 4 4 6
5 3 5 4 3
;;;;
run;quit;

*          _       _   _
 ___  ___ | |_   _| |_(_) ___  _ __  ___
/ __|/ _ \| | | | | __| |/ _ \| '_ \/ __|
\__ \ (_) | | |_| | |_| | (_) | | | \__ \
|___/\___/|_|\__,_|\__|_|\___/|_| |_|___/

;
proc iml;
submit / R;
   library(haven)
   have<-read_sas("d:/sd1/have.sas7bdat")
   want<-have[!duplicated(as.list(have))]
   want;
endsubmit;
run importdatasetfromr("work.want", "want");
run;quit;

proc print data=want;
run;quit;

%macro _vdo_dupcol(
       lib=&libname
      ,mem=&data
      ,typ=Char
      );

     /* %let typ=num;  */
      options nonotes;
      data _vvren;
         retain _vvvls;
         length _vvvls $32560;
         set _vvcolumn (where=( upcase(type)=%upcase("&typ") and
           libname=%upcase("&lib") and memname = %upcase("&mem"))) end=dne;
           _vvvls=catx(' ',_vvvls,quote(strip(name)));
         if dne then call symputx('_vvvls',_vvvls);
      run;quit;
      option notes;

      %put &_vvvls;
      %let _vvdim=%sysfunc(countw(&_vvvls));
      %*put &=_vvdim;

      data _null_;;
       length var wth $32560;
       array nam[&_vvdim]  $32 (&_vvvls);
       do i=1 to (dim(nam)-1);
         do j=i+1 to dim(nam);
          var=catx(' ',var,nam[i]);
          wth=catx(' ',wth,nam[j]);
        end;
       end;
       call symputx('_vvtop',var);
       call symputx('_vvbot',wth);
      run;

      %put &_vvtop;
      %put &_vvbot;

      ods listing close;
      ods output comparesummary=_vvcmpsum;
      proc compare data=%str(&lib).%str(&mem) compare=%str(&lib).%str(&mem) listequalvar novalues;
         var &_vvtop;
         with &_vvbot;
      run;quit;
      ods listing;

      data _vveql(keep=batch);
        retain flg 0;
        set _vvcmpsum;
        if index(batch,'Variables with All Equal Values')>0 then flg=1;
        if index(batch,'Variables with Unequal Values'  )>0 then flg=0;
        if flg=1;
      run;quit;

      proc sql noprint;select count(*) into :_vvcntstar from _vveql;quit;
      title;footnote;
      %put &=_vvcntstar;

      %if &_vvcntstar ^= 0 %then %do;
         proc print data=_vveql;
         title1 ' ';title2 ' ';title3 ' ' ;
         title4 "These &typ variables have equal values for all observations";
         run;quit;
      %end;
      %else %do;
         data _null_;
           file print;
           put //;
           put "Comparison of Numeric variables to see if a variable is duplicated exactly";
           put //;
           put "*** NO equal &typ Variables with All Equal Values found ***";
           put ' ' //;
         run;
      %end;

%mend _vdo_dupcol;


%_vdo_dupcol( lib=sd1 ,mem=have ,typ=num );

proc print data=_vveql;
run;quit;

