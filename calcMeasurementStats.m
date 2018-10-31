
function [pmOverallStats, pmPatientMeasStats] = calcMeasurementStats(pmRawDatacube, pmPatients, measures, npatients, maxdays, nmeasures, studydisplayname)

% calcMeasurementStats - function that calculates measurement statistics 
% (overall and by patient) and creates an excel file of results

pmPatientMeasStats = table('Size',[(npatients * nmeasures), 15], ...
    'VariableTypes', {'double', 'cell', 'double', 'double', 'cell', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'PatientNbr', 'Study', 'ID', 'MeasureIndex', 'MeasureName', 'Count', 'Mean', 'StdDev', 'Min', 'Max', ...
    'Mid50Mean', 'Upper50Mean', 'Lower50Mean', 'Upper75Mean', 'Lower75Mean'});

pmOverallStats = table('Size',[nmeasures, 12], ...
    'VariableTypes', {'double', 'cell', 'double', 'double', 'double', 'double', 'double', ...
    'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'MeasureIndex', 'MeasureName', 'Count', 'Mean', 'StdDev', 'Min', 'Max', ...
    'Mid50Mean', 'Upper50Mean', 'Lower50Mean', 'Upper75Mean', 'Lower75Mean'});

fprintf('Calculating measurement stats by patient\n');
for p = 1:npatients
    fprintf('Processing patient %d\n', p);
    for m = 1:nmeasures
        %fprintf('Processing measure %d\n', m);
        row = nmeasures * (p-1) + m;
        data = pmRawDatacube(p, ~isnan(pmRawDatacube(p, :, m)), m)';
        if (size(data,1) > 2)
            pmPatientMeasStats.PatientNbr(row)   = p;
            pmPatientMeasStats.Study(row)        = pmPatients.Study(p);
            pmPatientMeasStats.ID(row)           = pmPatients.ID(p);
            pmPatientMeasStats.MeasureIndex(row) = m;
            pmPatientMeasStats.MeasureName(row)  = measures.Name(m);
            pmPatientMeasStats.Count(row)        = size(data,1);
            pmPatientMeasStats.Mean(row)         = mean(data);
            pmPatientMeasStats.StdDev(row)       = std(data);
            pmPatientMeasStats.Min(row)          = min(data);
            pmPatientMeasStats.Max(row)          = max(data);
            pmPatientMeasStats.Mid50Mean(row)    = mid50mean(data);
            pmPatientMeasStats.Upper50Mean(row)  = upper50mean(data);
            pmPatientMeasStats.Lower50Mean(row)  = lower50mean(data);
            pmPatientMeasStats.Upper75Mean(row)  = upper75mean(data);
            pmPatientMeasStats.Lower75Mean(row)  = lower75mean(data);     
        end
    end
end
pmPatientMeasStats(pmPatientMeasStats.PatientNbr==0,:) = [];


fprintf('Calculating overall measurement stats\n');
for m = 1:nmeasures
    data = reshape(pmRawDatacube(:, :, m), [1 (npatients * maxdays)]);
    data = data(~isnan(data))';
    if (size(data,1) > 2)
        pmOverallStats.MeasureIndex(m) = m;
        pmOverallStats.MeasureName(m)  = measures.Name(m);
        pmOverallStats.Count(m)        = size(data,1);
        pmOverallStats.Mean(m)         = mean(data);
        pmOverallStats.StdDev(m)       = std(data);
        pmOverallStats.Min(m)          = min(data);
        pmOverallStats.Max(m)          = max(data);
        pmOverallStats.Mid50Mean(m)    = mid50mean(data);
        pmOverallStats.Upper50Mean(m)  = upper50mean(data);
        pmOverallStats.Lower50Mean(m)  = lower50mean(data);
        pmOverallStats.Upper75Mean(m)  = upper75mean(data);
        pmOverallStats.Lower75Mean(m)  = lower75mean(data); 
    end
end
pmOverallStats(pmOverallStats.Count==0,:) = [];

basedir = setBaseDir();
subfolder = 'ExcelFiles';
outputfilename = sprintf('%sMeasurementStats.xlsx', studydisplayname);
fprintf('Saving results to excel file %s\n', outputfilename);
writetable(pmOverallStats, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'OverallStats');
writetable(pmPatientMeasStats, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'ByPatientStats');

end
