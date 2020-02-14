**************************************************************************
Program Name : libfunction.sas
Purpose : Common processing
Author : Ohtsuka Mariko
Date : 2020-02-14
SAS version : 9.4
**************************************************************************;

* Define functions;
libname sasfunc "&projectpath.\program\sas\function";
options cmplib=sasfunc.functions; 
proc fcmp outlib=sasfunc.functions.test;
    deletefunc getDays;
    deletefunc getYears;
    deletefunc setDecimalFormat;
run;
Quit;
options cmplib=sasfunc.functions; 
proc fcmp outlib=sasfunc.functions.test;
    function getDays(start_date, end_date);
        temp=end_date - start_date;
        return(temp);
    endsub;
    function getYears(days);
        temp=round((days / 365), 0.001);
        return(temp);
    endsub;
    function setDecimalFormat(input) $;
        temp_input=round(input, 0.1);
        temp=put(temp_input, 8.1);
        return(temp);
    endsub;
run;
/*list the source code*/
Options cmplib=_null_; 
proc fcmp library=sasfunc.functions;
    listfunc getDays getYears setDecimalFormat;
run;
Quit;
options cmplib = sasfunc.functions;
