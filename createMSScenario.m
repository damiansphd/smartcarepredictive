function [pmMSFeatureIndex, pmMSNormFeatures, mslabels, pmMSAMPred, pmMSAntibiotics, pmMSPatient, ...
          pmMSPatientSplit, pmMSRawDatacube, pmMSInterpDatacube, pmMSInterpVolcube, ...
          pmMSMucube, pmMSSigmacube, pmMSMuNormcube, pmMSSigmaNormcube] ...
    = createMSScenario(pmAMPred, pmAntibiotics, pmPatients, pmPatientSplit, ...
            pmPatientMeasStats, pmRawDatacube, pmOverallStats, ...
            pmMucube, pmSigmacube, pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
            msscenario, pmFeatureParamsRow, pmModelParamsRow, measures, nmeasures)

% createMSScenario - creates the required feature and labels tables for a
% given example (patient id + from and to dates) and missingness scenario
% (mstype)

% set common variables
featdur    = pmFeatureParamsRow.featureduration;
normwind   = pmFeatureParamsRow.normwindow;

% override this for the creation of the base features. reset back for the
% full features later
tmpdatefeat = pmFeatureParamsRow.datefeat;
pmFeatureParamsRow.datefeat = 3;

pnbr       = msscenario.PatientNbr;
fromdn     = msscenario.ScaledDateNumFrom - featdur - normwind + 1;
todn       = msscenario.ScaledDateNumTo;
mstype     = msscenario.ScenarioType;
msfreq     = msscenario.Frequency;
msduration = msscenario.Duration;


% extract data just for this patient
pmMSPatient      = pmPatients(pmPatients.PatientNbr == pnbr, :);
pmMSAMPred       = pmAMPred(pmAMPred.PatientNbr == pnbr, :);
pmMSAntibiotics  = pmAntibiotics(pmAntibiotics.PatientNbr == pnbr, :);
pmMSPatientSplit = pmPatientSplit(pmPatientSplit.PatientNbr == pnbr, :);
pmMSPatientMeasStats = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr, :);

% reset patient nbr
msnpatients    = 1;
pmMSPatient.PatientNbr(:)          = 1;
pmMSAMPred.PatientNbr(:)           = 1;
pmMSAntibiotics.PatientNbr(:)      = 1;
pmMSPatientSplit.PatientNbr(:)     = 1;
pmMSPatientMeasStats.PatientNbr(:) = 1;

% reset patient dates
pmMSPatient.RelLastMeasdn = todn - fromdn + 1;
pmMSPatient.LastMeasdn    = pmMSPatient.FirstMeasdn   + todn - 1;
pmMSPatient.FirstMeasdn   = pmMSPatient.FirstMeasdn   + fromdn - 1;
pmMSPatient.LastMeasDate  = pmMSPatient.FirstMeasDate + days(todn - 1);
pmMSPatient.FirstMeasDate = pmMSPatient.FirstMeasDate + days(fromdn - 1);

pmMSAMPred.IVScaledDateNum     = pmMSAMPred.IVScaledDateNum     - fromdn + 1;
pmMSAMPred.IVScaledStopDateNum = pmMSAMPred.IVScaledStopDateNum - fromdn + 1;
pmMSAMPred.Pred                = pmMSAMPred.Pred                - fromdn + 1;
pmMSAMPred.RelLB1              = pmMSAMPred.RelLB1              - fromdn + 1;
pmMSAMPred.RelUB1              = pmMSAMPred.RelUB1              - fromdn + 1;
if pmMSAMPred.RelLB2 ~= -1
    pmMSAMPred.RelLB2          = pmMSAMPred.RelLB2              - fromdn + 1;
    pmMSAMPred.RelUB2          = pmMSAMPred.RelUB2              - fromdn + 1;
end

pmMSAntibiotics.RelStartdn = pmMSAntibiotics.RelStartdn - fromdn + 1;
pmMSAntibiotics.RelStopdn  = pmMSAntibiotics.RelStopdn  - fromdn + 1;

