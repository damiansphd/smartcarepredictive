function [scenmode, scenthresh, scensuffix, validresponse] = selectStudyScenario()

% selectStudyScenario - enter the study data completeness scenario
%
%   Study Data Completeness Filtering
%       0: Baseline - all patients
%       1: >= 10%
%       2: >= 20%
%       3: >= 30%
%       4: >= 40%
%       5: >= 50%
%

fprintf('Select data completeness scenario\n');
fprintf('---------------------------------\n');

fprintf('0: Baseline - all patients\n');
fprintf('1: >= 10%%\n');
fprintf('2: >= 20%%\n');
fprintf('3: >= 30%%\n');
fprintf('4: >= 40%%\n');
fprintf('5: >= 50%%\n');
fprintf('\n');

sscenmode = input('Enter data completeness scenario ? ', 's');
scenmode = str2double(sscenmode);
if (isnan(scenmode) || scenmode < 0 || scenmode > 5)
    fprintf('Invalid choice - defaulting to baseline\n');
    validresponse = 0;
    scenmode = 0;
else
    validresponse = 1;
end
fprintf('\n');

scenthresh = scenmode * 10;

scenmode   = sprintf('S%d', scenmode);
scensuffix = sprintf('scn%s', scenmode);

end