function [resstruct] = predictPredModel(resstruct, predmodel, features, labels, lossfunc)

% predictPredModel - generate predictions from the trained model

[~, tempscore] = predict(predmodel, features);
                                    
tempscore          = tempscore ./ sum(tempscore, 2);
resstruct.Pred = tempscore(:, 2);
resstruct.Loss = loss(predmodel, features, labels, 'Lossfun', lossfunc);

end

