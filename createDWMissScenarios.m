function [pmMissPattIndex] = createDWMissScenarios(pmMissPattIndex, nexamples, nqcfolds, nactmisspatts, nsynmisspatts)

% createDWMissScenarios - creates the missingness pattern index table
% containing all the scenarios to be used to generate the quality
% classifier data-set

% first add the rows for the baseline scenarios
for n = 1:nqcfolds
    pmMissPattIndex.ScenType(n) = 0;
    pmMissPattIndex.Scenario{n} = 'None';
    pmMissPattIndex.QCFold(n)   = n;
end

if nactmisspatts > 0
    actfrom = nqcfolds + 1;
    actto   = nqcfolds + nactmisspatts;

    pmMissPattIndex.ScenType(actfrom:actto)  = 4;
    pmMissPattIndex.Scenario(actfrom:actto)  = {'Actual'};
    pmMissPattIndex.MSExample(actfrom:actto) = randperm(nexamples, nactmisspatts)';
    nperfold = ceil((actto - actfrom + 1)/nqcfolds);
    for n = 1:nqcfolds
        foldfrom = actfrom     + (n - 1) * nperfold;
        foldto   = actfrom - 1 +  n      * nperfold;
        if foldto > actto
            foldto = actto;
        end
        pmMissPattIndex.QCFold(foldfrom:foldto) = n;
    end
    
    % hardcoding for examples with a lot of missing data
    %randmpidx(nqcfolds + 1) = 1260;
    %randmpidx(nqcfolds + 2) = 6880;
end

if nsynmisspatts > 0
    fprintf('**** Need to implement logic to generate synthetic missingness scenarios ****\n');
end

