%% =========================================================
% CYCLIC PHS MODEL (CONTROL VOLUME + TEMPERATURE)
% TURBINE + PUMP WITH SCHEDULING –  with efficiency heat source
% SURFACE HEAT TRANSFER
%
% =========================================================
clear; clc;
%% -------------------------
% INPUTS
%% -------------------------
% Time inputs
% MAX DATA RANGE
% 2025: 3/13/2025 19:00 - 9/24/2025 15:00

csvDat = 'Dalles2021FilteredData_table.csv';
% startTime = datetime('3/13/2025 19:00', Format  = 'MM-dd-uuuu HH:mm');
% endTime = datetime('9/24/2025 15:00', Format  = 'MM-dd-uuuu HH:mm');
%csvDat = 'Dalles2025FilteredData_table.csv'
% 2024: 3/27/24 16:00 -  9/24/24 19:00
% csvDat = 'Dalles2024FilteredData_table.csv';
% startTime = datetime('3/27/2024 16:00', Format  = 'MM-dd-uuuu HH:mm');
% endTime = datetime('9/24/2024 19:00', Format  = 'MM-dd-uuuu HH:mm');
% 2023 data range 4/5/23 23:00 - 9/19/23 19:00
%startTime = datetime('4/5/2023 23:00', Format  = 'MM-dd-uuuu HH:mm');
%endTime = datetime('9/19/2023 19:00', Format  = 'MM-dd-uuuu HH:mm');
% 2022 data range 3/30/2022 17:00 - 9/13/2022 21:00
% startTime = datetime('3/30/2022 17:00', Format  = 'MM-dd-uuuu HH:mm');
% endTime = datetime('9/13/2022 21:00', Format  = 'MM-dd-uuuu HH:mm');
% 2021 data range 9/3/2021 19:00 - 9/22/2021 16:00
startTime = datetime('9/3/2021 19:00', Format  = 'MM-dd-uuuu HH:mm');
endTime = datetime('9/22/2021 16:00', Format  = 'MM-dd-uuuu HH:mm');
%% DAM PARAMETERS
spillwayCrest = 121; %{Ft]
maxStorage = 554900; %[Acre*ft] by top of flood control
maxStoragePreFlood = 310000; %[Acre*ft] bottom of flood control storage
damBed = 55/ 3.281; %[Ft]
damTop = 185; %[ft]
floodControlTop = 182.3; %[ft]
floodControlBottom = 160; %[ft]
resMaxRadius = 10000; %[m] Resivour Radius at Max depth    
resMaxDepth     =   (182.3 - 55)/3.281;%[m]        

riverElevation = 77.4/3.281; %[m]
riverBottom = 55/ 3.281; %[m] from sea level

resivourDir = 46.5; % [Deg]
riverDir = 319.59; %[riverDirection]



Tf = readtable(csvDat); % filtered data
any(isnan(Tf{:,2}), 'all')
timeVar = Tf{:,1};
Tair =  Tf{:,2}; %[m^3/s]
upstreamTemp = Tf{:,3};%[C]
downstreamTemp = Tf{:,4}; %[C]
inflow = Tf{:,5}; %[m^3/s]
outflow = Tf{:,6}; %[m^3/s]
discharge = Tf{:,7}; %[m^3/s]
downstreamWaterVelocity = Tf{:,8};
gaugeHeight = Tf{:,9}; %[ft]
wZ = Tf{:,10}; %[m/s]
rH = Tf{:,11}; %[%]
lowCloud = Tf{:,12}; 
highCloud = Tf{:,13};
damElevation =  Tf{:,14}; %[ft]
damStorage = Tf{:,15}; %[acre*ft]
rain = Tf{:,16}; %{mm]
windDirection = Tf{:,17}; % [angle from true north]
summary(damElevation)

disp("all data has loaded")




