%% =========================================================
% CYCLIC PHS MODEL (CONTROL VOLUME + TEMPERATURE)
% TURBINE + PUMP LOOP  –  with efficiency heat sources
% =========================================================
clear; clc;

%% -----------------------------
% 1. DOMAIN (CV)
%% -----------------------------
N     = 50; % number of steps
L     = 1000; % length
dx    = L / N; % control volume size
x     = linspace(dx/2, L - dx/2, N); % steps between control volumes

%% -----------------------------
% 2. PARAMETERS
%% -----------------------------
B      = 20;        % channel width        [m]
H      = 10;        % channel depth        [m]
Acs    = B * H;     % cross-section area   [m^2]
Dx     = 5;         % thermal diffusivity  [m^2/s]
rho    = 1000;      % water density        [kg/m^3]
Cp     = 4186;      % specific heat        [J/(kg·K)]
Tin    = 15;        % initial temperature  [°C]
cycles = 5;

% --- Efficiency & head parameters ---
eta_turb = 0.90;    % turbine efficiency   [-]
eta_pump = 0.85;    % pump efficiency      [-]
g        = 9.81;    % gravity              [m/s^2]
H_head   = 100;     % hydraulic head       [m]

Q_turb = 50;        % turbine flow rate    [m^3/s]
Q_pump = 50;        % pump flow rate       [m^3/s]

Vol_CV = Acs * dx;  % volume of one CV     [m^3]

% --- Heat source terms [W/m^3] ---
% Turbine: fraction (1-eta) of hydraulic power dissipated as heat
Sphi_turb = (1 - eta_turb) * rho * g * H_head * Q_turb / (N * Vol_CV);

% Pump: extra energy above ideal (1/eta - 1) dissipated as heat
Sphi_pump = (1/eta_pump - 1) * rho * g * H_head * Q_pump / (N * Vol_CV);

fprintf('Turbine heat source : %.4f W/m^3\n', Sphi_turb);
fprintf('Pump    heat source : %.4f W/m^3\n', Sphi_pump);

%% -----------------------------
% 3. INITIAL CONDITIONS
%% -----------------------------
T_up  = Tin * ones(N, 1);   % upper reservoir temperature profile [°C]
T_low = Tin * ones(N, 1);   % lower reservoir temperature profile [°C]

%% -----------------------------
% 4. CYCLE LOOP
%% -----------------------------
% Storage for diagnostics
T_up_mean  = zeros(cycles, 1);
T_low_mean = zeros(cycles, 1);

figure('Name','PHS Cyclic Thermal Evolution','NumberTitle','off');
colors_up  = winter(cycles);
colors_low = autumn(cycles);

for c = 1:cycles
    fprintf('\n===== CYCLE %d =====\n', c);

    %% =====================================================
    % TURBINE MODE: water flows UPPER -> LOWER
    %   Inlet temperature = well-mixed mean of upper reservoir
    %   Heat source = turbine inefficiency losses
    %% =====================================================
    T_inlet_turb = mean(T_up);      % well-mixed reservoir inlet [°C]

    T = runCVTemperature(N, dx, B, H, Dx, rho, Cp, ...
                         Sphi_turb, T_inlet_turb, Q_turb);

    T_low = T;   % discharged water becomes lower reservoir profile
    fprintf('  Turbine | inlet = %.4f°C | T_low: %.4f – %.4f°C\n', ...
            T_inlet_turb, min(T_low), max(T_low));

    %% =====================================================
    % PUMP MODE: water flows LOWER -> UPPER
    %   Inlet temperature = well-mixed mean of lower reservoir
    %   Heat source = pump inefficiency losses
    %% =====================================================
    T_inlet_pump = mean(T_low);     % well-mixed reservoir inlet [°C]

    T = runCVTemperature(N, dx, B, H, Dx, rho, Cp, ...
                         Sphi_pump, T_inlet_pump, Q_pump);

    T_up = T;    % pumped water becomes upper reservoir profile
    fprintf('  Pump    | inlet = %.4f°C | T_up:  %.4f – %.4f°C\n', ...
            T_inlet_pump, min(T_up), max(T_up));

    % Store cycle-mean temperatures for trend plot
    T_up_mean(c)  = mean(T_up);
    T_low_mean(c) = mean(T_low);

    %% --- Profile plots (left panels) ---
    subplot(2, 2, 1); hold on;
    plot(x, T_up,  'Color', colors_up(c,:),  'LineWidth', 1.5, ...
         'DisplayName', sprintf('Cycle %d', c));

    subplot(2, 2, 3); hold on;
    plot(x, T_low, 'Color', colors_low(c,:), 'LineWidth', 1.5, ...
         'DisplayName', sprintf('Cycle %d', c));
