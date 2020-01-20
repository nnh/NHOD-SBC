**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-20
SAS version : 9.4
**************************************************************************;
* 5.2. Breakdown of cases and count of discontinued cases;
%CREATE_OUTPUT_DS(output_ds=cancel, items_label='Ç—á‚Ì“à–ó‚Æ’†~—áWŒv');
%FORMAT_FREQ(DSDECOD, %quote('Š®—¹', '’†~'), 'Ç—á‚Ì“à–ó‚Æ’†~—áWŒv', output_ds=cancel);
proc sql;
    create table ds_reasons_for_withdrawal(
        reasons num label='’†~——R');
quit;
%ds2csv (data=cancel, runmode=b, csvfile=&outpath.\_5_2_cancel.csv, labels=Y);
%ds2csv (data=ds_reasons_for_withdrawal, runmode=b, csvfile=&outpath.\_5_2_reasons_for_withdrawal.csv, labels=Y);
