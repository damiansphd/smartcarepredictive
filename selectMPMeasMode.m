function [mpmeasmode, mpmeasidx, mpmeastxt, validresponse] = selectMPMeasMode(mpmeasures)

% selectMPMeasMode - selects which measure to apply the missingness pattern
% to, or all measures

smpmeasmode = input(sprintf('Select measures mode (1 = All measures, 2 = Single Measure Excl 3 = Single Measure Inc) ? '), 's');

mpmeasmode = str2double(smpmeasmode);
mpmeastxt = ' ';

if (isnan(mpmeasmode) || mpmeasmode < 1 || mpmeasmode > 3)
    fprintf('Invalid choice\n');
    validresponse = false;
    mpmeasmode = 0;
else
    validresponse = true;
end

mpmeasidx = 0;

if mpmeasmode ==1
    mpmeastxt = 'All';
elseif (mpmeasmode == 2) || (mpmeasmode == 3)
    fprintf('\n');
    fprintf('Index  MeasureName \n');
    fprintf('-----  ----------- \n');
    for m = 1:size(mpmeasures, 1)
        if logical(mpmeasures.RawMeas(m))
            fprintf('  %2d  %13s\n', mpmeasures.Index(m), mpmeasures.DisplayName{m});
        end
    end
    fprintf('\n');
    smpmeasidx = input(sprintf('Select measure to apply missingess pattern to from list above ? '), 's');
    mpmeasidx = str2double(smpmeasidx);

    if (isnan(mpmeasidx) || ~ismember(mpmeasidx, mpmeasures.Index(logical(mpmeasures.RawMeas))))
        fprintf('Invalid choice\n');
        validresponse = false;
        mpmeasmode = 0;
        mpmeasidx = 0;
    else
        mpmeastxt = mpmeasures.ShortName{mpmeasidx};
        validresponse = true;
    end
else
    fprintf('**** Unknown mp model mode ****\n');
    validresponse = false;
    return;
end

end

