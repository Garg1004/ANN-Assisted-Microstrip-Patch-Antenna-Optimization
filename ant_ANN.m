target_freq_Hz  = 2.45e9;
target_freq_GHz = 2.45;
eta_rad = 0.8;

folder = 'D:\Downloads\';
files = dir(fullfile(folder, 'slot_*.xlsx'));

num_slots_total = 121;

% FEED POINT SLOT (4th ROW, 6th COLUMN)
feed_slot = 39;

X = [];
Y = [];

disp('Loading CST data...');

% LOAD DATA
for k = 1:length(files)

    filepath = fullfile(folder, files(k).name);

    fprintf('\nReading %s\n', files(k).name);

    num = readmatrix(filepath);
    raw = readcell(filepath);

    freq = num(:,1);
    sdata = num(:,2:end);
    headers = raw(1,2:end);

    if max(freq) < 1e6
        [~, idx_freq] = min(abs(freq - target_freq_GHz));
    else
        [~, idx_freq] = min(abs(freq - target_freq_Hz));
    end

    for i = 1:size(sdata,2)

        label = headers{i};

        if iscell(label)
            label = label{1};
        end

        if isempty(label)
            continue;
        end

        label = string(label);

        nums = regexp(label, '\d+', 'match');

        if isempty(nums)
            continue;
        end

        idxs = str2double(nums);

        idxs = idxs(idxs>=1 & idxs<=num_slots_total);

        % FEED SLOT SHOULD NEVER BE REMOVED
        idxs(idxs == feed_slot) = [];

        slot_vec = ones(num_slots_total,1);

        slot_vec(idxs) = 0;

        % FORCE FEED SLOT AS METAL
        slot_vec(feed_slot) = 1;

        s11_db = sdata(idx_freq, i);

        if isnan(s11_db)
            continue;
        end

        X = [X; slot_vec'];
        Y = [Y; s11_db];

    end
end

X = X';
Y = Y';

fprintf('\nDATASET\n');
fprintf('Total Samples = %d\n', size(X,2));

S11_min = min(Y);
S11_max = max(Y);

fprintf('Best S11 (min) = %.2f dB\n', S11_min);
fprintf('Worst S11 (max) = %.2f dB\n', S11_max);

idx_rand = randperm(size(X,2));

X = X(:, idx_rand);
Y = Y(:, idx_rand);

[Xn, psX] = mapminmax(X,0,1);
[Yn, psY] = mapminmax(Y,0,1);

% FEEDFORWARD ANN
net = fitnet([60 40 20]);

net.trainParam.epochs = 500;
net.trainParam.goal = 1e-5;
net.trainParam.showWindow = false;

net = train(net, Xn, Yn);

disp('ANN Training Completed');

desired_eff = input('\nEnter desired efficiency (0 to 0.8): ');

% LIMIT USER INPUT
if desired_eff > 0.8
    error('Desired efficiency cannot exceed 80%%');
end

min_removed = 1;
max_removed = 10;

num_slots = size(X,1);

num_trials = 10000;

best_pattern = X(:,1);
best_s11 = Y(1);

best_error = inf;

for i = 1:num_trials

    base_idx = randi(size(X,2));

    candidate = X(:, base_idx);

    num_changes = randi([1 3]);

    % EXCLUDE FEED SLOT FROM MUTATION
    available_slots = setdiff(1:num_slots, feed_slot);

    idx = available_slots(randperm(length(available_slots), num_changes));

    current_removed = sum(candidate == 0);

    for j = 1:length(idx)

        pos = idx(j);

        if candidate(pos) == 1 && current_removed < max_removed

            candidate(pos) = 0;
            current_removed = current_removed + 1;

        elseif candidate(pos) == 0 && current_removed > min_removed

            candidate(pos) = 1;
            current_removed = current_removed - 1;

        end
    end

    % FORCE FEED SLOT TO REMAIN METAL
    candidate(feed_slot) = 1;

    candidate_n = mapminmax('apply', candidate, psX);

    pred_n = net(candidate_n);

    pred_s11 = mapminmax('reverse', pred_n, psY);

    pred_s11 = max(min(pred_s11, S11_max), S11_min);

    s11_mag = 10^(pred_s11/20);

    mismatch = 1 - (s11_mag)^2;

    pred_eff = eta_rad * mismatch;

    err_eff = abs(pred_eff - desired_eff);

    % PENALTY IF S11 IS WORSE THAN -10 dB
    if pred_s11 > -10
        penalty = 5;
    else
        penalty = 0;
    end

    % BONUS FOR VERY GOOD MATCHING
    if pred_s11 < -15
        bonus = -0.02;
    else
        bonus = 0;
    end

    total_error = err_eff + penalty + bonus;

    if total_error < best_error

        best_error = total_error;

        best_s11 = pred_s11;

        best_pattern = candidate;

    end
end

s11_mag = 10^(best_s11/20);

mismatch = 1 - (s11_mag)^2;

final_eff = eta_rad * mismatch;

fprintf('\nFINAL RESULT\n');

fprintf('User Desired Efficiency = %.2f %%\n', desired_eff*100);

fprintf('Predicted S11 @2.45     = %.2f dB\n', best_s11);

fprintf('Actual Efficiency       = %.2f %%\n', final_eff*100);

fprintf('\nSlot Configuration:\n');

for i = 1:length(best_pattern)

    if best_pattern(i) == 0
        fprintf('Slot %d -> REMOVED\n', i);
    else
        fprintf('Slot %d -> METAL\n', i);
    end

end
