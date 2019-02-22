function printFeatVals(normfeaturerow, featureweights, calcdatedn, i, tempmeas, nmfeat, nextfeat)

% printFeatVals - prints feature weights, feature values, and product of
% these

if nmfeat > 0
    mfw        = featureweights(nextfeat:(nextfeat + nmfeat - 1));
    total      = normfeaturerow(nextfeat:(nextfeat + nmfeat - 1))  * mfw;
    components = normfeaturerow(nextfeat:(nextfeat + nmfeat - 1)) .* mfw';
    
    fprintf('%13s:    FW (', tempmeas.DisplayName{i});
    for n = 1:nmfeat - 1
       fprintf('%+.2f, ', mfw(n));
    end
    fprintf('%+.2f)\n', mfw(nmfeat));
    
    fprintf('%13s:    NF (', tempmeas.DisplayName{i});
    for n = 1:nmfeat - 1
        fprintf('%+.2f, ', normfeaturerow(nextfeat - 1 + n));
    end
    fprintf('%+.2f)\n', normfeaturerow(nextfeat - 1 + nmfeat));
    
    fprintf('%13s: %+.2f (', tempmeas.DisplayName{i}, total);
    for n = 1:nmfeat - 1
        fprintf('%+.2f, ', components(n));
    end
    fprintf('%+.2f)\n', components(nmfeat));
end

end

