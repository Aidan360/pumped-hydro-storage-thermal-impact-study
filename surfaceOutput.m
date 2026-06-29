% cloudiness has a range of 0 - 1
% swRad model is either EPA or MBH 
% long and lat in degrees 
% elevation of resivours
% Jday = Julian day of the year 
% HOUR is hour of the year 
% year ofc is year 
% TZ is time zone
% Ts and Tair is Temp of the surface and temp of the air 
% cond model could probably be simplifed down to just resivour or lake
% rZ is relative depth to surface, if its zero its considered surface, if
% not then it uses shortwave penetration
% wind speed units are m/s

%mon, 8 - 


%%
% hStor = zeros(1,24);
% for h = 1:24
%     HE = surfaceOut(0,-121.190,45.608,50,6,h,2026,6,-8, 18.3, 15.4,3, 30);
%     hStor(h) = HE;
% end
% figure;
% plot(1:24,hStor,'-o')
% xlabel('Index')
% ylabel('hStor')
% title('hStor vs 1:23')
% grid on
%G = graph(hStor,1:23);
%plot(G)
% function output = surfaceOutput(Tair, Ts, Wz,rH,cloudiness)  
%     es = saturationVaporPressureCalc(Tair);
%     ea = vaporPressure(rH,es);
%     br = bRCalc(Ts);
%     e = evapCalcGenModel(Wz,es,ea);
%     c = conductionGenModel(Wz,Tair,Ts);
%     an = lwRCalc(Tair,cloudiness);
%   %  disp(["an",an,"br",br,"e",e,"c",c])
% 
%     output = an-br-e-c;
% end
% im going to cry
function output = surfaceOutput(Tair, Ts, Wz, RH, cloudiness,long,lat,z,Jday,HOUR,yearS,monthS,TZ)
    es = saturationVaporPressureCalc(Tair);
    ea = vaporPressure(RH,es);
    Tdpt = dewPointTempCalc(ea);
    Ba = 0.84; %Ba is recommended to be 0.84
    K1 = 0.1; %K1 is recommended to be 0.1 unless more data is available
    %We're going to assume its in the pacific north west?? so ta038 and
    %ta050 will be 0.1 and 0.05 (mt vernon stuff)
    ta038 = 0.05;
    ta050 = 0.1;
    s = pswMBHcalc(cloudiness,Ba,K1,ta038,ta050,long,lat,Tdpt,z,Jday,HOUR,yearS,monthS,TZ); 

    an = lwRCalc(Tair,cloudiness);
    br = bRCalc(Ts);
    e = evapCalcGenModel(Wz,es,ea);
    c = conductionGenModel(Wz,Tair,Ts);
    if any(isnan([s, an, br, e, c]), 'all')
       warning('NaN detected at heat functions');
       keyboard
    end
    output = s + an - br - e - c;
end



