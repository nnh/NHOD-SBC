**************************************************************************
Program Name : demog.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2020-02-10
SAS version : 9.4
**************************************************************************;
* 5.3. Background and demographic characteristics;
options noquotelenmax; 
%CREATE_OUTPUT_DS(output_ds=ds_demog_n, items_label='背景と人口統計学的特性', input_n=ds_N_efficacy, insert_n_flg=1);
data ds_demog_n;
    set ds_demog_n;
    keep all_cnt ope_non_chemo_cnt ope_chemo_cnt non_ope_non_chemo_cnt non_ope_chemo_cnt;
run;
%EDIT_N(ds_demog_n, ds_demog_n, pattern_f=0);
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='背景と人口統計学的特性');
%MEANS_FUNC(title='年齢', var_var=AGE);
%FORMAT_FREQ(sex, %quote('男性', '女性'), '性別');
%FORMAT_FREQ(CrohnYN, %quote('あり', 'なし', '不明'), 'クローン病');
%FORMAT_FREQ(HNPCCYN, %quote('あり', 'なし', '不明'), 'HNPCC');
%FORMAT_FREQ(TNMCAT, %quote('I', 'II', 'III', 'IV'), 'TNM分類');
%FORMAT_FREQ(PS, %quote('0', '1', '2', '3', '4'), 'PS');
%FORMAT_FREQ(SBCSITE, %quote('十二指腸', '空腸', '回腸'), '部位');
%FORMAT_FREQ(SBCdegree, %quote('高分化', '中分化', '低分化', '未分化', '不明'), '病理組織の分化度');
%FORMAT_FREQ(RASYN, %quote('あり', 'なし', '不明'), 'RAS変異の有無');
%FORMAT_FREQ(metaYN, %quote('あり', 'なし', '不明'), '転移臓器');
data meta_Y;
    set ptdata;
    where metaYN=2;
run;
%CREATE_OUTPUT_DS(output_ds=temp_meta, items_label='');
%FORMAT_FREQ(metaSITE_1, %quote('TRUE'), '肝臓', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_2, %quote('TRUE'), '肺', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_3, %quote('TRUE'), '腹膜播種', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_4, %quote('TRUE'), '腹腔内リンパ節', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
%FORMAT_FREQ(metaSITE_5, %quote('TRUE'), 'その他', input_ds=meta_Y, output_ds=temp_meta, output_n_flg=0);
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
* Multiple primary cancers;
data ds_multiple_primary_cancers;
    format subjid best12.;
    set ptdata(rename=(subjid=id));
    where MHCOM ne '';
    subjid = id;
    keep subjid MHCOM;
run;

