function [hyperparamQS, foldhpTrQS, foldhpCVQS, foldhpTeQS] = createHpQSTables(nhpcomb, nfolds)

% createHpQSTables - creates the tables to store the hyper parameter QS
% results

hyperparamQS = table('Size',[nhpcomb, 28], ...
                'VariableTypes', {'double', 'double', 'double', 'double', 'double', ...
                                  'double', 'double', 'double', 'double', 'double', 'double',...
                                  'double', 'double', 'double', 'double', 'double', ...
                                  'double', 'double', 'double', 'double', 'double', 'double', ...
                                  'double', 'double', ...
                                  'double', 'double', 'double', 'double'}, ...
                'VariableNames', {'LearnRate', 'NumTrees', 'MinLeafSize', 'MaxNumSplit', 'FracVarsToSample', ...
                                  'AvgLoss', 'PScore', 'ElecPScore', 'AvgEpiTPred', 'AvgEpiFPred', 'AvgEPV', ...
                                  'PRAUC', 'ROCAUC', 'Acc', 'PosAcc', 'NegAcc', ...
                                  'TrigDelay', 'EarlyWarn', 'TrigIntrTPR', 'EpiFPROp', 'EpiPredOp', 'IdxOp', ...
                                  'IntrCount', 'IntrTrig', ...
                                  'MaxNumNodes', 'AvgNumNodes', 'MaxBranchNodes', 'AvgBranchNodes'});

temp = array2table(zeros(nhpcomb, 1));
temp.Properties.VariableNames{'Var1'} = 'Fold';
foldhpTrQS = [temp, hyperparamQS];
foldhpTrQS = repmat(foldhpTrQS, nfolds, 1);
foldhpCVQS = foldhpTrQS;
foldhpTeQS = foldhpTrQS;

end

