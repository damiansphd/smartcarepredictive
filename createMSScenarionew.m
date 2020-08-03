function [pmMSFeatureIndex, pmMSNormFeatures, mslabels, pmMSRawDatacube, pmMSDatacube, pmMSInterpDatacube, pmMSInterpVolcube, mvolstats] ...
    = createMSScenarionew(pmMSAMPred, pmMSAntibiotics, pmMSPatient, pmMSPatientMeasStats, ...
        pmMSRawDatacube, pmOverallStats, pmMSMucube, pmMSSigmacube, pmMSMuNormcube, pmMSSigmaNormcube, ...
        pmMSBuckMuNormcube, pmMSBuckSigmaNormcube, ...
        msscenario, pmFeatureParamsRow, pmModelParamsRow, measures, nmeasures, msnpatients, msmaxdays)

% createMSScenarionew - creates the required feature and labels tables for a
% given example (patient id  and missingness scenario
% (mstype)

% override this for the creation of the base features. reset back for the
% full features later
tmpdatefeat = pmFeatureParamsRow.datefeat;
pmFeatureParamsRow.datefeat = 3;

mspnbr      = msscenario.PatientNbr;
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
        pmMSRawDatacube(1, :, remidx) = nan;
    case 3
        fprintf('Scenario Type 3: Removing points for measures mask %d:%s with frequency - every %d days\n', msmmask, msmmasktext, msfreq);
        nreps = ceil(msmaxdays/msfreq);
        freqidx = false(1, msfreq);
        freqidx(1) = true;
        dateidx = repmat(freqidx, 1, nreps);
        dateidx = dateidx(1:msmaxdays);
        pmMSRawDatacube(1,dateidx, remidx) = nan;
    case 4
        fprintf('Scenario Type 4: Removing points for measures mask %d:%s for %d%% at random\n', msmmask, msmmasktext, mspct);
        nrem = ceil(msmaxdays * mspct / 100);
        rng(mspnbr);
        posarray = randperm(msmaxdays, nrem);
        dateidx = false(1, msmaxdays);
        dateidx(posarray) = true;
        pmMSRawDatacube(1,dateidx, remidx) = nan;
    case 5
        fprintf('Scenario Type 5: Removing points for measures mask %d:%s for successive points of duration %d days\n', msmmask, msmmasktext, msduration);
        % leave this one for now
end

% interpolate missing data
tic
fprintf('Re-Interpolating\n');
[pmMSInterpDatacube]   = createPMInterpDatacube(pmMSPatient, pmMSRawDatacube, msnpatients, msmaxdays, nmeasures);
[pmMSLimInterpDatacube] = createPMLimInterpDatacube(pmMSPatient, pmMSRawDatacube, msnpatients, nmeasures);
toc
fprintf('\n');

% handle missing features (eg no sleep measures for a given patient)
tic
fprintf('Re-handling missing features\n');
[pmMSInterpDatacube] = handleMissingFeatures(pmMSPatient, pmMSInterpDatacube, pmOverallStats, msnpatients, msmaxdays, nmeasures); 
toc
fprintf('\n');

[~, ~, ~, ~, ~, ~, ~, ~, ~, pmMSInterpDatacube, pmMSInterpVolcube, mvolstats, pmInterpSegVolcube, ...
    pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ntilepoints, pmMSDatacube] ...
    = createPreBaseFeat(pmMSPatient, msnpatients, pmOverallStats, pmMSPatientMeasStats, ...
    pmMSRawDatacube, pmMSInterpDatacube, pmMSLimInterpDatacube, msmaxdays, measures, nmeasures, pmFeatureParamsRow);

% create  base feature/label examples from the data
% need to add setting and using of the measures mask
tic
fprintf('Creating Base Features and Labels\n');
[pmMSFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
    pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
    pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, ...
    pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels] ...
    = createBaseFeaturesAndLabelsFcn(pmMSPatient, pmMSAntibiotics, pmMSAMPred, ...
        pmMSInterpDatacube, pmMSInterpVolcube, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, pmMSDatacube, ...
        pmMSMuNormcube, pmMSSigmaNormcube, pmMSBuckMuNormcube, pmMSBuckSigmaNormcube, ...
        pmMSMucube, pmMSSigmacube, ...
        measures, nmeasures, msnpatients, msmaxdays, ...
        pmFeatureParamsRow.featureduration, pmFeatureParamsRow.normwindow, pmFeatureParamsRow);
toc
fprintf('\n');

% reset date feature value
pmFeatureParamsRow.datefeat = tmpdatefeat;

% then create full features and labels
[pmMSNormFeatures, pmMSNormFeatNames, measures] = createFullFeaturesAndLabelsFcn(pmRawMeasFeats, pmMSFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
        pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
        pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, pmFeatureParamsRow, measures, nmeasures);

[mslabels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmIVLabels, pmExLabels, pmABLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels);


end

