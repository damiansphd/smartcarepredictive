function [ovmsqsrow] = setOvMSQSrow(ovmsqsrow, mdlres, i, ovmsscenario)

% setOvMSQSrow - sets the values in the overall missingness row

ovmsqsrow.ScenarioNbr  = i;
ovmsqsrow.ScenarioType = ovmsscenario.ScenarioType;
ovmsqsrow.MMask        = ovmsscenario.MMask;
ovmsqsrow.MMaskText    = ovmsscenario.MMaskText;
ovmsqsrow.Frequency    = ovmsscenario.Frequency;
ovmsqsrow.Duration     = ovmsscenario.Duration;
ovmsqsrow.Percentage   = ovmsscenario.Percentage;


ovmsqsrow.PRAUC        = mdlres.PRAUC;
ovmsqsrow.ROCAUC       = mdlres.ROCAUC;
ovmsqsrow.Acc          = mdlres.Acc;
ovmsqsrow.PosAcc       = mdlres.PosAcc;
ovmsqsrow.NegAcc       = mdlres.NegAcc;
ovmsqsrow.AvgEpiTPred  = mdlres.AvgEpiTPred;
ovmsqsrow.AvgEpiFPred  = mdlres.AvgEpiFPred;
ovmsqsrow.AvgEPV       = mdlres.AvgEPV;

ovmsqsrow.PScore      = {sprintf('%.1f%% (%d/%d/%d)', mdlres.PScore, mdlres.HighP, ...
                            mdlres.MedP, mdlres.LowP)};
ovmsqsrow.ElecPScore  = {sprintf('%.1f%% (%d/%d/%d)', mdlres.ElecPScore, mdlres.ElecHighP, ...
                            mdlres.ElecMedP, mdlres.ElecLowP)};
                        
end

