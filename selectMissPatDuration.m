function [mpdur, validresponse] = selectMissPatDuration()

% selectMissPatDuration - choose the duration of the missingness pattern

validresponse = true;

smpdur = input('Choose missingness pattern duration (7, 14, 25 days) ? ', 's');

mpdur = str2double(smpdur);

if (isnan(mpdur) || ~(mpdur == 7 || mpdur == 14 || mpdur == 25))
    fprintf('Invalid choice\n');
    validresponse = false;
    mpdur = 0;
    return;
end

end

