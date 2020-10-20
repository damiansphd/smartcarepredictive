function [pmFeatureIndex, pmDataWinArray, pmExABxElLabels, nexamples] ...
        = createDataWindowArrayFcn(pmPatients, pmAntibiotics, pmAMPred, pmRawDatacube, ...
            nmeasures, npatients, maxdays, maxfeatureduration, maxnormwindow, datawinparamsrow)

% createDataWindowArrayFcn - function to create the feature index, data window and label arrays
% One example (prediction day) for each patient, for each study day, excluding days on AB treatment
% for each example in the overall data set. The data window is the sum of
% the normalisation (stable mean) window and the feature duration

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
[~, ~, totalduration] = setDataWindowArrayParams(datawinparamsrow);

example = 1;

[pmFeatureIndex, pmDataWinArray, pmExABxElLabels] = createDataWindowArrays(nexamples, nmeasures, totalduration); 

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
                  
            % 1) Data window array
            for m = 1:nmeasures
                pmDataWinArray(example, :, m) = pmRawDatacube(p, (d - totalduration + 1): d, m);
            end
                
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

misspts = sum(sum(sum(isnan(pmDataWinArray))));
totpts  = size(pmDataWinArray, 1) * size(pmDataWinArray, 2) * size(pmDataWinArray, 3);
fprintf('%3.1f%% (%d/%d) missing data points in raw features\n', 100 * misspts / totpts, misspts, totpts);

end