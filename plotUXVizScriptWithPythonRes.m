clear; close all; clc;

% add alignment model code directory to path to allow sharing of code
basedir = setBaseDir();
tempdir = fullfile(strrep(basedir, 'Predictive', 'Alignment'), 'Code/');
addpath(tempdir);

mlsubfolder = 'MatlabSavedVariables';
dfsubfolder = 'DataFiles';

% logic to load in results for a given feature&label version, label method and raw measures combination
[fv1, validresponse] = selectFeatVer();
if validresponse == 0
    return;
end
[lb1, lbdisplayname, validresponse] = selectLabelMethod();
if validresponse == 0
    return;
end
[rm1, validresponse] = selectRawMeasComb();
if validresponse == 0
    return;
end

fprintf('Select Outer (Quality) Classifier model results file\n');
typetext = 'QCResults';
[baseqcmodefile] = selectQCModelResultsFile(fv1, lb1, rm1, typetext);
qcmodfile = sprintf('%s.mat', baseqcmodefile);
baseqcmodefile = strrep(baseqcmodefile, typetext, '');

tic
fprintf('Loading quality classifier results data for %s\n', qcmodfile);
load(fullfile(basedir, mlsubfolder, qcmodfile), ...
        'pmQCModelRes', 'nqcfolds', 'pmMPModelParamsRow');
toc
fprintf('\n');

qcmodel    = pmQCModelRes.Folds(1).Model;
qcmodelver = pmMPModelParamsRow.ModelVer{1};
qclossfunc = 'hinge'; % hardcoded for now - until add this to mp other run parameters

% choose the operating threshold for the quality classifier
[qcopthres, validresponse] = selectFromArrayByIndex('Operating Threshold', [pmQCModelRes.PredOp; 0.6; 0.7; 0.8; 0.9; 0.95]);
if validresponse == 0
    return;
end

fprintf('Select Inner (Predictive) Classifier trained model file\n');
[basepcmodfile] = selectModelResultsFile(fv1, lb1, rm1);
pcmodfile = sprintf('%s.mat', basepcmodfile);
basepcmodfile = strrep(basepcmodfile, ' ModelResults', '');

tic
fprintf('Loading trained Inner (Predictive) classifier and run parameters for %s\n', pcmodfile);
load(fullfile(basedir, mlsubfolder, pcmodfile), 'pmModelRes', 'pmFeatureParamsRow', 'pmModelParamsRow', 'pmOtherRunParams', 'pmTrCVFeatureIndex', 'pmTrCVNormFeatures');
toc
fprintf('\n');

pcmodelres = pmModelRes.pmNDayRes(1);
pcmodelver = pmModelParamsRow.ModelVer{1};
pclossfunc = pmOtherRunParams.lossfunc;

% load overall data statistics from trained model data inputs to ensure
% consistent normalisation
%featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
%featureparamsfile = sprintf('%s.mat', featureparamsfile);
%fprintf('Loading overall data statistics from the trained model data inputs %s\n', featureparamsfile);
%load(fullfile(basedir, mlsubfolder, featureparamsfile), 'pmOverallStats');

fprintf('Select model input file to run for\n');
[basepcresfile] = selectModelResultsFile(fv1, lb1, rm1);
pcresfile = sprintf('%s.mat', basepcresfile);
basepcresfile = strrep(basepcresfile, ' ModelResults', '');

tic
fprintf('Loading run parameters for %s\n', pcresfile);        
load(fullfile(basedir, mlsubfolder, pcresfile), ...
    'pmFeatureParamsRow');
toc
fprintf('\n');
% load data window arrays and other variables
featureparamsfile = generateFileNameFromModFeatureParams(pmFeatureParamsRow);
if pmFeatureParamsRow.augmethod > 1
    findaugtext = sprintf('au%d', pmFeatureParamsRow.augmethod);
    replaceaugtext = sprintf('au1');
    featureparamsfile = strrep(featureparamsfile, findaugtext, replaceaugtext);
