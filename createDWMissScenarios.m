function [pmMissPattIndex] = createDWMissScenarios(lastbatch, batchto, batchsize, npcexamples, nqcfolds, nrawmeasures, datawin)

% createDWMissScenarios - creates the missingness pattern index table
% containing all the scenarios to be used to generate the quality
% classifier data-set (returning just the relevant next set of scenarios)

mpfrom = (lastbatch * batchsize) + 1;
mpto   = (batchto   * batchsize)    ;
nmptotal = mpto;

if nmptotal > npcexamples
    nactmisspatts = npcexamples;
    nsynmisspatts = nmptotal - nactmisspatts;
else
    nactmisspatts = nmptotal;
    nsynmisspatts = 0;
end
fprintf('Running for batch size %d from batch %d to %d\n', batchsize, lastbatch + 1, batchto);
fprintf('\n');

[pmMissPattIndex, ~, ~, ~] ... 
    = createDWMissPattTables(nmptotal, nrawmeasures, datawin);


% add actual missingness examples
if nactmisspatts > 0
    exfrom = 1;
    exto   = nactmisspatts;
    pmMissPattIndex.ScenType(exfrom:exto)  = 4;
    pmMissPattIndex.Scenario(exfrom:exto)  = {'Actual'};
    pmMissPattIndex.MSExample(exfrom:exto) = randperm(npcexamples, nactmisspatts)';
    
end

% add synthetic examples (for now just random percentage)
if nsynmisspatts > 0
    exfrom = exto + 1;
    exto   = exfrom + nsynmisspatts - 1;
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
