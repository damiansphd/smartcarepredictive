function [measures, nmeasures] = createMeasuresTable(pmStudyInfo, nstudies, basedir, subfolder)
% createMeasuresTable - creates the measures table across one or more
% studies (and removes duplicates as necessary)

for a = 1:nstudies
    fprintf('Processing study %s\n', pmStudyInfo.StudyName{a});
    study = pmStudyInfo.Study{a};
    [datamatfile, ~, ~] = getRawDataFilenamesForStudy(study);
    [physdata, ~] = loadAndHarmoniseMeasVars(datamatfile, subfolder, study);
    %load(fullfile(basedir, subfolder, pmStudyInfo.MeasurementMatFile{a}));
    %if isequal(pmStudyInfo.Study(a), {'TM'})
    %    physdata = tmphysdata;
    %end
    [temp_measures, temp_nmeasures] = createMeasuresTableForOneStudy(physdata, study);
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

end

