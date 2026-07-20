%% =========================================================
% CYCLIC PHS MODEL (CONTROL VOLUME + TEMPERATURE)
% TURBINE + PUMP WITH SCHEDULING –  with efficiency heat source
% SURFACE HEAT TRANSFER
%
% =========================================================
clear; clc;
% Create a simple GUI with a Start button

%{
Todo list.
1.  Seperate elevation and depth for stuff. Done 
2. Establish one storage - elevation - area relationship??? done and or not
possible?
3. Add mass balance residual and diagnose storage drift ??  switch to
cylcindrical model
4. River reach, doesn't reach not that detailed lol
5. correct vvapor pressure formulation, yeahhhh i gotta do that
6. correct date/time solar calculations, huh
7. theres negative turbine flow?




%}






%% -------------------------
% INPUTS
%% -------------------------
thirdVol = false; % pumped resivour 
csvDat = 'Dalles2016-2025FilteredData_table.csv';
startTime = datetime('1/1/2020 0:00', Format  = 'MM-dd-uuuu HH:mm');
endTime = datetime(' 12/30/2025 23:45', Format  = 'MM-dd-uuuu HH:mm');




riverDir = 319.59; %[riverDirection]



Tf = readtable(csvDat); % filtered data
timeVar = Tf{:,1};
Tair =  Tf{:,2}; %[m^3/s]
upstreamTemp = Tf{:,3};%[C]
downstreamTemp = Tf{:,4}; %[C]
inflow = Tf{:,5}; %[m^3/s]
outflow = Tf{:,6}; %[m^3/s]
discharge = Tf{:,7}; %[m^3/s]
downstreamWaterVelocity = Tf{:,8}; %[m/s]
gaugeHeight = Tf{:,9}; %[ft]
wZ = Tf{:,10}; %[m/s]
rH = Tf{:,11}; %[%]
lowCloud = Tf{:,12}; 
highCloud = Tf{:,13};  
damElevation =  Tf{:,14}; %[m]
damStorage = Tf{:,15}; %[acre*ft]
rain = Tf{:,16}; %{mm]
windDirection = Tf{:,17}; % [angle from true north]
spillWay = Tf{:,18};
summary(damElevation)

disp("all data has loaded")






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



%%% DAM PARAMETERS

dam = resivourClass;
dam.length = 12000;
dam.resMaxRadius = 12000000;
dam.resMaxDepth = (182.3 - 55)/3.281;
dam.Cp = Cp;
dam.density = waterDensity;
dam.inEff = 1; % efficiency of pump
dam.outEff = .9; % efficiency of turbine
dam.rainCheck = false;
dam.elevation = 55/3.81; % note elevation is at the BOTTOM OF DAM
dam.head = -40; % if the base elevation of the dam is the same as the river as stated in the model, then the head is zero
dam = dam.fullVolCalc();


%%% RIVER PARAMETERS
river = riverClass;
river.Cp = Cp;
river.density = waterDensity;
river.elevation = 55/ 3.281; % elevation from BOTTOM of river
river.rainCheck = false;


%%% RESIVOUR PARAMETERS

res = resivourClass;
res.resMaxRadius = 5000;
res.resMaxDepth = 50;
res.Cp = Cp;
res.density = waterDensity;
res.inEff = 0.85;
res.outEff = 0.9;
res.rainCheck = true;
res.spill = 0; % adjusted later in live flow
res.elevation = dam.elevation + 25;







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
damEl = ones(1,totalSteps);

contMonitor = ones(1,totalSteps);
contTrueMonitor = ones(1,totalSteps);
pumpTypeMonitor = ones(1,totalSteps);

resMonitor = ones(1,totalSteps);
resDepthMonitor = ones(1,totalSteps);


%%------------------
% 3. Thermal Processes
%%------------------
mode = -1;


