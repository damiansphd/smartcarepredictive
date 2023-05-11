clear; close all; clc;

basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

[studynbr, studydispname, pmStudyInfo] = selectStudy();

[fv1name, validresponse] = selectFeatVer();
if ~validresponse
    return
end

[modfeatparamfile, ~, ~, validresponse] = selectModelFeatureParameters(fv1name);
if ~validresponse
    return
end

modfeatparamfile = strcat(modfeatparamfile, '.xlsx');
subfolder = 'DataFiles';
pmModFeatureParams = readtable(fullfile(basedir, subfolder, modfeatparamfile));
pmModFeatParamsRow = pmModFeatureParams(1,:);
inputmatfile = generateFileNameFromModFeatureParams(pmModFeatParamsRow);
inputmatfile = sprintf('%s.mat', inputmatfile);

[vid, vname, validresponse] = selectPythVarName();
if ~validresponse
    return
end

fprintf('Loading input data\n');
tic
subfolder = 'MatlabSavedVariables';
if ~ismember(vname, {'pmPatientSplit'})
    load(fullfile(basedir, subfolder, inputmatfile), 'measures', 'pmPatients', 'npatients', 'pmModFeatParamsRow', 'totalvolwin', 'pmNormFeatNames', vname);
    
    % create selected measures table
    nselmeas = 7;
    selmeas = measures(ismember(measures.Index, [2,10,13,14,16,17,18]), {'Index', 'DisplayName'});
else
    psplitfile = sprintf('%spatientsplit.mat', studydispname);
    fprintf('Loading patient splits from file %s\n', psplitfile);
    load(fullfile(basedir, subfolder, psplitfile), vname);
end

toc
fprintf('\n');

tic
fprintf('Creating output data\n');

if ismember(vname, {'pmPatients', 'pmAntibiotics', 'pmAMPred', 'pmOverallStats', 'pmPatientMeasStats', 'measures', 'pmPatientSplit'})
    
    eval(sprintf('outputtable = %s;', vname));
    
