function [tree, validresponse] = selectTree(ntrees)

% selectTree - select which tree to run plot for

stree = input(sprintf('Choose tree (1-%d) ? ', ntrees), 's');

tree = str2double(stree);

if (isnan(tree) || tree < 1 || tree > ntrees)
    fprintf('Invalid choice\n');
    validresponse = false;
    tree = 0;
else
    validresponse = true;
end

end

