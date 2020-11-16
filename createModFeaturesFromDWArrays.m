function [pmNormFeatures, pmNormFeatNames, pmMuIndex, pmSigmaIndex, ...
        pmNormDataWinArray, pmInterpNormDataWinArray, pmRawMeasWinArray, pmMSWinArray, ...
        pmVolWinArray, pmPMeanWinArray, totalvolwin, measures] = createModFeaturesFromDWArrays(pmDataWinArray, ...
            pmOverallStats, nexamples, measures, nmeasures, pmModFeatParamsRow)

% createModFeaturesFromDWArrays - takes the Data Window arrays as inputs,
% and creates the normalised features for input to the model, along with
% the various run parameter processing (normalisation, interpolation,
% smoothing etc)

datawin = pmModFeatParamsRow.datawinduration;
normwin = pmModFeatParamsRow.normwinduration;
totalwin = datawin + normwin;

% 2. normalise data window array + create pmMuIndex + create pmPMeanWinArray
tic
[pmNormDataWinArray, pmMuIndex, pmSigmaIndex, pmPMeanWinArray] = createNormDataWinArray(pmDataWinArray, ...
        pmOverallStats, nexamples, measures, nmeasures, totalwin, normwin, pmModFeatParamsRow.StudyDisplayName);
toc

% 3. create missingness features
tic
pmMSWinArray = createMSWinArray(pmNormDataWinArray, nexamples, totalwin, nmeasures, pmModFeatParamsRow);
toc

% 4. interpolate/smooth replace with const values and create VolWinArray
tic
if pmModFeatParamsRow.interpmethod == 0
    fprintf('Creating volatility features\n');
    [pmVolWinArray, totalvolwin] = createVolWinArray(pmNormDataWinArray, nexamples, totalwin, nmeasures);

    % populate nan's with missingness constant
    fprintf('Populating missing values with const %d\n', pmModFeatParamsRow.msconst);
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

end

