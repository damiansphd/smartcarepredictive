function [modelinputfile, modelidx, modelinputs] = selectFeatureAndLabelInputs()

% selectModelInputs - select the matlab saved variable file for the model
% inputs

modelinputs = {  
            'pm_stSC_fd20_pd15_mm1_nm2_sm1_tp0.70';
            };

nmodels = size(modelinputs,1);
fprintf('Model input files available\n');
fprintf('---------------------------\n');
for i = 1:nmodels
    fprintf('%d: %s\n', i, modelinputs{i});
end
fprintf('\n');

modelidx = input('Choose model run to use ? ');
if modelidx > nmodels 
    fprintf('Invalid choice\n');
    return;
end
if isequal(modelidx,'')
    fprintf('Invalid choice\n');
    return;
end
fprintf('\n');

modelinputfile = modelinputs{modelidx};

end

