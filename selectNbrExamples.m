function [nexamples, validresponse] = selectNbrExamples(maxexamples)

% selectNbrExamples - select how many missingness pattern examples to run
% for

snexamples = input(sprintf('Choose number of missingness patterns (1-%d)? ', maxexamples), 's');

nexamples = str2double(snexamples);

if (isnan(nexamples) || nexamples < 1 || nexamples > maxexamples)
    fprintf('Invalid choice\n');
    validresponse = false;
    nexamples = 0;
else
    validresponse = true;
end

end

