%% =========================================================
% data processing file so everything doesn't take forever :D 
%
% 
%
% =========================================================
clear; clc;
% MAX DATA RANGE 3/13/2025 19:00 - 9/24/2025 15:00
startTime = datetime('3/13/2025 19:00', Format  = 'MM-dd-uuuu HH:mm');
%endTime = datetime('3/13/2025 23:00', Format  = 'MM-dd-uuuu HH:mm');
endTime = datetime('9/24/2025 15:00', Format  = 'MM-dd-uuuu HH:mm');
csvFile = 'Dalles2024FilteredData_table.csv';
% copy and paste all data points for ai usage:
%upstreamTemp inflow outflow discharge downstreamWaterVelocity wZ rH
%lowCloud highCloud gaugeHeight damElevation damStorage precipitation windDirection

upstreamTemp = tableProcess(readtable('Dalles2025.xlsx','Sheet',5),2,3); %[C] f
downstreamTemp = tableProcess(readtable('Dalles2025.xlsx','Sheet',1),2,3); %[C]f
inflow = tableProcess(readtable('Dalles2025.xlsx','Sheet',6),2,4); %[m^3/s] f
outflow = tableProcess(readtable('Dalles2025.xlsx','Sheet',3),2,5); %[m^3/s] f
discharge = tableProcess(readtable('Dalles2025.xlsx','Sheet',7),2,4); %[m^3/s] f
Tair = tableProcess(readtable('Dalles2025.xlsx','Sheet',10),1,2); %[m^3/s] f
rH = tableProcess(readtable('Dalles2025.xlsx','Sheet',10),1,3); %[%] f
wZ = tableProcess(readtable('Dalles2025.xlsx','Sheet',9),1,5); %[m/s] f
% skyc1 = tableProcess(readtable('Dalles2025.xlsx','Sheet',10),1,5); 
% skyc2 = tableProcess(readtable('Dalles2025.xlsx','Sheet',10),1,6);
% skyc3 = tableProcess(readtable('Dalles2025.xlsx','Sheet',10),1,7); 
downstreamWaterVelocity = tableProcess(readtable('Dalles2025.xlsx','Sheet',2),2,5); 
gaugeHeight = tableProcess(readtable('Dalles2025.xlsx','Sheet',4),2,5); 
damElevation = tableProcess(readtable('elevation_raw.csv'),2,4);
damStorage = tableProcess(readtable('storage_raw.csv'),2,4);
precipitation = tableProcess(readtable('Dalles2025Updated.xlsx','Sheet',13),3,4);
windDirection = tableProcess(readtable('Dalles2025Updated.xlsx','Sheet',12),4,5);


function outputTable = tableProcess(inputArray,timeLoc,dataLoc) % all arrays are processed Tvar Dvar
    inputT = inputArray{:,timeLoc};
    inputT = datetime(inputT);
    inputV = inputArray{:,dataLoc};
    if (inputT(end) - inputT(1)) < 0 % checks if its orded last to first 
        inputT = rot90(inputT,2);
        inputV = rot90(inputV,2);
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
riverBottom = 77.4 - 70; %[m] from sea level
% for t= 1:totalSteps
%     disp(["timeStamp: ", t, "/",totalSteps])
%     dt = startTime + minutes((t-1)*15);
%     nTime(t) = dt;
%     disp(dt)
% 
%     %ndamStorage(t) = dCheck(dt,damStorage);
%     nwindDirection(t) = dCheck(dt,windDirection);
%     if any(isnan([nwindDirection(t)]), 'all')
%             warning('NaN detected at t=%d', t);
%             disp(dt)
%             keyboard      % inspect workspace interactively
%     end
%     % nlowCloud(t) = dCheck(dt,skyc1);
%     % nhighCloud(t) = max([dCheck(dt,skyc2),dCheck(dt,skyc3)]);
% end
% % nTime = rot90(nTime);
% newTable = {nTime,nTair,nupStreamTemp,nDownStreamTemp,nInflow,nOutFlow,nDischarge,ndsWV,ndepthH,nWz,nRH,nlowCloud,nhighCloud};
% writecell(newTable, 'DallesFilteredData.csv');

% Prepare table with column names and data columns
% T = table(nTime.', nTair.', nupStreamTemp.', nDownStreamTemp.', nInflow.', ...
%     nOutFlow.', nDischarge.', ndsWV.', ndepthH.', nWz.', nRH.', nlowCloud.', nhighCloud.', ...
%     'VariableNames', {'nTime','nTair','nupStreamTemp','nDownStreamTemp','nInflow', ...
%     'nOutFlow','nDischarge','ndsWV','ndepthH','nWz','nRH','nlowCloud','nhighCloud'});
% 
% % Write table to CSV with header (first row are variable names)
% writetable(T, );

