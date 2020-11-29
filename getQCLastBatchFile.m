function lastbatchfile = getQCLastBatchFile(qcinputfiles, baseqcinputfile, nbatchfiles, batchsize)

% getQCLastBatchFile - gets the last batch file created

batchfilenbrs = zeros(nbatchfiles, 1);

for i = 1:nbatchfiles
    qcinputfiles{i} = strrep(qcinputfiles{i}, sprintf('.mat'), '');
    qcinputfiles{i} = strrep(qcinputfiles{i}, sprintf('%sB%d-', baseqcinputfile, batchsize), '');
    batchfilenbrs(i) = str2double(cell2mat(qcinputfiles(i)));
end

lastbatchfile = max(batchfilenbrs);


end

