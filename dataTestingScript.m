


csvDat = 'Dalles2016-2025FilteredData_table.csv';
% 
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
startTime = datetime('1/1/2020 0:00', Format  = 'MM-dd-uuuu HH:mm');
endTime = datetime(' 12/30/2020 23:45', Format  = 'MM-dd-uuuu HH:mm');
totalSteps = minutes(endTime - startTime)/15;

timeVars = ones(1,totalSteps);
transferVar = ones(1,totalSteps);

% disp(["timeSteps",totalSteps])
Cp    = 4186; 

% % % % Ensure damElevation and damStorage are column vectors
% % % damElevation = damElevation(:);
% % % damStorage = damStorage(:);
% % % % Find unique pairs of (elevation, storage)
% % % [uniqPairs, ia, ~] = unique([damElevation, damStorage], 'rows', 'stable');
% % % % If any duplicates, warn and keep only unique entries
% % % if numel(ia) < numel(damElevation)
% % %     warning('Found %d duplicate elevation-storage entries; keeping first occurrence of each unique pair.', ...
% % %         numel(damElevation)-numel(ia));
% % % end % graph dam elevation vs dam height. use multiple diffrent curve fitting methods on system, and then output all results onto the graph. output all fitting equations into console  
% % % % Replace with unique-only vectors for subsequent processing
% % % damElevation = uniqPairs(:,1);
% % % damStorage = uniqPairs(:,2);
% % % % Prepare data for plotting/fitting
% % % y = damElevation;
% % % x = damStorage;
% % % 
% % % % Plot raw data
% % % figure('Units','normalized','Position',[0.1 0.1 0.6 0.6]);
% % % scatter(x,y,40,'b','filled'); hold on;
% % % xlabel('Dam Elevation (m)');
% % % ylabel('Dam Storage (m^3)');
% % % title('Dam Storage vs Elevation with Curve Fits');
% % % grid on;
% % % 
% % % % Define fit types to try
% % % fitTypes = { ...
% % %     fittype('poly1'), 'Linear'; ...
% % %     fittype('poly2'), 'Quadratic'; ...
% % %     fittype('poly3'), 'Cubic'; ...
% % %     fittype('exp1'), 'Exponential (a*exp(b*x))'; ...
% % %     fittype('power1'), 'Power (a*x^b)'; ...
% % %     fittype('rat11'), 'Rational (1,1)'; ...
% % %     };
% % % 
% % % colors = lines(size(fitTypes,1));
% % % legendEntries = {'Data'};
% % % 
% % % % Fit over a fine x-grid for plotting
% % % xFine = linspace(min(x), max(x), 400)';
% % % 
% % % for k = 1:size(fitTypes,1)
% % %     ft = fitTypes{k,1};
% % %     label = fitTypes{k,2};
% % %     opts = fitoptions(ft);
% % %     % set robust option to reduce influence of outliers when available
% % %     try
% % %         opts.Robust = 'LAR';
% % %         fitobj = fit(x, y, ft, opts);
% % %     catch
% % %         % fallback without options
% % %         fitobj = fit(x, y, ft);
% % %     end
% % %     % Evaluate fit
% % %     yFit = feval(fitobj, xFine);
% % %     plot(xFine, yFit, 'Color', colors(k,:), 'LineWidth', 1.5);
% % %     legendEntries{end+1} = label;
% % %     % Print equation to console
% % %     coeffs = coeffvalues(fitobj);
% % %     coeffNames = coeffnames(fitobj);
% % %     eqStr = sprintf('%s fit: ', label);
% % %     for iC = 1:numel(coeffs)
% % %         eqStr = [eqStr, sprintf('%s = %.6g', coeffNames{iC}, coeffs(iC))];
% % %         if iC < numel(coeffs), eqStr = [eqStr, ', ']; end
% % %     end
% % %     % Also print the fit expression if available
% % %     try
% % %         expr = formula(fitobj);
% % %         eqStr = [eqStr, '   Expression: ', char(expr)];
% % %     end
% % %     fprintf('%s\n', eqStr);
% % % end
% % % 
% % % legend(legendEntries,'Location','best');
% % % hold off;
% % % 
% % % % Compute and display R-squared for each fit using original data
% % % yxMean = mean(y);
% % % for k = 1:size(fitTypes,1)
% % %     ft = fitTypes{k,1};
% % %     label = fitTypes{k,2};
% % %     % Recreate fit object same as above (robust if possible)
% % %     opts = fitoptions(ft);
% % %     try
% % %         opts.Robust = 'LAR';
% % %         fitobj = fit(x, y, ft, opts);
% % %     catch
% % %         fitobj = fit(x, y, ft);
% % %     end
% % %     % Predicted values at original x
% % %     yPred = feval(fitobj, x);
% % %     ssRes = sum((y - yPred).^2);
% % %     ssTot = sum((y - yxMean).^2);
% % %     if ssTot == 0
% % %         R2 = NaN;
% % %     else
% % %         R2 = 1 - ssRes/ssTot;
% % %     end
% % %     fprintf('R^2 for %s: %.6f\n', label, R2);
% % % end


%%%% dam storage testing 
% % % % damDer = ones(size(damStorage));
% % % % inOutDer = ones(size(damStorage));
% % % % diffMon = ones(size(damStorage));
% % % % for t = 1:size(damStorage,1)
% % % %     if t == 1
% % % %         damDer(t) = 0;
% % % %         inOutDer(t) = inflow(t) - discharge(t);
% % % %         diffMon(t) = damDer(t) - inOutDer(t);
% % % %     else
% % % %         damDer(t) = damStorage(t) - damStorage(t - 1);
% % % %         inOutDer(t) = inflow(t) - discharge(t);
% % % %         diffMon(t) = abs( damDer(t)) - abs(inOutDer(t));
% % % %     end
% % % % end
% % % % 
% % % % figure('Units','normalized','Position',[0.1 0.1 0.8 0.6]);
% % % % t = timeVar;
% % % % plot(t, damDer, '-b','LineWidth',1.2); 
% % % % hold on;
% % % % plot(t, diffMon, '-g','LineWidth',1.2);
% % % % plot(t, inOutDer, '-r','LineWidth',1.2);
% % % % hold off;
% % % % xlabel('Time');
% % % % legend('damDer','inOutDer','diffMon','Location','best');
% % % % grid on;



