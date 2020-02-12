**************************************************************************
Program Name : demog.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-10
SAS version : 9.4
**************************************************************************;
* 5.3. Background and demographic characteristics;
options noquotelenmax; 
%CREATE_OUTPUT_DS(output_ds=ds_demog_n, items_label='�w�i�Ɛl�����v�w�I����', insert_n_flg=1);
data ds_demog_n;
    set ds_demog_n;
    keep all_cnt ope_non_chemo_cnt ope_chemo_cnt non_ope_non_chemo_cnt non_ope_chemo_cnt;
run;
%EDIT_N(ds_demog_n, ds_demog_n, pattern_f=0);
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='�w�i�Ɛl�����v�w�I����');
%MEANS_FUNC(title='�N��', var_var=AGE);
%FORMAT_FREQ(sex, %quote('�j��', '����'), '����');
%FORMAT_FREQ(CrohnYN, %quote('����', '�Ȃ�', '�s��'), '�N���[���a');
%FORMAT_FREQ(HNPCCYN, %quote('����', '�Ȃ�', '�s��'), 'HNPCC');
%FORMAT_FREQ(TNMCAT, %quote('I', 'II', 'III', 'IV'), 'TNM����');
%FORMAT_FREQ(PS, %quote('0', '1', '2', '3', '4'), 'PS');
%FORMAT_FREQ(SBCSITE, %quote('�\��w��', '��', '��'), '����');
%FORMAT_FREQ(SBCdegree, %quote('������', '������', '�ᕪ��', '������', '�s��'), '�a���g�D�̕����x');
%FORMAT_FREQ(RASYN, %quote('����', '�Ȃ�', '�s��'), 'RAS�ψق̗L��');
%FORMAT_FREQ(metaYN, %quote('����', '�Ȃ�', '�s��'), '�]�ڑ���');
data meta_Y;
    set ptdata;
    where metaYN=2;
run;
%CREATE_OUTPUT_DS(output_ds=temp_meta, items_label='');
%FORMAT_FREQ(metaSITE_1, %quote('TRUE'), '�̑�', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_2, %quote('TRUE'), '�x', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_3, %quote('TRUE'), '�����d��', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_4, %quote('TRUE'), '���o�������p��', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_5, %quote('TRUE'), '���̑�', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
* Restructure percentage;
%DELETE_PER(temp_meta);
data ds_demog;
    set ds_demog temp_meta;
run;
%TO_NUM_TEST_RESULTS(var=LDH);
%MEANS_FUNC(title='LDH', var_var=LDH_num);
%TO_NUM_TEST_RESULTS(var=CEA);
%MEANS_FUNC(title='CEA', var_var=CEA_num);
%TO_NUM_TEST_RESULTS(var=CA199);
%MEANS_FUNC(title='CA199', var_var=CA199_num);
%ds2csv (data=ds_demog, runmode=b, csvfile=&outpath.\_5_3_demog.csv, labels=Y);
* Multiple primary cancers;
data ds_multiple_primary_cancers;
    format subjid best12.;
    set ptdata(rename=(subjid=id));
    where MHCOM ne '';
    subjid = id;
    keep subjid MHCOM;
run;
%ds2csv (data=ds_multiple_primary_cancers, runmode=b, csvfile=&outpath.\_5_3_multiple_primary_cancers.csv, labels=Y);

* Delete the working dataset;
proc datasets lib=work nolist; 
    delete ds_colnames ds_join ds_title template_ds temp_ds_demog temp_freq temp_meta meta_Y; 
    run;
quit;
