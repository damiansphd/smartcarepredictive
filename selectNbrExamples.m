function [nexamples, validresponse] = selectNbrExamples(type, maxexamples)

% selectNbrExamples - select how many missingness pattern examples to run
% for

snexamples = input(sprintf('Choose number of %s missingness patterns (0-%d)? ', type, maxexamples), 's');

nexamples = str2double(snexamples);

if (isnan(nexamples) || nexamples < 0 || nexamples > maxexamples)
    fprintf('Invalid choice\n');
    validresponse = false;
    nexamples = 0;
else
    validresponse = true;
end

end