% 
% % -------------------------
% % PLOTS: pairwise plotting of listed variables against time and against each other
% % -------------------------
% vars = { ...
%     'upstreamTemp', upstreamTemp; ...
%     'downstreamTemp', downstreamTemp; ...
%     'inflow', inflow; ...
%     'outflow', outflow; ...
%     'discharge', discharge; ...
%     'downstreamWaterVelocity', downstreamWaterVelocity; ...
%     'wZ', wZ; ...
%     'rH', rH; ...
%     'lowCloud', lowCloud; ...
%     'highCloud', highCloud; ...
%     'gaugeHeight', gaugeHeight; ...
%     'damElevation', damElevation; ...
%     'damStorage', damStorage; ...
%     'rain', rain; ...
%     'windDirection', windDirection ...
%     };
% 
% nVars = size(vars,1);
% 
% % 1) Plot each variable vs time in individual subplots (grouped pages if needed)
% ptsPerPage = 6; % number of subplots per figure
% nPages = ceil(nVars/ptsPerPage);
% for p = 1:nPages
%     hf = figure('Name',sprintf('Time series page %d',p),'NumberTitle','off');
%     startIdx = (p-1)*ptsPerPage + 1;
%     endIdx = min(p*ptsPerPage, nVars);
%     for k = startIdx:endIdx
%         axIdx = k - startIdx + 1;
%         subplot(ptsPerPage,1,axIdx);
%         plot(timeVar, vars{k,2}, '-b');
%         grid on;
%         ylabel(vars{k,1}, 'Interpreter','none');
%         if axIdx == 1
%             title(sprintf('Time series (page %d)', p));
%         end
%         if axIdx == ptsPerPage || k==endIdx
%             xlabel('Time');
%         else
%             set(gca,'XTickLabel',[]);
%         end
%     end
% end
% 
% % 2) Scatter matrix (pairwise) for quick visual correlation among numeric arrays
% % Assemble numeric matrix: convert all to column vectors and ensure same length
% N = numel(timeVar);
% dataMat = nan(N, nVars);
% for k = 1:nVars
%     v = vars{k,2};
%     if isrow(v), v = v(:); end
%     if numel(v) ~= N
%         % try to expand or truncate to match N
%         minN = min(numel(v), N);
%         temp = nan(N,1);
%         temp(1:minN) = v(1:minN);
%         v = temp;
%     end
%     dataMat(:,k) = v;
% end
% 
% % Use built-in scattermatrix if available; otherwise create custom pairwise scatter plots
% if exist('plotmatrix','file')
%     hf2 = figure('Name','Pairwise scatter matrix','NumberTitle','off');
%     [H, ax] = plotmatrix(dataMat);
%     % label axes
%     n = nVars;
%     for i = 1:n
%         xlabel(ax(n,i), vars{i,1}, 'Interpreter','none');
%         ylabel(ax(i,1), vars{i,1}, 'Interpreter','none');
%     end
% else
%     % simple pairwise scatter loops, create multiple figures to avoid huge figure
%     maxPerFig = 9; % plots per figure (3x3)
%     pairs = nchoosek(1:nVars,2);
%     nPairs = size(pairs,1);
%     figs = ceil(nPairs / maxPerFig);
%     pIdx = 1;
%     for f = 1:figs
%         hf = figure('Name',sprintf('Pairwise scatters %d',f),'NumberTitle','off');
%         for s = 1:min(maxPerFig, nPairs-(f-1)*maxPerFig)
%             subplot(3,3,s);
%             i = pairs(pIdx,1);
%             j = pairs(pIdx,2);
%             scatter(dataMat(:,i), dataMat(:,j), 6, '.');
%             xlabel(vars{i,1}, 'Interpreter','none');
%             ylabel(vars{j,1}, 'Interpreter','none');
%             grid on;
%             pIdx = pIdx + 1;
%         end
%     end
% end
% 
% % 3) Correlation matrix (Pearson) and heatmap for numeric insight
% R = corrcoef(dataMat, 'Rows','pairwise');
% hf3 = figure('Name','Correlation matrix','NumberTitle','off');
% imagesc(R);
% colorbar;
% axis tight;
% xticks(1:nVars); yticks(1:nVars);
% xticklabels(vars(:,1)); yticklabels(vars(:,1));
% xtickangle(45);
% title('Pearson correlation matrix (pairwise)');
% % annotate values
% for i = 1:nVars
%     for j = 1:nVars
%         text(j,i,sprintf('%.2f',R(i,j)), 'HorizontalAlignment','center', 'Color','w','FontSize',8);
%     end
% end
% 
% % 4) Save figures to a folder 'plots' for later inspection
% outDir = fullfile(pwd,'plots');
% if ~exist(outDir,'dir'), mkdir(outDir); end
% figs = findobj('Type','figure');
% for i = 1:numel(figs)
%     try
%         fname = fullfile(outDir, sprintf('figure_%02d.png', i));
%         saveas(figs(i), fname);
%     catch
%         % ignore save errors
%     end
% end
% 
% disp('Plotting complete. Figures saved in ./plots (if writable).');







