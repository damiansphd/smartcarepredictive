function [pmPatients, pmAntibiotics, pmDatacube, npatients, maxdays] = createPMRawDatacubeForOneStudy(physdata, cdPatient, cdAntibiotics, pmStudyInfoRow, measures, nmeasures)

% createPMDataCube - populates a 3D array from the measurement data of
% appropriate size

offset = pmStudyInfoRow.Offset(1);
study = pmStudyInfoRow.Study{1};

patients = unique(physdata.SmartCareID);
npatients = size(patients,1);

pmPatients = table('Size',[npatients, 9], 'VariableTypes', {'double', 'cell', 'double', 'datetime', 'datetime', 'datetime', 'double', 'double', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'StudyStartDate', 'FirstMeasDate', 'LastMeasDate', 'StudyStartdn', 'FirstMeasdn', 'LastMeasdn'});

pmAntibiotics = table('Size',[0, 10], 'VariableTypes', {'double', 'cell', 'double', 'cell', 'double',  'cell', 'cell', 'cell', 'datetime', 'datetime'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'Hospital', 'AntibioticID', 'AntibioticName', 'Route', 'HomeIV_s_', 'StartDate', 'StopDate'});

maxdays = 0;
for n = 1:npatients
    scid = patients(n);
    pmPatients.PatientNbr(n) = n;
    pmPatients.Study(n) = {study};
    pmPatients.ID(n) = scid;
    pmPatients.StudyStartDate(n) = cdPatient.StudyDate(cdPatient.ID == scid);
    pmPatients.StudyStartdn(n)   = ceil(datenum(pmPatients.StudyStartDate(n) + seconds(1))) - offset;

    tempAntibiotics = cdAntibiotics(cdAntibiotics.ID == scid,{'ID', 'Hospital', 'AntibioticID', 'AntibioticName', 'Route', 'HomeIV_s_', 'StartDate', 'StopDate'});
    temppnbr = array2table(n * ones(size(tempAntibiotics,1),1));
    temppnbr.Properties.VariableNames({'Var1'}) = {'PatientNbr'};
    tempstudy = array2table(cell(size(tempAntibiotics,1),1));
    tempstudy.Properties.VariableNames({'Var1'}) = {'Study'};
    tempstudy.Study(:) = {study};
    tempAntibiotics = [temppnbr, tempstudy, tempAntibiotics];
    pmAntibiotics = [pmAntibiotics; tempAntibiotics];
    
    tempdata = physdata(physdata.SmartCareID == scid,:);
    pmPatients.FirstMeasDate(n) = min(tempdata.Date_TimeRecorded);
    pmPatients.FirstMeasdn(n)   = ceil(datenum(datetime(pmPatients.FirstMeasDate(n)) + seconds(1)) - offset);
    pmPatients.LastMeasDate(n)  = max(tempdata.Date_TimeRecorded);
    pmPatients.LastMeasdn(n)    = ceil(datenum(datetime(pmPatients.LastMeasDate(n))  + seconds(1)) - offset);
    if (pmPatients.LastMeasdn(n) - pmPatients.FirstMeasdn(n)) > maxdays
        maxdays = (pmPatients.LastMeasdn(n) - pmPatients.FirstMeasdn(n)) + 1;
    end
end

pmDatacube = NaN(npatients, maxdays, nmeasures);

physdata = innerjoin(physdata, measures, 'LeftKeys', {'RecordingType'}, 'RightKeys', {'Name'});

for i=1:size(physdata,1)
    pnbr = pmPatients.PatientNbr(ismember(pmPatients.Study, study) & (pmPatients.ID == physdata.SmartCareID(i)));
    scaleddn = physdata.ScaledDateNum(i);
    index = physdata.Index(i);
    column = physdata.Column{i};
    
    pmDatacube(pnbr, scaleddn, index) = physdata{i, {column}};
    
    if (round(i/10000) == i/10000)
        fprintf('Processed %5d rows\n', i);
    end
end

end

