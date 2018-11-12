function [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmExLabels] = createFeaturesAndLabelsFcn(pmPatients, ...
    pmAntibiotics, pmAMPred, pmRawDatacube, pmInterpDatacube, pmInterpNormcube, ...
    measures, nmeasures, npatients, maxdays, maxfeatureduration, featureparamsrow)
 
% createFeaturesAndLabels - function to create the set of features and
% labels for each example in the overall data set.

pmFeatureIndex = table('Size',[1, 5], 'VariableTypes', {'double', 'cell', 'double', 'datetime', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'CalcDate', 'CalcDatedn'});
featureindexrow = pmFeatureIndex;
pmFeatureIndex(1,:) = [];
pmFeatures = [];
pmNormFeatures = [];
pmIVLabels = logical([]);
pmExLabels = logical([]);
featureduration = featureparamsrow.featureduration;
predictionduration = featureparamsrow.predictionduration;
minmaxfeat = featureparamsrow.minmaxfeat;
volfeat = featureparamsrow.volfeat;

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
            featureindexrow.CalcDatedn = d - 1;
            featureindexrow.CalcDate = pmPatients.FirstMeasDate(p) + days(d - 1);
            
            % for each patient/day, create row in features arrays
            featurerow     = reshape(pmInterpDatacube(p, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            normfeaturerow = reshape(pmInterpNormcube(p, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            
            % if minmaxfeat is enabled, create additional range features
            % for each measure
            if minmaxfeat == 2
                minmaxrow = zeros(1,nmeasures);
                for m = 1:nmeasures
                    minmaxrow(m) = max(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration))) - ...
                                    min(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)));
                end
                normfeaturerow = [normfeaturerow, minmaxrow];
            end
            
            % if volfeat is enabled, create additional volatility features
            % for each measure
            if volfeat == 2     
                volrow = zeros(1,nmeasures);
                for m = 1:nmeasures
                    volrow(m) = sum(abs(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)))) ...
                                    / featureduration;
                end
                normfeaturerow = [normfeaturerow, volrow];
            end
            
            % for each patient/day, create row in IV label array
            ivlabelrow = checkIVInTimeWindow(featureindexrow, ...
                    pmAntibiotics(pmAntibiotics.PatientNbr == p, :), predictionduration);
                
            % also create label array for Exacerbation having started in
            % the last n days
            exlabelrow = checkExStartInTimeWindow(featureindexrow, ...
                    pmAMPred(pmAMPred.PatientNbr  == p, :), predictionduration);
            
            % add to arrays
            pmFeatureIndex = [pmFeatureIndex; featureindexrow];
            pmFeatures     = [pmFeatures; featurerow];
            pmNormFeatures = [pmNormFeatures; normfeaturerow];
            pmIVLabels     = [pmIVLabels; ivlabelrow];
            pmExLabels     = [pmExLabels; exlabelrow];
        end
    end
    fprintf('.');
    if (p/50) == round(p/50)
        fprintf('\n');
    end
end
fprintf('\n');

end