%% -----------------------------
% 1. VARIABLES
%% -----------------------------
totalSteps = minutes(endTime - startTime)/15;
disp(["timeSteps",totalSteps])
waterDensity   =        999.07; % [kg/m^3]
Cp    = 4186;      % specific heat        [J/(kg·K)]
g        = 9.81;    % gravity              [m/s^2]
long = -121.190;
lat = 45.608;
TZ = -8;






%upper resivour parameters
% resiovur modeled as cone to simulate water loss 

% resInitalRadius   = resRadCalc(resInitalDepth,resMaxRadius,resMaxDepth); %[m]
% resInitalSurfaceArea = resAreaCalc(resInitalDepth,resMaxRadius,resMaxDepth); % [m^2]
% resInitalVolume = resVolumeCalc(resInitalDepth,resInitalRadius); %[m^3]


%transient resivour variables
resD = ones(1,totalSteps); %[m]
resV = ones(1,totalSteps); %[m^3]
resT = ones(1,totalSteps); %[C]
resTControl = ones(1,totalSteps);

%river values
riverT = ones(1,totalSteps); % [C]
riverTControl = ones(1,totalSteps);
%riverSA = 0.67*10^6; %[m^2] surface area taken from top of dalles dam 
% --- Turbine Parameters ---

head = 25; % gotta find a way to get rid of this 

turbineEff = 0.90;    % turbine efficiency   [-]
pumpEff = 0.85;    % pump efficiency      [-]
turbmMFR = 10700;        % max turbine flow rate    [m^3/s] using data from dalles dam
pumpmMFR = 10700;        % max pump flow rate       [m^3/s]

turbHeatCoff = (1 - turbineEff) * waterDensity * g * head; % [J/m^3] 
pumpHeatCoff = (1 - pumpEff) * waterDensity * g * head; % [J/m^3]
turbPowerCoff = (turbineEff) * waterDensity * g * head; % [J/m^3] 
pumpPowerCoff = (pumpEff) * waterDensity * g * head; % [J/m^3]
% m^3/s * J/m^3 = W

%%-----------------
% 2. Data Processing
%%----------------

surfdat = ones(1,totalSteps);
pumpdat = ones(1,totalSteps);
turbdat = ones(1,totalSteps);
indat = ones(1,totalSteps);
diffdat = ones(1,totalSteps);
updat = ones(1,totalSteps);
downdat = ones(1,totalSteps);
monitorUpperTemp = ones(1,totalSteps);
monitorLowerTemp = ones(1,totalSteps);

%%------------------
% 3. Thermal Processes
%%------------------
mode = -1;


