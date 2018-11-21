function [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmExLabels] = createFeaturesAndLabelsFcn(pmPatients, ...
    pmAntibiotics, pmAMPred, pmInterpDatacube, pmInterpNormcube, pmBucketedcube, ...
    nmeasures, npatients, maxdays, maxfeatureduration, featureparamsrow)
 
% createFeaturesAndLabels - function to create the set of features and
% labels for each example in the overall data set.

% first calculate total number of examples (patients * run days) to
% pre-allocate tables/arrays
nexamples = 0;
for p = 1:npatients
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p & ismember(pmAntibiotics.Route, 'IV'),:);
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
bucketfeat = featureparamsrow.bucketfeat;
nbuckets   = featureparamsrow.nbuckets;
minmaxfeat = featureparamsrow.minmaxfeat;
volfeat    = featureparamsrow.volfeat;
nfeatures  = nmeasures * featureduration;
nnormfeatures = nfeatures;
if bucketfeat == 2
    nnormfeatures = nnormfeatures + (nfeatures * (nbuckets + 1));
end
if minmaxfeat == 2
    nnormfeatures = nnormfeatures + nmeasures;
end
if volfeat == 2
    nnormfeatures = nnormfeatures + nmeasures;
end
example = 1;

pmFeatureIndex = table('Size',[nexamples, 5], 'VariableTypes', {'double', 'cell', 'double', 'datetime', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'CalcDate', 'CalcDatedn'});
featureindexrow = pmFeatureIndex(1,:);
pmFeatures = zeros(nexamples, nfeatures);
pmNormFeatures = zeros(nexamples, nnormfeatures);
normfeaturerow = zeros(1, nnormfeatures);
pmIVLabels = false(nexamples, predictionduration);
pmExLabels = false(nexamples, predictionduration);

fprintf('Processing data for patients\n');
for p = 1:npatients
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p & ismember(pmAntibiotics.Route, 'IV'),:);
    
    for d = maxfeatureduration:maxdays
        % only include this run day for the period between first and last measurement for
        % patient for days when the patient wasn't on antibiotics.
        % potentially add a check on completeness of raw data in this
        % window
        if d <= (pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1) && ...
           (~any(pabs.StartDate <= pmPatients.FirstMeasDate(p) + days(d - 1) & ...
                 pabs.StopDate  >= pmPatients.FirstMeasDate(p) + days(d - 1)))
                  
            featureindexrow.PatientNbr = pmPatients.PatientNbr(p);
            featureindexrow.Study = pmPatients.Study(p);
            featureindexrow.ID = pmPatients.ID(p);
            featureindexrow.CalcDatedn = d;
            featureindexrow.CalcDate = pmPatients.FirstMeasDate(p) + days(d - 1);
            
            % for each patient/day, create row in features arrays
            featurerow     = reshape(pmInterpDatacube(p, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            normfeaturerow(1:nfeatures) = reshape(pmInterpNormcube(p, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            nextfeat = nfeatures + 1;
            
            % if bucketedfeat is enabled, create additional bucketed
            % features
            if bucketfeat == 2
                buckfeatrow = reshape(reshape(pmBucketedcube(p, (d - featureduration + 1): d, :, :), [featureduration  * nmeasures, (nbuckets + 1)])', ...
                    [1, featureduration * nmeasures * (nbuckets + 1)]);
                normfeaturerow(nextfeat:((nextfeat - 1) + featureduration * nmeasures * (nbuckets + 1)))  = buckfeatrow;
                nextfeat = nextfeat + featureduration * nmeasures * (nbuckets + 1);
            end
            
            % if minmaxfeat is enabled, create additional range features
            % for each measure
            if minmaxfeat == 2
                minmaxrow = zeros(1,nmeasures);
                for m = 1:nmeasures
                    minmaxrow(m) = max(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration))) - ...
                                    min(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)));
                end
                normfeaturerow(nextfeat:((nextfeat - 1) + nmeasures)) = minmaxrow;
                nextfeat = nextfeat + nmeasures;
            end
            
            % if volfeat is enabled, create additional volatility features
            % for each measure
            if volfeat == 2     
                volrow = zeros(1,nmeasures);
                for m = 1:nmeasures
                    volrow(m) = sum(abs(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)))) ...
                                    / featureduration;
                end
                normfeaturerow(nextfeat:((nextfeat - 1) + nmeasures)) = volrow;
            end
            
            % for each patient/day, create row in IV label array
            ivlabelrow = checkIVInTimeWindow(featureindexrow, ...
                    pmAntibiotics(pmAntibiotics.PatientNbr == p, :), predictionduration);
                
            % also create label array for Exacerbation having started in
            % the last n days
            exlabelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmAMPred(pmAMPred.PatientNbr  == p, :), predictionduration);
            
            % add to arrays
            pmFeatureIndex(example,:) = featureindexrow;
            pmFeatures(example,:)     = featurerow;
            pmNormFeatures(example,:) = normfeaturerow;
            pmIVLabels(example,:)     = ivlabelrow;
            pmExLabels(example,:)     = exlabelrow;
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