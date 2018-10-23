function [pmStudyInfo, pmPatients, pmAntibiotics, pmDatacube, npatients, maxdays] = createPMRawDatacube(pmStudyInfo, measures, nmeasures, nstudies, basedir, subfolder)

% createPMDataCube - creates the raw data cube for the predictive model
% across one or more studies

for a = 1:nstudies
    fprintf('Processing study %s\n', pmStudyInfo.StudyName{a});
    fprintf('Loading clinical data\n');
    load(fullfile(basedir, subfolder, pmStudyInfo.ClinicalMatFile{a}));
    fprintf('Loading measurement data\n');
    load(fullfile(basedir, subfolder, pmStudyInfo.MeasurementMatFile{a}));
    if isequal(pmStudyInfo.Study(a), {'TM'})
        physdata = tmphysdata;
        cdPatient = tmPatient;
        cdAntibiotics = tmAntibiotics;
        offset = tmoffset;
    end
    
    % store the study offset in pmStudyInfo table
    pmStudyInfo.Offset(a) = offset;
    
    % create datacube - 3D array of patients/days/measures for model
    fprintf('Creating 3D data array\n');
    [temp_pmPatients, temp_pmAntibiotics, temp_pmDatacube, temp_npatients, temp_maxdays] = createPMRawDatacubeForOneStudy(physdata, cdPatient, cdAntibiotics, pmStudyInfo(a, :), measures, nmeasures);
    
    % combine results into one array
    if a == 1
        pmPatients    = temp_pmPatients;
        pmAntibiotics = temp_pmAntibiotics;
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
        tempabpnbr = innerjoin(pmAntibiotics(:,{'Study', 'ID'}), pmPatients(:,{'PatientNbr', 'Study', 'ID'}));
        pmAntibiotics.PatientNbr = tempabpnbr.PatientNbr;
        
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

