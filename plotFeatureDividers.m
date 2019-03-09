function [xl1, yl1, nextfeat] = plotFeatureDividers(ax, featureparamsrow, measures, nmeasures, xl1, yl1, nextfeat, lcolor)

% plotFeatureDividers - plot vertical lines to divide up feature types and
% also measures within feature types

[featureduration, ~, monthfeat, demofeat, ...
 nbuckets, navgseg, nvolseg, nbuckpmeas, nrawmeasures, nbucketmeasures, nrangemeasures, ...
 nvolmeasures, navgsegmeasures, nvolsegmeasures, ncchangemeasures, ...
 npmeanmeasures, npstdmeasures, nbuckpmeanmeasures, nbuckpstdmeasures, ...
 nrawfeatures, nbucketfeatures, nrangefeatures, nvolfeatures, navgsegfeatures, ...
 nvolsegfeatures, ncchangefeatures, npmeanfeatures, npstdfeatures, ...
 nbuckpmeanfeatures, nbuckpstdfeatures, ndatefeatures, ndemofeatures, ...
 nfeatures, nnormfeatures] = setNumMeasAndFeatures(featureparamsrow, measures, nmeasures);


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
if nbucketmeasures > 0
    mf =  nbucketfeatures/nbucketmeasures;
    for i = 1:nbucketmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if nrangemeasures > 0
    mf =  nrangefeatures/nrangemeasures;
    for i = 1:nrangemeasures - 1
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
if navgsegmeasures > 0
    mf =  navgsegfeatures/navgsegmeasures;
    for i = 1:navgsegmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if nvolsegmeasures > 0
    mf =  nvolsegfeatures/nvolsegmeasures;
    for i = 1:nvolsegmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if ncchangemeasures > 0
    mf =  ncchangefeatures/ncchangemeasures;
    for i = 1:ncchangemeasures - 1
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
if npstdmeasures > 0
    mf =  npstdfeatures/npstdmeasures;
    for i = 1:npstdmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if nbuckpmeanmeasures > 0
    mf =  nbuckpmeanfeatures/nbuckpmeanmeasures;
    for i = 1:nbuckpmeanmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if nbuckpstdmeasures > 0
    mf =  nbuckpstdfeatures/nbuckpstdmeasures;
    for i = 1:nbuckpstdmeasures - 1
        nextfeat = nextfeat + mf;
        [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, ':', 1);
    end
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if monthfeat > 0
    mf =  ndatefeatures;
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end
if demofeat > 1
    mf =  ndemofeatures;
    nextfeat = nextfeat + mf;
    [xl1, yl1] = plotVerticalLine(ax, nextfeat, xl1, yl1, lcolor, '-', 1);
end

end