msmaxdays = pmMSPatient.RelLastMeasdn;

% extract relevant raw data for scenario
pmMSRawDatacube       = pmRawDatacube(pnbr, fromdn:todn, :);

pmMSMucube            = pmMucube(pnbr, fromdn:todn, :);
pmMSSigmacube         = pmSigmacube(pnbr, fromdn:todn, :);
pmMSMuNormcube        = pmMuNormcube(pnbr, fromdn:todn, :);
pmMSSigmaNormcube     = pmSigmaNormcube(pnbr, fromdn:todn, :);
pmMSBuckMuNormcube    = pmBuckMuNormcube(pnbr, fromdn:todn, :, :);
pmMSBuckSigmaNormcube = pmBuckSigmaNormcube(pnbr, fromdn:todn, :, :);


switch mstype
    case 1
        fprintf('Scenario Type 1: Recreating identical features\n');
        % nothing to do here
        
    case 2
        fprintf('Scenario Type 2: Removing points with frequency - every %d days\n', msfreq);
        
    case 3
        fprintf('Scenario Type 3: Removing successive points of duration %d days\n', msduration);

    case 4
        fprintf('Scenario Type 4: Removing specific pattern of data\n');
end

% interpolate missing data
tic
fprintf('Re-Interpolating\n');
[pmMSInterpDatacube] = createPMInterpDatacube(pmMSPatient, pmMSRawDatacube, msnpatients, msmaxdays, nmeasures); 
toc
fprintf('\n');

% handle missing features (eg no sleep measures for a given patient)
tic
fprintf('Re-handling missing features\n');
[pmMSInterpDatacube] = handleMissingFeatures(pmMSPatient, pmMSInterpDatacube, pmOverallStats, msnpatients, msmaxdays, nmeasures); 
toc
fprintf('\n');

[~, ~, ~, ~, ~, ~, ~, ~, pmMSInterpDatacube, pmMSInterpVolcube, mvolstats, pmInterpSegVolcube, ...
    pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ntilepoints] ...
    = createPreBaseFeat(pmMSPatient, msnpatients, pmOverallStats, pmMSPatientMeasStats, ...
    pmMSInterpDatacube, msmaxdays, measures, nmeasures, pmFeatureParamsRow, 1);

% create  base feature/label examples from the data
% need to add setting and using of the measures mask
tic
fprintf('Creating Base Features and Labels\n');
[pmMSFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
    pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
    pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, ...
    pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels] ...
    = createBaseFeaturesAndLabelsFcn(pmMSPatient, pmMSAntibiotics, pmMSAMPred, ...
        pmMSInterpDatacube, pmMSInterpVolcube, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ...
        pmMSMuNormcube, pmMSSigmaNormcube, pmMSBuckMuNormcube, pmMSBuckSigmaNormcube, ...
        pmMSMucube, pmMSSigmacube, ...
        measures, nmeasures, msnpatients, msmaxdays, ...
        pmFeatureParamsRow.featureduration, pmFeatureParamsRow.normwindow, pmFeatureParamsRow);
toc
fprintf('\n');

% reset date feature value
pmFeatureParamsRow.datefeat = tmpdatefeat;

% then create full features and labels
[pmMSNormFeatures, pmMSNormFeatNames] = createFullFeaturesAndLabelsFcn(pmRawMeasFeats, pmBuckMeasFeats, pmRangeFeats, pmVolFeats, ...
        pmAvgSegFeats, pmVolSegFeats, pmCChangeFeats, pmPMeanFeats, pmPStdFeats, ...
        pmBuckPMeanFeats, pmBuckPStdFeats, pmDateFeats, pmDemoFeats, pmFeatureParamsRow, measures, nmeasures);

[mslabels] = setLabelsForLabelMethod(pmModelParamsRow.labelmethod, pmIVLabels, pmExLabels, pmABLabels, pmExLBLabels, pmExABLabels, pmExABxElLabels);


end

