fd = fopen('../modelsim/fp_addsub_data.txt', 'r');

pipelineLatency = 5;

A = fscanf(fd, '%u + %u = %u', [3 Inf]);

A = uint32(A);

data_a = A(1,1:end-pipelineLatency);
data_b = A(2,1:end-pipelineLatency);
result = A(3,1+pipelineLatency:end);

data_a = typecast(data_a, 'single');
data_b = typecast(data_b, 'single');
result = typecast(result, 'single');

compArray = (result ~= (data_a + data_b));

testedTotal = numel(compArray);
mismatchTotal = nnz(compArray);

fprintf('Total numbers tested : %d\n', testedTotal);
fprintf('Total mismatches : %d\n', mismatchTotal);

fclose(fd);
