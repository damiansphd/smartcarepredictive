
setBaseDir();
subfolder = 'MatlabSavedVariables';
load(fullfile(basedir, subfolder, 'smartcaredata.mat'), 'physdata_predupehandling');

sortrows(physdata_original(ismember(physdata_original.UserName, {'BRISTOLSC020'}) & ismember(physdata_original.RecordingType, {'LungFunctionRecording'}),:), {'Date_TimeRecorded'},'ascend')

sortrows(physdata_original(ismember(physdata_original.UserName, {'BRISTOLSC013'}) & ismember(physdata_original.RecordingType, {'LungFunctionRecording'}),:), {'Date_TimeRecorded'},'ascend')

sortrows(physdata_original(ismember(physdata_original.UserName, {'wessex0003'}) & ismember(physdata_original.RecordingType, {'LungFunctionRecording'}),:), {'Date_TimeRecorded'},'ascend')

physdata = physdata_predupehandling;

idxna = find(ismember(physdata.RecordingType,'LungFunctionRecording'));
timewindow = '00:30:00';
diffDTR = diff(physdata.Date_TimeRecorded);
similaridx = find(diffDTR > '00:00:00' & diffDTR < timewindow);
nasimidx = intersect(similaridx, idxna);

invalididx = find(physdata.SmartCareID(nasimidx) ~= physdata.SmartCareID(nasimidx+1));
nasimidx(invalididx) = [];


