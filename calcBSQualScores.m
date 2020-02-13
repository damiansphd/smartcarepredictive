function [mdlres] = calcBSQualScores(mdlres, labels, nbssamples, nexamples)

% calcBSQualSScores - calculates the quality scores for the bootstrapping samples 

for s = 1:nbssamples
    rng(s);
    sampleidx = generateResampledIdx(nexamples, nexamples);
    tempRes = mdlres;
    tempRes.Pred = tempRes.Pred(sampleidx);
    templabels = labels(sampleidx);

    fprintf('BS Sample %2d Qual Scores: ', s);
    tempRes = calcModelQualityScores(tempRes, templabels, nexamples);
    fprintf('\n');
    mdlres.bsPRAUC(s)    = tempRes.PRAUC;
    mdlres.bsROCAUC(s)   = tempRes.ROCAUC;
    mdlres.bsAcc(s)      = tempRes.Acc;
    mdlres.bsPosAcc(s)   = tempRes.PosAcc;
    mdlres.bsNegAcc(s)   = tempRes.NegAcc;   
end

end