% % %  area testing 
% % % dam = resivourClass;
% % % dam.length = 12000;
% % % dam.resMaxRadius = 12000;
% % % dam.resMaxDepth = 39;
% % % dam.Cp = Cp;
% % % dam.density = 1000;
% % % dam.inEff = 1; % efficiency of pump
% % % dam.outEff = .9; % efficiency of turbine
% % % dam.rainCheck = false;
% % % dam.elevation = 55/3.81; % note elevation is at the BOTTOM OF DAM
% % % dam.head = -40; % if the base elevation of the dam is the same as the river as stated in the model, then the head is zero
% % % dam = dam.fullVolCalc();
% % % 
% % % disp(dam.fullVolume);
% % % dam.depth = dam.resMaxDepth;
% % % totalSteps = (dam.fullVolume/1000);
% % % totalSteps = floor(totalSteps);
% % % depthMonitor =  ones(1,totalSteps);
% % % volumeMonitor = ones(1,totalSteps);
% % % surfAreaMonitor = ones(1,totalSteps);
% % % 
% % % lastVol = 0;
% % % for d = 1:(totalSteps)
% % %     lastVol = dam.volume;
% % %     dam.volume = d*1000;
% % %     dam.inflow = dam.volume - lastVol;
% % %     disp(dam.inflow)
% % %     dam = dam.troughDepthCalc();
% % %     dam = dam.troughSurfCalc();
% % %     disp(dam.surfaceArea)
% % %     depthMonitor(d) = dam.depth;
% % %     volumeMonitor(d) = dam.volume;
% % %     surfAreaMonitor(d) = dam.surfaceArea;
% % %     disp([d,"/",totalSteps]);
% % % end
% % % 
% % % disp(max(surfAreaMonitor));
% % % 
% % % 
% % % figure('Units','normalized','Position',[0.1 0.1 0.8 0.6]);
% % % tiledlayout(1,2,'Padding','compact','TileSpacing','compact');
% % % 
% % % % Left: depth vs volume
% % % nexttile;
% % % plot(volumeMonitor,depthMonitor, '-o','LineWidth',1.2);
% % % xlabel('Volume (m)');
% % % ylabel('Depth (m^3)');
% % % title('Depth vs Volume');
% % % grid on;
% % % 
% % % % Right: depth vs surface area
% % % nexttile;
% % % plot(volumeMonitor, surfAreaMonitor, '-o','LineWidth',1.2);
% % % xlabel('Volume (m)');
% % % ylabel('Surface Area (m^2)');
% % % title('Depth vs Surface Area');
% % % grid on;
% % % 
% % % 
% % 









for t = 1:totalSteps
    dt = startTime + minutes((t-1)*15);
    disp(dt)
    aP = find(timeVar == dt);
    long = -121.190;
    lat = 45.608;
    TZ = -8;  
    Jday = day(dt);
    HOUR = hour(dt) + minute(dt)/60;
    monthS = month(dt);
    yearS = year(dt);
    transferVar(t) = surfaceOutput(Tair(aP), 20, wZ(aP), rH(aP), [lowCloud(aP),highCloud(aP)],long,lat,50,Jday,HOUR,yearS,monthS,rain(aP),Cp,999.97);
    timeVars(t) = t;
end

figure('Units','normalized','Position',[0.2 0.2 0.5 0.4]);
plot(timeVars, transferVar, '-','LineWidth',1.5); hold on;
hold off;
xlabel('Time step');
ylabel('Solar Radiation (W)');
title('Solar Radiation over week');
%legend('Solar Radiation (W)','Location','best');
xlim([1 totalSteps]);
grid on;


% vars = Tf{:,2:end};                % numeric matrix of all variables except timeVar
% varNames = Tf.Properties.VariableNames(2:end);
% 
% % Figure 1: scatter matrix of all variables
% figure('Name','Variable Scatter Matrix');
% % Use built-in plotmatrix for matrix of scatter plots
% [H,ax,BigAx] = plotmatrix(vars);
% % Label axes with variable names
% n = numel(varNames);
% for i=1:n
%     xlabel(ax(n,i), varNames{i}, 'Interpreter','none');
%     ylabel(ax(i,1), varNames{i}, 'Interpreter','none');
% end
% title(BigAx, 'Pairwise Scatter Matrix','Interpreter','none');
% 
% % Figure 2: Pearson correlation matrix
% R = corr(vars, 'Rows','complete', 'Type','Pearson');
% 
% figure('Name','Pearson Correlation Matrix');
% imagesc(R);
% colorbar;
% caxis([-1 1]);
% xticks(1:n); yticks(1:n);
% xticklabels(varNames); yticklabels(varNames);
% xtickangle(45);
% title('Pearson Correlation Matrix','Interpreter','none');
% % Overlay correlation values
% textStrings = num2str(R(:), '%0.2f');
% textStrings = strtrim(cellstr(textStrings));
% [xGrid,yGrid] = meshgrid(1:n,1:n);
% hStrings = text(xGrid(:), yGrid(:), textStrings(:), 'HorizontalAlignment','center');
% set(gca,'TickLength',[0 0]);