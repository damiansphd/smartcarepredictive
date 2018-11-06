function savePlotInDir(f, name, basedir, subfolder)

% savePlots - saves the figure to png and svp file types in the specified
% subfolder

% save plot
filename = [name '.png'];
saveas(f,fullfile(basedir, subfolder, filename));
%filename = [name '.svg'];
%saveas(f,fullfile(basedir, subfolder, filename));

end

