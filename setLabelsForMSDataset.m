function labels = setLabelsForMSDataset(pmMissPattQSPct, qsmeasure, qsthresh)

% setLabelsForMSDataset - sets the labels for the missingness pattern/qs
% data set - based on a threshold from the baseline quality score for a given quality score

labels = table2array(pmMissPattQSPct(:, {qsmeasure})) >= qsthresh;

fprintf('Missingness pattern dataset has %d of %d positive labels\n', sum(labels), size(labels, 1));

end

