clear; close all; clc;

[studynbr, studydisplayname, pmStudyInfo] = selectStudy();
nstudies = size(pmStudyInfo,1);

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
npatients = 0;
ndays = 0;
%pmPatients = table('Size',[1, 9], 'VariableTypes', {'double', 'string(2)', 'double', 'datetime', 'datetime', 'datetime', 'double', 'double', 'double'}, ...
%    'VariableNames', {'PatientNbr', 'Study', 'ID', 'StudyStartDate', 'FirstMeasDate', 'LastMeasDate', 'StudyStartdn', 'FirstMeasdn', 'LastMeasdn'});

fprintf('Creating Measures table\n');
for a = 1:nstudies
    fprintf('Processing study %s\n', pmStudyInfo.StudyName{a});
    load(fullfile(basedir, subfolder, pmStudyInfo.MeasurementMatFile{a}));
    if isequal(pmStudyInfo.Study(a), {'TM'})
        physdata = tmphysdata;
    end
    fprintf('Creating measures table\n');
    [temp_measures, temp_nmeasures] = createMeasuresTable(physdata);
    if a == 1
        measures   = temp_measures;
        nmeasures  = temp_nmeasures;
    else
        nmeasures_before = nmeasures;
        nmeasures_incr = temp_nmeasures;
        measures.Index(:) = 0;
        temp_measures.Index(:) = 0;
        measures = unique([measures; temp_measures]);
        nmeasures = size(measures, 1);
        measures.Index = (1:nmeasures)';
        if (nmeasures < (nmeasures_before + nmeasures_incr))
            fprintf('There were %d duplicate measurement types\n', nmeasures_before + nmeasures_incr - nmeasures);
        else
            fprintf('There were no duplicate measurement types\n');
        end
    end
end

for a = 1:nstudies
    fprintf('Processing study %s\n', pmStudyInfo.StudyName{a});
    fprintf('Loading clinical data\n');
    load(fullfile(basedir, subfolder, pmStudyInfo.ClinicalMatFile{a}));
    fprintf('Loading measurement data\n');
    load(fullfile(basedir, subfolder, pmStudyInfo.MeasurementMatFile{a}));
    fprintf('Loading iv treatment and measures prior data\n');
    load(fullfile(basedir, subfolder, pmStudyInfo.IVAndMeasuresMatFile{a}));
    if isequal(pmStudyInfo.Study(a), {'TM'})
        physdata = tmphysdata;
        cdPatient = tmPatient;
        cdAntibiotics = tmAntibiotics;
        offset = tmoffset;
    end
    tic
    % create datacube - 3D array of patients/days/measures for model
    fprintf('Creating 3D data array\n');
    [temp_pmPatients, temp_pmDatacube, temp_npatients, temp_maxdays] = createPMDataCube(physdata, cdPatient, offset, measures, nmeasures, pmStudyInfo.Study{a});
    
    if a == 1
        pmPatients = temp_pmPatients;
        pmDatacube = temp_pmDatacube;
        npatients  = temp_npatients;
        maxdays    = temp_maxdays;
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
        else
            fprintf('There were no duplicate patients\n');
        end
        
        if maxdays > temp_maxdays
            temp_pmDatacube(:, (temp_maxdays + 1): maxdays, :) = nan;
        elseif temp_maxdays > maxdays
            pmDatacube(:, (maxdays + 1): temp_maxdays, :) = nan;
            maxdays = temp_maxdays;
        end
        pmDatacube = [pmDatacube; temp_pmDatacube];
    end
    toc
end
toc
fprintf('\n');

% create list of interventions with enough data to run model on
%tic
%fprintf('Creating list of interventions\n');
%amInterventions = createListOfInterventions(ivandmeasurestable, physdata, offset);
%ninterventions = size(amInterventions,1);
%toc

tic
basedir = './';
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%spredictivemodelinputs.mat', studydisplayname);
fprintf('Saving output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'pmPatients', 'pmDatacube', 'measures', 'npatients','maxdays', 'nmeasures');
toc




