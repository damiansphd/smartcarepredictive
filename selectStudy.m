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

pmStudyInfo = table('Size',[size(study,1), 6], 'VariableTypes', {'cell', 'cell', 'double', 'cell', 'cell', 'cell'}, ...
    'VariableNames', {'Study', 'StudyName', 'Offset', 'MeasurementMatFile', 'ClinicalMatFile', 'AMPredMatFile'});

for a = 1:size(study,1)
    pmStudyInfo.Study(a) = study(a);
    if isequal(study(a), {'SC'})
        pmStudyInfo.StudyName{a}            = 'SmartCare';
        pmStudyInfo.MeasurementMatFile{a}   = 'smartcaredata.mat';
        pmStudyInfo.ClinicalMatFile{a}      = 'clinicaldata.mat';
        pmStudyInfo.AMPredMatFile{a}        = 'SCvEM4_sig4_mu4_ca2_sm2_rm4_ob1_im1_cm2_mm3_mo25_dw25_ex-28_obj1.40679241.mat';
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