function out = pswMBHcalc(cloudiness,Ba,K1,ta038,ta050,long,lat,Tdpt,z,dayIn,HOUR,yearS,monthS,TZ)
% Patched swMBHcalc with defensive checks to avoid unexpected complex values.
% Assumptions:
% - lat and long are given in degrees (converted to radians internally).
% - dayIn, HOUR, year, month, TZ as before.
% Returns out = 0 when sun is below horizon or numerics invalid.
    if any(isnan([cloudiness, long, lat, Tdpt]), 'all')
       warning('NaN detected at surface shortwave inputs functions');
       keyboard
    end
    % Small tolerances
    TOL = 1e-12;
    MIN_POS = eps;

    % Helper to clamp into [-1,1]
    clamp01 = @(x) max(min(x,1),-1);

    % Helper to check for complex and stop for debugging (optional)
    function checkc(name,x)
        if ~isreal(x) && any(imag(x(:))~=0)
            fprintf('Complex detected in %s: minImag=%g maxImag=%g\n', name, min(imag(x(:))), max(imag(x(:))));
            keyboard
        end
    end

    % Convert lat/long to radians if given in degrees
    lat = deg2rad(lat);
    long = deg2rad(long);

    % Time and Julian date calculations
    day = dayIn - TZ/24;
    DD = day + HOUR/24;
    if yearS <= 2
        yearS = yearS - 1;
        monthS = monthS + 12;
    end
    Ajd = floor(yearS/100);
    Bjd = 2 - Ajd + floor(Ajd/4.0);
    JD = floor(365.25*(yearS + 4716.0)) + floor(30.6001*(monthS + 1)) + DD + Bjd - 1524.5;
    t = (JD - 2451545.0) / 36525.0;

    % Orbital elements (these are in degrees per Meeus-style form)
    eEarth = 0.016708734 - t*(0.000042037 + 0.0000001267*t);
    LO = 280.46646 + t*(36000.76983 + 0.0003032*t);
    M = 357.52911 + t*(35999.05029 - 0.0001537*t);

    % Convert degree-valued angles to radians before trig
    LOr = deg2rad(LO);
    Mr  = deg2rad(M);

    c = sin(Mr) * (1.914602 - t*(0.004817 + 0.000014*t)) + ...
        sin(2*Mr)*(0.019993 - 0.000101*t) + sin(3*Mr) * 0.000289;
    TLO = LO + c;
    omega = 125.04 - 1934.136*t;
    lambd = TLO - 0.00569 - 0.00478*sin(deg2rad(omega));

    seconds = 21.448 - t*(46.8150 + t*(0.00059 - 0.001813*t));
    % Correct mean obliquity: 23 degrees 26' seconds -> 23 + 26/60 + seconds/3600
    epsilonO = 23 + 26/60 + seconds/3600;
    epsilonP = epsilonO + 0.0256 * cos(deg2rad(omega));

    % Convert to radians for trig
    epsilonPr = deg2rad(epsilonP);
    lambdar = deg2rad(lambd);

    % Declination
    arg_delta = sin(epsilonPr) * sin(lambdar);
    arg_delta = clamp01(arg_delta);
    delta = asin(arg_delta); % radians
    checkc('delta', delta);

    % Equation of time (ensure trig args in radians)
    yEQT = tan(epsilonPr / 2).^2;
    EQT = 4 * ( yEQT .* sin(2*LOr) - 2*eEarth.*sin(Mr) + 4*eEarth.*yEQT.*sin(Mr).*cos(2*LOr) ...
           - 0.5*(yEQT.^2).*sin(4*LOr) - 1.25*(eEarth^2).*sin(2*Mr) );

    trueSolarTime = 60*HOUR + EQT - 4*rad2deg(long); % long was converted to rad, convert back to deg for this formula
    H = trueSolarTime / 4 - 180; % in degrees
    Hr = deg2rad(H);

    % Solar altitude Ao (radians). Clamp asin arg.
    arg_Ao = sin(lat).*sin(delta) + cos(lat).*cos(delta).*cos(Hr);
    arg_Ao = clamp01(arg_Ao);
    Ao = asin(arg_Ao);
    checkc('Ao', Ao);

    % Atmospheric refraction correction RC (Ao in degrees used by empirical formula)
    Ao_deg = rad2deg(Ao);
    if Ao_deg <= -0.575
        % Use formula but avoid dividing by zero in tan(Ao)
        tAo = tan(Ao);
        if abs(tAo) < TOL
            RC = 0;
        else
            RC = (1/3600) * (-20.774 ./ tAo);
        end
    elseif Ao_deg <= 5
        % polynomial in degrees; use Ao_deg
        RC = (1/3600) * (1735 - 518.2*Ao_deg + 103.4*Ao_deg.^2 - 12.79*Ao_deg.^3 + 0.711*Ao_deg.^4);
    elseif Ao_deg <= 85
        tAo = tan(Ao);
        if abs(tAo) < TOL
            RC = 0;
        else
            % use Ao in radians for tan; polynomial terms use tAo
            RC = (1/3600) * (58.1 ./ tAo - 0.07./(tAo.^3) + 0.000086./(tAo.^5));
        end
    else
        RC = 0;
    end

    AoC = Ao + RC; % AoC in radians + degrees -> convert RC to radians
    % RC computed in degrees arcseconds; actually RC was arcseconds/3600 => degrees.
    % Convert RC (degrees) to radians before adding:
    RC_rad = deg2rad(RC);
    AoC = Ao + RC_rad;
    checkc('AoC', AoC);

    % If sun below horizon (corrected altitude <= 0), return zero irradiance
    if AoC <= 0
        out = 0;
        return
    end

    % True anomaly v: M and c are degrees; ensure radians for cos
    v = M + c;
    vr = deg2rad(v);
    % Distance r
    denom_r = 1 + eEarth .* cos(vr);
    denom_r = max(denom_r, MIN_POS);
    r = (1.000001018*(1 - eEarth^2)) ./ denom_r;

    Oo = 1361;
    Oext = Oo ./ (r.^2) .* sin(AoC);
    checkc('Oext', Oext);

    % Relative optical air mass mp
    % Use AoC in radians inside sin; handle denominators carefully
    base_mp = ( (288 - 0.0065*z) / 288 )^5.256;
    denom_mp = sin(AoC) + 0.1500 * ( (AoC + 3.885) );
    % The original used (AoC+3.885)^-1.253; ensure base positive and in correct units.
    base1 = AoC + deg2rad(3.885); % ensure same units (radians)
    base1 = max(base1, MIN_POS);
    denom_mp = sin(AoC) + 0.1500 * base1.^(-1.253);
    if denom_mp <= 0
        denom_mp = MIN_POS;
    end
    mp = base_mp ./ denom_mp;
    mp = max(mp, MIN_POS);
    checkc('mp', mp);

    % Transmittances; ensure mp used as positive
    Tr = exp(-0.0903 * mp.^2 .* (1 + mp - mp.^1.01));
    Tum = exp(-0.0127 * mp.^0.26);
    w = exp(-0.0592 + 0.06912*Tdpt);
    Xw = w .* mp;
    % Tw: ensure positive denominator and numerator shapes
    Tw_denom = (1 + 79.034*Xw).^0.6828 + 6.385*Xw;
    Tw_denom = max(Tw_denom, MIN_POS);
    Tw = 1 - 2.4959.*Xw ./ Tw_denom;
    checkc('Tw', Tw);

    Bu = 1.28;
    if abs(long) == long
        Pu = 20;
    else
        Pu = 0;
    end
    Hu = 3; Fu = -30; Cu = 40; Au = 150;
    Uo = (235 + Au + Cu*sin(deg2rad(0.9856 * round(day) + Fu)) + 20*sin(Hu * (rad2deg(long) + Pu)) ) .* (sin(Bu*lat)).^2 / 1000;
    Xo = Uo .* mp;
    To = 1 - 0.1611.*Xo.*(1 + 139.48.*Xo).^(-0.3035) - 0.002715.*Xo.*(1 + 0.044.*Xo + 0.0003.*Xo.^2).^(-1);
    checkc('To', To);

    ta = 0.2758*ta038 + 0.35*ta050;
    Ta = exp((-ta^0.873) .* (1 + ta - ta^0.7088) .* mp.^0.9108);
    Taa = 1 - K1.*(1 - mp + mp.^1.06).*(1 - Ta);
    checkc('Ta_Taa', [Ta(:); Taa(:)]);

    rs = 0.3;

    Ias = 0.79 .* Oext .* Taa .* Tw .* Tum .* To .* ( (0.5*(1 - Tr) + Ba.*(1 - Ta./Taa)) ./ (1 - mp + mp.^1.02) );
    directHz = 0.9662 .* Oext .* Ta .* Tw .* Tum .* To .* Tr;
    
    checkc('Ias', Ias);
    checkc('directHz', directHz);

    % Set RtA and RtB based on cloudiness (fix typo: use cloudiness
    % consistently) cloud 0 is low, cloud 1 is high
    if isequal(cloudiness(1),0) && isequal(cloudiness(2),0)
        RtA = 1.18; RtB = -0.77;
    else
        if cloudiness(1) >= 0.01 && cloudiness(1) <= 0.59
            LRtA = 2.17; LRtB = -0.96;
        elseif cloudiness(1) >= 0.6 && cloudiness(1) <= 0.99
            LRtA = 0.78; LRtB = -0.68;
        elseif isequal(cloudiness(1),1)
            LRtA = 0.20; LRtB = -0.30;
        else
            LRtA = 1.18; LRtB = -0.77;
        end
        if cloudiness(2) >= 0.01 && cloudiness(2) <= 0.59
            HRtA = 2.20; HRtB = -0.98;
        elseif cloudiness(2) >= 0.6 && cloudiness(2) <= 0.99
            HRtA = 1.10; HRtB = -0.80;
        elseif isequal(cloudiness(2),1)
            HRtA = 0.51; HRtB = -0.58;
        else
            HRtA = 1.18; HRtB = -0.77;
        end
        RtA = max([LRtA,HRtA]); RtB = max([LRtB,HRtB]);
    end
        % 
    % elseif cloudiness >= 0.01 && cloudiness <= 0.59
    %     RtA = 2.20; RtB = -0.97;
    % elseif cloudiness >= 0.6 && cloudiness <= 0.99
    %     RtA = 0.95; RtB = -0.75;
    % elseif isequal(cloudiness,1)
    %     RtA = 0.33; RtB = -0.45;
    % else
    %     error('cloudiness must be 0, in [0.1,0.5], in [0.6,0.9], or 1.');
    

    % Surface reflectivity Rt, use Ao in degrees in exponent as original
    Rt = RtA .* (rad2deg(Ao)).^RtB;
    denom_out = 1 - Rt .* rs;
    if abs(denom_out) < TOL
        denom_out = sign(denom_out) * TOL;
    end
    if any(isnan([denom_out, directHz, Ias]), 'all')
            warning('NaN detected at exhange functions');
            keyboard
    end
    out = (directHz + Ias) ./ denom_out;
    % Force any tiny imaginary parts to zero if numerically insignificant
    if ~isreal(out)
        if max(abs(imag(out(:)))) < 1e-9
            out = real(out);
        else
            % Unexpected significant complex result: set to zero and warn
            warning('swMBHcalc:complexResult', 'Significant complex component produced; returning real part.');
            out = real(out);
        end
    end