end

%% =========================================================
% PLOTS
%% =========================================================

% --- Upper reservoir profile ---
subplot(2, 2, 1);
grid on;
xlabel('x [m]'); ylabel('Temperature [°C]');
title('Upper Reservoir – T profile (end of pump phase)');
legend('show', 'Location', 'best');

% --- Lower reservoir profile ---
subplot(2, 2, 3);
grid on;
xlabel('x [m]'); ylabel('Temperature [°C]');
title('Lower Reservoir – T profile (end of turbine phase)');
legend('show', 'Location', 'best');

% --- Cycle-mean temperature trend ---
subplot(2, 2, [2 4]);
plot(1:cycles, T_up_mean,  'r-o', 'LineWidth', 2, ...
     'MarkerFaceColor','r', 'DisplayName','Upper reservoir (mean)');
hold on;
plot(1:cycles, T_low_mean, 'b-s', 'LineWidth', 2, ...
     'MarkerFaceColor','b', 'DisplayName','Lower reservoir (mean)');
grid on;
xlabel('Cycle number');
ylabel('Mean Temperature [°C]');
title('Cycle-to-cycle thermal evolution (mean T)');
legend('show', 'Location', 'northwest');
xticks(1:cycles);

sgtitle('PHS Cyclic Thermal Model – Efficiency Heat Dissipation');

%% =========================================================
% FUNCTION: 1-D Steady CV Temperature Solver
%
%   Govening equation (steady advection-diffusion with source):
%       d/dx(rho*U*T) = d/dx(rho*Dx*dT/dx) + Sphi/Cp
%
%   Discretisation: first-order UPWIND for advection,
%                   central difference for diffusion.
%
%   Boundary conditions:
%     Inlet  (i=1): Dirichlet  – T = T_inlet  (prescribed)
%     Outlet (i=N): Neumann    – dT/dx = 0    (zero gradient)
%
%   Inputs:
%     N        – number of CVs                      [-]
%     dx       – CV width                           [m]
%     B        – channel width                      [m]
%     H        – channel depth                      [m]
%     Dx       – thermal diffusivity                [m^2/s]
%     rho      – density                            [kg/m^3]
%     Cp       – specific heat                      [J/(kg·K)]
%     Sphi     – volumetric heat source             [W/m^3]
%     T_inlet  – scalar inlet temperature           [°C]
%     Q_in     – volumetric flow rate (positive L->R) [m^3/s]
%
%   Output:
%     T        – temperature profile                [N×1, °C]
% =========================================================
function T = runCVTemperature(N, dx, B, H, Dx, rho, Cp, Sphi, T_inlet, Q_in)

    Acs = B * H;
    U   = Q_in / Acs;           % bulk velocity [m/s]

    % Convective flux [kg/s] and diffusive conductance [kg·m/s / m] you
    % just said mass flow rate twice?
    F = rho * U * Acs;
    D = rho * Dx * Acs / dx;

    % Upwind neighbour coefficients — valid for any sign of F
    aW = D + max( F, 0);        % west (upwind when F>0)
    aE = D + max(-F, 0);        % east (upwind when F<0)

    % Source term per CV [W/m = W/m^3 * m^2 * m]
    S_CV = Sphi * Acs * dx / Cp;   % [°C·kg/s] consistent units

    A = zeros(N, N);
    b = zeros(N, 1);

    %% Interior CVs (i = 2 … N-1)
    for i = 2:N-1
        A(i, i-1) = -aW;
        A(i, i)   =  aW + aE;
        A(i, i+1) = -aE;
        b(i)      =  S_CV;
    end

    %% Inlet BC (i = 1) — Dirichlet: T_inlet known at west face
    %   Flux balance: (aW+aE)*T(1) - aE*T(2) = aW*T_inlet + S_CV
    A(1, 1) =  aW + aE;
    A(1, 2) = -aE;
    b(1)    =  aW * T_inlet + S_CV;

    %% Outlet BC (i = N) — Neumann: dT/dx = 0  =>  T(N) = T(N-1)
    A(N, N)   =  1;
    A(N, N-1) = -1;
    b(N)      =  0;

    T = A \ b;
end