for t = 1:totalSteps
    
    disp(["timeStamp: ", t])
    dt = startTime + minutes((t-1)*15);
 %   disp(dt)
    aP = find(timeVar == dt);
    if isempty(aP)
      error('No matching timestamp for %s', char(dt));
    end
    c1 = lowCloud(aP);
    c2 = highCloud(aP);
    cloudiness = [c1,c2]; 
   
    if t == 1
        resT(t) = upstreamTemp(aP);
        riverT(t) = downstreamTemp(aP);
        monitorUpperTemp(t) = upstreamTemp(aP);
        monitorLowerTemp(t) = downstreamTemp(aP);
        resV(t) = damStorage(aP);
        resD(t) = damElevation(aP);
    else
        resT(t) = resT(t-1);
        riverT(t) = riverT(t-1);
        resD(t) = resD(t - 1);
        resV(t) = resV(t - 1);
        monitorUpperTemp(t) = upstreamTemp(aP);
        monitorLowerTemp(t) = downstreamTemp(aP);
    end
    tableData = [ % all transient data 
            Tair(aP) ... % 1
            wZ(aP),... % 2
            outflow(aP),... % 3
            cloudiness,... % 4
            rH(aP), ...% 5
            downstreamWaterVelocity(aP), ... % 6
            gaugeHeight(aP), ... % 7
            inflow(aP), ... % 8
            upstreamTemp(aP),... % 9
            rain(aP), ... % 10
            windDirection(aP)... % 11  
            ];
    transientData = [
            resD(t), ... %1 
            resT(t), ... %2
            riverT(t), ... %3
            resV(t)
        ];
        mode = 1;
        % 
        % if resD(t) >= resMaxDepth || resD(t) <= resMinDepth
        %     mode = 1;
        % else
        %     mode = 1;
        % end
        if mode == 0
            dT = noFlowCondition(resMaxRadius,resMaxDepth,Cp,waterDensity, ...
                transientData, ...
                tableData,dt);
            resT(t) =  dT(1); 
            riverT(t) = dT(2);
        else
            %powerReq = powerOutputSimpleSchedule(t/4) * 10^6; %[W]
            % if powerReq >= 0
            %     reqFlowRate = -powerReq/turbPowerCoff; % flow condition considers flow to resivour as positive
            % else
            %     reqFlowRate = -powerReq/pumpPowerCoff;
            % end
            reqFlowRate = -discharge(aP);
            dT = flowCondition(resMaxRadius,resMaxDepth,riverBottom,Cp,waterDensity,turbHeatCoff,pumpHeatCoff, ...
                transientData,reqFlowRate, ...
                tableData,dt,riverDir);
            resT(t) =  dT(1); 
            riverT(t) = dT(2); 
            resV(t) = dT(3);
            resD(t) = dT(4);
            surfdat(t) = dT(5);
            indat(t) = dT(6);
            turbdat(t) = dT(7);
            pumpdat(t) = dT(8);
            diffdat(t) = dT(9);
            updat(t) = dT(10);
            downdat(t) = dT(11);
        end
        if any(isnan([resT(t), resV(t), resD(t), riverT(t), upstreamTemp(aP)]), 'all')
            warning('NaN detected at t=%d', t);
            disp(dt)
            keyboard      % inspect workspace interactively
        end


end
disp("Calculations Finished!");
% Prepare hours



%{
no flow considerations:
River temp does not matter, data can be assumed for now for heat exchange
heat exchange in resivour 

%} 
% non transient then transient stuff
% function out = noFlowCondition(rMR,rMD,Cp, ...
%     depth,lT,uT,resV, ...
%     t,dt)
% 
%     %Proccessing Transient data values
%     Tair = t(1);
%     Wz = t(2);
%     riverDischarge = t(3);
%     cloudiness = [t(4),t(5)];
%     rH = t(6);
%     riverV = t(7);
%     riverD = t(8);
%     rain = t(10);
%     windDirection = t(11);
%     %Preliminary Area Calculations
%     resArea = resAreaCalc(depth,rMR,rMD);
%     riverCrossArea = riverDischarge / riverV; % modeling river as cylinder 
%     %riverDia = 2*sqrt(riverCrossArea/pi); % river dia, assume river surface area is 1m x river dia area square.
%     riverDia = rivDiaCalc(riverD,riverCrossArea);
%     riverSA = riverDia;
% 
%     %Surface Heat Transfer
%     duT = surfaceHeatTransfer(cloudiness,Tair,uT,Wz,Cp,resArea,resV,rH,dt,150); % [°C]
%     dlT =  surfaceHeatTransfer(cloudiness,Tair,lT,Wz,Cp,riverSA,riverCrossArea,rH,dt,50);
% 
%     %Heat Exchange
%     reT = lT + duT; % new res temp
%     riT = uT + dlT; % new river temp
%     out = [reT,riT];
% end

