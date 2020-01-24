function [fold, validresponse] = selectFold(nfolds)

% selectFold - select which fold to run plot for

sfold = input(sprintf('Choose fold (1-%d) ? ', nfolds), 's');

fold = str2double(sfold);

if (isnan(fold) || fold < 1 || fold > nfolds)
    fprintf('Invalid choice\n');
    validresponse = false;
    fold = 0;
else
    validresponse = true;
end

end

