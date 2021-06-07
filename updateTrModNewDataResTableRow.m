function pmtrmodnewdatarow = updateTrModNewDataResTableRow(pmtrmodnewdatarow, pmFeatureParamsRow, ...
            pcmodelresultsfile, qcmodelresultsfile, qcopthres, pmModFeatParamsRow, featureinputmatfile, ...
            datascope, daysscope, rundays, totdays, resstruct)

% updateTrModNewDataResTable - updates a row in the table

pmtrmodnewdatarow.ModStudy     = pmFeatureParamsRow.StudyDisplayName;
pmtrmodnewdatarow.PCModel{1}   = pcmodelresultsfile;
pmtrmodnewdatarow.QCModel{1}   = qcmodelresultsfile;
pmtrmodnewdatarow.QCOpThresh   = qcopthres;
pmtrmodnewdatarow.DataStudy    = pmModFeatParamsRow.StudyDisplayName;
pmtrmodnewdatarow.DataSet{1}   = featureinputmatfile;
pmtrmodnewdatarow.DataScope{1} = datascope;
pmtrmodnewdatarow.DaysScope{1} = daysscope;
pmtrmodnewdatarow.RunDays      = rundays;
pmtrmodnewdatarow.TotDays      = totdays;
pmtrmodnewdatarow.PctDaysRun   = round(100 * rundays / totdays, 1);
pmtrmodnewdatarow.PRAUC        = round(resstruct.PRAUC, 3);
pmtrmodnewdatarow.ROCAUC       = round(resstruct.ROCAUC, 3);
pmtrmodnewdatarow.Acc          = round(resstruct.Acc, 3);
pmtrmodnewdatarow.PosAcc       = round(resstruct.PosAcc, 3);
pmtrmodnewdatarow.NegAcc       = round(resstruct.NegAcc, 3);

end

