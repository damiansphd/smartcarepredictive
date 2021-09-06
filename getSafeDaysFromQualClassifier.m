function [safedayidx, nsafedays] = getSafeDaysFromQualClassifier(featindex, qcfeatures, qcmodel, qcmodelver, qcopthres)

% getSafeDaysFromQualClassifier - function to derive which days are safe to 
% make a prediction for (i.e. enough data in the preceding data window) by 
% using a previously trained quality classifier

nexamples = size(qcfeatures, 1);

origidx    = featindex.ScenType == 0;
norigex    = sum(origidx);

qclossfunc = 'hinge'; % hardcoded for now - until add this to mp other run parameters
pmAllQCRes = createQCModelResStruct(nexamples, 1);
pmAllQCRes = predictPredModel(pmAllQCRes, qcmodel, qcfeatures(origidx, :), zeros(norigex, 1), qcmodelver, qclossfunc);
pmAllQCRes.Loss = 0; % Loss calculation does not make sense for new data as we don't have labels to compare to

% create index of safe days
safedayidx    = pmAllQCRes.Pred >= qcopthres;
nsafedays  = sum(safedayidx);
fprintf('Using the quality classifier with op thresh %.2f, there are %d safe days out of a total of %d days (%.1f%%)\n', qcopthres, nsafedays, nexamples, 100 * nsafedays / nexamples);
    
end