end
featureparamsfile = sprintf('%s.mat', featureparamsfile);
fprintf('Loading Inner (Predictive) model input data for %s\n', featureparamsfile);
load(fullfile(basedir, mlsubfolder, featureparamsfile), 'pmNormFeatures', 'pmFeatureIndex', 'pmDataWinArray', 'pmExABxElLabels', ...
    'pmPatients', 'pmAMPred', 'pmAntibiotics', 'pmRawDatacube', 'npatients', 'measures', 'nmeasures', 'maxdays', ...
    'pmOverallStats', 'pmPatientMeasStats', 'pmModFeatParamsRow');
toc
fprintf('\n');

% if I want to dynamically calculate the normalised features based on the
% overall stats of the original trained model data, then would need to do
% here rather than loading in (and use the OverallStats from originally).
% or as I'll have to change the logic of normalisation, in re-creating all
% the normalised features, they should match and so I should be able to
% just load in.
%npcexamples = size(pmFeatureIndex, 1);
%[pmNormFeatures, ~, ~, ~, ...
%    ~, ~, ~, ~, ...
%    ~, ~, ~, ~] = createModFeaturesFromDWArrays(pmDataWinArray, ...
%        pmOverallStats, npcexamples, measures, nmeasures, pmModFeatParamsRow);

pyrt = 2;

fprintf('Loading python predictive classifier feature index table\n');
pypcfeatidxfname = sprintf('PythonPredClassFeatIdx-rt%d.csv', pyrt);
pypcfeatidx = readtable(fullfile(basedir, dfsubfolder, pypcfeatidxfname));

fprintf('Loading python predictive classifier predictions\n');
pypcfname = sprintf('PythonPredClassifier-rt%d.csv', pyrt);
temppypcres = readtable(fullfile(basedir, dfsubfolder, pypcfname));
pypcres = temppypcres.Var1;

plotsubfolder = sprintf('Plots/%s', basepcresfile);
mkdir(fullfile(basedir, plotsubfolder));

fprintf('Creating interpolated cube\n');
[pmInterpDatacube] = createPMInterpDatacube(pmPatients, pmRawDatacube, npatients, maxdays, nmeasures);
[pmInterpDatacube] = handleMissingFeatures(pmPatients, pmInterpDatacube, pmOverallStats, npatients, maxdays, nmeasures);

tic
psplitfile = sprintf('%spatientsplit.mat', pmModFeatParamsRow.StudyDisplayName{1});
fprintf('Loading patient splits from file %s\n', psplitfile);
load(fullfile(basedir, mlsubfolder, psplitfile));
toc
fprintf('\n');

if nqcfolds ~= 1
    fprintf('Need to choose an Outer (Quality) classifier model with only one fold\n');
    return
end

% create the mapping of pred classifier folds to quality classifier folds
if ceil((nsplits - 1) / nqcfolds) == (nsplits - 1) / nqcfolds
   pcfolds = reshape((1:nsplits - 1), [nqcfolds (nsplits - 1)/nqcfolds]); 
else
    fprintf('**** Number of predictive classifier folds must be a multiple of the number of quality classifier folds ****\n');
end

[baseuxfile, validresponse] = selectUXExampleFile();
if validresponse == 0
    return;
end
uxfile = strcat(baseuxfile, '.xlsx');

uxtable  = readtable(fullfile(basedir, dfsubfolder, uxfile));
nuxexs = size(uxtable,1);

% populate run parameters
dwdur      = pmModFeatParamsRow.datawinduration;
normwin    = pmModFeatParamsRow.normwinduration;
totalwin   = dwdur + normwin;
smfn       = pmModFeatParamsRow.smfunction;
smwin      = pmModFeatParamsRow.smwindow;
smln       = pmModFeatParamsRow.smlength;
perioddays = 80;

if ismember(pmModFeatParamsRow.StudyDisplayName, {'BR', 'CL'})
    mfev1idx = measures.Index(ismember(measures.DisplayName, {'FEV1', 'LungFunction'}));
