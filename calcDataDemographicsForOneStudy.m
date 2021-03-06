
function [pmOverallDemographics, pmPatientDemographics] = calcDataDemographics(pmRawDatacube, pmPatient, pmStudyInfoRow)

% calcDataDemographics - function that creates data
% demographics (overall and by patient) and stores matlab variables and creates an excel
% file of results

pmPatient = sortrows(pmPatient, {'PatientNbr'}, 'ascend');

fprintf('Calculating data demographics by patient\n');
tempdata = physdata;
tempdata(:,{'UserName', 'ScaledDateNum', 'DateNum', 'Date_TimeRecorded', 'FEV1', 'PredictedFEV', 'ScalingRatio', 'CalcFEV1SetAs'}) = [];

demofunc = @(x)[mean(x)  std(x)  min(x)  max(x) mid50mean(x) upper50mean(x) lower50mean(x) upper75mean(x) lower75mean(x)];
demographicstable = varfun(demofunc, tempdata, 'GroupingVariables', {'SmartCareID', 'RecordingType'});

tempdata(:,{'SmartCareID'}) = [];
overalltable = varfun(demofunc, tempdata, 'GroupingVariables', {'RecordingType'});

% example of how to access max FEV1_ for a given row
% demographicstable(3,:).Fun_FEV1_(4)

measurecounttable = demographicstable(:, {'SmartCareID','RecordingType', 'GroupCount'});

demographicstable = sortrows(demographicstable, {'RecordingType','SmartCareID'});
overalltable = sortrows(overalltable, {'RecordingType'});

timenow = datestr(clock(),30);

basedir = './';
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%sdatademographicsbypatient-%s.mat', study, timenow);
fprintf('Saving output variables to matlab file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), 'measurecounttable', 'demographicstable', 'overalltable');
outputfilename = sprintf('%sdatademographicsbypatient.mat', study);
fprintf('Saving output variables to matlab file %s\n', outputfilename);
save(fullfile(basedir, subfolder, outputfilename), 'measurecounttable', 'demographicstable', 'overalltable');

basedir = './';
subfolder = 'ExcelFiles';
outputfilename = sprintf('%sDataDemographicsByPatient-%s.xlsx',study, timenow);
fprintf('Saving results to excel file %s\n', outputfilename);
writetable(measurecounttable, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'MeasureCountByPatient');
writetable(demographicstable, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'DataDemographicsByPatient');
writetable(overalltable, fullfile(basedir, subfolder, outputfilename), 'Sheet', 'OverallDataDemographics');

end