% Replace a column in an existing CSV (DallesFilteredData_table.csv) with a new data array.
% Configurable inputs:
% temp = ones(1:totalSteps);
datainput = {
   % temp,...    % nTime, ...
    nTair;...
    nWz;  ...
    nOutFlow;...
    nRH;...
    ndsWV;...
    ndepthH;...
    nInflow;...
    nupStreamTemp;...
    nDownStreamTemp;...
    nDischarge;...
    nlowCloud;...
    nhighCloud;...
    ndamElevation;...
    ndamStorage;...
    nRain;...
    nwindDirection...
};
disp(datainput(:,1));
num = size(datainput(:,1));
arrays = num(1);
disp(num)
for i = 1:arrays
     writeColumnToCSV(datainput(i,:), csvFile, i)
     disp("iter")
end

function writeColumnToCSV(dataCellOrArray, csvFile, colNum)
% writeColumnToCSV Write a column vector/array into specified column of CSV table.
%   writeColumnToCSV(dataCellOrArray, csvFile, colNum)
%   - dataCellOrArray: cell containing one array (row or column) or numeric/char array
%   - csvFile: path to CSV file to write/update
%   - colNum: 1-based column index where to place the data (1 = first data column)
%
% If csvFile does not exist, a new CSV is created with a header of generic names.
% If existing table has different number of rows, it will be expanded or trimmed to match data.

    % Normalize input data to column vector numeric/cell as needed
    if iscell(dataCellOrArray) && numel(dataCellOrArray) == 1
        newCol = dataCellOrArray{1};
    elseif iscell(dataCellOrArray) && isvector(dataCellOrArray)
        % If cell array of multiple entries, try to concatenate if they are scalars
        try
            newCol = vertcat(dataCellOrArray{:});
        catch
            newCol = dataCellOrArray;
        end
    else
        newCol = dataCellOrArray;
    end

    % Ensure column vector
    if isrow(newCol) && ~iscell(newCol)
        newCol = newCol(:);
    end

    nNew = numel(newCol);

    % If file exists, read it; otherwise create a new table with generic headers
    if isfile(csvFile)
        opts = detectImportOptions(csvFile, 'NumHeaderLines', 0);
        try
            T = readtable(csvFile, opts);
        catch
            % If readtable fails, create empty table
            T = table();
        end
    else
        T = table();
    end

    % Determine current number of rows and columns
    nRows = height(T);
    nCols = width(T);

    % If table is empty, create appropriate number of rows and columns
    if nRows == 0 && nCols == 0
        % Create at least colNum columns and nNew rows
        nRows = nNew;
        nCols = max(colNum, 1);
        % Generate generic variable names Var1..VarN
        varNames = matlab.lang.makeUniqueStrings(arrayfun(@(k) sprintf('Var%d',k), 1:nCols, 'UniformOutput', false));
        % Initialize with missing values
        initData = cell2table(repmat({missing}, nRows, nCols), 'VariableNames', varNames);
        T = initData;
    else
        % Adjust number of rows to match nNew
        if nRows < nNew
            % Append rows filled with missing
            addRows = nNew - nRows;
            addTbl = array2table(repmat(missing, addRows, nCols), 'VariableNames', T.Properties.VariableNames);
            T = [T; addTbl];
            nRows = nNew;
        elseif nRows > nNew
            % Trim table to match new data length
            T = T(1:nNew, :);
            nRows = nNew;
        end
        % Ensure enough columns
        if nCols < colNum
            addCols = colNum - nCols;
            for k = 1:addCols
                newName = sprintf('Var%d', nCols + k);
                % Ensure unique
                newName = matlab.lang.makeUniqueStrings(newName, T.Properties.VariableNames);
                T.(newName{1}) = repmat(missing, nRows, 1);
            end
            nCols = width(T);
        end
    end

    % Prepare the column data for insertion: match table row count
    if iscell(newCol) && numel(newCol) == nRows
        colData = newCol;
    else
        % Convert numeric/logical/char to column matching table rows
        if isnumeric(newCol) || islogical(newCol)
            colData = num2cell(newCol(:));
        elseif isstring(newCol) || ischar(newCol) || iscellstr(newCol)
            colData = cellstr(newCol);
            if numel(colData) ~= nRows
                % If single string, replicate
                if isscalar(colData)
                    colData = repmat(colData, nRows, 1);
                else
                    colData = colData(:);
                end
            end
        else
            colData = newCol;
        end
    end

    % Insert or replace the column at colNum
    varNames = T.Properties.VariableNames;
    targetName = varNames{colNum};
    % Attempt to convert cell of numerics back to numeric column if original column was numeric
    % But to keep things simple and robust, assign as cell when types differ
    try
        % If column in table is numeric, try convert colData to numeric
        if isnumeric(T.(targetName))
            numericData = cell2mat(colData);
            T.(targetName) = numericData;
        else
            T.(targetName) = colData;
        end
    catch
        % Fallback: assign as cell
        T.(targetName) = colData;
    end

    % Write table back to CSV
    try
        writetable(T, csvFile);
    catch ME
        error('Failed to write CSV "%s": %s', csvFile, ME.message);
    end
end


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
