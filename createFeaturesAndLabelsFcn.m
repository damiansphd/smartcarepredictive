function [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels] = ...
    createFeaturesAndLabelsFcn(pmPatients, pmAntibiotics, pmAMPred, pmInterpDatacube, pmInterpNormcube, ...
    pmBucketedcube, measures, nmeasures, npatients, maxdays, maxfeatureduration, featureparamsrow)
 
% createFeaturesAndLabels - function to create the set of features and
% labels for each example in the overall data set.

% first calculate total number of examples (patients * run days) to
% pre-allocate tables/arrays
nexamples = 0;
for p = 1:npatients
    %pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p & ismember(pmAntibiotics.Route, 'IV'), :);
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p, :);
    for d = maxfeatureduration:maxdays
        if d <= (pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1) && ...
           (~any(pabs.StartDate <= pmPatients.FirstMeasDate(p) + days(d - 1) & ...
                 pabs.StopDate  >= pmPatients.FirstMeasDate(p) + days(d - 1)))
             nexamples = nexamples + 1;
        end
    end
end

% set variousl variables
featureduration = featureparamsrow.featureduration;
predictionduration = featureparamsrow.predictionduration;
nbuckets        = featureparamsrow.nbuckets;

nbucketmeasures = sum(measures.Bucket);
nrawmeasures    = nmeasures - nbucketmeasures;
nrangemeasures  = sum(measures.Range);
nvolmeasures    = sum(measures.Volatility);

nrawfeatures    = nrawmeasures * featureduration;
nbucketfeatures = nbucketmeasures * nbuckets * featureduration;
nrangefeatures  = nrangemeasures;
nvolfeatures    = nvolmeasures;

nfeatures       = nmeasures * featureduration;
nnormfeatures   = nrawfeatures + nbucketfeatures + nrangefeatures + nvolfeatures;

example = 1;

pmFeatureIndex = table('Size',[nexamples, 5], 'VariableTypes', {'double', 'cell', 'double', 'datetime', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'CalcDate', 'CalcDatedn'});

featureindexrow = pmFeatureIndex(1,:);
pmFeatures      = zeros(nexamples, nfeatures);
pmNormFeatures  = zeros(nexamples, nnormfeatures);
normfeaturerow  = zeros(1, nnormfeatures);
pmIVLabels      = false(nexamples, predictionduration);
pmExLabels      = false(nexamples, predictionduration);
pmABLabels      = false(nexamples, predictionduration);
pmExLBLabels    = false(nexamples, predictionduration);
pmExABLabels    = false(nexamples,1);

fprintf('Processing data for patients\n');
for p = 1:npatients
%for p = 1:2    
    %pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p & ismember(pmAntibiotics.Route, 'IV'), :);
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p, :);
    
    for d = maxfeatureduration:maxdays
        % only include this run day for the period between first and last measurement for
        % patient for days when the patient wasn't on antibiotics.
        % potentially add a check on completeness of raw data in this
        % window
        if d <= (pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1) && ...
           (~any(pabs.StartDate <= pmPatients.FirstMeasDate(p) + days(d - 1) & ...
                 pabs.StopDate  >= pmPatients.FirstMeasDate(p) + days(d - 1)))
                  
            featureindexrow.PatientNbr = pmPatients.PatientNbr(p);
            featureindexrow.Study      = pmPatients.Study(p);
            featureindexrow.ID         = pmPatients.ID(p);
            featureindexrow.CalcDatedn = d;
            featureindexrow.CalcDate   = pmPatients.FirstMeasDate(p) + days(d - 1);
            
            % for each patient/day, create row in unnormalised features
            % array (this array is for informational purposes only - model
            % should always run with normalised features
            featurerow     = reshape(pmInterpDatacube(p, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            
            % create normalised features
            
            % 1) Raw features
            normfeaturerow(1: nrawfeatures) = reshape(pmInterpNormcube(p, (d - featureduration + 1): d, ~logical(measures.Bucket)), [1, nrawfeatures]);
            nextfeat = nrawfeatures + 1;
            
            % 2) Bucketed features
            buckfeatrow = reshape(reshape(pmBucketedcube(p, (d - featureduration + 1): d, logical(measures.Bucket), :), [featureduration  * nbucketmeasures, nbuckets])', ...
                    [1, nbucketfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nbucketfeatures) = buckfeatrow;
            nextfeat = nextfeat + nbucketfeatures;
            
            % 3) Range features
            % needs reworking to use pmInterpNormcube
            %minmaxrow = zeros(1,nmeasures);
            %for m = 1:nmeasures
            %    minmaxrow(m) = max(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration))) - ...
            %                   min(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)));
            %end
            %normfeaturerow(nextfeat: ((nextfeat - 1) + nmeasures)) = minmaxrow;
            %    nextfeat = nextfeat + nmeasures;
            
            % 4) Volatility features
            % needs reworking to use pmInterpVolcube
            % if volfeat is enabled, create additional volatility features
            % for each measure
            %volrow = zeros(1,nmeasures);
            %for m = 1:nmeasures
            %    volrow(m) = sum(abs(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)))) ...
            %                / featureduration;
            %end
            %normfeaturerow(nextfeat:((nextfeat - 1) + nvolmeasures)) = volrow;
            
            % for each patient/day, create row in IV label array
            ivlabelrow = checkABInTimeWindow(featureindexrow, ...
                    pmAntibiotics(pmAntibiotics.PatientNbr == p & ismember(pmAntibiotics.Route, 'IV'), :), predictionduration);
            
            % for each patient/day, create row in AB label array (Oral + IV
            % AB)
            ablabelrow = checkABInTimeWindow(featureindexrow, ...
                    pmAntibiotics(pmAntibiotics.PatientNbr == p, :), predictionduration);    
                
            % also create label arrays for Exacerbation having started in
            % the last n days. First uses Prediction day, second uses lower
            % bound as the ex start point
            exlabelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmAMPred(pmAMPred.PatientNbr  == p, :), predictionduration, 'Pred');
                
            exlblabelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmAMPred(pmAMPred.PatientNbr  == p, :), predictionduration, 'LB');    
                
            % add new ExAB labels here. First uses Prediction day, second uses lower
            % bound as the ex start point
            exablabelrow = checkInExStartToTreatmentWindow(featureindexrow, ...
                    pmAMPred(pmAMPred.PatientNbr  == p, :), ...
                    pmAntibiotics(pmAntibiotics.PatientNbr == p, :));
            
            % add to arrays
            pmFeatureIndex(example, :) = featureindexrow;
            pmFeatures(example, :)     = featurerow;
            pmNormFeatures(example, :) = normfeaturerow;
            pmIVLabels(example, :)     = ivlabelrow;
            pmABLabels(example, :)     = ablabelrow;
            pmExLabels(example, :)     = exlabelrow;
            pmExLBLabels(example, :)   = exlblabelrow;
            pmExABLabels(example, :)   = exablabelrow;
            example = example + 1;
        end
    end
    fprintf('.');
    if (p/50) == round(p/50)
        fprintf('\n');
    end
end
fprintf('\n');

end