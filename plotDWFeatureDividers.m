function [xl1, yl1, nextfeat] = plotDWFeatureDividers(ax, featureparamsrow, measures, nmeasures, xl1, yl1, nextfeat, lcolor)

% plotDWFeatureDividers - plot vertical lines to divide up feature types and
% also measures within feature types

[datawinduration, nrawmeasures, nmsmeasures, nvolmeasures, npmeanmeasures, ...
          nrawfeatures, nmsfeatures, nvolfeatures, npmeanfeatures, ...
          nfeatures, nnormfeatures] = setDWNumMeasAndFeatures(featureparamsrow, measures, nmeasures);

[xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
if nrawmeasures > 0
    mf =  nrawfeatures/nrawmeasures;
    for i = 1:nrawmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if nmsmeasures > 0
    mf =  nmsfeatures/nmsmeasures;
    for i = 1:nmsmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if nvolmeasures > 0
    mf =  nvolfeatures/nvolmeasures;
    for i = 1:nvolmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if npmeanmeasures > 0
    mf =  npmeanfeatures/npmeanmeasures;
    for i = 1:npmeanmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end

end