elseif ismember(vname, {'pmRawDatacube'})

    % calculate total rows for output table and create table
    totdays = sum(pmPatients.RelLastMeasdn - pmPatients.RelFirstMeasdn + 1);
    totrows = nselmeas * totdays;
    outputtable = table('Size',[totrows, 4], ...
        'VariableTypes', {'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'PatientNbr', 'ScaledDateNum', 'Index', 'Value'});

    curridx = 1;
    for i = 1:npatients
        pnbr = pmPatients.PatientNbr(i);
        pmindays = pmPatients.RelFirstMeasdn(i);
        pmaxdays = pmPatients.RelLastMeasdn(i);
        fprintf('Processing patient %3d for days %4d to %4d\n', pnbr, pmindays, pmaxdays);

        for m = 1:nselmeas
            midx = selmeas.Index(m);
            fprintf('Measure %2d:%13s\n', midx, selmeas.DisplayName{m});

            valarray = pmRawDatacube(pnbr, pmindays:pmaxdays, midx);
            nextidx = curridx + size(valarray, 2);
            outputtable.PatientNbr(curridx:nextidx - 1) = pnbr;
            outputtable.ScaledDateNum(curridx:nextidx - 1) = pmindays:pmaxdays;
            outputtable.Index(curridx:nextidx - 1) = midx;
            outputtable.Value(curridx:nextidx - 1) = valarray;

            curridx = nextidx;
        end
    end

    fprintf('\n');
    % remove null value rows
    nullvalidx = isnan(outputtable.Value);
    fprintf('Removing %d null value rows\n', sum(nullvalidx));
    outputtable(nullvalidx,:) = [];

    % sort output to match python
    fprintf('Sorting table to match python\n');
    outputtable = sortrows(outputtable, {'Index', 'PatientNbr', 'ScaledDateNum'}, 'ascend');
    fprintf('\n');

elseif ismember(vname, {'pmFeatureIndex'})
    
    outputtable = pmFeatureIndex;
    nrundays = size(pmFeatureIndex,1);
    outputtable.Index = (1:nrundays)';
    
elseif ismember(vname, {'pmDataWinArray', 'pmNormDataWinArray', 'pmInterpNormDataWinArray', 'pmRawMeasWinArray', 'pmVolWinArray'})

    eval(sprintf('worktable = %s;', vname));
    
    % calculate total rows for output table and create table
    nrundays = size(worktable,1);
    totwin   = size(worktable,2);
    totrows = nrundays * totwin * nselmeas;
    
    outputtable = table('Size',[totrows, 4], ...
        'VariableTypes', {'double', 'double', 'double', 'double'}, ...
        'VariableNames', {'Index', 'ScaledDateNum', 'Measure', 'Value'});
    
    curridx = 1;
    for m = 1:nselmeas
        midx = selmeas.Index(m);
        fprintf('Processing for measure %d of %d\n', m, nselmeas);
        
        indexcol = repmat((1:nrundays)', totwin, 1);
        
        dayscol  = repmat((1:totwin), nrundays, 1);
        dayscol  = reshape(dayscol, nrundays*totwin, 1);
        
        valarray = reshape(worktable(:, :, midx), nrundays * totwin, 1);
        
        nextidx = curridx + size(valarray, 1);
        
        outputtable.Index(curridx:nextidx - 1) = indexcol;
        outputtable.ScaledDateNum(curridx:nextidx - 1) = dayscol;
        outputtable.Measure(curridx:nextidx - 1) = midx;
        outputtable.Value(curridx:nextidx - 1) = valarray;

        curridx = nextidx;
    end
    fprintf('\n');
    
    for m = 1:nselmeas
        midx = selmeas.Index(m);
        fprintf('%13s: Min %3.2f Max %3.2f\n', selmeas.DisplayName{m}, min(outputtable.Value(outputtable.Measure==midx)), max(outputtable.Value(outputtable.Measure==midx)));
    end
        
    % sort output to match python
    fprintf('Sorting table to match python\n');
    outputtable = sortrows(outputtable, {'Index', 'Measure', 'ScaledDateNum'}, 'ascend');
    fprintf('\n');
    
elseif ismember(vname, {'pmExABxElLabels'})
    
    % calculate total rows for output table and create table
    nrundays = size(pmExABxElLabels,1);
    
    outputtable = table('Size',[nrundays, 2], ...
        'VariableTypes', {'double', 'double'}, ...
        'VariableNames', {'Index', 'Label'});
    
    outputtable.Index = (1:nrundays)';
    outputtable.Label = pmExABxElLabels;
    
elseif ismember(vname, {'pmPMeanWinArray', 'pmMuIndex', 'pmSigmaIndex'})
    
    eval(sprintf('worktable = %s;', vname));
    outputtable = array2table(worktable(:, ismember(measures.Index, [2,10,13,14,16,17,18])'));
    outputtable.Properties.VariableNames = selmeas.DisplayName';
    outputtable.Index(:) = 1:size(outputtable,1);
    outputtable = outputtable(:, {'Index', selmeas.DisplayName{:}});
    
elseif ismember(vname, {'pmNormFeatures'})
    
    eval(sprintf('worktable = %s;', vname));
    outputtable = array2table(worktable);
    outputtable.Properties.VariableNames = pmNormFeatNames;
    outputtable.Index(:) = 1:size(outputtable,1);
    outputtable = outputtable(:, {'Index', pmNormFeatNames{:}});
    
elseif ismember(vname, {'pmNormFeatNames'})
    
    eval(sprintf('worktable = %s;', vname));
    outputtable = array2table(worktable');
    outputtable.Properties.VariableNames = {'NormFeatName'};
    outputtable.Index(:) = 1:size(outputtable,1);
    outputtable = outputtable(:, {'Index', 'NormFeatName'});

end

toc
fprintf('\n');
fprintf('Final rows count is %d\n', size(outputtable, 1));
fprintf('\n');

% save tabular output table
tic
subfolder = 'ExcelFiles';
outfilename = sprintf('%s-%s.csv', studydispname, vname);
fprintf('Saving tabular form of %s to csv file %s\n', vname, outfilename);
writetable(outputtable, fullfile(basedir, subfolder, outfilename));
toc
fprintf('\n');
        
    