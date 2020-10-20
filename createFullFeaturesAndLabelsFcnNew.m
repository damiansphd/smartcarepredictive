function [pmNormFeatures, pmNormFeatNames, measures] = createFullFeaturesAndLabelsFcnNew(pmRawMeasFeats, ...
                pmMSFeats, pmVolFeats, pmPMeanFeats, featureparamsrow, measures, nmeasures)

% createFullFeaturesAndLabelsFcnNew - function to apply measures mask to base
% features and create the final normalised feature array

% set various variables
[featureduration, ~, ~] = setBaseNumMeasAndFeaturesNew(featureparamsrow, nmeasures);

% set measures masks for the particular feature combination requested
tic
fprintf('Setting measures masks for features\n');
[measures] = preprocessMeasuresMaskNew(measures, nmeasures, featureparamsrow);

fprintf('Extracting relevant features for measures\n');
rawmeasmask    = logical(duplicateMeasuresByFeatures(measures.RawMeas', featureduration, nmeasures));
msmask         = logical(duplicateMeasuresByFeatures(measures.MSMeas', featureduration, nmeasures));
volmask        = logical(duplicateMeasuresByFeatures(measures.Volatility', (featureduration - 1), nmeasures));
pmeanmask      = logical(measures.PMean');

pmNormFeatures = [pmRawMeasFeats(:, rawmeasmask), ...
                  pmMSFeats(:, msmask), ...
                  pmVolFeats(:, volmask), ...
                  pmPMeanFeats(:, pmeanmask)];

pmNormFeatNames = [reshape(cellstr(cellstr('RM-' + string(measures.ShortName(logical(measures.RawMeas)))    + '-') + string(featureduration:-1:1))',            [1 sum(measures.RawMeas)    * featureduration]           ), ...
                   reshape(cellstr(cellstr('MS-' + string(measures.ShortName(logical(measures.MSMeas)))     + '-') + string(featureduration:-1:1))',            [1 sum(measures.MSMeas)     * featureduration]           ), ...
                   reshape(cellstr(cellstr('VO-' + string(measures.ShortName(logical(measures.Volatility))) + '-') + string((featureduration - 1):-1:1))',      [1 sum(measures.Volatility) * (featureduration - 1)]     ), ...
                   reshape(        cellstr('PM-' + string(measures.ShortName(logical(measures.PMean)))      )',                                                 [1 sum(measures.PMean)]                                  )];

toc
fprintf('\n');

end

