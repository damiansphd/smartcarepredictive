function [mindatarule, validresponse] = selectMinDataRuleType()

% selectMinDataRuleType - choose whether to drop data points for a given
% measure/day or for all measures on a given day at each iteration

smindatarule = input(sprintf('Select min data rule type (1 = One measure at a time, 2 = All measures) ? '), 's');

mindatarule = str2double(smindatarule);

if (isnan(mindatarule) || mindatarule < 1 || mindatarule > 2)
    fprintf('Invalid choice\n');
    validresponse = false;
    mindatarule = 0;
else
    validresponse = true;
end

end

