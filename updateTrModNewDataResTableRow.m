function pmtrmodnewdatarow = updateTrModNewDataResTableRow(pmtrmodnewdatarow, pmFeatureParamsRow, ...
            pcmodelresultsfile, qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureinputmatfile, ...
            resstruct)

% need to add these parameters when ready to use manual data completeness function: mindatadays, maxdatagap, recpctgap, 
% updateTrModNewDataResTable - updates a row in the table

pmtrmodnewdatarow.ModStudy      = pmFeatureParamsRow.StudyDisplayName;
pmtrmodnewdatarow.PCModel{1}    = pcmodelresultsfile;
pmtrmodnewdatarow.QCModel{1}    = qcmodelresultsfile;
pmtrmodnewdatarow.QCOpThresh    = qcopthres;
%pmtrmodnewdatarow.MinDataDays   = mindatadays;
%pmtrmodnewdatarow.MaxDataGap    = maxdatagap;
%pmtrmodnewdatarow.RecPctGap     = recpctgap;
pmtrmodnewdatarow.DataStudy     = pmModFeatParamsRow.StudyDisplayName;
pmtrmodnewdatarow.DataSet{1}    = featureinputmatfile;
pmtrmodnewdatarow.DataScope{1}  = resstruct.DataScope;
pmtrmodnewdatarow.DaysScope{1}  = resstruct.DaysScope;

pmtrmodnewdatarow.RunDays       = resstruct.RunDays;
pmtrmodnewdatarow.TotDays       = resstruct.TotDays;
pmtrmodnewdatarow.PctDaysRun    = round(100 * resstruct.RunDays / resstruct.TotDays, 2);
pmtrmodnewdatarow.PosLblDays    = resstruct.PosLblDays;
pmtrmodnewdatarow.PctPosLblDays = round(100 * resstruct.PosLblDays / resstruct.RunDays, 2);

pmtrmodnewdatarow.RunEpi        = resstruct.RunEpi;
pmtrmodnewdatarow.TotEpi        = resstruct.TotEpi;
pmtrmodnewdatarow.PctEpiRun     = round(100 * resstruct.RunEpi / resstruct.TotEpi, 2);
pmtrmodnewdatarow.PosLblEpi     = resstruct.PosLblEpi;
pmtrmodnewdatarow.PctPosLblEpi  = round(100 * resstruct.PosLblEpi / resstruct.RunEpi, 2);

pmtrmodnewdatarow.PRAUC         = round(resstruct.PRAUC, 3);
pmtrmodnewdatarow.ROCAUC        = round(resstruct.ROCAUC, 3);
pmtrmodnewdatarow.Acc           = round(resstruct.Acc, 3);
pmtrmodnewdatarow.PosAcc        = round(resstruct.PosAcc, 3);
pmtrmodnewdatarow.NegAcc        = round(resstruct.NegAcc, 3);
pmtrmodnewdatarow.HighP         = resstruct.HighP;
pmtrmodnewdatarow.MedP          = resstruct.MedP;
pmtrmodnewdatarow.LowP          = resstruct.LowP;
pmtrmodnewdatarow.ElecHighP     = resstruct.ElecHighP;
pmtrmodnewdatarow.ElecMedP      = resstruct.ElecMedP;
pmtrmodnewdatarow.ElecLowP      = resstruct.ElecLowP;
pmtrmodnewdatarow.PScore        = round(resstruct.PScore, 3);
pmtrmodnewdatarow.ElecPScore    = round(resstruct.ElecPScore, 3);
pmtrmodnewdatarow.AvgEpiTPred   = round(resstruct.AvgEpiTPred, 3);
pmtrmodnewdatarow.AvgEpiFPred   = round(resstruct.AvgEpiFPred, 3);
pmtrmodnewdatarow.AvgEPV        = round(resstruct.AvgEPV, 3);
pmtrmodnewdatarow.TrigIntrTPR   = round(resstruct.TrigIntrTPR, 3);
pmtrmodnewdatarow.TrigDelay     = round(resstruct.TrigDelay, 3);
pmtrmodnewdatarow.EarlyWarn     = round(resstruct.EarlyWarn, 3);
pmtrmodnewdatarow.EpiFPROp      = round(resstruct.EpiFPROp, 5);
pmtrmodnewdatarow.EpiPredOp     = round(resstruct.EpiPredOp, 5);
pmtrmodnewdatarow.IdxOp         = resstruct.IdxOp;
pmtrmodnewdatarow.IntrCount     = resstruct.IntrCount;
pmtrmodnewdatarow.IntrTrig      = resstruct.IntrTrig;
                                
end

