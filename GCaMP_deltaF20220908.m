% Clear previous variables and command window
clear
clc

% Open file and set x and y variables and graph data
data = uiimport('-file');
x = data.Frame;
y = data.Intensity;
plot(x, y,'blue')

% Find lowest 50 values in user-defined beginning of trace
prompt1 = {'Enter Start Value or use 1 as default:'};
definput1 = {'1'};
dlgtitle1 = 'Start Value for beginning of trace';
dims = [1 35];
y1 = inputdlg(prompt1, dlgtitle1, dims, definput1);
prompt2 = {'Enter Stop Value or use 600 as default'};
definput2 = {'600'};
dlgtitle2 = 'Stop Value for beginning of trace';
y2 = inputdlg(prompt2, dlgtitle2, dims, definput2);
start1 = str2num(y1{1});
stop1 = str2num(y2{1});
DataStart = y(start1:stop1);
StartSort = sort(DataStart);
StartMin = mean(StartSort(1:50));

% Find lowest 50 values in user-defined end of trace
prompt3 = {'Enter Start Value or use 2735 as default'};
definput3 = {'2735'};
dlgtitle3 = 'Start Value for end of trace';
y3 = inputdlg(prompt3, dlgtitle3, dims, definput3);
start2 = str2num(y3{1});
DataEnd = y(start2:3334);
EndSort = sort(DataEnd);
EndMin = mean(EndSort(1:50));

% Calculate intensity photobleaching and baseline
PhotoBleach = (StartMin - EndMin) / (3334 - stop1);
Baseline = (StartMin + EndMin) / 2;

% Correct Intensity for photobleaching over time
y_start = y(1:stop1);
x_start = x(1:stop1);
y_end = y((stop1+1):3334);
x_end = x((stop1+1):3334);

for y_correct_calc = y_end
    % Correction with photobleach seems variable, need to fix
    y_correct = y_end + (PhotoBleach * x_end) - (StartMin - EndMin);
end

y_full = cat(1, y_start, y_correct);

% Calculate deltaF/F from data
Baseline_sort = sort(y_full);
Baseline = mean(Baseline_sort(1:100));

for deltaF_calc = y_full
    deltaF = (y_full - Baseline) / Baseline;
end

% Convert frames to time based on 11 Hz imaging
for time_calc = x
    time = (x - 1) * 0.0909;
end

% Smooth data over 50 points using moving mean
smooth = smoothdata(deltaF, 'movmean', 25);

% Identify peaks as greater than 0.05
peak = islocalmax(smooth, 'MinProminence', 0.05);

% Create graph of deltaF/F over time
plot(time, smooth, 'blue')
hold on
plot(time, smooth, time(peak), smooth(peak), 'ro')
hold off

% Create table of deltaF data and save file
deltaFtable = table(time, deltaF);

% Smooth data and calculate peaks and troughs
smooth = smoothdata(deltaF, 'movmean', 50);
peak = islocalmax(smooth, 'MinProminence', 0.05);
trough = islocalmin(smooth, 'MinProminence', 0.02);

% Calculate amplitude of each peak
troughlist = deltaF(trough);
mean_trough = mean(troughlist);
peaklist = deltaF(peak);
for amp = peaklist
amplitude = amp - mean_trough;
end

% Plot data to check peak and trough detection
plot(time, smooth, time(peak), smooth(peak), 'ro')
hold on
plot(time, smooth, time(trough), smooth(trough), 'r*')
yline(mean_trough, 'm--')
plot(time, smooth, 'b')
hold off

% Calculate frequency of peaks per minute and mean amplitude
frequency = length(peaklist) / (time(end) / 60);
mean_amp = mean(amplitude);

% Open dialog box to save deltaF data table as .csv file
prompt = 'File Name: ';
dlgtitle = 'Save deltaF table as';
dims = [1 35];
filename = string(inputdlg(prompt, dlgtitle, dims)+".csv");
writetable(deltaFtable, filename)