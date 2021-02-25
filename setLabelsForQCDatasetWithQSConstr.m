function [labels, labelsbyqs] = setLabelsForQCDatasetWithQSConstr(pmMissPattQSPct, pmQSConstr, threshtype)

% setLabelsForQCDatasetWithQSConstr - sets the labels for the missingness
% pattern/quality classifier data set - based on a threshold from the baseline 
% quality score for one or more quality measure constraints

nqsconstr = size(pmQSConstr, 1);
nexamples = size(pmMissPattQSPct, 1);
threshcol = sprintf('%sthresh', threshtype);

labelsbyqs = false(nexamples, nqsconstr);

for i = 1:nqsconstr
    if ismember(pmQSConstr.threshdir(i), {'gt'})
        labelsbyqs(:, i) = table2array(pmMissPattQSPct(:, pmQSConstr.qsmeasure{i})) >= table2array(pmQSConstr(i, threshcol));
    elseif ismember(pmQSConstr.threshdir(i), {'lt'})
        labelsbyqs(:, i) = table2array(pmMissPattQSPct(:, pmQSConstr.qsmeasure{i})) <= table2array(pmQSConstr(i, threshcol));
    else
        fprintf('**** Unknown threshold type ****\n');
        labels = [];
        return
    end
    fprintf('Constraint %s gives %d of %d positive labels\n', pmQSConstr.qsmeasure{i}, sum(labelsbyqs(:, i)), size(labelsbyqs, 1));
    if i == 1
        labels = labelsbyqs(:, 1);
    else
        labels = labelsbyqs(:, i - 1) & labelsbyqs(:, i);
    end
end

%labels = table2array(pmMissPattQSPct(:, {qsmeasure})) >= qsthresh;

fprintf('All constraints give %d of %d positive labels\n', sum(labels), size(labels, 1));

end

