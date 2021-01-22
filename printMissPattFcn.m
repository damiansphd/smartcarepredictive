function printMissPattFcn(mvsetindex, mvsetmp3D, qcdrmeasures, nrawmeas, mpdur)

% printMissPattFcn - convenience function to print out a formatted version
% of a missingness pattern (or set of missingness patterns)

nmps = size(mvsetindex, 1);

for n = 1:nmps
    
    tempmp2D = reshape(mvsetmp3D(n, :, :), nrawmeas, mpdur);
    fprintf('Iteration: %d | MoveType: %d %s Measure %d Index %d\n', mvsetindex.Iteration(n), ...
        mvsetindex.MoveType(n), mvsetindex.MoveDesc{n}, mvsetindex.Measure(n), mvsetindex.MPIndex(n));
    
    for m = 1:nrawmeas
        fprintf('%13s: ', qcdrmeasures.DisplayName{m});
        fprintf('%d ', ~tempmp2D(m, :));
        fprintf('\n');
    end

    fprintf('\n');
end

