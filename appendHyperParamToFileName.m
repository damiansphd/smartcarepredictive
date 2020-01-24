function [hpfilename] = appendHyperParamToFileName(filename, lr, lc, mls, mns)

% appendHyperParamToFileName - append the hyperparameters to the filename

hpfilename = sprintf('%s-lr%.2f-lc%d-ml%d-ns%d', ...
            filename, lr, lc, mls, mns);

end

