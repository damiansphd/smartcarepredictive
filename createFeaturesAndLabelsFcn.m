function [pmFeatureIndex, pmFeatures, pmNormFeatures, pmIVLabels, pmABLabels, pmExLabels, pmExLBLabels, pmExABLabels] = ...
    createFeaturesAndLabelsFcn(pmPatients, pmAntibiotics, pmAMPred, ...
        pmInterpDatacube, pmInterpNormcube, pmInterpVolcube, pmInterpSegVolcube, ...
        pmInterpRangecube, pmInterpSegAvgcube, pmBucketedcube, ...
        pmMuNormcube, pmSigmaNormcube, pmBuckMuNormcube, pmBuckSigmaNormcube, ...
        measures, nmeasures, npatients, maxdays, ...
        maxfeatureduration, maxnormwindow, featureparamsrow)
 
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

% set various variables
[featureduration, predictionduration, monthfeat, demofeat, ...
 nbuckets, navgseg, nvolseg, nbuckpmeas, nrawmeasures, nbucketmeasures, nrangemeasures, ...
 nvolmeasures, navgsegmeasures, nvolsegmeasures, ncchangemeasures, ...
 npmeanmeasures, npstdmeasures, nbuckpmeanmeasures, nbuckpstdmeasures, ...
 nrawfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
 nvolsegfeatures, ncchangefeatures, npmeanfeatures, npstdfeatures, ...
 nbuckpmeanfeatures, nbuckpstdfeatures, ndatefeatures, ndemofeatures, ...
 nfeatures, nnormfeatures] = setNumMeasAndFeatures(featureparamsrow, measures, nmeasures);

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
    %pmeasstats = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == p, :);
    
    if ndemofeatures ~= 0
        age      = pmPatients.Age(p)      / max(pmPatients.Age);
        height   = pmPatients.Height(p)   / max(pmPatients.Height);
        weight   = pmPatients.Weight(p)   / max(pmPatients.Weight);
        predfev1 = pmPatients.PredFEV1(p) / max(pmPatients.PredFEV1);
        if pmPatients.Sex{p}(1) == 'F'
            sex = 0;
        else
            sex = 1;
        end
    end
    
    %for d = (maxfeatureduration + maxnormwindow + 1):maxdays
    for d = (maxfeatureduration + maxnormwindow):maxdays
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
            normfeaturerow(1: nrawfeatures) = reshape(pmInterpNormcube(p, (d - featureduration + 1): d, logical(measures.RawMeas)), [1, nrawfeatures]);
            nextfeat = nrawfeatures + 1;
            
            % 2) Bucketed features
            buckfeatrow = reshape(reshape(pmBucketedcube(p, (d - featureduration + 1): d, logical(measures.BucketMeas), :), [featureduration  * nbucketmeasures, nbuckets])', ...
                    [1, nbucketfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nbucketfeatures) = buckfeatrow;
            nextfeat = nextfeat + nbucketfeatures;
            
            % 3) Range features
            rangefeatrow = reshape(pmInterpRangecube(p, d, logical(measures.Range)), [1, nrangefeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nrangefeatures) = rangefeatrow;
            nextfeat = nextfeat + nrangefeatures;
            
            % 4) Volatility features
            volfeatrow = reshape(pmInterpVolcube(p, (d - (featureduration - 1) + 1): d, logical(measures.Volatility)), [1, nvolfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nvolfeatures) = volfeatrow;
            nextfeat = nextfeat + nvolfeatures;
            
            % 5) add average measuresment segment features
            avgsegfeatrow = reshape(reshape(pmInterpSegAvgcube(p, d, logical(measures.AvgSeg), :), [navgsegmeasures, navgseg])', ...
                    [1, navgsegfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + navgsegfeatures) = avgsegfeatrow;
            nextfeat = nextfeat + navgsegfeatures;
            
            % 6) add average volatility segment features
            volsegfeatrow = reshape(reshape(pmInterpSegVolcube(p, d, logical(measures.VolSeg), :), [nvolsegmeasures, nvolseg])', ...
                    [1, nvolsegfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nvolsegfeatures) = volsegfeatrow;
            nextfeat = nextfeat + nvolsegfeatures;
            
            % 7) contiguous change feature
            nextm = 0;
            for m = 1:nmeasures
                if measures.CChange(m) == 1
                    cchange = 0;
                    for i = 2:navgseg
                        if (measures.Factor(m) * pmInterpSegAvgcube(p, d, m, i)) > (measures.Factor(m) * pmInterpSegAvgcube(p, d, m, (i - 1)))
                            cchange = cchange +  (measures.Factor(m) * pmInterpSegAvgcube(p, d, m, i)) - (measures.Factor(m) * pmInterpSegAvgcube(p, d, m, (i - 1)));
                        else
                            break;
                        end
                    end
                    normfeaturerow(nextfeat + nextm) = cchange;
                    nextm = nextm + 1;
                end
            end
            nextfeat = nextfeat + ncchangefeatures;
            
            % 8) patient mean features
            pmeanfeatrow = reshape(pmMuNormcube(p, d, logical(measures.PMean)), [1, npmeanfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + npmeanfeatures) = pmeanfeatrow;
            nextfeat = nextfeat + npmeanfeatures;
            
            % 9) patient std features
            pstdfeatrow = reshape(pmSigmaNormcube(p, d, logical(measures.PStd)), [1, npstdfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + npstdfeatures) = pstdfeatrow;
            nextfeat = nextfeat + npstdfeatures;
            
            % 10) bucketed patient mean features
            buckpmeanfeatrow = reshape(reshape(pmBuckMuNormcube(p, d, logical(measures.BuckPMean), :), [nbuckpmeanmeasures, nbuckpmeas])', ...
                    [1, nbuckpmeanfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nbuckpmeanfeatures) = buckpmeanfeatrow;
            nextfeat = nextfeat + nbuckpmeanfeatures;
            
            % 11) bucketed patient std features
            buckpstdfeatrow = reshape(reshape(pmBuckSigmaNormcube(p, d, logical(measures.BuckPStd), :), [nbuckpstdmeasures, nbuckpmeas])', ...
                    [1, nbuckpstdfeatures]);
            normfeaturerow(nextfeat: (nextfeat - 1) + nbuckpstdfeatures) = buckpstdfeatrow;
            nextfeat = nextfeat + nbuckpstdfeatures;
            
            % 12) Date feature
            if monthfeat ~= 0
                datefeat = createCyclicDateFeatures(featureindexrow.CalcDate, ndatefeatures, monthfeat);
                normfeaturerow(nextfeat: (nextfeat - 1) + ndatefeatures) = datefeat;
                nextfeat = nextfeat + ndatefeatures;
            end
            
            % 13) Patient demographic features (Age, Height, Weight, Sex,
            % PredFEV1
            if demofeat == 2
                normfeaturerow(nextfeat)     = age;
                normfeaturerow(nextfeat + 1) = height;
                normfeaturerow(nextfeat + 2) = weight;
                normfeaturerow(nextfeat + 3) = predfev1;
                normfeaturerow(nextfeat + 4) = sex;
            elseif demofeat == 3
                normfeaturerow(nextfeat)     = age;
            elseif demofeat == 4
                normfeaturerow(nextfeat)     = height;
            elseif demofeat == 5
                normfeaturerow(nextfeat)     = weight;
            elseif demofeat == 6
                normfeaturerow(nextfeat)     = predfev1;
            elseif demofeat == 7
                normfeaturerow(nextfeat)     = sex;    
            end
            nextfeat = nextfeat + ndemofeatures;
            
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