end
function out = swMBHcalc(cloudiness,Ba,K1,ta038,ta050,long,lat,Tdpt,z,dayIn,HOUR,yearS,month,TZ) % shortwave solar radtion model from Meeus, Bird and hulstrom models
   
    day = dayIn - TZ/24; % Jday is julian day, TZ is time zone adjusted to GMT
    DD = day + HOUR/24;
    if year <= 2 
        year = year - 1;
        month = month + 12;
    end
    Ajd = floor(year/100);
    Bjd = 2 - Ajd + floor(Ajd/4.0);
    JD = floor(365.25*(year + 4716.0)) + floor(30.6001*(month + 1)) + DD + Bjd - 1524.5;% julian ephermeris day
    t = (JD - 2451545.0) / 36525.0; % julian centuries
    eEarth = 0.016708734 - t*(0.000042037 + 0.0000001267*t); % t is the julian centuries. why is there here, idk man 
    LO = 280.46646 + t*(36000.76983 + 0.0003032*t);
    M = 357.52911 + t*(35999.05029 - 0.0001537*t); % mean geometric anomoly of the sun
    c = sin(M) * (1.914602 - t*(0.004817 + 0.000014*t)) + sin(2*M)*(0.019993 - 0.000101*t) + sin(3*M) * 0.000289; % center of the sun
    TLO = LO + c; % true longitude of the sun
    omega = 125.04 - 1934.136*t; % longitude correction factor 
    lambda = TLO - 0.00569 - 0.00478*sin(omega); % apparent longitude of the sun 
    seconds = 21.448 - t*(46.8150 + t*(0.00059 - 0.001813*t));
    epsilonO = 23 + 26 + (seconds/60)/60; % mean obliquity of the eliptic
    epsilonP = epsilonO + 0.0256 * cos(omega); % corrected obliquity of the elliptic
    delta = asin(sin(epsilonP) * sin(lambda)); % declination of the sun
    yEQT = (tan(epsilonP / 2))^2;
    EQT = 4*(yEQT * sin(2*LO) - 2*eEarth*sin(M) + 4*eEarth*yEQT*sin(M)*cos(2*LO) - 0.5*(yEQT^2)*sin(4*LO)-1.25*(eEarth^2)*sin(2*M));
    trueSolarTime = 60*HOUR + EQT -  4*long;
    H = trueSolarTime / 4 - 180;
    Ao = asin(sin(lat)*sin(delta) + cos(lat)*cos(delta)*cos(H)); % Ao is solar altiude
    if rad2deg(Ao) <= -0.575 
        RC = (1/3600) * (-20.774 / tan(Ao));
    elseif rad2deg(Ao) <= 5 
        RC = (1/3600) * (1735-518.2*Ao + 103.4*Ao^2 - 12.79*Ao^3 + 0.711*Ao^4);
    elseif rad2deg(Ao) <= 85
        RC = (1/3600) * (58.1 / tan(Ao) - 0.07/(tan(Ao))^3 + 0.000086 / (tan(Ao))^5);
    else
        RC = 0;
    end
    AoC = Ao + RC; % Corrected solar altitude, Ao is solar altiude from previous formulas, RC is atmospheric correction. depends on a table 
    v = M + c;% true anomaly of the sun. M is the mean geometric anomly of the sun and C is the center of the sun. 
    r = (1.000001018*(1-eEarth^2)) / (1 + eEarth*cos(v)); % e is the eccentricity of earths orbit, v is the true anomaly of the sun
    Oo = 1361; % W/m^2, Solar Constant
    Oext = Oo / r^2 * sin(AoC);  
    mp = ((((288-0.0065*z)) / 288)^5.256) / (sin(AoC) +(0.1500*(AoC+3.885)^-1.253)); % relative optical air mass z is elevation of water body in meters
    Tr = exp(-0.0903*mp^2 * (1+mp - mp^1.01)); % Transmittance of rayleigh scattering
    Tum = exp(-0.0127*mp^0.26);% Transmittance of uniformly mixed gases     
    w = exp(-0.0592 + 0.06912*Tdpt);% preciptable water content in atmosphere Tdpt is dew point temperature
    Xw = w*mp; % precipitable water content in slanted path
    Tw = 1 - 2.4959*Xw /((1+79.034*Xw)^0.6828 + 6.385*Xw); % transmittance of the water vapor 
    Bu = 1.28;
    if abs(long) == long
        Pu = 20;
    else 
        Pu = 0;
    end
    Hu = 3;
    Fu = -30;
    Cu = 40; 
    Au = 150; % northern hemisphere model, i'll program if it isn't later maybe idk
    Uo = (235 + Au + Cu*sin(0.9856 * round(day) + Fu) + 20*sin(Hu * (long + Pu)) ) * (sin(Bu*lat))^2/1000; % Ozone content by van heulon model
    Xo = Uo*mp; % Uo is a table value and a calculated value, Uo will be used  
    To = 1 - 0.1611*Xo*(1 + 139.48*Xo)^-0.3035 - 0.002715*Xo*(1+0.044*Xo + 0.0003*Xo^2)^-1; % Transmittance of ozone content
    ta = 0.2758*ta038 + 0.35*ta050; % ta038 and ta050 are from tables, 0.2661 and 0.3538 are us standard atmosphere, 0.1 and 0.05 are Mt vernon which will be used
    
    Ta = exp((-ta^0.873)*(1+ta-ta^0.7088) * mp^0.9108); % transmittance of aerosol absoprtion and scattering
    Taa = 1 - K1*(1 - mp + mp^1.06)*(1-Ta); % Transmittance of aerosol absorptance, K1 is a table value. 0.1 is recommended unless aerosol data is available
    
    
    % disp(["Ba: ", Ba]) % this one is fine
    % disp(["Ta: ", Ta]) % too hihg 
    % disp(["Taa: ", Taa])
   % rs = 0.0685+(1-Ba)*(1.0-Ta/Taa); % Albedo (dimensionless), Ba is found from table 0.84 is recommended but can change demning on situation
    rs = 0.3;
    if any(isnan([directHz, Ias, duTInflow, dlTSurface, duTTurb,duTdiff]), 'all')
            warning('NaN detected at exhange functions');
            keyboard
    end
    
    Ias = 0.79*Oext*Taa*Tw*Tum*To*   ( (0.5*( 1 - Tr ) + Ba*(1 - Ta/Taa))/(1 - mp + mp^1.02)); % scattered solar radiation
    directHz = 0.9662*Oext*Ta*Tw*Tum*To*Tr; % direct solar radiation
    
    % set A and B based on C using a 4-part switch-like structure
    % cases: C == 0, C in [0.1,0.5], C in [0.6,0.9], C == 1
    if isequal(cloudiness,0)
        RtA = 1.18; % set specific value for A when C == 0
        RtB = -0.77; % set specific value for B when C == 0
    elseif cloudiness >= 0.1 && cloudiness <= 0.5
        RtA = 2.20; % set specific value for A when 0.1 <= C <= 0.5
        RtB = -0.97; % set specific value for B when 0.1 <= C <= 0.5
    elseif C >= 0.6 && cloudiness <= 0.9
        RtA = 0.95; % set specific value for A when 0.6 <= C <= 0.9
        RtB = -0.75; % set specific value for B when 0.6 <= C <= 0.9
    elseif isequal(cloudiness,1)
        RtA = 0.33; % set specific value for A when C == 1
        RtB = -0.45; % set specific value for B when C == 1
    else
        error('C must be one of: 0, in [0.1,0.5], in [0.6,0.9], or 1.');
    end
    % Aoc should be fine as well
    Rt = RtA*(rad2deg(Ao))^RtB;% Surface reflectivity, cloudiness coefficents are found in tables, using 1.18 and -0.77 for clear skies
 %   disp(["rs: ", rs]); % typical values of 03 - 0.31, too high  just using values from a textbook, i couldn't be bothered to fix the calculator. 
    out = (directHz + Ias) / (1 - Rt * rs);
