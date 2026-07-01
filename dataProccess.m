%% =========================================================
% data processing file so everything doesn't take forever :D 
%
% 
%
% =========================================================
clear; clc;
datRecord = true;
% MAX DATA RANGE 3/13/2025 19:00 - 9/24/2025 15:00
startTime = datetime('5/19/2021 18:00', Format  = 'MM-dd-uuuu HH:mm');
endTime = datetime('9/22/2021 16:00', Format  = 'MM-dd-uuuu HH:mm');
% dataFiles = blanks(1,2025);
% dataFiles(2021) = 'Dalles2021.xlsx';
% dataFiles(2022) = 'Dalles2022.xlsx';
% dataFiles(2023) 

csvFile = 'Dalles2021FilteredData_table.csv';
% copy and paste all data points for ai usage:
%upstreamTemp inflow outflow discharge downstreamWaterVelocity wZ rH
%lowCloud highCloud gaugeHeight damElevation damStorage precipitation windDirection
datFile = 'Dalles2021.xlsx';
% 2025 data range 3/13/2025 19:00 - 9/24/2025 15:00
% 2024 data range 3/27/2024 16:00 -  9/24/2024 19:00
% 2023 data range 4/5/2023 23:00 - 9/19/2023 19:00
% 2022 data range 3/30/2022 17:00 - 9/13/2022 21:00
% 2021 data range 5/19/2021 19:00 - 9/22/2021 16:00
gaugeHeight = tableProcess(readtable(datFile,'Sheet',1),1,3); % 1  
outflow = tableProcess(readtable(datFile,'Sheet',2),1,3); %2
%downstreamWaterVelocity = tableProcess(readtable(datFile,'Sheet',3),1,3);  %3
downstreamTemp = tableProcess(readtable(datFile,'Sheet',4),1,2); %4
upstreamTemp = tableProcess(readtable(datFile,'Sheet',5),1,2); %5
damStorage = tableProcess(readtable(datFile,'Sheet',6),1,3);%6
damElevation = tableProcess(readtable(datFile,'Sheet',7),1,3);  %7
inflow = tableProcess(readtable(datFile,'Sheet',8),1,3); %8
discharge = tableProcess(readtable(datFile,'Sheet',9),1,3); %9
Tair = tableProcess(readtable(datFile,'Sheet',10),1,2); %10
rH = tableProcess(readtable(datFile,'Sheet',11),1,2); %11
windDirection = tableProcess(readtable(datFile,'Sheet',12),1,2); % 12
wZ = tableProcess(readtable(datFile,'Sheet',13),1,3); %13
precipitation = tableProcess(readtable(datFile,'Sheet',14),1,2); % 14
skyc1 = tableProcess(readtable(datFile,'Sheet',15),1,5); %15
skyc2 = tableProcess(readtable(datFile,'Sheet',15),1,6); %15
skyc3 = tableProcess(readtable(datFile,'Sheet',15),1,7); %15

% 
% 
% 
if ~exist('downstreamWaterVelocity','var')
    disp('replacing downstream with function')
    downStreamCalc = true;
else
    downStreamCalc = false;
end
% 
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
         summary(inputV)
         class(inputV)
         disp(dataLoc)
         pause;
     
       end
    end
    input = table(inputT, inputV);
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
if datRecord == true

    totalSteps = minutes(endTime - startTime)/15;

    nTime    =       NaT(1,totalSteps); 
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
  




parfor t= 1:totalSteps
    disp(["timeStamp: ", t, "/",totalSteps])
    dt = startTime + minutes((t-1)*15);
    nTime(t) = dt;
    disp(dt) 

    ndepthH(t) = dCheck(dt,gaugeHeight);
    nupStreamTemp(t) = dCheck(dt,upstreamTemp);
    nDownStreamTemp(t) = dCheck(dt,downstreamTemp);
    nTair(t) = dCheck(dt, Tair);
    nInflow(t) = dCheck(dt, inflow);
    nOutFlow(t) = dCheck(dt, outflow);
    nDischarge(t) = dCheck(dt, discharge);
    nWz(t) = dCheck(dt,wZ);
    nRH(t) = dCheck(dt,rH);
    ndamElevation(t) = dCheck(dt,damElevation);
    nlowCloud(t) = dCheck(dt,skyc1);
    nhighCloud(t) = max([dCheck(dt,skyc2),dCheck(dt,skyc3)]);
    ndamStorage(t) = dCheck(dt,damStorage);
    nwindDirection(t) = dCheck(dt,windDirection);
    nRain(t) = dCheck(dt,precipitation);
    if downStreamCalc == false
        ndsWV(t) = dCheck(dt,downstreamWaterVelocity);
    else
        ndsWV(t) = 0.000104602*nDischarge(t)+0.01683; 
    end
end
newTable = {nTime,nTair,nupStreamTemp,nDownStreamTemp,nInflow,nOutFlow,nDischarge,ndsWV,ndepthH,nWz,nRH,nlowCloud,nhighCloud};
writecell(newTable, csvFile);





