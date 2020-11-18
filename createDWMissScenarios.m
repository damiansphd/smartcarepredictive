function [pmMissPattIndex] = createDWMissScenarios(pmMissPattIndex, nexamples, nqcfolds, nactmisspatts, nsynmisspatts, mpfrom, mpto)

% createDWMissScenarios - creates the missingness pattern index table
% containing all the scenarios to be used to generate the quality
% classifier data-set

% add actual missingness examples
if nactmisspatts > 0
    exfrom = 1;
    exto   = nactmisspatts;
    pmMissPattIndex.ScenType(exfrom:exto)  = 4;
    pmMissPattIndex.Scenario(exfrom:exto)  = {'Actual'};
    pmMissPattIndex.MSExample(exfrom:exto) = randperm(nexamples, nactmisspatts)';
    
end

% add synthetic examples (for now just random percentage)
if nsynmisspatts > 0
    exfrom = exto + 1;
    exto   = exfrom + nsynmisspatts;
    pmMissPattIndex.ScenType(exfrom:exto)   = 2;
    pmMissPattIndex.Scenario(exfrom:exto)   = {'Percentage'};
    pmMissPattIndex.Percentage(exfrom:exto) = rand(nsynmisspatts, 1) * 100;
end

% now allocate each row to a fold - alternating distribution to ensure
% approx equal numbers to each fold.
folds = (1:nqcfolds)';
nreps = ceil((nactmisspatts + nsynmisspatts) / nqcfolds);
foldlist = repmat(folds, nreps, 1);
pmMissPattIndex.QCFold(:)   = foldlist;
    
% now return just the subset relevant for this batch run
pmMissPattIndex = pmMissPattIndex(mpfrom:mpto, :);

end
