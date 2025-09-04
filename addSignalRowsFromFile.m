function pmSignal = addSignalRowsFromFile(study, signaldir, acoffset, signalfile, pmSignal, pmPatients, cdPatient)

% addSignalRowsFromFile - adds the rows from a given breathe signal
% file 

basedir = setBaseDir();
subfolder = sprintf('DataFiles/%s/%s', signaldir, study);

% only ingest the 11pm (ish) versions - skip other manual runs
officialruntime = '23-';
if (matches(extractBefore(extractAfter(signalfile, 19), 4), officialruntime))
    
    % load in file
    sfopts = detectImportOptions(fullfile(basedir, subfolder, signalfile));
    sfopts.DataLines(1) = 2;
    tempSignal = readtable(fullfile(basedir, subfolder, signalfile), sfopts);
    nrows = size(tempSignal, 1);
    widgeterrorstr = 'ErrorCallingWidget';

    % ingest each row and add row to pmSignal table, along with additional info
    for i = 1:nrows
        if any(ismember(cdPatient.PartitionKey, tempSignal.UserId(i)))
            scid = cdPatient.ID(ismember(cdPatient.PartitionKey, tempSignal.UserId(i)));
            if any(pmPatients.ID == scid)
                if ~matches(tempSignal.SignalState{i}, widgeterrorstr)
                    rowtoadd               = createSignalTable(1);
                    rowtoadd.PatientNbr    = pmPatients.PatientNbr(pmPatients.ID == scid);
                    rowtoadd.Study         = {study};
                    rowtoadd.SmartCareID   = scid;
                    rowtoadd.StudyNumber   = cdPatient.StudyNumber(cdPatient.ID == scid);
                    rowtoadd.StudyNumber2  = cdPatient.StudyNumber2(cdPatient.ID == scid);
                    rowtoadd.Hospital      = cdPatient.Hospital(cdPatient.ID == scid);
                    rowtoadd.PartitionKey  = tempSignal.UserId(i);
                    rowtoadd.CalcDate      = tempSignal.WhenCalculated(i);
                    rowtoadd.CalcDatedt    = datetime(rowtoadd.CalcDate, 'Format','yyyy-MM-dd''T''HH:mm:ss');
                    rowtoadd.CalcDatedn    = ceil(datenum(rowtoadd.CalcDatedt+seconds(1)) - acoffset);
                    rowtoadd.RelCalcDatedn = rowtoadd.CalcDatedn - pmPatients.StudyStartdn(pmPatients.ID == scid) + 1;
                    rowtoadd.PredScore     = tempSignal.OutputScore(i);
                    rowtoadd.SafetyScore   = tempSignal.SafetyScore(i);
                    rowtoadd.SignalState   = tempSignal.SignalState(i);

                    pmSignal = [pmSignal; rowtoadd];
                    rowtoadd = [];
                else
                    fprintf('\tPartition Key %s (%d/%s/%s) on date %s returned an error - skipping\n', tempSignal.UserId{i}, scid, ...
                    cdPatient.StudyNumber{cdPatient.ID == scid}, cdPatient.StudyNumber2{cdPatient.ID == scid}, tempSignal.WhenCalculated(i));
                end
            else
                fprintf('\tPartition Key %s (%d/%s/%s) has no data - skipping\n', tempSignal.UserId{i}, scid, ...
                    cdPatient.StudyNumber{cdPatient.ID == scid}, cdPatient.StudyNumber2{cdPatient.ID == scid});
            end
        else
            fprintf('\tPartition Key %s not in %s study - skipping\n', tempSignal.UserId{i}, study);
        end
    end
else
    fprintf('\t%s is not an official signal score run - skipping\n', signalfile);
end

end

