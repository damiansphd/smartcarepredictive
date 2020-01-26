function [hyperparamqsrow] = setHyperParamQSrow(hyperparamqsrow, lrval, ntrval, mlsval, mnsval, fvsval, mdlres)

% setHyperParamQSrow - sets the values in the hyper parameter row

hyperparamqsrow.LearnRate        = lrval;
hyperparamqsrow.NumTrees         = ntrval;
hyperparamqsrow.MinLeafSize      = mlsval;
hyperparamqsrow.MaxNumSplit      = mnsval;
hyperparamqsrow.FracVarsToSample = fvsval;
hyperparamqsrow.AvgLoss          = mean(mdlres.Loss);
hyperparamqsrow.PScore           = mdlres.PScore;
hyperparamqsrow.ElecPScore       = mdlres.ElecPScore;
hyperparamqsrow.PRAUC            = mdlres.PRAUC;
hyperparamqsrow.ROCAUC           = mdlres.ROCAUC;
hyperparamqsrow.Acc              = mdlres.Acc;
hyperparamqsrow.PosAcc           = mdlres.PosAcc;
hyperparamqsrow.NegAcc           = mdlres.NegAcc;
hyperparamqsrow.AvgEpiTPred      = mdlres.AvgEpiTPred;
hyperparamqsrow.AvgEpiFPred      = mdlres.AvgEpiFPred;
hyperparamqsrow.AvgEPV           = mdlres.AvgEPV;

end

