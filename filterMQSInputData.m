function [pmFIWithSignal, pmAMPred, pmPatients] = filterMQSInputData(pmFIWithSignal, pmAMPred, pmPatients, idlist)

% filterMQSInputData - filters the data needed for model quality scores based 
% on the list of study id's based on the cohort and scenario filtering selected

% get list of patients that correspond to the idlist - that s/s used the
% alignment model patient identifier, not the predictive model patient
% number
patlist = pmPatients.PatientNbr(ismember(pmPatients.ID, idlist));

% filter the relevant data tables/arrays accordingly
pmFIWithSignal = pmFIWithSignal(ismember(pmFIWithSignal.PatientNbr, patlist), :);
pmAMPred       = pmAMPred(ismember(pmAMPred.PatientNbr, patlist), :);
pmPatients     = pmPatients(ismember(pmPatients.PatientNbr, patlist), :);

end