% 
function out = flowCondition(rMR,resMaxDepth,riverBottom,Cp,waterDensity,turbHeatCoff,pumpHeatCoff, ...
    tD,flowRate, ...
    t,dt,rivDirection)


    %transient data
    depth = tD(1);
    lT = tD(2);
    uT = tD(3);
    resV = tD(4);

    %table data 
    Tair = t(1);
    Wz = t(2);
    riverDischarge = t(3);
    cloudiness = [t(4),t(5)];
    rH = t(6);
    riverV = t(7);
    gaugeRiv = t(8);
    resInflow = t(9);
    upperTemp = t(10);
    rain = t(11);
    windDirection = t(12);
  
    %Area Calculations

    newDepth = resDepthCalc(flowRate*15*60 + resInflow*15*60,depth,rMR,resMaxDepth);
    resArea = resAreaCalc(newDepth,rMR,resMaxDepth);
    newResV = resV + flowRate*15*60 + resInflow*15*60; %considering 15 minute intervals
    
    riverD = gaugeRiv - riverBottom;
    riverCrossArea = (riverDischarge) / riverV; % modeling river as cylinder 
    %riverDia = 2*sqrt(riverCrossArea/pi); % river dia, assume river surface area is 1m x river dia area square.
    riverDia = rivDiaCalc(riverD,riverCrossArea);
    riverSA = riverDia;
    
    %Surface Heat Transfer
    duTSurface = surfaceHeatTransfer(cloudiness,Tair,uT,Wz,Cp,resArea,newResV,rH,dt,55/3.81 + depth,rain,0,0,waterDensity); % [°C]
    dlTSurface = surfaceHeatTransfer(cloudiness,Tair,lT,Wz,Cp,riverSA,riverCrossArea,rH,dt,gaugeRiv,rain,windDirection - rivDirection,riverV,waterDensity); 
    % Considering river depth not to change from resivour flows
    Qinflow = (upperTemp-uT)*Cp*resInflow*waterDensity*15*60;
    duTInflow = Qinflow/(newResV*waterDensity*Cp);

    duTPump = 0;
    duTTurb = 0;
   if flowRate >= 0 % case one, flowing up to the upper resivour
        % heat transfer model, river ----> pump -----> resivour
        Qpump = pumpHeatCoff*flowRate*15*60; %[W], 
        Qriv = (lT-uT)*Cp*flowRate*waterDensity*15*60; %[W] considering 15 min intervals
        duTdiff = Qriv/(riverDischarge*15*60 * waterDensity *Cp);
        duTPump = Qpump/(newResV * waterDensity *Cp);
        duT = duTSurface + duTPump+duTInflow+ duTdiff;
        dlT = dlTSurface;
    else
        Qturb = turbHeatCoff*-flowRate*15*60;
        Qres = (uT-lT)*Cp*flowRate*waterDensity*15*60;
        duTTurb = Qturb/(riverDischarge*15*60 * waterDensity *Cp);
        duTdiff = Qres/(riverDischarge*15*60 * waterDensity *Cp);
        duT = duTSurface + duTInflow;
        dlT = dlTSurface + duTTurb+duTdiff;
        if any(isnan([duT, duTSurface, duTInflow, dlTSurface, duTTurb,duTdiff]), 'all')
            warning('NaN detected at exhange functions');
            keyboard
        end
   end
    reT = lT + duT; % new res temp
    riT = uT + dlT; % new river temp
    out = [reT,riT,newResV,newDepth,duTSurface,duTInflow,duTTurb,duTPump,duTdiff,duT,dlT];


end


%% ----------------
% 4. Background Functions
%% ----------------
% note, considers 15 minute intervals between
function out = surfaceHeatTransfer(cloudiness,Tair,Ts,Wz,Cp,surfaceArea,volume,rH,dt,z,rain,windDirection,riverSpeed,waterDensity) % ~ = solar rad
   % heatExchange = solarRad + surfaceOutput(Tair,Ts,Wz,rH,0.5);
    long = -121.190;
    lat = 45.608;
    TZ = -8;  
    Jday = day(dt);
    HOUR = hour(dt);
    monthS = month(dt);
    yearS = year(dt);
    beta = deg2rad(windDirection);
    if Wz == 0
        WzC = riverSpeed;
    else
         WzC = Wz - cos(beta)* riverSpeed;
    end
    heatExchange = surfaceOutput(Tair, Ts, WzC, rH,cloudiness,long,lat,z,Jday,HOUR,yearS,monthS,TZ);
    rainExchange = surfaceArea*rain * waterDensity * Cp * (Tair - Ts) * (1/3600) * (1/1000) * 60 * 15;

    Q = (heatExchange)*surfaceArea*60*15;
    if volume <= 0
      error('volume <= 0 in surfaceHeatTransfer');
    end
    out = (Q+rainExchange)/(volume * waterDensity *Cp);
end






function out = resDepthCalc(flowRate,depth,resMaxRadius,resMaxDepth) % changes depth depending on flow rate to deter
    % L = resLength;
    % r = resMaxRadius;
    % h = depth;
    %Vder = L*2*sqrt(h*(2*r -h));
    Vder = pi * (resMaxRadius^2)/(resMaxDepth^2) * depth * (2*resMaxDepth - depth);
    
    if Vder == 0
        out = depth; % no change or handle appropriately
     else
        out = depth - (flowRate)/Vder;
    end
    % out = depth - (flowRate)/Vder;
    
