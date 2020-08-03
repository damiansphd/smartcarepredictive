function [pmFeatureIndex, pmNormFeatures, ...
    pmIVLabels, pmExLabels, pmABLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels, ...
    pmMSRawDatacube, pmMSDatacube, pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, ...
    pmBuckSigmaNormcube, muntilepoints, sigmantilepoints, pmInterpDatacube, pmInterpVolcube, mvolstats] ...
    = createOvMSScenarionew(pmAMPred, pmAntibiotics, pmPatients, pmPatientMeasStats, pmMSRawDatacube, ...
        pmOverallStats, msscenario, pmFeatureParamsRow, pmModelParamsRow, measures, nmeasures, npatients, maxdays)

% createOvMSScenarionew - creates the required feature and labels tables for a
% overall dataset for a given missingness scenario (mstype)

% override this for the creation of the base features. reset back for the
% full features later
tmpdatefeat = pmFeatureParamsRow.datefeat;
pmFeatureParamsRow.datefeat = 3;

mstype      = msscenario.ScenarioType;
msmmask     = msscenario.MMask;
msmmasktext = msscenario.MMaskText{1};
msfreq      = msscenario.Frequency;
msduration  = msscenario.Duration;
mspct       = msscenario.Percentage;

[remidx] = convertMeasureCombToMask(msmmask, measures, nmeasures);

switch mstype
    case 1
        fprintf('Scenario Type 1: Recreating identical features\n');
        % nothing to do here
    case 2
        fprintf('Scenario Type 2: Removing all points for measures mask %d:%s\n', msmmask, msmmasktext);
        pmMSRawDatacube(:, :, remidx) = nan;
    case 3
        fprintf('Scenario Type 3: Removing points for measures mask %d:%s with frequency - every %d days\n', msmmask, msmmasktext, msfreq);
        nreps = ceil(maxdays/msfreq);
        freqidx = false(1, msfreq);
        freqidx(1) = true;
        dateidx = repmat(freqidx, 1, nreps);
        dateidx = dateidx(1:maxdays);
        pmMSRawDatacube(:, dateidx, remidx) = nan;
    case 4
        fprintf('Scenario Type 4: Removing points for measures mask %d:%s for %d%% at random\n', msmmask, msmmasktext, mspct);
        for p = 1:npatients
            pmaxdays = pmPatients.RelLastMeasdn(p);
            nrem = ceil(pmaxdays * mspct / 100);
            rng(p);
            posarray = randperm(pmaxdays, nrem);
            dateidx = false(1, pmaxdays);
            dateidx(posarray) = true;
            pmMSRawDatacube(p, dateidx, remidx) = nan;
        end
    case 5
        fprintf('Scenario Type 5: Removing points for measures mask %d:%s for successive points of duration %d days\n', msmmask, msmmasktext, msduration);
        % leave this one for now
end

% interpolate missing data
tic
fprintf('Re-Interpolating\n');
[pmInterpDatacube]    = createPMInterpDatacube(pmPatients, pmMSRawDatacube, npatients, maxdays, nmeasures); 
[pmLimInterpDatacube] = createPMLimInterpDatacube(pmPatients, pmRawDatacube, npatients, nmeasures);
toc
fprintf('\n');

% handle missing features (eg no sleep measures for a given patient)
tic
fprintf('Re-handling missing features\n');
[pmInterpDatacube] = handleMissingFeatures(pmPatients, pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures); 
toc
fprintf('\n');

[pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
muntilepoints, sigmantilepoints, pmDatacube, pmInterpDatacube, pmInterpVolcube, mvolstats, pmInterpSegVolcube, ...
    pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ntilepoints, pmMSDatacube] ...
    = createPreBaseFeat(pmPatients, npatients, pmOverallStats, pmPatientMeasStats, ...
    pmMSRawDatacube, pmInterpDatacube, pmLimInterpDatacube, maxdays, measures, nmeasures, pmFeatureParamsRow);

% create  base feature/label examples from the data
% need to add setting and using of the measures mask
tic
fprintf('Creating Base Features and Labels\n');
[pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
    pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
    pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, ...
    pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels] ...
    = createBaseFeaturesAndLabelsFcn(pmPatients, pmAntibiotics, pmAMPred, ...
        pmInterpDatacube, pmInterpVolcube, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, pmMSDatacube, ...
        pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
        pmMucube, pmSigmacube, ...
        measures, nmeasures, npatients, maxdays, ...
        pmFeatureParamsRow.featureduration, pmFeatureParamsRow.normwindow, pmFeatureParamsRow);
toc
fprintf('\n');

% reset date feature value
pmFeatureParamsRow.datefeat = tmpdatefeat;

% then create full features and labels
[pmNormFeatures, pmNormFeatNames, measures] = createFullFeaturesAndLabelsFcn(pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
        pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
        pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, pmFeatureParamsRow, measures, nmeasures);

end