end
%%

function out = lwRCalc(Tair,cloudiness) %  net long wave radiation formula.
    sigma = 5.67*10^-8;
    if Tair >= 5 % Swinbank Formula 
        Oac = (5.31 * 10^-13) * (Tair  + 273)^6; % clear sky long wave radiation, Tair in celcius
    else % 
        Oac = sigma*((Tair + 273)^4) * (1 - 0.261 * exp((-7.77 * 10^-4)*Tair^2));
    end
    k = 0.17;
    out = Oac*(1+k*max(cloudiness)^2) * 0.97; % C is for cloudniess which can be from 0 to 1. 
end
%%
function out = bRCalc(Ts) % back radiation 
    epsilon = 0.97; % emissivity of water
    sigma = 5.67*10^-8;
    out = epsilon*sigma*(Ts + 273.15)^4; % Ts is water temp surface in Celcius
end
%%
function out = saturationVaporPressureCalc(Tair)
    eJ = exp((17.625 * Tair)/(Tair + 243.04));
    if eJ == 0
       warning('NaN detected at saturationPressure');
       keyboard
    end
    out = 6.1094*eJ; % From August Roche Magnus formula, assuming it temps don't go below freezing (uh oh)
end
function out = vaporPressure(RH,eS)
    vP = eS * (RH/100);
    if vP == 0
       warning('NaN detected at vaporPressure');
       keyboard
    end
    out = eS * (RH/100);
    
