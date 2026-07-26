function [motion, labels] = read_amc_motion(path)
%READ_AMC_MOTION Parse AMC joint rotations into padded 3-D joint channels.

fid = fopen(path, 'r');
assert(fid >= 0, 'Cannot open AMC file: %s', path);
cleanup = onCleanup(@() fclose(fid));
frames = {};
current = [];
frame_labels = {};
template_labels = {};

while ~feof(fid)
    line = strtrim(fgetl(fid));
    if isempty(line) || startsWith(line, ':')
        continue;
    end
    if ~isempty(regexp(line, '^\d+$', 'once'))
        if ~isempty(current)
            frames{end + 1} = current; %#ok<AGROW>
            if isempty(template_labels), template_labels = frame_labels; end
        end
        current = [];
        frame_labels = {};
        continue;
    end
    tokens = strsplit(line);
    joint = tokens{1};
    values = str2double(tokens(2:end));
    if strcmpi(joint, 'root') && numel(values) >= 6
        values = values(end-2:end); % Remove global XYZ translation.
    end
    padded = zeros(1, 3);
    padded(1:min(3, numel(values))) = values(1:min(3, numel(values)));
    current = [current, padded]; %#ok<AGROW>
    for axis = 1:3
        frame_labels{end + 1} = sprintf('%s_%d', joint, axis); %#ok<AGROW>
    end
end
if ~isempty(current)
    frames{end + 1} = current;
    if isempty(template_labels), template_labels = frame_labels; end
end

width = min(cellfun(@numel, frames));
motion = zeros(numel(frames), width);
for i = 1:numel(frames)
    motion(i, :) = frames{i}(1:width);
end
labels = template_labels(1:width);
end
