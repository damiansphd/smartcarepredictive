function pmRes = calcQCPredAndQS(mdl, features, labels, modelver, lossfunc, ...
                    lrval, ntrval, mlsval, mnsval, fvsval)

% calcQCPredAndQS - wrapper function to create predictions and quality
% metrics for the quality classifier

nexamples = size(features, 1);
pmRes     = createMSModelResStuct(nexamples, 1);

% create predictions
pmRes     = predictPredModel(pmRes, mdl, features, labels, modelver, lossfunc);
fprintf('LR: %.2f NT: %3d MLS: %3d MNS: %3d FVS: %.2f- ', lrval, ntrval, mlsval, mnsval, fvsval);
fprintf('Loss: %.6f ', pmRes.Loss);

% calculate training set quality scores
pmRes = calcModelQualityScores(pmRes, labels, nexamples);

fprintf('\n');

end

