**************************************************************************
Program Name : treatment.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-01-09
SAS version : 9.4
**************************************************************************;
* 5.4 treatment;
%SET_FREQ(temp_ds_surgical_curability, '手術の根治度', resectionCAT, %str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per));
%JOIN_TO_TEMPLATE(temp_ds_surgical_curability, ds_surgical_curability, 
                    %quote(items char(2), ope_non_chemo_cnt num, ope_non_chemo_per num, ope_chemo_cnt num, ope_chemo_per num), 
                    items, 
                    %quote('n', 'RX', 'R0', 'R1', 'R2'), 
                    %quote(B.ope_non_chemo_cnt, B.ope_non_chemo_per, B.ope_chemo_cnt, B.ope_chemo_per));
%ds2csv (data=ds_surgical_curability, runmode=b, csvfile=&outpath.\_5_4_1_surgical_curability.csv, labels=Y);

%SET_FREQ(temp_ds_adjuvant_chemo_regimen, 'アジュバント化学療法レジメン', adjuvantCAT, %str(ope_chemo_cnt ope_chemo_per));
%JOIN_TO_TEMPLATE(temp_ds_adjuvant_chemo_regimen, ds_adjuvant_chemo_regimen, 
                    %quote(items char(100), ope_chemo_cnt num, ope_chemo_per num), 
                    items, 
                    %quote('n', &regimens_adjuvant.), 
                    %quote(B.ope_chemo_cnt, B.ope_chemo_per));
%ds2csv (data=ds_adjuvant_chemo_regimen, runmode=b, csvfile=&outpath.\_5_4_2_adjuvant_chemo_regimen.csv, labels=Y);

%SET_FREQ(temp_ds_first_line_chemo_regimen, '第一選択化学療法レジメン', chemCAT, %str(non_ope_chemo_cnt non_ope_chemo_per));
%JOIN_TO_TEMPLATE(temp_ds_first_line_chemo_regimen, ds_first_line_chemo_regimen, 
                    %quote(items char(100), non_ope_chemo_cnt num, non_ope_chemo_per num), 
                    items, 
                    %quote('n', &regimens_first_line.), 
                    %quote(B.non_ope_chemo_cnt, B.non_ope_chemo_per));
%ds2csv (data=ds_first_line_chemo_regimen, runmode=b, csvfile=&outpath.\_5_4_3_first_line_chemo_regimen.csv, labels=Y);

%let temp_str_keep=%str(ope_non_chemo_cnt ope_non_chemo_per ope_chemo_cnt ope_chemo_per
                        non_ope_non_chemo_cnt non_ope_non_chemo_per non_ope_chemo_cnt non_ope_chemo_per);
%SET_FREQ(ds_primary_site_resection, '原発巣切除の有無', PLresectionYN, &temp_str_keep.);
%ds2csv (data=ds_primary_site_resection, runmode=b, csvfile=&outpath.\_5_4_4_primary_site_resection.csv, labels=Y);

/* Delete the working dataset */
proc datasets lib=work nolist; delete temp_ds_surgical_curability temp_ds_adjuvant_chemo_regimen temp_ds_first_line_chemo_regimen; run; quit;
