function [combtable, qsarray ] = createTabularBSQSResults(pmBSAllQS, ncombinations, nbssamples, qualmeasures, nqualmeas, basedir, subfolder)

% createTabularBSQSResults - create table and sample arrays for bootstrap
% quality scores

combtable = [];
qsarray   = nan(ncombinations, nqualmeas, nbssamples); 

for i = 1:ncombinations
    
    featureparamsrow = pmBSAllQS(i).FeatureParams;
    modelparamsrow   = pmBSAllQS(i).ModelParams;
    featureparamsfile = generateFileNameFromFeatureParams(featureparamsrow);
    featureparamsmatfile = sprintf('%s.mat', featureparamsfile);
    fprintf('Loading predictive model input data for %s\n', featureparamsfile);
    load(fullfile(basedir, subfolder, featureparamsmatfile), 'measures', 'nmeasures');
    [resultrow] = setTableDisplayRow(featureparamsrow, modelparamsrow, pmBSAllQS(i).NDayQS, measures, nmeasures);
    combtable = [combtable; resultrow];
    
    for n = 1:nqualmeas
        qsarray(i, n, :) = pmBSAllQS(i).NDayQS.(sprintf('bs%s',qualmeasures{n}));
    end

end

end


