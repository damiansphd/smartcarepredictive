clear; close all; clc;

basedir = setBaseDir();
subfolder = 'DataFiles';
[fv1name, validresponse] = selectFeatVer();
if ~validresponse
    return
end

[modfeatparamfile, ~, ~, validresponse] = selectModelFeatureParameters(fv1name);
if ~validresponse
    return
end

modfeatparamfile = strcat(modfeatparamfile, '.xlsx');

pmModFeatureParams = readtable(fullfile(basedir, subfolder, modfeatparamfile));

fprintf('Creating Model feature and label files for %2d permutations of parameters\n', size(pmModFeatureParams,1));
fprintf('\n');

for rp = 1:size(pmModFeatureParams,1)
    pmModFeatParamsRow = pmModFeatureParams(rp,:);
    outputfilename = generateFileNameFromModFeatureParams(pmModFeatParamsRow);
    fprintf('%2d. Generating model features and labels for %s\n', rp, outputfilename);
    fprintf('-------------------------------------------------------------------------------\n');
    
    % 1. load data window arrays
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    datawinfile = generateFileNameFromDataWinParams(pmModFeatParamsRow);
    fprintf('Loading data window array data: %s\n', datawinfile);
    load(fullfile(basedir, subfolder, strcat(datawinfile, '.mat')));
    toc
    fprintf('\n');
    
    datawin = pmModFeatParamsRow.datawinduration;
    normwin = pmModFeatParamsRow.normwinduration;
    totalwin = datawin + normwin;
    
    % 2. normalise data window array + create pmMuIndex + create pmPMeanWinArray
    tic
    [pmNormDataWinArray, pmMuIndex, pmSigmaIndex, pmPMeanWinArray] = createNormDataWinArray(pmDataWinArray, ...
            pmOverallStats, nexamples, measures, nmeasures, totalwin, normwin, pmModFeatParamsRow.StudyDisplayName);
    toc
    fprintf('\n');
    
    % 3. create missingness features
    tic
    pmMSWinArray = createMSWinArray(pmNormDataWinArray, nexamples, totalwin, nmeasures, pmModFeatParamsRow);
    toc
    fprintf('\n');
    
    % 4. interpolate/smooth replace with const values and create VolWinArray
    tic
    if pmModFeatParamsRow.interpmethod == 0
        fprintf('Creating volatility features\n');
        [pmVolWinArray, totalvolwin] = createVolWinArray(pmNormDataWinArray, nexamples, totalwin, nmeasures);
        
        % populate nan's with missingness constant
        fprintf('Populating missing values with const %d\n', basefeatparamsrow.msconst);
        pmInterpNormDataWinArray = pmNormDataWinArray;
        pmInterpNormDataWinArray(isnan(pmInterpNormDataWinArray)) = pmModFeatParamsRow.msconst;
        pmRawMeasWinArray = pmInterpNormDataWinArray;
        pmVolWinArray(isnan(pmVolWinArray)) = pmModFeatParamsRow.msconst;
        
    elseif pmModFeatParamsRow.interpmethod == 1 
         % interpolate raw features
        fprintf('Populating missing values with interpolation\n');
        pmInterpNormDataWinArray = interpolateDataWin(pmNormDataWinArray, ...
                pmMuIndex, pmSigmaIndex, pmOverallStats, nexamples, totalwin, nmeasures);
    
        pmRawMeasWinArray = createSmoothDataWin(pmInterpNormDataWinArray, ...
                measures, nmeasures, nexamples, pmModFeatParamsRow.smfunction, ...
                pmModFeatParamsRow.smwindow, pmModFeatParamsRow.smlength);

        fprintf('Creating volatility features with interpolation\n');
        [pmVolWinArray, totalvolwin] = createVolWinArray(pmRawMeasWinArray, nexamples, totalwin, nmeasures);
    else
        fprintf('Interp method %d not allowed - only 0.No and 1.Full interpolation methods allowed\n', basefeatparamsrow.interpmethod); 
    end
    toc
    fprintf('\n');
    
    % 5. filter by measures, create normalised features for input to model
    tic
    [pmNormFeatures, pmNormFeatNames, measures] = createModelFeaturesFcn(pmRawMeasWinArray, ...
                pmMSWinArray, pmVolWinArray, pmPMeanWinArray, pmModFeatParamsRow, nexamples, totalvolwin, measures, nmeasures);
    toc
    fprintf('\n');
    
    % 6. save output variables
    tic
    basedir = setBaseDir();
    subfolder = 'MatlabSavedVariables';
    outputfilename = sprintf('%s.mat',outputfilename);
    fprintf('Saving output variables to file %s\n', outputfilename);
    save(fullfile(basedir, subfolder, outputfilename), ...
        'studynbr', 'studydisplayname', 'pmStudyInfo', ...
        'pmPatients', 'npatients', 'pmAntibiotics', 'pmAMPred', ...
        'pmOverallStats', 'pmPatientMeasStats', 'maxdays', 'measures', 'nmeasures', ...
        'pmRawDatacube', 'pmModFeatParamsRow', ...
        'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
        'pmMuIndex', 'pmSigmaIndex', ...
        'pmNormDataWinArray', 'pmInterpNormDataWinArray', ...
        'pmRawMeasWinArray', 'pmMSWinArray', 'pmVolWinArray', 'pmPMeanWinArray', 'totalvolwin', ...
        'pmNormFeatures', 'pmNormFeatNames');
    toc
    fprintf('\n');
end

beep on;
beep;