else
    mfev1idx = measures.Index(ismember(measures.DisplayName, 'LungFunction'));
end

widthinch = 16;
heightinch = 7;

undefcol    = [0.0,  0.0,  1.0];    % blue

stablecol   = [0.0,  1.0,  0.0];    % green
ambercol    = [1.0,  0.76, 0.0];    % amber
unstablecol = [1.0,  0.0,  0.0];    % red
pccolarray  = [undefcol; stablecol; ambercol; unstablecol];

safecol     = [1.0,  1.0,  1.0];    % white
%unsafecol   = [0.83, 0.83, 0.83];   % grey
unsafecol   = [0.42, 0.42, 0.42];   % grey

qccolarray  = [undefcol; unsafecol; safecol];

edgecol     = [0.0,  0.0,  0.0];    % black
dmisscol    = [1.0,  0.0,  0.0];    % red
dprescol    = [1.0,  1.0,  1.0];    % white

labelcol    = [0.796, 0.765, 0.89]; % light purple
predcol     = [0.0,  0.0,  0.0]; % black
pypredcol   = [0.0,  0.0,  1.0]; % grey

amberlowpct  = 20;
amberhighpct = 30;

undefval     = 1;

stableval    = 2;
amberval     = 3;
unstableval  = 4;

unsafeval     = 2;
safeval       = 3;

transparency = 0.6;
        
% set subplot axes position array for desired layout for plots
mplotsdown   = 5;
mplotsacross = 2;
mplotwidth   = 1;
mplotpos = reshape((1:mplotsacross * mplotwidth * mplotsdown), mplotsacross * mplotwidth, mplotsdown)';
mplotpos = [mplotpos(:, 1:mplotwidth); mplotpos(:, mplotwidth + 1:mplotsacross * mplotwidth)];

totplotsdown   = mplotsdown;
totplotsacross = mplotsacross;

