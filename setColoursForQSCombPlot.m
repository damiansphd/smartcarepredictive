function [colarray] = setColoursForQSCombPlot(study, type, f4etype, mstype)

% setColoursForFig4E - sets the column colour arrays for fig 4E and for
% missingness comparison plots

colarray = [];
    
if ismember(type, {f4etype})
    if ismember(study, 'SC')
        colarray = [ 250, 191, 143; ...
                    250, 191, 143; ...
                    247, 150,  70; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    155, 187,  89; ...
                    149, 179, 215; ...
                     79, 129, 189; ...
                     79, 129, 189; ...
                     79, 129, 189; ...
                     79, 129, 189; ...
                     79, 129, 189];
    elseif ismember(study, 'BR')
        colarray = [ 250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    247, 150,  70; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    155, 187,  89; ...
                    155, 187,  89; ...
                     79, 129, 189; ...
                     79, 129, 189];
    elseif ismember(study, 'CL')
            colarray = [ 250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    250, 191, 143; ...
                    247, 150,  70; ...
                    247, 150,  70; ...
                    247, 150,  70; ...
                    247, 150,  70; ...
                    247, 150,  70; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    196, 215, 155; ...
                    155, 187,  89; ...
                    155, 187,  89; ...
                    155, 187,  89; ...
                     79, 129, 189; ...
                     79, 129, 189; ...
                     79, 129, 189; ...
                     79, 129, 189];
    end
elseif ismember(type, {mstype})
    colarray = [250, 191, 143; ...
                196, 215, 155; ...
                149, 179, 215; ...
                247, 150,  70; ...
                155, 187,  89; ...
                 79, 129, 189];
end
    
colarray = colarray ./ 255;


end