end
% function out = resRadCalc(depth,rMR,rMD)
%     out = rMR*sqrt(1 - ((rMD - depth)^2 / rMD^2)); % for whatever reason resMaxRadius is not defined??
% 
% end
function out = resAreaCalc(h,r,L)
    out = L*2*sqrt(h*(2*r-h));
end


function out = powerOutputSimpleSchedule(hourTime)
    out = 500*cos((pi/12) * hourTime + 14.5);
end
function out = rivDiaCalc(depth,crossArea)

    out = 2*crossArea/(pi*depth);
end

%% ----------------
% 5. Plotting and post processing
%% ----------------
hours = 1:totalSteps;
upperDiff = (monitorUpperTemp - resT);
lowerDiff = (monitorLowerTemp - riverT);
disp("var test")
disp(mean(upperDiff))
disp(mean(lowerDiff))

% Compute coefficient of determination (R^2) between monitored and modeled temps
% for upper (monitorUpperTemp vs resT) and lower (monitorLowerTemp vs riverT).
% Ensure vectors are same length and ignore NaNs.
mu = @(x) mean(x,'omitnan');

u_obs = monitorUpperTemp(:);
u_pred = resT(:);
l_obs = monitorLowerTemp(:);
l_pred = riverT(:);

% Align lengths to totalSteps if needed
n = totalSteps;
u_obs = u_obs(1:min(end,n));
u_pred = u_pred(1:min(end,n));
l_obs = l_obs(1:min(end,n));
l_pred = l_pred(1:min(end,n));

% Remove pairs with NaNs
validU = ~isnan(u_obs) & ~isnan(u_pred);
validL = ~isnan(l_obs) & ~isnan(l_pred);

if any(validU)
    ss_res_u = sum((u_obs(validU) - u_pred(validU)).^2);
    ss_tot_u = sum((u_obs(validU) - mu(u_obs(validU))).^2);
    R2_upper = 1 - ss_res_u/ss_tot_u;
else
    R2_upper = NaN;
end

if any(validL)
    ss_res_l = sum((l_obs(validL) - l_pred(validL)).^2);
    ss_tot_l = sum((l_obs(validL) - mu(l_obs(validL))).^2);
    R2_lower = 1 - ss_res_l/ss_tot_l;
else
    R2_lower = NaN;
end