for t = 1:totalSteps
    
    disp(["timeStamp: ", t])
    dt = startTime + minutes((t-1)*15);
    disp(dt)
    aP = find(timeVar == dt);
    if isempty(aP)
      error('No matching timestamp for %s', char(dt));
    end
    c1 = lowCloud(aP);
    c2 = highCloud(aP);
    cloudiness = [c1,c2]; 
   
    if t == 1
        resT(t) = upstreamTemp(aP);
        dam.temp = resT(t);
        river.temp = downstreamTemp(aP);
        riverT(t) = river.temp;
        monitorUpperTemp(t) = upstreamTemp(aP);
        monitorLowerTemp(t) = downstreamTemp(aP);
        resV(t) = damStorage(aP);
        dam.volume = resV(t);
        resD(t) = damElevation(aP);
        dam.depth = resD(t);
        damEl(t) = damElevation(aP);
        res.depth = 20;
        res.temp  = dam.temp;
        resMonitor(t) = res.temp;
        resDepthMonitor(t) = res.depth;
    else
        resT(t) = dam.temp;
        riverT(t) = river.temp;
        resD(t) = dam.depth;
        resV(t) = dam.volume;
        monitorUpperTemp(t) = upstreamTemp(aP);
        monitorLowerTemp(t) = downstreamTemp(aP);
        damEl(t) = damElevation(aP);
        resMonitor(t) = res.temp;
        resDepthMonitor(t) = res.depth;
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
            windDirection(aP),... % 11  
            spillWay(aP),...
            ];
    transientData = [
            riverT(t), ... %3
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
            dT = flowCondition( ...
                transientData,reqFlowRate, ...
                tableData,dt,riverDir,dam,river,res,thirdVol);
            pumpTypeMonitor(t) = dT(1);
            contMonitor(t) = dT(2);
            contTrueMonitor(t) = dT(3);
        end 
        if (any(isnan([resT(t), resV(t), resD (t), riverT(t), upstreamTemp(aP)]), 'all') || any(isinf([resT(t), resV(t), resD(t), riverT(t), upstreamTemp(aP)]), 'all'))
            warning('NaN detected at t=%d', t);
            disp(dt)
            keyboard      % inspect workspace interactively
        end
        if resT(t) >= 100 || riverT(t) >= 100
            disp('water is boiling')
            break


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





function out = flowCondition( ...
    tD,flowRate, ...
    t,dt,rivDirection,dam,river,res,thirdVol)
    
    %transient data
    lT = tD(1);
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
    spillWay = t(13);
    %update Parameters
    river.gaugeIn = gaugeRiv;
    river.velocity = riverV;
    river.flow = riverDischarge;

    if thirdVol == true
        powerReq = powerOutputSimpleSchedule(hour(dt));
        %
        %monitoring variables
        pumpType = 0; % 0 if nothing, 1 if pumping, -1 if turbining, 0.5 of either if forced
        if powerReq >= 0
            res.inflow = 0;
            res.outflow = -1*powerReq/res.outCoff;
            pumpType = -1;
            disp("turbining")
        elseif powerReq <= 0
            res.inflow = powerReq/res.inCoff;
            res.outflow = 0;
            pumpType = 1;
            disp("pumping")
        else
            res.inflow = 0;
            res.outflow = 0;
            pumpType = 0;
            disp("no flow");
        end
        if res.depth >= 25
            res.inflow = 0;
            disp("nvm turbining")
            res.spill = res.surfaceArea/10 * (res.depth - 24);
            res.outflow = -res.spill + res.outflow;
            pumpType = -.5;
        elseif res.depth <= 5
            res.outflow = 0;
            disp("nvm filling")
            res.inflow = 1000;
            res.spill = 0;
            pumpType = .5;
        else
            res.spill = 0;
        end
        disp(["depth",res.depth])
        dam.inflow = resInflow - res.outflow;
        % disp(["inflow check",resInflow,dam.inflow])
        dam.outflow = flowRate - res.inflow;
        % disp(["outflow check",flowRate,dam.outflow]);
        dam.spill = spillWay;
        dam.rain = rain;    
        res.rain = rain; % trying to see if it fixes it
        res = res.updateWaterBalance();
        disp("check for continuity")
        damStor = (dam.inflow + dam.outflow - res.surfaceArea * res.rain); % checks storage between both dams, rain removed to mimic real
        damStorTrue = resInflow + flowRate; % the real amount generated.
        qRes = surfaceHeatTransfer(cloudiness,Tair,res.temp,Wz,res.Cp,res.surfaceArea,rH,dt, 1000,res.rain,0,0,res.density);
    else
        dam.inflow = resInflow;
        dam.outflow = flowRate;
        dam.spill = spillWay;
        dam.rain = rain;
        pumpType = -100;
        damStor = -1;
        damStorTrue = -1;
    end
    % area stuff
    dam = dam.updateWaterBalance(); 
    river = river.updateWaterBalance();
    
    %Surface Heat Transfer
    qSurfaceDam = surfaceHeatTransfer(cloudiness,Tair,dam.temp,Wz,dam.Cp,dam.surfaceArea,rH,dt, dam.elevation+dam.depth,dam.rain,0,0,dam.density);
   % qSurfaceRiver = surfaceHeatTransfer(cloudiness,Tair,river.temp,Wz,river.Cp,river.surfaceArea,rH,dt,river.elevation + river.depth,rain,windDirection - rivDirection,river.velocity,river.density); 

    qInflow = (upperTemp-dam.temp)*dam.Cp*dam.inflow*dam.density*dam.tS;
    % qInflow = 0;
    if thirdVol == true
        dam.outflow = -res.inflow;
        resInflowq = dam.outHeatTransfer(res.temp,false);
        res = res.inHeatTransfer(resInflowq + qRes);
        disp("res temp")
        disp(res.temp)
    
        dam.outflow = flowRate - res.inflow;
        resOutflowq = res.outHeatTransfer(dam.temp,true);
    %resOutflowq = 0;
        qDam = outHeatTransfer(dam,lT,true);
        dam = dam.inHeatTransfer(qSurfaceDam + qInflow + resOutflowq);
    else
        qDam = outHeatTransfer(dam,lT,true);
        dam = dam.inHeatTransfer(qSurfaceDam + qInflow);
    end
    river = river.inHeatTransfer(qDam);
    out = [pumpType,damStor,damStorTrue];
  

end


%% ----------------
% 4. Background Functions
%% ----------------

% note, considers 15 minute intervals between
function out = surfaceHeatTransfer(cloudiness,Tair,Ts,Wz,Cp,surfaceArea,rH,dt,z,rain,windDirection,riverSpeed,waterDensity) % ~ = solar rad
   % heatExchange = solarRad + surfaceOutput(Tair,Ts,Wz,rH,0.5);
   % https://www.weather.gov/media/tsa/pdf/WBGTpaper2.pdf 
    long = -121.190;
    lat = 45.608;
    Jday = day(dt);
    HOUR = hour(dt) + minute(dt)/60;
    monthS = month(dt);
    yearS = year(dt);
    beta = deg2rad(windDirection);
    if Wz == 0
        WzC = riverSpeed;
    else
         WzC = Wz - cos(beta)* riverSpeed;
    end
    heatExchange = surfaceOutput(Tair, Ts, WzC, rH,cloudiness,long,lat,z,Jday,HOUR,yearS,monthS,rain,Cp,waterDensity);

    Q = (heatExchange)*surfaceArea*60*15;
    out = Q; % output in WATTS
end


function out = powerOutputSimpleSchedule(hourTime) %output JOULES
    out = 74*1000*10*cos((pi/12) * hourTime + 14.5);
end
function out = rivDiaCalc(depth,crossArea)

    out = 2*crossArea/(pi*depth);
end


function out = evaporation()
    out = N * u * (es - ea) % coeff * wind in km/day * mb * m, out = cm/day
    % https://www.nrcs.usda.gov/sites/default/files/2023-06/8a_MT_estimation_evaporation_ponds-impound.pdf
    % 
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



offsetTime = posixtime(startTime);


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
subplot(3,2,1);
plot(hours,resT,'-','LineWidth',1.5); hold on;
plot(hours,upstreamTemp,'-','LineWidth',1.5);
hold off;
xlabel('Time step');
ylabel('Dam Temp (°C)');
title('Dam Temperature vs Timestep');
legend('resT','upperTemp','Location','best');
xlim([1 totalSteps]);
grid on;

% Bottom-left: riverT, riverTControl, rivControlTemp
subplot(3,2,3);
plot(hours,riverT,'-s','LineWidth',1.5); hold on;
plot(hours,downstreamTemp,'-.','LineWidth',1.5);
hold off;
xlabel('Time step');
ylabel('Temperature (°C)');
legend('riverT','downstreamTemp','Location','best');
title('River Temperatures vs Timestep');
xlim([1 totalSteps]);
grid on;

subplot(3,2,5);
plot(hours,resMonitor,'-s','LineWidth',1.5); hold on;
hold off;
xlabel('Time step');
ylabel('Temperature (°C)');
legend('resMonitor','Location','best');
title('Resivour Temperatures vs Timestep');
xlim([1 totalSteps]);
grid on;

% Right column (merged): reservoir depth
subplot(3,2,[2,4]);
plot(hours,resD,'-^','LineWidth',1.5,'Color',[0.85 0.33 0.1]);
hold on;
if exist('damEl','var')
    damElRow = padTo24(toRow(damEl));
    plot(hours, damElRow, '-','LineWidth',1.5,'Color',[0 0.45 0.74]);
    legendEntries = legend;
    if isempty(legendEntries)
        legend('resD','damEl','Location','best');
    else
        % update existing legend to include damEl
        existing = legendEntries.String;
        legend([existing, {'damEl'}],'Location','best');
    end
end
hold off;
xlabel('Time step');
ylabel('Dam Depth (m)');
title('Dam Depth vs Timestep');
xlim([1 totalSteps]);
grid on;

subplot(3,2,6);
plot(hours,resDepthMonitor,'-s','LineWidth',1.5); hold on;
hold off;
xlabel('Time step');
ylabel('depth (m)');
legend('Resivour Depth (m)','Location','best');
title('Resivour Temperatures vs Timestep');
xlim([1 totalSteps]);
grid on;

% Additional figure: pumpTypeMonitor (right), contMonitor vs contTrueMonitor (top-left),
% and percent difference (bottom-left)

% Prepare vectors as row, padded to totalSteps
if thirdVol == true

% Plot contMonitor and contTrueMonitor vs time in a new figure
figure('Units','normalized','Position',[0.2 0.2 0.5 0.4]);
plot(hours, contMonitor, '-','LineWidth',1.5); hold on;
plot(hours, contTrueMonitor, '--','LineWidth',1.5);
hold off;
xlabel('Time step');
ylabel('Controller Value');
title('contMonitor vs contTrueMonitor');
legend('contMonitor','contTrueMonitor','Location','best');
xlim([1 totalSteps]);
grid on;
iCheck = ones(1,totalSteps);
for a = 1:totalSteps
    iCheck(a) = (((contMonitor(a) - contTrueMonitor(a)) / contTrueMonitor(a)) * 100);
end
figure('Units','normalized','Position',[0.2 0.2 0.5 0.4]);
plot(hours, iCheck, '-','LineWidth',1.5); hold on;
hold off;
xlabel('Time step');
ylabel('Controller Value');
title('diff check');
legend('contMonitor','contTrueMonitor','Location','best');
xlim([1 totalSteps]);
grid on;

figure('Units','normalized','Position',[0.2 0.2 0.5 0.4]);
plot(hours, pumpTypeMonitor, '-','LineWidth',1.5); hold on;
hold off;
xlabel('Time step');
ylabel('Controller Value');
title('diff check');
legend('contMonitor','contTrueMonitor','Location','best');
xlim([1 totalSteps]);
grid on;
end
% % 
% % % Plot surfdat, indat, turbdat, and pumpdat vs hours on a new figure
% % figure('Units','normalized','Position',[0.15 0.15 0.6 0.5]);
% % % Ensure vectors exist and are row vectors of length totalSteps
% % padRow = @(v) padTo24(toRow(v));
% % surfdat = padRow(surfdat);
% % indat = padRow(indat);
% % turbdat = padRow(turbdat);
% % pumpdat = padRow(pumpdat);
% % diffdat = padRow(diffdat);
% % updat = padRow(updat);
% % downdat = padRow(downdat);
% % plot(hours, surfdat, '-','LineWidth',1.5); hold on;
% % plot(hours, indat,  '-','LineWidth',1.5);
% % plot(hours, turbdat, '-.','LineWidth',1.5);
% % plot(hours, pumpdat, '-','LineWidth',1.5);
% % plot(hours, diffdat, '-','LineWidth',1.5);
% % plot(hours, updat, '-','LineWidth',1.5);
% % plot(hours, downdat, '-.','LineWidth',1.5);
% % %disp(downdat)
% % 
% % hold off;
% % xlabel('Time step');
% % ylabel('Value');
% % title('Total, Surface, Inflow, Turbine, Diffusion, and Pump Data vs Timestep');
% % legend('surfdat','indat','turbdat','pumpdat', 'diffdat','updat', 'downdat','Location','best');
% % xlim([1 totalSteps]);
% % grid on;
% % 
% % surfUpperPercentage = mean(surfdat)/ mean(updat);
% % surfLowerPercentage = mean(surfdat)/ mean(downdat);
% % pumpMeanPercentage = mean(pumpdat)/mean(updat);
% % turbMeanPercetnage = mean(turbdat)/mean(downdat);
% % inPercentage = mean(indat)/mean(updat);
% % diffPercentage = mean(diffdat)/mean(updat);
% % 
% % 
% % disp(["uppper",surfUpperPercentage,pumpMeanPercentage,inPercentage])
% % disp(["lower",surfLowerPercentage,turbMeanPercetnage,diffPercentage])
% % % Prepare table and write CSV of time series variables
% % % Ensure all vectors are row vectors of length totalSteps
% % vars = {'resT','resV','surfdat','indat','turbdat','pumpdat','diffdat','updat','downdat'};
% % for k = 1:numel(vars)
% %     v = eval(vars{k});
% %     v = toRow(v); v = padTo24(v);
% %     eval([vars{k} ' = v;']);
% % end
% % 
% % timeSteps = (1:totalSteps).';
% % T = table(timeSteps, resT(:), resV(:), surfdat(:), indat(:), turbdat(:), ...
% %     pumpdat(:), diffdat(:), updat(:), downdat(:), ...
% %     'VariableNames', {'TimeStep','resT','resV','surfdat','indat','turbdat','pumpdat','diffdat','updat','downdat'});
% % 
% % writetable(T,'modelOutput.csv');

%% JUNK FROM TESTING





%% all of these are not being used anymore
spillwayCrest = 121; %{Ft]
maxStorage = 554900; %[Acre*ft] by top of flood control
maxStoragePreFlood = 310000; %[Acre*ft] bottom of flood control storage
damBed = 55/ 3.281; %[Ft]
damTop = 185; %[ft]
floodControlTop = 182.3; %[ft]
floodControlBottom = 160; %[ft]
resMaxRadius = 10000; %[m] Resivour Radius at Max depth    
resMaxDepth     =   (182.3 - 55)/3.281;%[m]        


resivourDir = 46.5; % [Deg]