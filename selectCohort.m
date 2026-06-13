function [cohortfiltmode, cohortmatch, cohortsuffix, validresponse] = selectCohort()

% selectCohort - enter the cohort for filtering data
%
%   Cohort Filtering
%       1: Only include measurement data for signal cohort
%       2: Only include measurement data for breathe only cohort
%       3: Include measurement data for both cohorts
%

fprintf('Select cohort filter method\n');
fprintf('---------------------------\n');

fprintf('1: Only include signal cohort\n');
fprintf('2: Only include breathe only cohort\n');
fprintf('3: Include both cohorts\n');
fprintf('\n');

scohortfiltmode = input('Enter cohort filter method ? ', 's');
cohortfiltmode = str2double(scohortfiltmode);
if (isnan(cohortfiltmode) || cohortfiltmode < 1 || cohortfiltmode > 3)
    fprintf('Invalid choice - defaulting to 3\n');
    validresponse = false;
    cohortfiltmode = 3;
else
    validresponse = 1;
end
fprintf('\n');

if cohortfiltmode == 1
    cohortmatch  = {'Signal'};
    cohortsuffix = 'SIG';
elseif cohortfiltmode == 2
    cohortmatch  = {'Breathe Only'};
    cohortsuffix = 'BRO';
elseif cohortfiltmode == 3
    cohortmatch  = {'Signal', 'Breathe Only'};
    cohortsuffix = 'ALL';
else
    cohortmatch  = 'ERR';
    cohortsuffix = 'ERR';
end

cohortsuffix = sprintf('cht%s', cohortsuffix);

end