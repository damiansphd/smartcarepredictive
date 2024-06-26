function [pmPatients, pmAntibiotics, pmAMPred, pmDatacube, npatients, maxdays] = createPMRawDatacubeForOneStudy(physdata, ...
    cdPatient, cdAntibiotics, amInterventions, pmElectiveTreatments, ex_start, pmStudyInfoRow, measures, nmeasures)

% createPMDataCube - populates a 3D array from the measurement data of
% appropriate size

offset = pmStudyInfoRow.Offset(1);
study = pmStudyInfoRow.Study{1};

patients = unique(physdata.SmartCareID);
npatients = size(patients,1);

pmPatients = table('Size',[npatients, 17], ...
    'VariableTypes', {'double', 'cell', 'double', 'cell', 'double', 'cell', ...
    'double', 'double', 'double', 'datetime', 'datetime', 'datetime', ...
    'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'Hospital', 'Age', 'Sex', ...
    'Height', 'Weight', 'PredFEV1','StudyStartDate', 'FirstMeasDate', 'LastMeasDate', ...
    'StudyStartdn', 'FirstMeasdn', 'LastMeasdn', 'RelFirstMeasdn', 'RelLastMeasdn'});

pmAntibiotics = table('Size',[0, 14], ...
    'VariableTypes', {'double', 'cell', 'double', 'cell', 'double', 'cell', ...
    'cell', 'cell', 'datetime', 'datetime', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'Hospital', 'AntibioticID', 'AntibioticName', ...
    'Route', 'HomeIV_s_', 'StartDate', 'StopDate', 'Startdn', 'Stopdn', 'RelStartdn', 'RelStopdn'});

maxdays = 0;
for p = 1:npatients
    scid = patients(p);
    pmPatients.PatientNbr(p) = p;
    pmPatients.Study(p)      = {study};
    pmPatients.ID(p)         = scid;
    pmPatients.Hospital(p)   = cdPatient.Hospital(cdPatient.ID == scid);
    pmPatients.Age(p)        = cdPatient.Age(cdPatient.ID == scid);
    pmPatients.Sex(p)        = cdPatient.Sex(cdPatient.ID == scid);
    pmPatients.Height(p)     = cdPatient.Height(cdPatient.ID == scid);
    pmPatients.Weight(p)     = cdPatient.Weight(cdPatient.ID == scid);
    pmPatients.PredFEV1(p)   = cdPatient.CalcPredictedFEV1(cdPatient.ID == scid);
    
    pmPatients.StudyStartDate(p) = cdPatient.StudyDate(cdPatient.ID == scid);
    pmPatients.StudyStartdn(p)   = ceil(datenum(pmPatients.StudyStartDate(p) + seconds(1))) - offset;
    
    tempdata = physdata(physdata.SmartCareID == scid,:);
    pmPatients.FirstMeasDate(p)  = dateshift(min(tempdata.Date_TimeRecorded), 'start', 'day');
    pmPatients.FirstMeasdn(p)    = ceil(datenum(datetime(pmPatients.FirstMeasDate(p)) + seconds(1)) - offset);
    pmPatients.RelFirstMeasdn(p) = 1;
    pmPatients.LastMeasDate(p)   = dateshift(max(tempdata.Date_TimeRecorded), 'start', 'day');
    pmPatients.LastMeasdn(p)     = ceil(datenum(datetime(pmPatients.LastMeasDate(p))  + seconds(1)) - offset);
    pmPatients.RelLastMeasdn(p)  = pmPatients.LastMeasdn(p) - pmPatients.FirstMeasdn(p) + 1;
    if pmPatients.RelLastMeasdn(p) > maxdays
        maxdays = pmPatients.RelLastMeasdn(p);
    end

    if ismember(study, {'CL','BR', 'AC'})
        tempAntibiotics = cdAntibiotics(cdAntibiotics.ID == scid,{'ID', 'Hospital', 'AntibioticName', 'Route', 'HomeIV_s', 'StartDate', 'StopDate'});
        tempAntibiotics.Properties.VariableNames({'HomeIV_s'}) =  {'HomeIV_s_'};
        tempAntibiotics.AntibioticID(:) = 0;
    else
        tempAntibiotics = cdAntibiotics(cdAntibiotics.ID == scid,{'ID', 'Hospital', 'AntibioticID', 'AntibioticName', 'Route', 'HomeIV_s_', 'StartDate', 'StopDate'});
    end
    temppnbr = array2table(p * ones(size(tempAntibiotics,1),1));
    temppnbr.Properties.VariableNames({'Var1'}) = {'PatientNbr'};
    tempstudy = array2table(cell(size(tempAntibiotics,1),1));
    tempstudy.Properties.VariableNames({'Var1'}) = {'Study'};
    tempstudy.Study(:) = {study};
    tempAntibiotics.Startdn = ceil(datenum(datetime(tempAntibiotics.StartDate) + seconds(1)) - offset);
    tempAntibiotics.Stopdn  = ceil(datenum(datetime(tempAntibiotics.StopDate)  + seconds(1)) - offset);
    tempAntibiotics.RelStartdn = tempAntibiotics.Startdn - (pmPatients.FirstMeasdn(p) - 1);
    tempAntibiotics.RelStopdn  = tempAntibiotics.Stopdn  - (pmPatients.FirstMeasdn(p) - 1);
    tempAntibiotics = [temppnbr, tempstudy, tempAntibiotics];
    pmAntibiotics = [pmAntibiotics; tempAntibiotics];  
end

pmAMPred = innerjoin(pmPatients, amInterventions, 'LeftKeys', {'ID'}, 'RightKeys', {'SmartCareID'}, 'LeftVariables', {'PatientNbr', 'Study', 'ID'});

% a hangover from before the elective treatments were captured in the
% alignment model interventions table. Leaving here as it does give a
% little extra flexibility - but intention is to have the override table
% match the same electives as the original table has.
% **** no need for the override for project breathe
if ~ismember(study, {'BR', 'AC'})
    pmElectiveTreatments.ElectiveTreatment(:) = 'Y';
    pmAMPred.ElectiveTreatment = [];
    pmAMPred = outerjoin(pmAMPred, pmElectiveTreatments, 'LeftKeys', {'PatientNbr', 'IVScaledDateNum'}, 'RightKeys', {'PatientNbr', 'IVScaledDateNum'}, 'RightVariables', {'ElectiveTreatment'});
    pmAMPred(isnan(pmAMPred.PatientNbr), :) = [];
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