% Display results in console
fprintf('R^2 (upper: monitor vs resT) = %.4f\n', R2_upper);
fprintf('R^2 (lower: monitor vs riverT) = %.4f\n', R2_lower);
% 
% 
% % Detailed statistical analysis between monitored and modeled temperatures
% % for upper (monitorUpperTemp vs resT) and lower (monitorLowerTemp vs riverT)
% 
% % Prepare vectors (column vectors) and align to totalSteps
% u_obs_full = monitorUpperTemp(:);
% u_pred_full = resT(:);
% l_obs_full = monitorLowerTemp(:);
% l_pred_full = riverT(:);
% 
% n = totalSteps;
% u_obs_full = u_obs_full(1:min(end,n));
% u_pred_full = u_pred_full(1:min(end,n));
% l_obs_full = l_obs_full(1:min(end,n));
% l_pred_full = l_pred_full(1:min(end,n));
% 
% % Remove NaN pairs
% validU = ~isnan(u_obs_full) & ~isnan(u_pred_full);
% validL = ~isnan(l_obs_full) & ~isnan(l_pred_full);
% 
% % Helper to compute stats
% computeStats = @(obs,pred) struct( ...
%     'N', sum(~isnan(obs) & ~isnan(pred)), ...
%     'mean_obs', mean(obs,'omitnan'), ...
%     'mean_pred', mean(pred,'omitnan'), ...
%     'bias', mean(pred-obs,'omitnan'), ...              % mean error
%     'MAE', mean(abs(pred-obs),'omitnan'), ...          % mean absolute error
%     'RMSE', sqrt(mean((pred-obs).^2,'omitnan')), ...  % root mean squared error
%     'R2', 1 - sum((obs-pred).^2,'omitnan')/sum((obs-mean(obs,'omitnan')).^2,'omitnan'), ...
%     'pearson_r', corr(obs,pred,'rows','complete'), ...
%     'spearman_rho', corr(obs,pred,'Type','Spearman','Rows','complete') ...
%     );
% 
% if any(validU)
%     statsU = computeStats(u_obs_full(validU), u_pred_full(validU));
% else
%     statsU = [];
% end
% 
% if any(validL)
%     statsL = computeStats(l_obs_full(validL), l_pred_full(validL));
% else
%     statsL = [];
% end
% 
% % Additional diagnostics: linear regression fit and Bland-Altman
% regressionFit = @(obs,pred) struct( ...
%     'coeff', polyfit(obs,pred,1), ... % fit pred = a*obs + b
%     'residuals', pred - polyval(polyfit(obs,pred,1),obs) ...
%     );
% 
% blandAltman = @(obs,pred) struct( ...
%     'mean_diff', mean(pred-obs,'omitnan'), ...
%     'sd_diff', std(pred-obs,'omitnan'), ...
%     'upper_LOA', mean(pred-obs,'omitnan') + 1.96*std(pred-obs,'omitnan'), ...
%     'lower_LOA', mean(pred-obs,'omitnan') - 1.96*std(pred-obs,'omitnan') ...
%     );
% 
% if any(validU)
%     regU = regressionFit(u_obs_full(validU), u_pred_full(validU));
%     baU = blandAltman(u_obs_full(validU), u_pred_full(validU));
% else
%     regU = [];
%     baU = [];
% end
% 
% if any(validL)
%     regL = regressionFit(l_obs_full(validL), l_pred_full(validL));
%     baL = blandAltman(l_obs_full(validL), l_pred_full(validL));
% else
%     regL = [];
%     baL = [];
% end
% 
% % Display results to console
% fprintf('\nDetailed statistical analysis: Upper (monitorUpperTemp vs resT)\n');
% if ~isempty(statsU)
%     fprintf('N = %d\n', statsU.N);
%     fprintf('Mean observed = %.3f, Mean predicted = %.3f\n', statsU.mean_obs, statsU.mean_pred);
%     fprintf('Bias (pred - obs) = %.3f\n', statsU.bias);
%     fprintf('MAE = %.3f, RMSE = %.3f\n', statsU.MAE, statsU.RMSE);
%     fprintf('R^2 = %.4f, Pearson r = %.4f, Spearman rho = %.4f\n', statsU.R2, statsU.pearson_r, statsU.spearman_rho);
%     fprintf('Linear fit (pred = a*obs + b): a = %.4f, b = %.4f\n', regU.coeff(1), regU.coeff(2));
%     fprintf('Bland-Altman: mean diff = %.4f, SD diff = %.4f, LOA = [%.4f, %.4f]\n', baU.mean_diff, baU.sd_diff, baU.lower_LOA, baU.upper_LOA);
% else
%     fprintf('No valid paired data for upper comparison.\n');
% end
% 
% fprintf('\nDetailed statistical analysis: Lower (monitorLowerTemp vs riverT)\n');
% if ~isempty(statsL)
%     fprintf('N = %d\n', statsL.N);
%     fprintf('Mean observed = %.3f, Mean predicted = %.3f\n', statsL.mean_obs, statsL.mean_pred);
%     fprintf('Bias (pred - obs) = %.3f\n', statsL.bias);
%     fprintf('MAE = %.3f, RMSE = %.3f\n', statsL.MAE, statsL.RMSE);
%     fprintf('R^2 = %.4f, Pearson r = %.4f, Spearman rho = %.4f\n', statsL.R2, statsL.pearson_r, statsL.spearman_rho);
%     fprintf('Linear fit (pred = a*obs + b): a = %.4f, b = %.4f\n', regL.coeff(1), regL.coeff(2));
%     fprintf('Bland-Altman: mean diff = %.4f, SD diff = %.4f, LOA = [%.4f, %.4f]\n', baL.mean_diff, baL.sd_diff, baL.lower_LOA, baL.upper_LOA);
% else
%     fprintf('No valid paired data for lower comparison.\n');
% end