for ux = 1:nuxexs

    uxtablerow = uxtable(ux, :);
    
    uxstudy  = uxtablerow.Study{1};
    uxscenario = uxtablerow.Description{1};
    
    if ~ismember(uxstudy, pmModFeatParamsRow.StudyDisplayName)
        fprintf('**** Predictive classifier study is not the same as the study of the example - skipping ****\n');
    end
    
    % set relevant variables for this example
    pnbr       = pmPatients.PatientNbr(ismember(pmPatients.Study, uxstudy) & pmPatients.ID == uxtablerow.PatientID);
    patientrow = pmPatients(pnbr, :);
    pmaxdays   = patientrow.LastMeasdn - patientrow.FirstMeasdn + 1;
    fromdn     = uxtablerow.FromRelDn;
    if fromdn < 0
        fromdn = 0;
    end
    todn       = uxtablerow.ToRelDn;
    if todn > pmaxdays
        todn = pmaxdays;
    end
    ndays      = todn - fromdn + 1;
    
    
    %pmeasstats = pmPatientMeasStats(pmPatientMeasStats.PatientNbr == pnbr, :);
    
    % get ab treatments in the example date range
    pabs = pmAntibiotics(pmAntibiotics.PatientNbr == pnbr & pmAntibiotics.RelStopdn >= fromdn & pmAntibiotics.RelStartdn <= todn, :);
    pivabsdates = pabs(ismember(pabs.Route, 'IV'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    poralabsdates = pabs(ismember(pabs.Route, 'Oral'),{'Startdn', 'Stopdn', 'RelStartdn','RelStopdn'});
    
    % get exacerbations starts in the example date range
    pexstsdates = pmAMPred(pmAMPred.PatientNbr == pnbr & ...
        ((pmAMPred.RelUB1 >= fromdn & pmAMPred.RelLB1 <= todn) | ...
         (pmAMPred.RelUB2 >= fromdn & pmAMPred.RelLB2 <= todn)), ...
        {'IVStartDate', 'IVDateNum', 'Offset', 'Ex_Start', ...
        'LowerBound1', 'UpperBound1', 'LowerBound2', 'UpperBound2', ...
        'Pred', 'RelLB1', 'RelUB1', 'RelLB2', 'RelUB2'});

    
    % run trained predictive classifier on chosen data set (for the patient
    % in this example)
    pfidx      = (pmFeatureIndex.PatientNbr == pnbr & pmFeatureIndex.ScenType == 0);
    npex       = sum(pfidx);
    pfeatindex = pmFeatureIndex(pfidx, :);
    

    pnormfeats = pmNormFeatures(pfidx, :);
    plabels    = pmExABxElLabels(pfidx);
    if pmOtherRunParams.runtype == 1
        % tr/cv mode
        pfold      = pmPatientSplit.SplitNbr(pmPatientSplit.PatientNbr == pnbr);
        ppcmodel   = pcmodelres.Folds(pfold).Model;
    else
        % held out test set mode
        ppcmodel   = pcmodelres.Folds(1).Model;
    end
    ppcres     = createModelDayResStuct(npex, 1, 1);
    ppcres     = predictPredModel(ppcres, ppcmodel, pnormfeats, plabels, pcmodelver, pclossfunc);
    
    pcopthres  = pcmodelres.EpiPredOp;
    
    % revised thresholds based on analysis by Maria
    %amberthres = pcopthres * (1 - amberlowpct/100);
    %redthres   = pcopthres * (1 + amberhighpct/100);
    amberthres = 0.0128;
    redthres   = 0.022;
    
    % create pred and label arrays in real days rather than just the days
    % we predict for
    ppreddata    = nan(1, pmaxdays); % pc prediction
    plabeldata   = nan(1, pmaxdays); % pc label
    for d = 1:size(ppcres.Pred,1)
        ppreddata(pfeatindex.CalcDatedn(d))  = ppcres.Pred(d);
        plabeldata(pfeatindex.CalcDatedn(d)) = plabels(d);
    end
    
    % create red/amber/green array for this patient
    psclpreddata = ones(1, pmaxdays) * undefval; % pc scale prediction - default value is undefined
    psclpreddata(ppreddata <  amberthres)                          = stableval;
    psclpreddata(ppreddata >= amberthres   & ppreddata < redthres) = amberval;
    psclpreddata(ppreddata >= redthres)                            = unstableval;
    
    % create quality classifier inputs and predictions
    qfidx        = (pmFeatureIndex.PatientNbr == pnbr & pmFeatureIndex.ScenType == 0);
    qfeatindex   = pmFeatureIndex(qfidx,:);
    datawinarray = pmDataWinArray(qfidx, :, :);
    pnex = size(datawinarray, 1); 
    [qcfeatures, ~, qcmeasures, qcmodfeatparamrow] = createQCFeaturesFromDataWinArray(datawinarray, pmModFeatParamsRow, pnex, totalwin, measures, nmeasures);
    qcres = createQCModelResStruct(pnex, 1);
    qcres = predictPredModel(qcres, qcmodel, qcfeatures, zeros(pnex, 1), qcmodelver, qclossfunc);
    qcres.Loss = 0; % Loss calculation does not make sense for new data as we don't have labels to compare to
    qpred = qcres.Pred;
    
    % create pred array in real days rather than just the days
    % we predict for
    qpreddata    = nan(1, pmaxdays); % qc prediction
    for d = 1:size(qpred,1)
        qpreddata(qfeatindex.CalcDatedn(d)) = qpred(d);
    end
    
    % create safe/unsafe array for this patient
    qsclpreddata = ones(1, pmaxdays) * undefval; % qc binary prediction - default value is undefined
    qsclpreddata(qpreddata <  qcopthres) = unsafeval;
    qsclpreddata(qpreddata >= qcopthres) = safeval;
    
    nsafedays  = sum(qsclpreddata==3);
    fprintf('For patient %d, there are %d safe days out of a total of %d days (%.1f%%)\n', pnbr, nsafedays, pnex, 100 * nsafedays / pnex);
    
    % create the colour arrays for plots
    pccol = pccolarray(psclpreddata, :);
    qccol = qccolarray(qsclpreddata, :);
    uxcol = pccol;
    uxcol(qsclpreddata == unsafeval, :) = qccol(qsclpreddata == unsafeval, :);
    
    % create python outputs to overlay on plots
    pyfidx = (pypcfeatidx.PatientNbr == pnbr & pypcfeatidx.ScenType == 0);
    ppypcfeatidx = pypcfeatidx(pyfidx, :);
    ppypcres = pypcres(pyfidx);
    
    ppypreddata    = nan(1, pmaxdays); % python pc prediction
    for d = 1:size(ppypcres,1)
        ppypreddata(ppypcfeatidx.CalcDatedn(d))  = ppypcres(d);
    end
    
    npages    = ceil(ndays / perioddays);
    for page = 1:npages
        
        dfrom = (page - 1) * perioddays + fromdn;
        dto   = (page * perioddays) + fromdn - 1;
        if dto > todn
            dto = todn;
        end
        
        plotname = sprintf('%s-UXVizPYP%d(%s%d)D%d-%d', ...
            basepcresfile, pnbr, patientrow.Study{1}, patientrow.ID, dfrom, dto);
        plottitle = sprintf('%s-P%d(%s%d)D%d-%d', ...
            uxscenario, pnbr, patientrow.Study{1}, patientrow.ID, dfrom, dto);
        fprintf('Page %d: From %d - To %d\n', page, dfrom, dto);
        [f, p] = createFigureAndPanelForPaper(plottitle, widthinch, heightinch);
        
        [tabResults] = createUXPlotResTable(dto - dfrom + 1);
        
        days  = (dfrom:dto);
        xl    = [(dfrom - 0.5) (dfrom + 0.5 + perioddays - 1)];
        thisplot = 0;
        
        % populate days column in excel table
        tabResults.Days = days';
        
        for m = 1:nmeasures
            
            if measures.RawMeas(m) == 1
                
                midx       = measures.Index(m);
                mrawdata   = pmRawDatacube(pnbr, dfrom:dto, midx);
                mdata      = pmInterpDatacube(pnbr, dfrom:dto, midx);
                interppts  = mdata;
                interppts(~isnan(mrawdata)) = nan;
                [combinedmask, plottext, left_color, lint_color, ~, ~] = setDWPlotColorsAndText(measures(midx, :));
        
                % raw measures - capture overall min/max range based on all
                % study data, rounding to the nearest 10
                %ovyl = [min(min(pmInterpDatacube(:, :, midx), [], 2), [], 1), max(max(pmInterpDatacube(:, :, midx), [], 2), [], 1)];
                if ismember(measures.DisplayName(midx), {'FEV1', 'LungFunction'})
                    pctrange = [25 75];
                else
                    pctrange = [10 90];
                end
                ovyl = [prctile(pmInterpDatacube(:, :, midx), pctrange(1), 'all'), prctile(pmInterpDatacube(:, :, midx), pctrange(2), 'all')];
                factor = 10;
                ovyl(1) = floor(ovyl(1)/factor) * factor;
                ovyl(2) = ceil(ovyl(2)/factor) * factor;
                
                yl = ovyl;
                
                thisplot = thisplot + 1;
                ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
                
                if ~all(isnan(mdata))
                    [~, yl] = plotMeasurementData(ax, days, mdata, xl, yl, plottext, combinedmask, left_color, ':', 1.0, 'none', 1.0, 'blue', 'green');
                    [~, yl] = plotMeasurementData(ax, days, applySmoothMethodToInterpRow(mdata, smfn, smwin, smln, midx, mfev1idx), xl, yl, plottext, combinedmask, left_color, '-', 1.0, 'none', 1.0, 'blue', 'green');
                    [~, yl] = plotMeasurementData(ax, days, interppts, xl, yl, plottext, combinedmask, left_color, 'none', 1.0, 'o', 4.0, 'black', lint_color);
                end
                [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
                ylim(ax, yl);
                xlim(ax, xl);
     
                % populate measurement data in excel table
                mcol = sprintf('%s_raw', measures.ShortName{m});
                tabResults(:, mcol) = array2table(mdata');
                mcol = sprintf('%s_sm', measures.ShortName{m});
                tabResults(:, mcol) = array2table(applySmoothMethodToInterpRow(mdata, smfn, smwin, smln, midx, mfev1idx)');
                mcol = sprintf('%s_interp', measures.ShortName{m});
                tabResults(:, mcol) = array2table(interppts');
                mcol = sprintf('%s_miss', measures.ShortName{m});
                tabResults(:, mcol) = array2table(isnan(mrawdata)');
    
            end
        end
        
        % 6) plot predictive classifier results
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        yl = [0.0001 1];
        
        plottitle = sprintf('Predictive Classifier');
        [~, yl] = plotMeasurementData(ax, days, 0.0001 + plabeldata(dfrom:dto), xl, yl, plottitle, 0, labelcol , '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotMeasurementData(ax, days, ppreddata(dfrom:dto), xl, yl, plottitle, 0, predcol, '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotMeasurementData(ax, days, ppypreddata(dfrom:dto), xl, yl, plottitle, 0, pypredcol, '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotHorizontalLine(ax, pcopthres, xl, yl, [0.83, 0.83, 0.83], ':', 1.0);
        [~, yl] = plotHorizontalLine(ax, amberthres, xl, yl, ambercol, '-', 0.5);
        [~, yl] = plotHorizontalLine(ax, redthres, xl, yl, unstablecol, '-', 0.5);
        
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        if ismember(uxstudy, 'BR')
            ax.YScale = 'log';
            ax.YTick  = [0.0001, 0.001, 0.01, 0.1, 1];
        end
        ylabel(ax, 'Predicted Risk', 'FontSize', 6);
        ylim(ax, yl);
        xlim(ax, xl);
        
        % populate pred classifier results in excel table
        mcol = 'PC_Pred';
        tabResults(:, mcol) = array2table(ppreddata(dfrom:dto)');
        mcol = 'PC_Label';
        tabResults(:, mcol) = array2table(plabeldata(dfrom:dto)');
        mcol = 'PC_Opthr';
        tabResults(:, mcol) = array2table(ones(size(days, 2), 1) * pcopthres);
        mcol = 'PC_Amthr';
        tabResults(:, mcol) = array2table(ones(size(days, 2), 1) * amberthres);
        mcol = 'PC_Rdthr';
        tabResults(:, mcol) = array2table(ones(size(days, 2), 1) * redthres);
        mcol = 'Py_PC_Pred';
        tabResults(:, mcol) = array2table(ppypreddata(dfrom:dto)');
        
        % 7) missing data by measure and day plot
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        counter = sum(measures.RawMeas);
        yl = [0.5 (counter + 0.5)];
        
        for m = 1:nmeasures
            
            if measures.RawMeas(m) == 1
                
                midx       = measures.Index(m);
                mrawdata   = pmRawDatacube(pnbr, dfrom:dto, midx);
                interppts  = pmInterpDatacube(pnbr, dfrom:dto, midx);
                interppts(~isnan(mrawdata)) = nan;

                yupper  = counter + 0.35;
                ylower  = counter - 0.35;
                
                for i = 1:size(interppts, 2)
                    if isnan(interppts(i))
                        datacol = dprescol;
                    else
                        datacol = dmisscol;
                    end
                    xlower = dfrom - 1 + i - 0.35;
                    xupper = dfrom - 1 + i + 0.35;
                    hold on;
                    fill(ax, [xlower xupper xupper xlower], ...
                             [ylower ylower yupper yupper], ...
                             datacol, 'FaceAlpha', transparency, 'EdgeColor', edgecol);
                    hold off;

                end
                
                counter = counter - 1;
            end
        
        end
        
        ax.FontSize = 6;
        ax.YTick = 1:sum(measures.RawMeas);
        ax.YTickLabel = flip(measures.DisplayName(measures.RawMeas == 1));
        
        xlabel(ax, 'Days', 'FontSize', 6);
        title(ax, 'Missing Data','FontSize', 6);
        ylim(ax, yl);
        xlim(ax, xl);
        
        hold on;
        h = zeros(2, 1);
        h(1) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', dprescol);
        h(2) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', dmisscol);
        legend(h, {'Data Present','Data Missing'}, 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 2);
        hold off;
        
        % 8) qual classifier prediction + qcopthres
        thisplot = thisplot + 1;
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot, :), 'Parent', p);
        yl = [0 1];
        
        plottitle = sprintf('Quality Classifier');
        [~, yl] = plotMeasurementData(ax, days, qpreddata(dfrom:dto), xl, yl, plottitle, 0, predcol, '-', 1.0, 'none', 1.0, 'blue', 'green');
        [~, yl] = plotHorizontalLine(ax, qcopthres, xl, yl, unsafecol, ':', 1.0);
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        ylabel(ax, 'Predicted Safety', 'FontSize', 6);
        ylim(ax, yl);
        xlim(ax, xl);
        
        % populate qual classifier results in excel table
        mcol = 'QC_Pred';
        tabResults(:, mcol) = array2table(qpreddata(dfrom:dto)');
        mcol = 'QC_Opthr';
        tabResults(:, mcol) = array2table(ones(size(days, 2), 1) * qcopthres);
        
        % 9 & 10 - plot for the various daily coloured results (takes up the space of two plot positions)
        thisplot = thisplot + 1;
        counter = 3;
        yl = [0.5 (counter + 0.5)];
        
        ax = subplot(totplotsdown, totplotsacross, mplotpos(thisplot:(thisplot+1), :), 'Parent', p);

        % Breathe score - red/green plot (change to add amber in).
        yupper  = counter + 0.25;
        ylower  = counter - 0.25;
        
        [ax] = plotABAndExFcn(ax, poralabsdates, pivabsdates, pexstsdates, xl, yl);
        for i = dfrom:dto
            xlower = i - 0.35;
            xupper = i + 0.35;
            hold on;
            fill(ax, [xlower xupper xupper xlower], ...
                     [ylower ylower yupper yupper], ...
                     pccol(i, :), 'FaceAlpha', transparency, 'EdgeColor', edgecol);
            hold off;
        end

        % qual classifier safe/not safe
        counter = counter - 1;
        yupper  = counter + 0.25;
        ylower  = counter - 0.25;
        for i = dfrom:dto
            xlower = i - 0.35;
            xupper = i + 0.35;
            hold on;
            fill(ax, [xlower xupper xupper xlower], ...
                     [ylower ylower yupper yupper], ...
                     qccol(i, :), 'FaceAlpha', transparency, 'EdgeColor', edgecol);
            hold off;
        end

        % Breathe app UX display
        counter = counter - 1;
        yupper  = counter + 0.25;
        ylower  = counter - 0.25;
        for i = dfrom:dto
            xlower = i - 0.35;
            xupper = i + 0.35;
            hold on;
            fill(ax, [xlower xupper xupper xlower], ...
                     [ylower ylower yupper yupper], ...
                     uxcol(i, :), 'FaceAlpha', transparency, 'EdgeColor', edgecol);
            hold off;
        end
        
        ax.FontSize = 6;
        ax.YTick = [1 2 3];
        ax.YTickLabel = {'Breathe App UX', 'Safe/Unsafe', 'Breathe Score'};
        
        xlabel(ax, 'Days', 'FontSize', 6);
        title(ax, 'UX Visualisation','FontSize', 6);
        ylim(ax, yl);
        xlim(ax, xl);
        
        hold on;
        h = zeros(6, 1);
        h(1) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', stablecol);
        h(2) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', ambercol);
        h(3) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', unstablecol);
        h(4) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', safecol);
        h(5) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', unsafecol);
        h(6) = plot(NaN,NaN, 'Marker', 's', 'LineStyle', 'none', 'MarkerEdgeColor', edgecol, 'MarkerFaceColor', undefcol);
        legend(h, {'Stable', 'Amber', 'Unstable', 'Safe', 'Unsafe', 'Undefined'}, 'Location', 'southoutside', 'Orientation', 'horizontal', 'NumColumns', 6);

        hold off;
        
        %populate colour columns in excel table
        scorearray   = {'PC', 'QC', 'BS'};
        colnamearray = {'R', 'G', 'B'};
        for s = 1:size(scorearray, 2)
            if s == 1
                coldata = pccol(dfrom:dto, :);
            elseif s == 2
                coldata = qccol(dfrom:dto, :);
            else
                coldata = uxcol(dfrom:dto, :);
            end
            for c = 1:size(colnamearray, 2)
                mcol = sprintf('%s_col_%s', scorearray{s}, colnamearray{c});
                tabResults(:, mcol) = array2table(coldata(:, c));
            end
        end
        
        %populate ab and ex_start columns in excel table
        for ab = 1:size(poralabsdates, 1)
            startdn = poralabsdates.RelStartdn(ab);
            if poralabsdates.RelStartdn(ab) < dfrom
                startdn = dfrom;
            end
            stopdn  = poralabsdates.RelStopdn(ab);
            if poralabsdates.RelStopdn(ab) > dto
                stopdn = dto;
            end
            idx = tabResults.Days >= startdn & tabResults.Days <= stopdn;
            tabResults.Ab_Oral(idx) = 1;    
        end
        for ab = 1:size(pivabsdates, 1)
            startdn = pivabsdates.RelStartdn(ab);
            if pivabsdates.RelStartdn(ab) < dfrom
                startdn = dfrom;
            end
            stopdn  = pivabsdates.RelStopdn(ab);
            if pivabsdates.RelStopdn(ab) > dto
                stopdn = dto;
            end
            idx = tabResults.Days >= startdn & tabResults.Days <= stopdn;
            tabResults.Ab_IV(idx) = 1;    
        end
        for ex = 1:size(pexstsdates, 1)
            if pexstsdates.Pred(ex) >= dfrom & pexstsdates.Pred(ex) <= dto
                idx = tabResults.Days == pexstsdates.Pred(ex);
                tabResults.Ex_Start(idx) = 1;
            end
            startdn = pexstsdates.RelLB1(ex);
            if pexstsdates.RelLB1(ex) < dfrom
                startdn = dfrom;
            end
            stopdn = pexstsdates.RelUB1(ex);
            if pexstsdates.RelUB1(ex) >= dto
                stopdn = dto;
            end
            idx = tabResults.Days >= startdn & tabResults.Days <= stopdn;
            tabResults.Ex_90Conf(idx) = 1;
            if pexstsdates.RelLB2(ex) ~= -1
                startdn = pexstsdates.RelLB2(ex);
                if pexstsdates.RelLB2(ex) < dfrom
                    startdn = dfrom;
                end
                stopdn = pexstsdates.RelUB2(ex);
                if pexstsdates.RelUB2(ex) >= dto
                    stopdn = dto;
                end
                idx = tabResults.Days >= startdn & tabResults.Days <= stopdn;
                tabResults.Ex_90Conf(idx) = 1;
            end
        end
        
        savePlotInDir(f, plotname, basedir, plotsubfolder);
        close(f);
        
        % save results to excel table
        excelfname = sprintf('%s.csv', plotname);
        writetable(tabResults, fullfile(basedir, 'ExcelFiles', excelfname));
        
    end
    
end







