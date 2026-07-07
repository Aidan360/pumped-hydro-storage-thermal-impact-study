%% =========================================================
% data processing file so everything doesn't take forever :D 
%
% 
%
% =========================================================
clear; clc;
datRecord = true;
% MAX DATA RANGE 3/13/2025 19:00 - 9/24/2025 15:00
startTime = datetime('1/1/2016 0:00', Format  = 'MM-dd-uuuu HH:mm');
endTime = datetime(' 12/31/2025     23:45', Format  = 'MM-dd-uuuu HH:mm');
% dataFiles = blanks(1,2025);
% dataFiles(2021         = 'Dalles2021.xlsx';
% dataFiles(2022) = 'Dalles2022.xlsx';
% dataFiles(2023) 

csvFile = 'Dalles2016-2025FilteredData_table.csv';
% copy and paste all data points for ai usage:
%upstreamTemp inflow outflow discharge downstreamWaterVelocity wZ rH
%skyc1 skyc2 skyc3 gaugeHeight damElevation damStorage precipitation
%windDirection spillway
datFile = 'Dalles2016-2025.xlsx';
% 2025 data range 3/13/2025 19:00 - 9/24/2025 15:00
% 2024 data range 3/27/2024 16:00 -  9/24/2024 19:00
% 2023 data range 4/5/2023 23:00 - 9/19/2023 19:00
% 2022 data range 3/30/2022 17:00 - 9/13/2022 21:00
% 2021 data range 5/19/2021 19:00 - 9/22/2021 16:00
% gaugeHeight = tableProcess(readtable(datFile,'Sheet',1),1,3); % 1  
% outflow = tableProcess(readtable(datFile,'Sheet',2),1,3); %2
% %downstreamWaterVelocity = tableProcess(readtable(datFile,'Sheet',3),1,3);  %3
% downstreamTemp = tableProcess(readtable(datFile,'Sheet',4),1,2); %4
% % upstreamTemp = tableProcess(readtable(datFile,'Sheet',5),2,3); %5
% damStorage = tableProcess(readtable(datFile,'Sheet',6),1,3);%6
% damElevation = tableProcess(readtable(datFile,'Sheet',7),1,3);  %7
% inflow = tableProcess(readtable(datFile,'Sheet',8),1,3); %8
% discharge = tableProcess(readtable(datFile,'Sheet',9),1,3); %9
% Tair = tableProcess(readtable(datFile,'Sheet',10),1,2); %10
% rH = tableProcess(readtable(datFile,'Sheet',11),1,2); %11
% windDirection = tableProcess(readtable(datFile,'Sheet',12),1,2); % 12
% wZ = tableProcess(readtable(datFile,'Sheet',13),1,3); % 12
% precipitation = tableProcess(readtable(datFile,'Sheet',14),1,2); % 14
% skyc1 = tableProcess(readtable(datFile,'Sheet',15),1,5); %15
% skyc2 = tableProcess(readtable(datFile,'Sheet',15),1,6); %15
% skyc3 = tableProcess(readtable(datFile,'Sheet',15),1,7); %15
% spillway = tableProcess(readtable(datFile,'Sheet',16),1,3);

% 2016-2025 inputs
gaugeHeight = tableProcess(readtable(datFile,'Sheet',1),1,3); % 1  
outflow = tableProcess(readtable(datFile,'Sheet',2),1,3); %2
%downstreamWaterVelocity = tableProcess(readtable(datFile,'Sheet',3),1,3);  %3
downstreamTemp = tableProcess(readtable(datFile,'Sheet',4),1,2); %4
% upstreamTemp = tableProcess(readtable(datFile,'Sheet',5),2,3); %5
damStorage = tableProcess(readtable(datFile,'Sheet',6),1,3);%6
damElevation = tableProcess(readtable(datFile,'Sheet',7),1,3);  %7
inflow = tableProcess(readtable(datFile,'Sheet',8),1,3); %8
discharge = tableProcess(readtable(datFile,'Sheet',9),1,3); %9
Tair = tableProcess(readtable(datFile,'Sheet',10),1,2); %10
rH = tableProcess(readtable(datFile,'Sheet',11),1,2); %11
windDirection = tableProcess(readtable(datFile,'Sheet',12),1,2); % 12
wZ = tableProcess(readtable(datFile,'Sheet',13),1,3); % 12
precipitation = tableProcess(readtable(datFile,'Sheet',14),1,2); % 14
skyc1 = tableProcess(readtable(datFile,'Sheet',15),1,5); %15
skyc2 = tableProcess(readtable(datFile,'Sheet',15),1,6); %15
skyc3 = tableProcess(readtable(datFile,'Sheet',15),1,7); %15
spillway = tableProcess(readtable(datFile,'Sheet',16),1,3);





% 
% 
% 
if ~exist('downstreamWaterVelocity','var')
    disp('replacing downstream with function')
    downStreamCalc = true;
else
    downStreamCalc = false;
end
if ~exist('upstreamTemp','var')
    disp('replacing upstreamTemp with function')
    upStreamTempCalc = true;
else
    upStreamTempCalc = false;
end
% % 
% % align downstream and upstream by time, interpolate upstream to downstream times
% % assume downstreamTemp and upstreamTemp are tables with datetime in first col and values in second
% t_down = downstreamTemp{:,1};
% v_down = downstreamTemp{:,2};
% t_up = upstreamTemp{:,1};
% v_up = upstreamTemp{:,2};
% 
% % restrict to overlapping time range
% t0 = max(min(t_down), min(t_up));
% t1 = min(max(t_down), max(t_up));
% mask_down = t_down >= t0 & t_down <= t1;
% mask_up = t_up >= t0 & t_up <= t1;
% t_down = t_down(mask_down); v_down = v_down(mask_down);
% t_up = t_up(mask_up); v_up = v_up(mask_up);
% 
% % interpolate upstream onto downstream times (use linear)
% v_up_on_down = interp1(datenum(t_up), v_up, datenum(t_down), 'linear', NaN);
% 
% % remove NaNs
% valid = ~isnan(v_up_on_down) & ~isnan(v_down);
% t = t_down(valid);
% y = v_down(valid);
% x = v_up_on_down(valid);
% 
% % fit linear model y = m*x + b
% p = polyfit(x,y,1);
% m = p(1);
% b = p(2);
% 
% % compute average slope approx (use mean of local slopes as check)
% local_slopes = diff(y)./diff(x);
% avg_local_slope = mean(local_slopes(~isnan(local_slopes) & isfinite(local_slopes)));
% 
% % plot
% figure;
% plot(x,y,'.');
% hold on;
% xx = linspace(min(x),max(x),100);
% plot(xx, polyval(p,xx), '-r','LineWidth',1.5);
% xlabel('Upstream Temp');
% ylabel('Downstream Temp');
% title(sprintf('Downstream vs Upstream Temp: slope=%.4f, offset=%.4f', m, b));
% legend('Data','Linear fit','Location','best');
% grid on;
% hold off;
% 
% % display results
% fprintf('Linear fit: downstream = %.6f * upstream + %.6f\n', m, b);
% fprintf('Average local slope: %.6f\n', avg_local_slope);
% 
% disp("data loaded!")




function outputTable = tableProcess(inputArray,timeLoc,dataLoc) % all arrays are processed Tvar Dvar
    inputT = inputArray{:,timeLoc};
    inputT = datetime(inputT, Format  = 'MM-dd-yy HH:mm');
    inputV = inputArray{:,dataLoc};
    
    % Remove rows where either time or value is missing/empty
    % Handle empty strings in cell/char/string arrays for inputV and NaT for inputT
    % Create logical mask of valid time entries
    if isdatetime(inputT)
        validT = ~isnat(inputT);
    else
        validT = ~ismissing(inputT);
    end

    % Create logical mask of valid value entries
    if isnumeric(inputV)
        validV = ~isnan(inputV);
    elseif iscell(inputV)
        % cell may contain empty '', <missing>, or NaN
        validV = true(size(inputV));
        for ii = 1:numel(inputV)
            v = inputV{ii};
            if isempty(v) || (ischar(v) && all(isspace(v))) || (isstring(v) && strlength(v) == 0)
                validV(ii) = false;
            elseif (isnumeric(v) && isnan(v)) || isequal(v,missing)
                validV(ii) = false;
            end
        end
    elseif isstring(inputV) || ischar(inputV)
        validV = ~ismissing(inputV) & strlength(string(inputV))>0;
    else
        % fallback: use ismissing
        validV = ~ismissing(inputV);
    end

    % Combine masks and apply to both arrays
    valid = validT & validV;
    inputT = inputT(valid);
    inputV = inputV(valid);
    %disp(inputT)
    disp(class(inputT))
    disp(size(inputT))
    if (inputT(end) - inputT(1)) < 0 % checks if its orded last to first 
        inputT = rot90(inputT,2);
        inputV = rot90(inputV,2);
    end
    if isnumeric(inputV) ~= true
       
        if iscell(inputV)
            % Convert cell column that contains scalar numeric entries (possibly as strings)
            % into a numeric column vector.
            % Handle cells that are numeric, char, or string scalars.
            n = numel(inputV);
            newInputV = nan(n,1);
            for k = 1:n
                val = inputV{k};
                if isnumeric(val) && isscalar(val)
                    newInputV(k) = val;
                elseif isstring(val) || ischar(val)
                    % try numeric conversion from text
                    num = str2double(string(val));
                    if ~isnan(num)
                        newInputV(k) = num;
                    else
                        newInputV(k) = NaN;
                    end
                else
                    % fallback: attempt to convert any other type to double
                    try
                        newInputV(k) = double(val);
                    catch
                        newInputV(k) = NaN;
                    end
                end
            end
            inputV = newInputV;
       % if iscell(inputV)
       %      num = size(inputV);
       %      newInputV = ones(1,num(1));
       %      disp(inputV)
       %      size(inputV)
       %      disp(num(1))
       %      for n = 1:num(1)
       %          disp(inputV{n})
       %          size(inputV{1,n})
       %          newInputV(n) = inputV{n,1};
       %      end
       %      inputV = newInputV;
       %     disp(inputV)
       % 
       % inputV = cell2mat(inputV);
       else  
     
       end
    end
    input = table(posixtime(inputT),inputV);
    outputTable = input;
end
function out = dCheck(in,arr) %faster terminology for interpolation
    
    % Extract datetime (x) and data (y) columns
    x = arr{:, 1};
    y = arr{:, 2};
    % Find unique x values, their indices, and reverse mapping
    [x_unique, ~, idx] = unique(x, 'stable');

    % Resolve duplicates: average the corresponding y values 
    % (You can alternatively use @(v) v(1) to take the first or @(v) v(end) to take the last)
    y_unique = accumarray(idx, y, [], @mean);

    % Pass the deduplicated data into interp1
    out = interp1(x_unique, y_unique, in,'linear');
 % out = interp1(arr{:,1},arr{:,2},in,'linear');
end
% Create a wrapper that accepts a datetime scalar 'in' and a cell/array of up to 16 tables
% Each table is assumed to have two columns: {datetime, numeric} or numeric timestamps and numeric values.
% This wrapper returns a 1xN numeric vector of interpolated values corresponding to each input table.
function vals = dCheckMany(in, tables)
    nTables = numel(tables);
    vals = nan(1,nTables);
    % Convert query time to numeric seconds since epoch (double)
    inNum = posixtime(datetime(in));
    % Process each table; allow GPU arrays inside tables (second column) and datetime first column
    for k = 1:nTables
        arr = tables{k};
        if isempty(arr)
            vals(k) = NaN;
            continue
        end
        % Extract x and y
        x = arr{:,1};
        y = gpuArray(arr{:,2});
        % Convert x to numeric seconds (gather if gpuArray)
        if isa(x,'datetime') || isstring(x) || iscell(x)
            xnum = posixtime(datetime(gatherIfNeeded(x)));
        else
            xnum = double(gatherIfNeeded(x));
        end
        ynum = double(gatherIfNeeded(y));
        % If any input is gpuArray, perform dedupe on CPU then move to GPU for interp if supported
        useGPU = isa(x,'gpuArray') || isa(y,'gpuArray');
        if useGPU
            % unique on CPU for reliability, preserve stable order
            [xu, ~, idx] = unique(gather(xnum),'stable');
            y_g = gather(ynum);
            y_unique = accumarray(idx, y_g, [], @mean);
            xu_gpu = gpuArray(xu);
            y_gpu = gpuArray(y_unique);
            outNum = interp1(xu_gpu, y_gpu, gpuArray(inNum), 'linear');
            vals(k) = gather(outNum);
        else
            [xu, ~, idx] = unique(xnum,'stable');
            y_unique = accumarray(idx, ynum, [], @mean);
            vals(k) = interp1(xu, y_unique, inNum, 'linear');
        end
    end

    function v = gatherIfNeeded(v)
        if isa(v,'gpuArray')
            v = gather(v);
        end
    end
end

% Small convenience: build a cell array of the 16 expected tables for use below.
% Adjust variable names as needed to match workspace variables.


% Example single-call function for a datetime 'dt' will be used below in parfor:
% vals = dCheckMany(dt, tables16);
if datRecord == true

    totalSteps = minutes(endTime - startTime)/15;
    
    nTime    =       NaT(1,totalSteps); 
    for t = 1:totalSteps
        dt = startTime + minutes((t-1)*15);
        nTime(t) = dt;
    end
    nTair =          ones(1,totalSteps);
    nWz   =          ones(1,totalSteps);
    nOutFlow =       ones(1,totalSteps);
    nRH   =          ones(1,totalSteps);
    ndsWV =          ones(1,totalSteps);
    ndepthH =        ones(1,totalSteps);
    nInflow =        ones(1,totalSteps);
    nupStreamTemp =  ones(1,totalSteps);
    nDownStreamTemp =ones(1,totalSteps);
    nDischarge      =ones(1,totalSteps);
    nlowCloud  =     ones(1,totalSteps);
    nhighCloud =     ones(1,totalSteps);
    ndamElevation = ones(1,totalSteps);
    ndamStorage = ones(1,totalSteps);
    nRain = ones(1,totalSteps);
    nwindDirection = ones(1,totalSteps);
    nspillWay = ones(1,totalSteps);
out16 = [ndepthH, nDownStreamTemp, nInflow, ...
    nOutFlow, nDischarge, ndepthH, nWz, nRH, nlowCloud, nhighCloud, ...
    ndamElevation, ndamStorage, nRain, nwindDirection, nspillWay];

allData = {Tair, downstreamTemp, inflow, outflow, discharge, gaugeHeight, wZ, rH,...
skyc1, skyc2, skyc3, damElevation, damStorage, precipitation,...
windDirection, spillway};

dataSize = 16;

timeArrays = cell(1,dataSize);
dataArrays = cell(1,dataSize);

for k = 1:dataSize
    t = allData{k}{:,1}; % curly braces -> numeric array, not a table
    y = allData{k}{:,2};
    class(t)
    % sort in case time isn't strictly increasing
    [t, idx] = sort(t);
    y = y(idx);
    
    % remove duplicate timestamps if any (keep first occurrence)
    [t, uniqueIdx] = unique(t, 'stable');
    y = y(uniqueIdx);
    
    timeArrays{k} = t;
    dataArrays{k} = y;
end

interpolatedData = zeros(numel(nTime), dataSize);
targetTime = posixtime(nTime);
for k = 1:dataSize
    F = griddedInterpolant(timeArrays{k}, dataArrays{k}, 'linear', 'linear');
    interpolatedData(:,k) = F(targetTime);
end


nTime = rot90(nTime,3); %1
nTair = interpolatedData(:,1);
nDownStreamTemp = interpolatedData(:,2); %3
for a = 1:numel(nDownStreamTemp)
    nupStreamTemp(a) = 0.994594373*nDownStreamTemp(a) + 0.064395157; % 2
end
nupStreamTemp = rot90(nupStreamTemp,3);
nInflow = interpolatedData(:,3); % 4
nOutFlow =  interpolatedData(:,4); % 5 
nDischarge = interpolatedData(:,5); % 6
for a = 1:numel(nDischarge)
    ndsWV(a) = 0.000104602*nDischarge(a)+0.01683; %7
end
ndsWV = rot90(ndsWV,3);
ndepthH = interpolatedData(:,6); % 8
nWz = interpolatedData(:,7);  % 9
nRH = interpolatedData(:,8); % 10
nlowCloud = interpolatedData(:,9); % 11
for a= 1:numel(interpolatedData(:,10))
    s2 = interpolatedData(a,10);
    s3 = interpolatedData(a,11);
    nhighCloud(a) = max(s2,s3);% 12
end
nhighCloud = rot90(nhighCloud,3);
ndamElevation = interpolatedData(:,12);
ndamStorage = interpolatedData(:,13);
nRain = interpolatedData(:,14);
nwindDirection = interpolatedData(:,15);
nspillWay = interpolatedData(:,16);


resultTable = table(nTime, nTair,nupStreamTemp, nDownStreamTemp,...
    nInflow, nOutFlow, nDischarge,ndsWV,...
    ndepthH,nWz, nRH, nlowCloud,...
    nhighCloud, ndamElevation, ndamStorage,...
    nRain, nwindDirection, nspillWay, 'VariableNames', {'nTime','nTair','nupStreamTemp','downstreamTemp','inflow','outflow',...
    'discharge','downstreamWaterVelocity','downstreamWaterDepth','wZ','rH','lowcloud','highcloud','damElevation','damStorage', ...
    'precipitation','windDirection','spillway'});
% downstreamTemp, inflow, outflow, discharge, wZ, rH,...
%skyc1, skyc2, skyc3, gaugeHeight, damElevation, damStorage, precipitation,...
%windDirection, spillway
end

writetable(resultTable, csvFile);
% 
% 
% 
% 
% 
% % Assemble table with specified variable order and names, ensuring column vectors
% varNames = {'nTime','nTair','nupStreamTemp','nDownStreamTemp','nInflow', ...
%     'nOutFlow','nDischarge','ndsWV','ndepthH','nWz','nRH','nlowCloud','nhighCloud', ...
%     'ndamElevation','ndamStorage','nRain','nwindDirection','nspillWay'};
% 
% % Ensure nTime is a column of datetimes (if currently NaT row vector)
% if isrow(nTime)
%     nTime = nTime.';
% end
% cols = {nTime, nTair(:), nupStreamTemp(:), nDownStreamTemp(:), nInflow(:), ...
%     nOutFlow(:), nDischarge(:), ndsWV(:), ndepthH(:), nWz(:), nRH(:), nlowCloud(:), nhighCloud(:), ...
%     ndamElevation(:), ndamStorage(:), nRain(:), nwindDirection(:), nspillWay(:)};
% 
% % Validate lengths: all columns must have same number of rows
% nRows = numel(cols{1});
% for k = 2:numel(cols)
%     if numel(cols{k}) ~= nRows
%         error('Column %s has length %d but expected %d.', varNames{k}, numel(cols{k}), nRows);
%     end
% end
% 
% % Create table using provided variable names
% Tout = table(cols{:}, 'VariableNames', varNames);
% 
% % Write to CSV file with header row (variable names)
% writetable(Tout, csvFile);
% end % end of dat record stuff






% 