% Ensure variables exist and are row vectors of length 24
%if ~exist('resT','var'), resT = nan(1,totalSteps); end
%if ~exist('resTControl','var'), resTControl = nan(1,totalSteps); end
%if ~exist('riverT','var'), riverT = nan(1,totalSteps); end
%if ~exist('riverTControl','var'), riverTControl = nan(1,totalSteps); end
%if ~exist('downstreamTemp','var'), monitorLowerTemp = nan(1,totalSteps); end
%if ~exist('resD','var'), resD = nan(1,totalSteps); end
%if ~exist('monitorUpperTemp','var'), monitorUpperTemp = nan(1,totalSteps); end
toRow = @(v) reshape(v(1:min(end,totalSteps)),1,[]);
padTo24 = @(v) (numel(v)<totalSteps) * [v, repmat(v(end),1,totalSteps-numel(v))] + (numel(v)>=totalSteps) * v(1:totalSteps);

resT = padTo24(toRow(resT));
resTControl = padTo24(toRow(resTControl));
riverT = padTo24(toRow(riverT));
riverTControl = padTo24(toRow(riverTControl));
downstreamTemp = padTo24(toRow(monitorLowerTemp));
resD = padTo24(toRow(resD));
upstreamTemp = padTo24(toRow(monitorUpperTemp));
% Create figure with desired layout
figure('Units','normalized','Position',[0.1 0.1 0.7 0.6]);

% Top-left: resT and resTControl
subplot(2,2,1);
plot(hours,resT,'-','LineWidth',1.5); hold on;
plot(hours,upstreamTemp,'-','LineWidth',1.5);
hold off;
xlabel('Time step');
ylabel('Reservoir Temp (°C)');
title('Reservoir Temperature vs Hour');
legend('resT','upperTemp','Location','best');
xlim([1 totalSteps]);
grid on;

% Bottom-left: riverT, riverTControl, rivControlTemp
subplot(2,2,3);
plot(hours,riverT,'-s','LineWidth',1.5); hold on;
plot(hours,downstreamTemp,'-.','LineWidth',1.5);
hold off;
xlabel('Time step');
ylabel('Temperature (°C)');
legend('riverT','downstreamTemp','Location','best');
title('River Temperatures vs Hour');
xlim([1 totalSteps]);
grid on;

% Right column (merged): reservoir depth
subplot(2,2,[2 4]);
plot(hours,resD,'-^','LineWidth',1.5,'Color',[0.85 0.33 0.1]);
xlabel('Time step');
ylabel('Reservoir Depth (m)');
title('Reservoir Depth vs Hour');
xlim([1 totalSteps]);
grid on;


% Plot surfdat, indat, turbdat, and pumpdat vs hours on a new figure
figure('Units','normalized','Position',[0.15 0.15 0.6 0.5]);
% Ensure vectors exist and are row vectors of length totalSteps
padRow = @(v) padTo24(toRow(v));
surfdat = padRow(surfdat);
indat = padRow(indat);
turbdat = padRow(turbdat);
pumpdat = padRow(pumpdat);
diffdat = padRow(diffdat);
updat = padRow(updat);
downdat = padRow(downdat);
plot(hours, surfdat, '-','LineWidth',1.5); hold on;
plot(hours, indat,  '-','LineWidth',1.5);
plot(hours, turbdat, '-.','LineWidth',1.5);
plot(hours, pumpdat, '-','LineWidth',1.5);
plot(hours, diffdat, '-','LineWidth',1.5);
plot(hours, updat, '-','LineWidth',1.5);
plot(hours, downdat, '-','LineWidth',1.5);


hold off;
xlabel('Time step');
ylabel('Value');
title('Total, Surface, Inflow, Turbine, Diffusion, and Pump Data vs Hour');
legend('surfdat','indat','turbdat','pumpdat', 'diffdat','updat', 'downdat','Location','best');
xlim([1 totalSteps]);
grid on;

surfUpperPercentage = mean(surfdat)/ mean(updat);
surfLowerPercentage = mean(surfdat)/ mean(downdat);
pumpMeanPercentage = mean(pumpdat)/mean(updat);
turbMeanPercetnage = mean(turbdat)/mean(downdat);
inPercentage = mean(indat)/mean(updat);
diffPercentage = mean(diffdat)/mean(updat);


disp(["uppper",surfUpperPercentage,pumpMeanPercentage,inPercentage])
disp(["lower",surfLowerPercentage,turbMeanPercetnage,diffPercentage])