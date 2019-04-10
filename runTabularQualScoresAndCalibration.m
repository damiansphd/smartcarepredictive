clear; close all; clc;

[~, studydisplayname, ~] = selectStudy();
[lb, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
if lb < 5
    fprintf('Chosen label method has multiple prediction days which is not supported by this script\n');
    return
end
labelstring = sprintf('lm%d', lb);

basedir   = setBaseDir();
subfolder = 'MatlabSavedVariables';
bsqsfile  = selectBSQualScores(studydisplayname, labelstring);

tic
fprintf('Loading Bootstrap Quality Scores - %s\n', bsqsfile);
load(fullfile(basedir, subfolder, bsqsfile));
toc
fprintf('\n');

tic
pmBSModelQualityScores = [];
qualmeasures = {'PRAUC'; 'ROCAUC'; 'Acc'; 'PosAcc'; 'NegAcc'};
nqualmeas = size(qualmeasures, 1);

[pmBSAllQSTable, pmBSAllQSArray, pmCalibTable ] = createTabularBSQSResultsAndCalibration(pmBSAllQS, ncombinations, nbssamples, ...
    qualmeasures, nqualmeas, basedir, subfolder, bsqsfile);

pmBSQSRankArray   = nan(ncombinations, nqualmeas, nbssamples);
rank = (1:ncombinations)';

for i = 1:nqualmeas
    for n = 1:nbssamples
        [~, sortidx] = sort(pmBSAllQSArray(:,i, n), 'descend');
        %for c = 1:ncombinations
        %    pmBSQSRankArray(sortidx(c), i, n) = c;
        %end
        [~, rankidx] = sort(sortidx);
        pmBSQSRankArray(:, i, n) = rankidx;
    end
end

for i = 1:nqualmeas
    for c = 1:ncombinations
        pmBSAllQSTable{c, {sprintf('%s_AvR',qualmeasures{i})}}   = mean(pmBSQSRankArray(c, i, :));
        pmBSAllQSTable{c, {sprintf('%sBestR',qualmeasures{i})}}  = min(pmBSQSRankArray(c, i, :));
        pmBSAllQSTable{c, {sprintf('%sWorstR',qualmeasures{i})}} = max(pmBSQSRankArray(c, i, :));
    end
end
toc
fprintf('\n');

tic
basedir = setBaseDir();
subfolder = 'ExcelFiles';
outputfilename = strrep(bsqsfile, '.mat', '.xlsx');

% save bootstrap quality scores table
fprintf('Saving bootstrap quality scores to excel file %s\n', outputfilename);
writetable(pmBSAllQSTable, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'BS Model Quality Scores');

% save model calibration table
outputfilename = strrep(outputfilename, 'BSQ', 'Calib');
fprintf('Saving model calibration to excel file %s\n', outputfilename);
writetable(pmCalibTable, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'ModelCalibration');

toc
fprintf('\n');

