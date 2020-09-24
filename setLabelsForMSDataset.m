function labels = setLabelsForMSDataset(pmMissPattQS, pmBaselineQS, qsmeasure, threshold)

% setLabelsForMSDataset - sets the labels for the missingness pattern/qs
% data set - based on a threshold from the baseline quality score for a given quality score

baselineqs = table2array(pmBaselineQS(1, {qsmeasure})) * threshold;

labels = table2array(pmMissPattQS(:, {qsmeasure})) > baselineqs;

fprintf('Missingness pattern dataset has %d of %d positive labels\n', sum(labels), size(labels, 1));

end

