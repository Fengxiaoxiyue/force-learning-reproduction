%RECOVER_FIGURE7B Scale static-input multifunction learning to paper N.

projectRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
addpath(fullfile(projectRoot, 'code'));
dataDir = fullfile(projectRoot, 'results', 'recovery', 'data');
figureDir = fullfile(projectRoot, 'results', 'recovery', 'figures');

attempts(1) = spec(300, 200, 10);
attempts(2) = spec(600, 400, 10);
attempts(3) = spec(1200, 800, 5);
attempts(4) = spec(1200, 800, 10);

rowCount = numel(attempts);
networkSize = zeros(rowCount, 1);
modifiedCount = zeros(rowCount, 1);
epochs = zeros(rowCount, 1);
meanMae = zeros(rowCount, 1);
meanCorrelation = zeros(rowCount, 1);
worstPatternMae = zeros(rowCount, 1);
firstEpochMae = zeros(rowCount, 1);
lastEpochMae = zeros(rowCount, 1);
elapsedSeconds = zeros(rowCount, 1);

for i = 1:rowCount
    tag = sprintf('recovery_figure7b_N%d_alpha80_epochs%d_sharedP', ...
        attempts(i).N, attempts(i).epochs);
    matPath = fullfile(dataDir, [tag, '.mat']);
    if exist(matPath, 'file')
        loaded = load(matPath, 'result');
        result = loaded.result;
    else
        cfg = make_config('smoke');
        cfg.N = attempts(i).N;
        cfg.p = 0.8;
        cfg.alpha = 80;
        cfg.g = 1.5;
        cfg.epochs = attempts(i).epochs;
        cfg.modified_count = attempts(i).modifiedCount;
        cfg.dataDir = dataDir;
        cfg.figureDir = figureDir;
        cfg.tag = tag;
        result = run_figure7_multifunction(cfg);
    end
    networkSize(i) = result.cfg.N;
    modifiedCount(i) = result.cfg.modified_count;
    epochs(i) = result.cfg.epochs;
    meanMae(i) = mean(result.mae);
    meanCorrelation(i) = mean(result.correlation);
    worstPatternMae(i) = max(result.mae);
    firstEpochMae(i) = mean(result.epoch_mae(1, :));
    lastEpochMae(i) = mean(result.epoch_mae(end, :));
    elapsedSeconds(i) = result.elapsed_seconds;
end

summary = table(networkSize, modifiedCount, epochs, meanMae, meanCorrelation, ...
    worstPatternMae, firstEpochMae, lastEpochMae, elapsedSeconds);
writetable(summary, fullfile(dataDir, 'recovery_figure7b_summary.csv'));
disp(summary);

function value = spec(N, modifiedCount, epochs)
value = struct('N', N, 'modifiedCount', modifiedCount, 'epochs', epochs);
end
