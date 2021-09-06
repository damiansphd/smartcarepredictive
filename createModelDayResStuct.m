function [pmDayRes] = createModelDayResStuct(nexamples, nfolds, nbssamples)

% createModelDayResStuct - convenience function to create the structure to
% house a set of model results

pmDayRes = struct('Folds'      , [], 'LLH', 0.0        , 'Pred'        , zeros(nexamples,1), ...
                  'PredSort'   , zeros(nexamples,1)    , 'LabelSort'   , zeros(nexamples,1), ...
                  'Precision'  , zeros(nexamples,1)    , 'Recall'      , zeros(nexamples,1), ...
                  'TPR'        , zeros(nexamples,1)    , 'FPR'         , zeros(nexamples,1), ...
                  'Loss'       , zeros(nfolds, 1)      , 'AvgLoss'     , 0.0, ...
                  'PRAUC'      , 0.0                   , 'ROCAUC'      , 0.0, ...
                  'Acc'        , 0.0                   , 'PosAcc'      , 0.0, ...
                  'NegAcc'     , 0.0                   , ...
                  'HighP'      , 0.0                   , 'MedP'        , 0.0, ....
                  'LowP'       , 0.0                   , 'ElecHighP'   , 0.0, ...
                  'ElecMedP'   , 0.0                   , 'ElecLowP'    , 0.0, ...
                  'PScore'     , 0.0                   , 'ElecPScore'  , 0.0, ...
                  'AvgEpiTPred', 0.0                   , 'AvgEpiFPred' , 0.0, ...
                  'AvgEPV'     , 0.0                   , 'TrigIntrTPR' , 0.0, ...
                  'TrigDelay'  , 0.0                   , 'EarlyWarn'   , 0.0, ...
                  'EpiFPROp'   , 0.0                   , 'EpiPredOp'   , 0.0, ...
                  'IdxOp'      , 0.0                   , 'IntrCount'   , 0.0, ...
                  'IntrTrig'   , 0.0                   , ...
                  'DataScope'  , []                    , 'DaysScope'   , [], ...
                  'RunDays'    , 0.0                   , 'TotDays'     , 0.0, ...
                  'PosLblDays' , 0.0                   , ...
                  'RunEpi'     , 0.0                   , 'TotEpi'      , 0.0, ...
                  'PosLblEpi'  , 0.0                   , ...
                  'bsPRAUC'    , zeros(nbssamples,1)   , 'bsROCAUC'   , zeros(nbssamples,1), ...
                  'bsAcc'      , zeros(nbssamples,1)   , 'bsPosAcc'   , zeros(nbssamples,1), ...
                  'bsNegAcc'   , zeros(nbssamples,1));

end

