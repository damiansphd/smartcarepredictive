function [resstruct] = predictPredModel(resstruct, predmodel, features, labels, modelver, lossfunc)

% predictPredModel - generate predictions from the trained model

if ismember(modelver, {'vPM1'})
    resstruct.Pred = predict(predmodel, features);
else    
    [~, tempscore] = predict(predmodel, features);
    tempscore      = tempscore ./ sum(tempscore, 2);
    resstruct.Pred = tempscore(:, 2);
    resstruct.Loss = loss(predmodel, features, labels, 'Lossfun', lossfunc);
end

end


