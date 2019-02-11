function [smtext] = setSmoothingText(smtype, smfn, smwdth)

% setSmoothingText - sets the text to be used in the figure and plot names
% for the relevant smoothing optiosn set

if smtype == 1
    typetext = 'Raw';
elseif smtype == 2
    typetext = 'CW';
elseif smtype == 3
    typetext = 'TW';
end
if smfn == 1
    fntext = 'Mean';
elseif smfn == 2
    fntext = 'Med';
elseif smfn == 3
    fntext = 'Max';
else
    fntext = '';
end
smtext = sprintf('sm-%s%d%s', typetext, smwdth, fntext);

end

