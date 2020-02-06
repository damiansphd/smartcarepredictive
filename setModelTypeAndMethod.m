function [modeltype, mmethod] = setModelTypeAndMethod(modelver)

% setModelNameAndMethod - sets the model type and method

if isequal(modelver, 'vPM10')
    modeltype = 'Random Forest';
    mmethod   = 'Bag';
elseif isequal(modelver, 'vPM11')
    modeltype = 'RUS Boosted Tree Ensemble';
    mmethod   = 'RUSBoost';
elseif isequal(modelver, 'vPM12')
    modeltype = 'Logit Boosted Tree Ensemble';
    mmethod   = 'LogitBoost';
elseif isequal(modelver, 'vPM13')
    modeltype = 'Adaptive Boosting Tree Ensemble';
    mmethod   = 'AdaBoostM1';
end

end

