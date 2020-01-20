**************************************************************************
Program Name : cancel.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-20
SAS version : 9.4
**************************************************************************;
* 5.2. Breakdown of cases and count of discontinued cases;
%CREATE_OUTPUT_DS(output_ds=cancel, items_label='症例の内訳と中止例集計');
%FORMAT_FREQ(DSDECOD, %quote('完了', '中止'), '症例の内訳と中止例集計', output_ds=cancel);
proc sql;
    create table ds_reasons_for_withdrawal(
        reasons num label='中止理由');
quit;
%ds2csv (data=cancel, runmode=b, csvfile=&outpath.\_5_2_cancel.csv, labels=Y);
%ds2csv (data=ds_reasons_for_withdrawal, runmode=b, csvfile=&outpath.\_5_2_reasons_for_withdrawal.csv, labels=Y);
