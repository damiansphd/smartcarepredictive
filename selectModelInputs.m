function [modelinputfile, modelidx, modelinputs] = selectModelInputs()

% selectModelInputs - select the matlab saved variable file for the model
% inputs

modelinputs = {  
            'SCpredictivemodelinputs';
            'TMpredictivemodelinputs';
            'SC_TMpredictivemodelinputs';
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

