function [pmNormFeatures, pmNormFeatNames, measures] = createModelFeaturesFcn(pmRawMeasWinArray, ...
                pmMSWinArray, pmVolWinArray, pmPMeanWinArray, pmModFeatParamsRow, nexamples, totalvolwin, measures, nmeasures)

% createModelFeaturesFcn - create the set of normalised features from the
% various data window arrays

% set various variables
datawin = pmModFeatParamsRow.datawinduration;
normwin = pmModFeatParamsRow.normwinduration;
totalwin = datawin + normwin;
volwin  = totalvolwin - normwin;

% set measures masks for the particular feature combination requested
fprintf('Creating feature arrays\n');
pmRawMeasFeats = zeros(nexamples, nmeasures * datawin);
pmMSFeats      = zeros(nexamples, nmeasures * datawin);
pmVolFeats     = zeros(nexamples, nmeasures * volwin );

for m = 1:nmeasures
        pmRawMeasFeats(:, ((m-1) * datawin) + 1:(m * datawin)) = pmRawMeasWinArray(:, (normwin + 1):totalwin,    m);
        pmMSFeats(     :, ((m-1) * datawin) + 1:(m * datawin)) = pmMSWinArray(     :, (normwin + 1):totalwin,    m);
        pmVolFeats(    :, ((m-1) * volwin)  + 1:(m * volwin))  = pmVolWinArray(    :, (normwin + 1):totalvolwin, m);
end
pmPMeanFeats = pmPMeanWinArray;

fprintf('Setting measures masks for features\n');
[measures] = preprocessMeasuresMaskNew(measures, nmeasures, pmModFeatParamsRow);

fprintf('Extracting relevant features for measures\n');
rawmeasmask    = logical(duplicateMeasuresByFeatures(measures.RawMeas',    datawin, nmeasures));
msmask         = logical(duplicateMeasuresByFeatures(measures.MSMeas',     datawin, nmeasures));
volmask        = logical(duplicateMeasuresByFeatures(measures.Volatility', volwin,  nmeasures));
pmeanmask      = logical(measures.PMean');


pmNormFeatures = [pmRawMeasFeats(:, rawmeasmask), ...
                  pmMSFeats(:, msmask), ...
                  pmVolFeats(:, volmask), ...
                  pmPMeanFeats(:, pmeanmask)];

pmNormFeatNames = [reshape(cellstr(cellstr('RM-' + string(measures.ShortName(logical(measures.RawMeas)))    + '-') + string(datawin:-1:1))', [1 sum(measures.RawMeas)    * datawin] ), ...
                   reshape(cellstr(cellstr('MS-' + string(measures.ShortName(logical(measures.MSMeas)))     + '-') + string(datawin:-1:1))', [1 sum(measures.MSMeas)     * datawin] ), ...
                   reshape(cellstr(cellstr('VO-' + string(measures.ShortName(logical(measures.Volatility))) + '-') + string(volwin :-1:1))', [1 sum(measures.Volatility) * volwin]  ), ...
                   reshape(        cellstr('PM-' + string(measures.ShortName(logical(measures.PMean)))      )',                              [1 sum(measures.PMean)]                )];

end

