**************************************************************************
Program Name : libfunction.sas
Purpose : Common processing
Author : Ohtsuka Mariko
Date : 2019-06-26
SAS version : 9.4
**************************************************************************;

* Define functions;
libname sasfunc "&projectpath.\program\function";
options cmplib=sasfunc.functions; 
proc fcmp outlib=sasfunc.functions.test;
    deletefunc getDays;
    deletefunc getYears;
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
/*    function getLength(input_ds, var);
        rc = run_macro('GET_LENGTH_MACRO', input_ds, var, var_len);
        if rc eq 0 then return(var_len);
        else return(.);
    endsub;*/
run;
/*list the source code*/
Options cmplib=_null_; 
proc fcmp library=sasfunc.functions;
    listfunc getDays getYears;
run;
Quit;
options cmplib = sasfunc.functions;
