function [pmStudyInfo, pmPatients, pmAntibiotics, pmAMPred, pmDatacube, npatients, maxdays] = ...
    createPMRawDatacube(pmStudyInfo, measures, nmeasures, nstudies, basedir, subfolder)

% createPMDataCube - creates the raw data cube for the predictive model
% across one or more studies

for a = 1:nstudies
    fprintf('Processing study %s\n', pmStudyInfo.StudyName{a});
    study = pmStudyInfo.Study{a};
    [datamatfile, clinicalmatfile, ~] = getRawDataFilenamesForStudy(study);
    [physdata, offset] = loadAndHarmoniseMeasVars(datamatfile, subfolder, study);
    [cdPatient, ~, ~, cdAntibiotics, ~, ~, ~, ...
        ~, ~, ~, ~, ~, ~, ~] = loadAndHarmoniseClinVars(clinicalmatfile, subfolder, study);
    
    fprintf('Loading alignment model prediction results\n');
    load(fullfile(basedir, subfolder, pmStudyInfo.AMPredMatFile{a}), 'amInterventions', 'ex_start');
    fprintf('Loading elective treatments\n');
    pmElectiveTreatments = readtable(fullfile(basedir, 'DataFiles', pmStudyInfo.ElectiveTrFile{a}));

    % store the study offset in pmStudyInfo table
    pmStudyInfo.Offset(a) = offset;
    
    % create datacube - 3D array of patients/days/measures for model
    fprintf('Creating patient, antibiotics, prediction, and 3D datacube arrays\n');
    [temp_pmPatients, temp_pmAntibiotics, temp_pmAMPred, temp_pmDatacube, temp_npatients, temp_maxdays] = createPMRawDatacubeForOneStudy(physdata, cdPatient, cdAntibiotics, amInterventions, pmElectiveTreatments, ex_start, pmStudyInfo(a, :), measures, nmeasures);
    
    % combine results into one array
    if a == 1
        pmPatients    = temp_pmPatients;
        pmAntibiotics = temp_pmAntibiotics;
        pmAMPred      = temp_pmAMPred;
        pmDatacube    = temp_pmDatacube;
        npatients     = temp_npatients;
        maxdays       = temp_maxdays;
    else
        npatients_before = npatients;
        npatients_incr = temp_npatients;
        pmPatients.PatientNbr(:) = 0;
        temp_pmPatients.PatientNbr(:) = 0;
        pmPatients = unique([pmPatients; temp_pmPatients]);
        npatients = size(pmPatients, 1);
        pmPatients.PatientNbr = (1:npatients)';
        if (npatients < (npatients_before + npatients_incr))
            fprintf('There were %d duplicate patients\n', npatients_before + npatients_incr - npatients);
            fprintf('Please remove and rerun\n');
            return;
        else
            fprintf('There were no duplicate patients\n');
        end
        
        pmAntibiotics = [pmAntibiotics; temp_pmAntibiotics];
        tempabpnbr    = innerjoin(pmAntibiotics(:,{'Study', 'ID'}), pmPatients(:,{'PatientNbr', 'Study', 'ID'}));
        pmAntibiotics.PatientNbr = tempabpnbr.PatientNbr;
        
        pmAMPred      = [pmAMPred; temp_pmAMPred];
        tempampnbr    = innerjoin(pmAMPred(:,{'Study', 'ID'}), pmPatients(:,{'PatientNbr', 'Study', 'ID'}));
        pmAMPred.PatientNbr = tempampnbr.PatientNbr;
        
        if maxdays > temp_maxdays
            temp_pmDatacube(:, (temp_maxdays + 1): maxdays, :) = nan;
        elseif temp_maxdays > maxdays
            pmDatacube(:, (maxdays + 1): temp_maxdays, :) = nan;
            maxdays = temp_maxdays;
        end
        pmDatacube = [pmDatacube; temp_pmDatacube];
    end
end

end

