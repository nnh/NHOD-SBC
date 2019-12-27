**************************************************************************
Program Name : treatment.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-12-27
SAS version : 9.4
**************************************************************************;
* 5.4 treatment;
%SET_FREQ(temp_ds_surgical_curability, '手術の根治度', resectionCAT, %str(ope_non_chemo_cnt ope_chemo_cnt), surgical_curability.csv);
%JOIN_TO_TEMPLATE(temp_ds_surgical_curability, ds_surgical_curability, %quote(items char(2), ope_non_chemo_cnt num, ope_chemo_cnt num), 
                    items, %quote('RX', 'R0', 'R1', 'R2'), %quote(B.ope_non_chemo_cnt label=&ope_non_chemo., B.ope_chemo_cnt label=&ope_chemo.));
%SET_FREQ(temp_ds_adjuvant_chemo_regimen, 'アジュバント化学療法レジメン', adjuvantCAT, %str(ope_chemo_cnt), adjuvant_chemo_regimen.csv);
%JOIN_TO_TEMPLATE(temp_ds_adjuvant_chemo_regimen, ds_adjuvant_chemo_regimen, %quote(items char(100), ope_chemo_cnt num), 
                    items, &regimens_adjuvant., %quote(B.ope_chemo_cnt label=&ope_chemo.));
%SET_FREQ(temp_ds_first_line_chemo_regimen, '第一選択化学療法レジメン', chemCAT, %str(non_ope_chemo_cnt), first_line_chemo_regimen.csv);
%JOIN_TO_TEMPLATE(temp_ds_first_line_chemo_regimen, ds_first_line_chemo_regimen, %quote(items char(100), non_ope_chemo_cnt num), items, 
                    &regimens_first_line., %quote(B.non_ope_chemo_cnt label=&non_ope_chemo.));
%let temp_str_keep=%str(ope_non_chemo_cnt ope_chemo_cnt non_ope_chemo_cnt non_ope_non_chemo_cnt);
%SET_FREQ(ds_primary_site_resection, '原発巣切除の有無', PLresectionYN, &temp_str_keep., primary_site_resection.csv);
