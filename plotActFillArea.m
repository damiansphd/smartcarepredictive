function plotActFillArea(ax, xlower, xupper, ylower, yupper, color, facealpha, edgecolor)

% plotActFillArea - plots a shaded area on the graph (eg for confidence bounds
% or labelled test data ranges) - this one is for just the actual area

fill(ax, [xlower xupper xupper xlower], ...
            [ylower ylower yupper yupper], ...
            color, 'FaceAlpha', facealpha, 'EdgeColor', edgecolor);

end