end

function out = dewPointTempCalc(vapPressure) % from Magnus formula 
    alpha = 6.112; % in hPa
    beta =  17.63; % constant
    Lambda = 243.12; % in Celcius
    denom = (beta - log(vapPressure/alpha));
    test = (Lambda) * log(vapPressure/alpha) / denom;
    if any(isnan([vapPressure,denom,test]), 'all')
       warning('NaN detected at dew point');
       keyboard
    end
    out = test;
end
%%

function out = windSpeedFunctionGenModel(Wz) % model 1 from Edinger et al 1974
    c = 2; 
    b = 0.46;
    a = 9.2;
    out = a + b*Wz ^ c; % evaporative wind speed function at wind height of z, measured at 2m off the ground if this is
end
%%
function out = evapCalcGenModel(Wz,es,ea) % evaporation heat loss  BIG NOTE: ASSUME WIND IS MEASURED FROM 2METERS OFF THE GROUND
    out = windSpeedFunctionGenModel(Wz) * (es - ea) / 1.333;  % es is saturation vapor pressaure at water surface mmHg, and atmospheric vapure pressure at mmHg
    % /1.333 for milibars to mmHg
end
%%
function out = conductionGenModel(Wz,Ta,Ts)
    Cc = 0.47; % Bowen Coefficient , 0.47mm Hg C--1
    out = Cc*windSpeedFunctionGenModel(Wz)*(Ts - Ta);
