function [pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels] ...
        = createBaseFeaturesAndLabelsFcnNew(pmPatients, pmAntibiotics, pmAMPred, ...
            pmRawDatacube, pmMuNormcube, pmMucube, pmSigmacube, pmOverallStats, ...
            measures, nmeasures, npatients, maxdays, maxfeatureduration, maxnormwindow, basefeatparamsrow)

% createBaseFeaturesAndLabelsFcnNew - function to create the base sets of features and
% labels for each example in the overall data set - for all measures for a given 
% feature duration, normalisation method and smoothing method.

% first calculate total number of examples (patients * run days) to
% pre-allocate tables/arrays
nexamples = 0;
for p = 1:npatients
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p, :);
    pampred = pmAMPred(pmAMPred.PatientNbr == p, :);
    for d = (maxfeatureduration + maxnormwindow):maxdays
        %if d <= (pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1) && ...
        %   (~any(pabs.StartDate <= pmPatients.FirstMeasDate(p) + days(d - 1) & ...
        %         pabs.StopDate  >= pmPatients.FirstMeasDate(p) + days(d - 1)))
        if d <= (pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1) && ...
           (~any(pabs.RelStartdn         <= d & pabs.RelStopdn              >= d)) && ...
           (~any(pampred.IVScaledDateNum <= d & pampred.IVScaledStopDateNum >= d))
            nexamples = nexamples + 1;
        end
    end
end

% set various variables
[featureduration, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures] = setBaseNumMeasAndFeaturesNew(basefeatparamsrow, nmeasures);

example = 1;

[pmFeatureIndex, pmMuIndex, pmSigmaIndex, pmRawMeasFeats, pmMSFeats, pmVolFeats, pmPMeanFeats, pmExABxElLabels] ...
        = createFeatureAndLabelArraysNew(nexamples, nmeasures, nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures); 

fprintf('Processing data for patients\n');
for p = 1:npatients
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p, :);
    pampred = pmAMPred(pmAMPred.PatientNbr == p, :);
    
    for d = (maxfeatureduration + maxnormwindow):maxdays
        % only include this run day for the period between first and last measurement for
        % patient for days when the patient wasn't on antibiotics (both from raw AB treatment 
        % data plus grouped AB treatment data from intervention list.
        
        if d <= (pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1) && ...
           (~any(pabs.RelStartdn         <= d & pabs.RelStopdn              >= d)) && ...
           (~any(pampred.IVScaledDateNum <= d & pampred.IVScaledStopDateNum >= d))   
             
            pmFeatureIndex.PatientNbr(example) = pmPatients.PatientNbr(p);
            pmFeatureIndex.Study(example)      = pmPatients.Study(p);
            pmFeatureIndex.ID(example)         = pmPatients.ID(p);
            pmFeatureIndex.CalcDatedn(example) = d;
            pmFeatureIndex.CalcDate(example)   = pmPatients.FirstMeasDate(p) + days(d - 1);
            
            pmFeatureIndex.ScenType(example)    = 0;
            pmFeatureIndex.Scenario(example)    = {'Actual'};
            pmFeatureIndex.BaseExample(example) = 0;
            pmFeatureIndex.Measure{example}     = '';
            pmFeatureIndex.Percentage(example)  = 0;
            pmFeatureIndex.Frequency(example)   = 0;
            pmFeatureIndex.MSExample(example)   = 0;
            
            pmMuIndex(example, :)    = reshape(pmMucube(p, d - featureduration + 1, :), [1 nmeasures]);
            pmSigmaIndex(example, :) = reshape(pmSigmacube(p, d - featureduration + 1, :), [1 nmeasures]);
                  
            % 1) Raw features
            pmRawMeasFeats(example, :) = reshape(pmRawDatacube(p, (d - featureduration + 1): d, :), [1, nrawfeatures]);
            
            % 2) patient mean features
            pmPMeanFeats(example, :) = reshape(pmMuNormcube(p, d - featureduration + 1, :), [1, npmeanfeatures]);
                
            % Labels: Labels for Exacerbation period (ie between predicted
            % ex start and treatment date) but exclude elective treatments
            pmExABxElLabels(example, :) = checkInExStartToTreatmentWindow(pmFeatureIndex(example, :), ...
                    pampred, pmAntibiotics(pmAntibiotics.PatientNbr == p, :), 'xEl');

            example = example + 1;
        end
    end
    fprintf('.');
    if (p/50) == round(p/50)
        fprintf('\n');
    end
end
fprintf('\n');

fprintf('Normalising Feature Arrays\n');

munorm         = duplicateMeasuresByFeatures(pmMuIndex, featureduration, nmeasures);
sigmanorm      = duplicateMeasuresByFeatures(pmSigmaIndex, featureduration, nmeasures);
pmRawMeasFeats = (pmRawMeasFeats - munorm) ./ sigmanorm;

misspts = sum(sum(isnan(pmRawMeasFeats)));
totpts  = size(pmRawMeasFeats, 1) * size(pmRawMeasFeats, 2);
fprintf('%3.1f%% (%d/%d) missing data points in raw features\n', 100 * misspts / totpts, misspts, totpts);

fprintf('Creating missingness features\n');
if basefeatparamsrow.missinterp == 1
    % calculate missingness features after populating missing values
    % i.e. missingness features always zero
    pmMSFeats = zeros(nexamples, nrawfeatures);
elseif basefeatparamsrow.missinterp == 2
    % calculate missingness features before populating missing values
    % i.e. missingness features represent true missing data points
    pmMSFeats = zeros(nexamples, nrawfeatures);
    pmMSFeats(isnan(pmRawMeasFeats)) = 1;
else
    fprintf('Unknown missingness interp order method\n');
end

if basefeatparamsrow.interpmethod == 0
    fprintf('Creating volatility features\n');
    pmVolFeats = createVolFeats(pmRawMeasFeats, nexamples, nmeasures, featureduration);

    % populate nan's with missingness constant
    fprintf('Populating missing values with const %d\n', basefeatparamsrow.msconst);
    pmRawMeasFeats(isnan(pmRawMeasFeats)) = basefeatparamsrow.msconst;
    pmVolFeats(isnan(pmVolFeats))         = basefeatparamsrow.msconst;

elseif basefeatparamsrow.interpmethod == 1
    % interpolate raw features
    fprintf('Populating missing values with interpolation\n');
    pmRawMeasFeats = interpolateFeats(pmRawMeasFeats, pmMuIndex, pmSigmaIndex, pmOverallStats, nexamples, nmeasures, featureduration);
    pmRawMeasFeats = createSmoothFeats(pmRawMeasFeats, measures, nmeasures,  nexamples, featureduration, basefeatparamsrow.smfunction, ...
                            basefeatparamsrow.smwindow, basefeatparamsrow.smlength);

    fprintf('Creating volatility features with interpolation\n');
    pmVolFeats = createVolFeats(pmRawMeasFeats, nexamples, nmeasures, featureduration); 
else
    fprintf('Interp method %d not allowed - only 0.No and 1.Full interpolation methods allowed\n', basefeatparamsrow.interpmethod); 
end

end