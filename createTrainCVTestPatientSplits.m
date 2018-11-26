clear; clc; close all;

[~, studydisplayname, ~] = selectStudy();

tic
basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
inputfilename = sprintf('%spredictivemodelinputs.mat', studydisplayname);
load(fullfile(basedir, subfolder, inputfilename));

nsplits = 5;

pinter = outerjoin(pmPatients, pmAMPred);

pnointer = array2table(pinter.PatientNbr_pmPatients(isnan(pinter.PatientNbr_pmAMPred),:));
pnointer.Properties.VariableNames({'Var1'}) = {'PatientNbr'};
pnointer.SplitNbr(:) = 0;

pinter(isnan(pinter.PatientNbr_pmAMPred),:) = [];
pinter = array2table(unique(pinter.PatientNbr_pmPatients));
pinter.Properties.VariableNames({'Var1'}) = {'PatientNbr'};
pinter.SplitNbr(:) = 0;

rng(2);
nointerrand = randperm(size(pnointer, 1));
interrand   = randperm(size(pinter  , 1));

nnointer = size(pnointer,1);
ninter   = size(pinter,1);

for a = 1:nsplits
    ifrom = ceil((a-1) * nnointer  / nsplits) + 1;
    ito   = ceil((a    * nnointer) / nsplits);
    %fprintf('NoInter: Split %2d: From %2d To %2d\n', a, ifrom, ito);
    pnointer.SplitNbr(nointerrand(ifrom:ito)) = a;
    
    ifrom = ceil((a-1) * ninter  / nsplits) + 1;
    ito   = ceil((a    * ninter) / nsplits);
    %fprintf('Inter: Split %2d: From %2d To %2d\n', a, ifrom, ito);
    pinter.SplitNbr(interrand(ifrom:ito)) = a;
end

pmPatientSplit = sortrows([pinter; pnointer], {'PatientNbr'}, {'ascend'});

basedir = setBaseDir();
subfolder = 'MatlabSavedVariables';
outputfilename = sprintf('%spatientsplit.mat', studydisplayname);
fprintf('Saving output variables to file %s\n', outputfilename);
save(fullfile(basedir, subfolder,outputfilename), 'pmPatientSplit', 'nsplits');
toc
fprintf('\n');





