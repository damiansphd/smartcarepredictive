function [pmFeatureIndex, pmFeatures, pmLabels] = createFeaturesAndLabels(pmStudyInfo, pmPatients, pmAntibiotics, ...
    pmDatacube, measures, nmeasures, npatients, maxdays, featureduration, predictionduration)
 
% createFeaturesAndLabels - function to create the set of features and
% labels for each example in the overall data set.

pmFeatureIndex = table('Size',[1, 5], 'VariableTypes', {'double', 'cell', 'double', 'datetime', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'CalcDate', 'CalcDatedn'});
featureindexrow = pmFeatureIndex;
pmFeatureIndex(1,:) = [];
pmFeatures = [];
pmLabels = [];

for a = 1:npatients
    fprintf('Processing data for patient %d\n', a);
    offset = pmStudyInfo.Offset(ismember(pmStudyInfo.Study, pmPatients.Study(a)));
    for d = featureduration:maxdays
        % add check for whether patient is on IV to this logic (skip if
        % true) and also if data completeness was good enough for this
        % patient/day
        if d <= (pmPatients.LastMeasdn(a) - pmPatients.FirstMeasdn(a) + 1) 
            featureindexrow.PatientNbr = pmPatients.PatientNbr(a);
            featureindexrow.Study = pmPatients.Study(a);
            featureindexrow.ID = pmPatients.ID(a);
            featureindexrow.CalcDatedn = d;
            featureindexrow.CalcDate = datetime(pmPatients.FirstMeasDate(a) + days(d - 1));
            
            % for each patient/day, create row in features array
            featurerow = reshape(pmDatacube(a, (d - featureduration + 1): d, :), [1, (nmeasures * featureduration)]);
            
            % for each patient/day, create row in label array
            labelrow = checkIVInTimeWindow(featureindexrow, ...
                    pmAntibiotics(pmAntibiotics.ID == pmPatients.ID(a),:), predictionduration);
            
            % add to arrays
            pmFeatureIndex = [pmFeatureIndex; featureindexrow];
            pmFeatures = [pmFeatures; featurerow];
            pmLabels = [pmLabels; labelrow];
        end
    end
end

end