end
%%


% dead model pile
%{
function out = swEPAcalc(long,lat,Jday,HOUR) % short wave solar radiation model for EPA
    Td = (2*pi*round(Jday) - 1) / 365;
    delta = 0.006918 - 0.399912*cos(Td) + 0.070257*sin(Td) - 0.006758*cos(2*Td) + 0.000907*sin(2*Td) - 0.002697*cos(3*Td) + 0.001480*sin(3*Td); 
    EQT = 0.170*sin(4*pi*(round(Jday) - 80) / 374) - 0.129*sin(2*pi*(round(Jday) - 8)/355);
    standardMeridian = 15 * round(long/15.0);

    H = (2*pi / 24) * (HOUR - (long - standardMeridian) * 24/360 + EQT - 12.0); % local hour angle in radians
    disp("H")
    disp(H) 
    Ao = asin(sin(lat)*sin(delta) + cos(lat)*cos(delta)*cos(H)); % Ao is solar altiude
    out = 24*(2.044 * Ao + 0.1296*Ao^2 - 1.941*(10^-3)*Ao^3 + (7.591*10^-6)*Ao^4) * 0.1314;
end

function out = windSpeedFunctionReservoirModel(Wz)
    out = 10.512 + 2.94 * Wz;
end
function out = conductionReservoirModel(Wz,Ta,Ts)
    Cc = 0.47; % Bowen Coefficient , 0.47mm Hg C--1
    out = Cc*windSpeedFunctionReservoirModel(Wz)*(Ts - Ta);
end
function out = evapCalcReservoirModel(Wz,es,ea)
    % disp("evap stuff")
    % disp(es)
    % disp(ea)
    out = (80 + 10*(Wz)) * (es - ea);
end

%}