% Assemble table with specified variable order and names, ensuring column vectors
varNames = {'nTime','nTair','nupStreamTemp','nDownStreamTemp','nInflow', ...
    'nOutFlow','nDischarge','ndsWV','ndepthH','nWz','nRH','nlowCloud','nhighCloud', ...
    'ndamElevation','ndamStorage','nRain','nwindDirection'};

% Ensure nTime is a column of datetimes (if currently NaT row vector)
if isrow(nTime)
    nTime = nTime.';
end
cols = {nTime, nTair(:), nupStreamTemp(:), nDownStreamTemp(:), nInflow(:), ...
    nOutFlow(:), nDischarge(:), ndsWV(:), ndepthH(:), nWz(:), nRH(:), nlowCloud(:), nhighCloud(:), ...
    ndamElevation(:), ndamStorage(:), nRain(:), nwindDirection(:)};

% Validate lengths: all columns must have same number of rows
nRows = numel(cols{1});
for k = 2:numel(cols)
    if numel(cols{k}) ~= nRows
        error('Column %s has length %d but expected %d.', varNames{k}, numel(cols{k}), nRows);
    end
end

% Create table using provided variable names
Tout = table(cols{:}, 'VariableNames', varNames);

% Write to CSV file with header row (variable names)
writetable(Tout, csvFile);
end % end of dat record stuff


% for i = 1:arrays
%      writeColumnToCSV(datainput(i,:), csvFile, i)
%      disp("iter")
% end
% I need you to write the following arrays into a table "Dalles2024FilteredData_table.csv". the first row of every column has the name of the variable. 'nTime','nTair','nupStreamTemp','nDownStreamTemp','nInflow', 'nOutFlow','nDischarge','ndsWV','ndepthH','nWz','nRH','nlowCloud','nhighCloud','ndamElevation', 'ndamStorage','nRain','nwindDirection'



% csvFile = 'DallesFilteredData_table.csv';
% newColName = 'nwindDirection';    % header for the replacement column
% newColData = nwindDirection(:);   % column vector of data to write (must match number of data rows)
% colNum = 17;
% % Read the CSV table (preserve text headers)
% if ~isfile(csvFile)
%     error('CSV file "%s" not found.', csvFile);
% end
% opts = detectImportOptions(csvFile,'NumHeaderLines',0);
% T = readtable(csvFile, opts);
% 
% % Ensure length matches (assume first column is datetime header + rows correspond to nTime)
% nRowsTable = height(T);
% if numel(newColData) ~= nRowsTable
%     % Allow case when table includes header row in file but readtable removed it — try to adjust by 1
%     error('Length mismatch: replacement data has %d rows but table has %d rows.', numel(newColData), nRowsTable);
% end
% 
% % If the column exists, replace it; otherwise add it
% if ismember(newColName, T.Properties.VariableNames)
%     T.(newColName) = newColData;
% else
%     % Insert new column after first column (so second column by default)
%     insertPos = min(colNum, width(T)+1);
%     varNames = T.Properties.VariableNames;
%     % Create a table for the new column
%     Tnew = table(newColData, 'VariableNames', {newColName});
%     % Concatenate preserving order: before, new, after
%     if insertPos == 1
%         T = [Tnew, T];
%     elseif insertPos == width(T)+1
%         T = [T, Tnew];
%     else
%         T = [T(:,1:insertPos-1), Tnew, T(:,insertPos:end)];
%     end
% end

% Write back to CSV, preserving variable names as header
% writetable(T, csvFile);





% 
% 
% vars = {nTair,nupStreamTemp,nDownStreamTemp,nInflow,nOutFlow,nDischarge,ndsWV,ndepthH,nWz,nRH,nlowCloud,nhighCloud};
% varNames = {'Tair','UpstreamTemp','DownstreamTemp','Inflow','Outflow','Discharge','DownstreamWaterVelocity','DepthHeight','Wz','RH','LowCloud','HighCloud'};
% 
% % Create datetime vector matching stored nTime/dt values
% dtVec = startTime + minutes(0:15:(totalSteps-1)*15);
% 
% for figIdx = 1:3 % 12 plots, 4 per figure -> 3 figures
%     figure;
%     for subIdx = 1:4
%         idx = (figIdx-1)*4 + subIdx;
%         if idx > numel(vars), break; end
%         ax = subplot(2,2,subIdx);
%         y = vars{idx};
%         plot(ax, dtVec, y, '-b', 'LineWidth', 1);
%         grid(ax,'on');
%         xlabel(ax,'Time');
%         ylabel(ax,varNames{idx}, 'Interpreter','none');
%         title(ax,[varNames{idx} ' vs Time'], 'Interpreter','none');
%         % Improve x-ticks for readability
%         datetick(ax,'x','keepticks');
%     end
% end
% 


% ORDER 
