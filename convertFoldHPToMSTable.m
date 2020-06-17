function mstestqs = convertFoldHPToMSTable(mstestqs, foldhpTestQS, i, pmmsscenario)

% convertFoldHPToMSTable - converts from the foldhpQS table to the
% missingness QS table

mstestqs.ScenarioNbr       = i;
mstestqs.PatientNbr        = pmmsscenario.PatientNbr;
mstestqs.Study             = pmmsscenario.Study;
mstestqs.ID                = pmmsscenario.ID;
mstestqs.ScaledDateNumFrom = pmmsscenario.ScaledDateNumFrom;
mstestqs.ScaledDateNumTo   = pmmsscenario.ScaledDateNumTo;
mstestqs.ScenarioType      = pmmsscenario.ScenarioType;
mstestqs.MMask             = pmmsscenario.MMask;
mstestqs.Frequency         = pmmsscenario.Frequency;
mstestqs.Duration          = pmmsscenario.Duration ;

mstestqs.AvgLoss           = foldhpTestQS.AvgLoss;
mstestqs.PScore            = foldhpTestQS.PScore;
mstestqs.ElecPScore        = foldhpTestQS.ElecPScore; 
mstestqs.AvgEpiTPred       = foldhpTestQS.AvgEpiTPred;
mstestqs.AvgEpiFPred       = foldhpTestQS.AvgEpiFPred;
mstestqs.AvgEPV            = foldhpTestQS.AvgEPV;
mstestqs.PRAUC             = foldhpTestQS.PRAUC;
mstestqs.ROCAUC            = foldhpTestQS.ROCAUC;
mstestqs.Acc               = foldhpTestQS.Acc;
mstestqs.PosAcc            = foldhpTestQS.PosAcc;
mstestqs.NegAcc            = foldhpTestQS.NegAcc;

end

