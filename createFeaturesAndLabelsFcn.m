function [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels] = createFeaturesAndLabelsFcn(pmPatients, pmAntibiotics, ...
    pmRawDatacube, pmInterpDatacube, pmInterpNormcube, measures, nmeasures, npatients, maxdays, ...
    featureduration, predictionduration)
 
% createFeaturesAndLabels - function to create the set of features and
% labels for each example in the overall data set.

pmFeatureIndex = table('Size',[1, 5], 'VariableTypes', {'double', 'cell', 'double', 'datetime', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'CalcDate', 'CalcDatedn'});
featureindexrow = pmFeatureIndex;
pmFeatureIndex(1,:) = [];
pmFeatures = [];
pmNormFeatures = [];
pmIVLabels = logical([]);

for p = 1:npatients
    fprintf('Processing data for patient %d\n', p);
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == p & ismember(pmAntibiotics.Route, 'IV'),:);
    
    for d = featureduration:maxdays
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
            normfeaturerow = reshape(pmInterpNormcube(p, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            %for m - 1:nmeasures
            %    vertshift      = pmInterpNormcube(p, (d - featureduration + 1), m);
            %    normfeaturerow = normfeaturerow - vertshift;
            
            minmaxrow = zeros(1,nmeasures);
            volrow = zeros(1,nmeasures);
            for m = 1:nmeasures
                minmaxrow(m) = max(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration))) - ...
                                min(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)));
                volrow(m) = sum(abs(normfeaturerow(((m-1)*featureduration) + 1:(m * featureduration)))) ...
                    / featureduration;
            end
            normfeaturerow = [normfeaturerow, minmaxrow, volrow];
            
            % for each patient/day, create row in IV label array
            ivlabelrow = checkIVInTimeWindow(featureindexrow, ...
                    pmAntibiotics(pmAntibiotics.ID == pmPatients.ID(p),:), predictionduration);
                
            % also create label array for Exacerbation having started in
            % the last n days
            
            % add to arrays
            pmFeatureIndex = [pmFeatureIndex; featureindexrow];
            pmFeatures     = [pmFeatures; featurerow];
            pmNormFeatures = [pmNormFeatures; normfeaturerow];
            pmIVLabels     = [pmIVLabels; ivlabelrow];
        end
    end
end

end