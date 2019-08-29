function [studynbr, studydisplayname, pmStudyInfo] = selectStudy()

% selectStudy - select and return a table containing the study information
% - with multiple rows if multiple studies chosen to run concurrently

fprintf('Select study to run for\n');
fprintf('-----------------------\n');
fprintf('1: Smartcare\n');
fprintf('2: Telemed\n');
fprintf('3: Both Smartcare and Telemed\n');
fprintf('\n');
studynbr = input('Choose study to run for: ');

if studynbr > 3
    fprintf('Invalid choice\n');
    return;
end
if isequal(studynbr,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

if studynbr == 1
    study = {'SC'};
    studydisplayname = 'SC';
elseif studynbr == 2
    study = {'TM'};
    studydisplayname = 'TM';
elseif studynbr == 3
    study = {'SC'; 'TM'};
    studydisplayname = 'SC_TM';
else
    fprintf('Invalid study\n');
    return;
end

pmStudyInfo = table('Size',[size(study,1), 7], 'VariableTypes', {'cell', 'cell', 'double', 'cell', 'cell', 'cell', 'cell'}, ...
    'VariableNames', {'Study', 'StudyName', 'Offset', 'MeasurementMatFile', 'ClinicalMatFile', 'AMPredMatFile', 'ElectiveTrFile'});

for a = 1:size(study,1)
    pmStudyInfo.Study(a)                    = study(a);
    pmStudyInfo.ElectiveTrFile{a}           = sprintf('%selectivetreatments.xlsx', study{a});
    if isequal(study(a), {'SC'})
        pmStudyInfo.StudyName{a}            = 'SmartCare';
        pmStudyInfo.MeasurementMatFile{a}   = 'smartcaredata.mat';
        pmStudyInfo.ClinicalMatFile{a}      = 'clinicaldata.mat';
        %pmStudyInfo.AMPredMatFile{a}        = 'SCvEM4_sig4_mu4_ca2_sm2_rm4_ob1_im1_cm2_mm3_mo25_dw25_ex-28_obj1.40679241.mat';
        %pmStudyInfo.AMPredMatFile{a}        = 'SCvEMMC_sig4_mu4_ca2_sm2_rm4_im1_cm2_mm4_mo25_dw25_nl1_rs4_ds2_ct5_ni84_ex-28_obj1.37704476.mat';
        %pmStudyInfo.AMPredMatFile{a}        = 'SCvEMMC_gp10_lm2_sig4_mu4_ca2_sm2_rm4_in1_im1_cm2_mm4_mo20_dw25_nl3_rs36_ds1_ct3_scP_vs0_ni200_ex-21-28-26_obj1.35851972.mat';
        pmStudyInfo.AMPredMatFile{a}        = 'SCvEMMC_gp10_lm1_sig4_mu4_ca2_sm2_rm4_in1_im1_cm2_mm4_mo25_dw25_nl1_rs4_ds1_ct5_scA_vs0_vm0.0_ni61_ex-30_obj1.39546370.mat';
        %pmStudyInfo.AMPredMatFile{a}        = 'SCvEMMC_gp10_lm1_sig4_mu4_ca2_sm2_rm4_in1_im1_cm2_mm4_mo25_dw25_nl1_rs4_ds1_ct5_scA_vs1_vm0.3_ni200_ex-30_obj1.29439794.mat';
    elseif isequal(study(a), {'TM'})
        pmStudyInfo.StudyName{a}            = 'TeleMed';
        pmStudyInfo.MeasurementMatFile{a}   = 'telemeddata.mat';
        pmStudyInfo.ClinicalMatFile{a}      = 'telemedclinicaldata.mat';
        pmStudyInfo.AMPredMatFile{a}        = 'TMvEM4_sig4_mu4_ca2_sm2_rm4_ob1_im1_cm2_mm3_mo25_dw25_ex-28_obj1.36073688.mat';
    else
        fprintf('Unknown study\n')
        return;
    end
end

end