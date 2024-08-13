function [physdata, cdAntibiotics, amInterventions] = filtMeasData(physdata, cdDrugTherapy, cdAntibiotics, amInterventions, datafiltmthd)

% filtMeasData - function to filter input measurement data

%   datafiltmthd == 1 - no filtering
%   datafiltmthd == 2 - only keep data while patients are on triple therapy

ttname = {'Kaftrio/Trikafta/TripleTherapy'};

% extract start date of most recent continuous period on triple therapy
ttdrugtherapy = cdDrugTherapy(ismember(cdDrugTherapy.DrugTherapyType, ttname) & isnat(cdDrugTherapy.DrugTherapyStopDate), {'ID', 'DrugTherapyStartDate'});

% hardcoded clean up of back data until REDCap data is corrected
ttdrugtherapy(ttdrugtherapy.ID == 221 & ttdrugtherapy.DrugTherapyStartDate == datetime(2020, 08, 22), :) = [];
ttdrugtherapy(ttdrugtherapy.ID == 247 & ttdrugtherapy.DrugTherapyStartDate == datetime(2018, 07, 01), :) = [];

if datafiltmthd == 1
    % do nothing - keep all data
elseif datafiltmthd == 2
    fprintf('Filtering data to only keep while on triple therapy\n');
    fprintf('---------------------------------------------------\n');
    origpats   = size(unique(physdata.SmartCareID), 1);
    origrows   = size(physdata, 1);
    origabrows = size(cdAntibiotics, 1);
    origintr   = size(amInterventions, 1);
    fprintf('Before: # Patients = %3d, # Data Records = %d, # Antibiotic records = %d, # Interventions = %d\n', ...
        origpats, origrows, origabrows, origintr);
    fprintf('\n');
    
    % get the min meas dates by patient prior to any updates
    doupdates = false;
    [~, origmindatesbypat] = scaleDaysByPatient(physdata, doupdates);
    origmindatesbypat.Properties.VariableNames(2) = {'OrigMinPatientDateNum'};
    
    % filter to only keep measurement data while patients on triple therapy
    physdata = innerjoin(physdata, ttdrugtherapy, 'LeftKeys', 'SmartCareID', 'RightKeys', 'ID', 'RightVariables', 'DrugTherapyStartDate');
    physdata = physdata(physdata.Date_TimeRecorded > physdata.DrugTherapyStartDate, :);
    % reset the ScaledDateNum to align to the (now later) first measurement
    % date.
    doupdates = true;
    [physdata, updmindatesbypat] = scaleDaysByPatient(physdata, doupdates);
    physdata.DrugTherapyStartDate = [];
    
    % filter to only keep AB treatments while patients on triple therapy
    cdAntibiotics = innerjoin(cdAntibiotics, ttdrugtherapy, 'LeftKeys', 'ID', 'RightKeys', 'ID', 'RightVariables', 'DrugTherapyStartDate');
    cdAntibiotics = cdAntibiotics(cdAntibiotics.StopDate >= cdAntibiotics.DrugTherapyStartDate, :);
    cdAntibiotics.DrugTherapyStartDate = [];
    
    % filter to only keep Interventions while patients on triple therapy
    % also need to scale the relative dates in amInterventions table
    % (ie IVScaledStartdn, IVScaledStopdn, Pred, RelLB1, RelUB1, RelLB2, RelUB2)
    amInterventions = innerjoin(amInterventions, ttdrugtherapy, 'LeftKeys', 'SmartCareID', 'RightKeys', 'ID', 'RightVariables', 'DrugTherapyStartDate');
    amInterventions = amInterventions(amInterventions.IVStartDate >= amInterventions.DrugTherapyStartDate, :);
    amInterventions.DrugTherapyStartDate = [];
    
    updmindatesbypat = innerjoin(updmindatesbypat, origmindatesbypat, 'LeftKeys', 'SmartCareID', 'RightKeys', 'SmartCareID', 'RightVariables', 'OrigMinPatientDateNum');
    updmindatesbypat.RelDiff = updmindatesbypat.MinPatientDateNum - updmindatesbypat.OrigMinPatientDateNum;
    
    amInterventions = innerjoin(amInterventions, updmindatesbypat, 'LeftKeys', 'SmartCareID', 'RightKeys', 'SmartCareID', 'RightVariables', 'RelDiff');
    amInterventions.IVScaledDateNum           = amInterventions.IVScaledDateNum - amInterventions.RelDiff;
    amInterventions.IVScaledStopDateNum       = amInterventions.IVScaledStopDateNum - amInterventions.RelDiff;
    amInterventions.PatientOffset             = amInterventions.IVDateNum - amInterventions.IVScaledDateNum;
    amInterventions.Pred                      = amInterventions.Pred - amInterventions.RelDiff;
    amInterventions.RelLB1                    = amInterventions.RelLB1 - amInterventions.RelDiff;
    amInterventions.RelUB1                    = amInterventions.RelUB1 - amInterventions.RelDiff;
    amInterventions.RelLB2(amInterventions.RelLB2 ~= -1) = amInterventions.RelLB2(amInterventions.RelLB2 ~= -1) - amInterventions.RelDiff(amInterventions.RelLB2 ~= -1);
    amInterventions.RelUB2(amInterventions.RelUB2 ~= -1) = amInterventions.RelUB2(amInterventions.RelUB2 ~= -1) - amInterventions.RelDiff(amInterventions.RelUB2 ~= -1);
    amInterventions.RelDiff = [];
    
    updpats = size(unique(physdata.SmartCareID), 1);
    updrows = size(physdata, 1);
    updabrows = size(cdAntibiotics, 1);
    updintr   = size(amInterventions, 1);
    fprintf('After: # Patients = %3d, # Data Records = %d, # Antibiotic records = %d, # Interventions = %d\n', ...
        updpats, updrows, updabrows, updintr);
    fprintf('\n');
else
    fprintf('**** Unknown data filtering method ****');
end


end

