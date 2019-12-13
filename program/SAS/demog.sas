**************************************************************************
Program Name : demog.sas
Study Name : NHOD-SBC
Author : Ohtsuka Mariko
Date : 2019-06-05
SAS version : 9.4
**************************************************************************;
%macro FREQ_METAYN;
    /*  *** Functional argument *** 
        none
        *** Output dataset ***
        ds_meta_1, ds_meta_2, ds_meta_3, ds_meta_4 
        *** Example ***
        %FREQ_METAYN;
    */
    %local i;
    proc sql noprint;
        %do i = 1 %to 4;     
            create table ds_meta_&i. like ds_demog;
        %end;
    quit;

    %FREQ_FUNC(var_var=metaYN, output_ds=ds_meta_1);

    proc sql noprint;
        insert into ds_meta_2 select * from ds_meta_1 where items = '����';
        update ds_meta_2 set title = '�]�ڑ���';
        insert into ds_meta_3 select * from ds_meta_1 where items = '�Ȃ�';
        insert into ds_meta_4 select * from ds_meta_1 where (items ne '����') and (items ne '�Ȃ�');
    quit;

%mend FREQ_METAYN;

%macro FREQ_METASITE;
    /*  *** Functional argument *** 
        none
        *** Example ***
        %FREQ_METASITE;
    */
    %local i temp_meta_1 temp_meta_2 temp_meta_3 temp_meta_4 temp_meta_5;
    %let temp_meta_1='�@�̑�';
    %let temp_meta_2='�@�x';
    %let temp_meta_3='�@�����d��';
    %let temp_meta_4='�@���o�������p��';
    %let temp_meta_5='�@���̑�';
    %do i = 1 %to %eval(&demog_group_count.);
        proc sql;
            create table temp_metasite_&i. like ds_demog;
        quit;
        %FREQ_FUNC(input_ds=ptdata, var_var=metasite_&i., output_ds=temp_metasite_&i.);
        proc sql noprint;
            create table output_meta_&i. like ds_demog;
            insert into output_meta_&i. select * from temp_metasite_&i. where items like '%TRUE%';
            update output_meta_&i. set title = &&temp_meta_&i., items = '';
        quit;
    %end;
    data ds_demog;
        set ds_demog output_meta_1-output_meta_&demog_group_count.;
    run;
    /* Delete the working dataset */
    proc datasets lib=work nolist; delete temp_metasite_1-temp_metasite_&demog_group_count. output_meta_1-output_meta_&demog_group_count. ; run; quit;

%mend FREQ_METASITE;

%macro FREQ_META;
    /*  *** Functional argument *** 
        none
        *** Example ***
        %FREQ_META;
    */
    %FREQ_METAYN;
    data ds_demog;
        set ds_demog ds_meta_2;
    run;
    %FREQ_METASITE;
    data ds_demog;
        set ds_demog ds_meta_3 ds_meta_4;
    run;
    /* Delete the working dataset */
    proc datasets lib=work nolist; delete ds_meta_1-ds_meta_4 ; run; quit;

%mend FREQ_META;

* 5.3. Background and demographic characteristics;
%CREATE_OUTPUT_DS(output_ds=ds_demog, items_label='�w�i�Ɛl�����v�w�I����');
%MEANS_FUNC(title='�N��', var_var=AGE);
%FREQ_FUNC(title='�N���[���a', var_var=CrohnYN);
%FREQ_FUNC(title='HNPCC', var_var=HNPCCYN);
%FREQ_FUNC(title='TNM����', var_var=TNMCAT);
%FREQ_FUNC(title='PS', var_var=PS);
%FREQ_FUNC(title='����', var_var=SBCSITE);
%FREQ_FUNC(title='�a���g�D�̕����x', var_var=SBCdegree);
%FREQ_FUNC(title='RAS�ψق̗L��', var_var=RASYN);
%FREQ_META;
%TO_NUM_TEST_RESULTS(var=LDH);
%MEANS_FUNC(title='LDH', var_var=LDH_num);
%TO_NUM_TEST_RESULTS(var=CEA);
%MEANS_FUNC(title='CEA', var_var=CEA_num);
%TO_NUM_TEST_RESULTS(var=CA199);
%MEANS_FUNC(title='CA199', var_var=CA199_num);
%ds2csv (data=ds_demog, runmode=b, csvfile=&outpath.\demog.csv, labels=Y);
* Multiple primary cancers;
data ds_multiple_primary_cancers;
    format subjid best12.;
    set ptdata(rename=(subjid=id));
    where MHCOM ne '';
    subjid = id;
    keep subjid MHCOM;
run;
%ds2csv (data=ds_multiple_primary_cancers, runmode=b, csvfile=&outpath.\multiple_primary_cancers.csv, labels=Y);
