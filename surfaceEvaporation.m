

function output = surfaceEvaporation(eS,eA,wZ,surfArea)
    
    A = surfArea / (1000^2);
    N = 0.000169*(A^-0.05);
    u = wZ *  86.4;
    E = N*u*(eS - eA); % cm/day = N * km/day * milibars 
    % output is needed in m^3 / s 
    % cm/day of whole lake so m/s * surfArea = m^3/s
    evap = E / (8.64*10^6);
    evapVol = evap * surfArea;
    if (any(isnan(evap), 'all') || any(isinf(evap), 'all'))
    warning('NaN detected at evaporation');
    keyboard      % inspect workspace interactively
    end
    output = evapVol;
end


% % Kohler 1955
% % function output = surfaceEvaporation(Tair,shortWave,longWave,eS,eA,wZ)
% %     T = (Tair * 9/5) + 32; % [F]
% %     mRad = shortWave + longWave; % W/m^2 
% %     rad = mRad * 2.06429; % langleys / day
% %     wind = wZ * 53.6865; % miles/day
% %     eSi = eS / 25.4; % in.hg
% %     eAi = eA / 25.4; % in.hg
% %     % T in *F, rad in langleys/day, eS - eA in in.hg, wind in miles per day
% %     Elake = (exp((T - 212) * (0.1024 - 0.1066 * log(rad))) * - 0.0001 + 0.0105 * (eSi - eAi) * 0.88 * (0.37 + 0.0041 * wind)) * (( 0.04686 * (0.0041 * T + 0.676)^7 + -0.01497) ^ -1);
% %     % output in cm/day [WHAT???]
% %     Elake = Elake / 8.64*10^-6
% %     output = Elake;
% % end