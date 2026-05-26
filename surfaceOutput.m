%mat lab timeeee

%work time so far 8:10


% short wave is by sun, long wave is radiation from the earths atmosphere 

% cloudiness has a range of 0 - 1
% swRad model is either EPA or MBH 
% long and lat in degrees 
% dew point 
% elevation of resivours
% Jday = Julian day of the year 
% HOUR is hour of the year 
% year ofc is year 
% TZ is time zone
% Ts and Tair is Temp of the surface and temp of the air 
% cond model could probably be simplifed down to just resivour or lake
% Es and Ea is evaporation data for saturation vapor pressure at water
% surface and atmospheric vapor pressure. 
function output = surfaceOutput(swRadModel,cloudiness,long,lat,Tdpt,z,Jday,HOUR,year,month,TZ, Tair, Ts, condModel, Wz, es, ea)
    if swRadModel == EPA
        s = swEPAcalc(long,lat,Jday,HOUR);
    elseif swRadModel == MBH 
        %Ba is recommended to be 0.84
        %K1 is recommended to be 0.1 unless more data is available
        %We're going to assume its in the pacific north west?? so ta038 and
        %ta050 will be 0.1 and 0.05 (mt vernon stuff)
        s = swMBHcalc(cloudiness,0.84,0.1,0.05,0.1,long,lat,Tdpt,z,Jday,HOUR,year,month,TZ);
    else
        error('Please Enter Valid Model, either EPA or MBH');
    end
    an = lwRCalc(Tair,cloudiness);
    br = bRCalc(Ts);
    if condModel == genModel % gen model does stuff 
        e = evapCalcGenModel(Wz,es,ea);
    else
        e = evapCalcReservoirModel(Wz,es,ea);
    end
    c = conductionReservoirModel(Wz,Tair,Ts);
    output = s-sr+an-br-e-c;
end

%Ba = 0.84; % irradiance to total irrdiance ratio
%K1 = 0.1; % aerosol absorptance coefficient
%ta038 = 0.05; % 
%ta050 = 0.1; 
%TZ = -8;

function out = swEPAcalc(long,lat,Jday, HOUR) % short wave solar radiation model for EPA
    Td = (2*pi*INT(Jday) - 1) / 365;
    delta = 0.006918 - 0.399912*cos(Td) + 0.070257*sin(Td) - 0.006758*cos(2*Td) + 0.000907*sin(2*Td) - 0.002697*cos(3*Td) + 0.001480*Sin(3*Td); 
    EQT = 0.170*sin(4*pi*(int8(Jday) - 80) / 374) - 0.129*sin(2*pi*(int8(Jday) - 8)/355);
    standardMeridian = 15 * int8(long/15.0);
    H = (2*pi / 24) * (HOUR - (long - standardMeridian) * 24/360 + EQT - 12.0); % local hour angle in radians
    Ao = A*Sin(Sin(lat)*Sin(delta) + cos(lat)*cos(delta)*cos(H)); % Ao is solar altiude
    out = 24*(2.044 * Ao + 0.1296*Ao^2 - 1.941*(10^-3)*Ao^3 + (7.591*10^-6)*Ao^4) * 0.1314;
end

function out = swMBHcalc(cloudiness,Ba,K1,ta038,ta050,long,lat,Tdpt,z,Jday, HOUR,year,month,TZ) % shortwave solar radtion model from Meeus, Bird and hulstrom models
    
    Jday = Jday - TZ/24; % Jday is julian day, TZ is time zone adjusted to GMT
    DD = day + HOUR/24;
    if year <= 2 
        year = year - 1;
        month = month + 12;
    end
    Ajd = Floor(year/100);
    Bjd = 2 - Ajd + Floor(A/4.0);
    JD = floor(365.25*(year + 4716.0)) + floor(30.6001*(month + 1)) + DD + Bjd - 1524.5;% julian ephermeris day
    t = (JD - 2451545.0) / 36525.0; % julian centuries
    eEarth = 0.016708734 - t*(0.000042037 + 0.0000001267*t); % t is the julian centuries. why is there here, idk man 



    % COPY AND PASTE FROM EPA MODEL, sorta modded by stuff
    LO = 280.46646 + t*(36000.76983 + 0.0003032*t);
    M = 357.52911 + t(35999.05029 - 0.0001537*t); % mean geometric anomoly of the sun
    c = sin(M) * (1.914602 - t*(0.004817 + 0.000014*t)) + sin(2*M)*(0.019993 - 0.000101*t) + sin(3*M) * 0.000289; % center of the sun
    TLO = LO + c; % true longitude of the sun
    omega = 125.04 - 1934.136*t; % longitude correction factor 
    lambda = TLO - 0.00569 - 0.00478*sin(omega); % apparent longitude of the sun 
    seconds = 21.448 - t*(46.8150 + t*(0.00059 - 0.001813*t));
    epsilonO = 23 + 26 + (seconds/60)/60; % mean obliquity of the eliptic
    epsilonP = epsilonO + 0.0256 * cos(omega); % corrected obliquity of the elliptic
    delta = asin(sin(epsilonP) * sin(lambda)); % declination of the sun
    %delta = 0.006918 - 0.399912*cos(Td) + 0.070257*sin(Td) - 0.006758*cos(2*Td) + 0.000907*sin(2*Td) - 0.002697*cos(3*Td) + 0.001480*Sin(3*Td); 
    %EQT = 0.170*sin(4*pi*(int8(Jday) - 80) / 374) - 0.129*sin(2*pi*(int8(Jday) - 8)/355);
    yEQT = (tan(epsilonP / 2))^2;
    EQT = 4*(yEQT * sin(2*LO) - 2*eEarth*sin(M) + 4*eEarth*yEQT*sin(M)*cos(2*LO) - 0.5*(yEQT^2)*sin(4*LO)-1.25*(eEarth^2)*sin(2*M));
  %  H = (2*pi / 24) * (HOUR - (long - standardMeridian) * 24/360 + EQT - 12.0); % local hour angle in radians
    trueSolarTime = 60*HOUR + EQT -  4*long;
    H = trueSolarTime / 4 - 180;
    Ao = A*Sin(Sin(lat)*Sin(delta) + cos(lat)*cos(delta)*cos(H)); % Ao is solar altiude
    % COPY AND PASTE FROM EPA MODEL
    

  

    % switchcase for RC via RC table, used AI to code it lol. 
    % switch based on value of A falling within ranges (one input variable)
    % ranges: case1: A <= 1.5, case2: (1.5, 2.5], case3: (2.5, 3.5], case4: > 3.5
    if rad2Deg(Ao) <= -0.575 
        RC = (1/3600) * (-20.774 / tan(Ao));
    elseif rad2Deg(Ao) <= 5 
        RC = (1/3600) * (1735-518.2*Ao + 103.4*Ao^2 - 12.79*Ao^3 + 0.711*Ao^4);
    elseif rad2Deg(Ao) <= 85
        RC = (1/3600) * (58.1 / tan(Ao) - 0.07/(tan(Ao))^3 + 0.000086 / (tan(Ao))^5);
    else
        RC = 0;
    end


    AoC = Ao + RC; % Corrected solar altitude, Ao is solar altiude from previous formulas, RC is atmospheric correction. depends on a table 
  
    
    v = M + c % true anomaly of the sun. M is the mean geometric anomly of the sun and C is the center of the sun. 
    r = (1.000001018*(1-eEarth^2)) / (1 + eEarth*cos(v)); % e is the eccentricity of earths orbit, v is the true anomaly of the sun
    Oext = Oo / r^2 * Sin(AoC);  

    mp = ((288 - 0.0065*z / 288)^5.256) / ((sin(AoC) + 0.1500*(AoC + 3.885)^-1.253)); % relative optical air mass z is elevation of water body in meters
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
    Uo = (235 + Au + Cu*sin(0.9856 * int8(Jday) + Fu) + 20*sin(Hu * (long + Pu)) ) * (sin(Bu*lat))^2/1000; % Ozone content by van heulon model
    Xo = Uo*mp; % Uo is a table value and a calculated value, Uo will be used  
    To = 1 - 0.1611*Xo(1 + 139.48*Xo)^-0.3035 - 0.002715*Xo*(1+0.044*Xo + 0.0003*Xo^2)^-1; % Transmittance of ozone content
    ta = 0.2758*ta038 + 0.35*ta050; % ta038 and ta050 are from tables, 0.2661 and 0.3538 are us standard atmosphere, 0.1 and 0.05 are Mt vernon which will be used
    Ta = exp((-ta^0.873)*(1+ta-ta^0.7088) * mp^0.9108); % transmittance of aerosol absoprtion and scattering
    Taa = 1 - K1*(1 - mp + mp^1.06)*(1-Ta); % Transmittance of aerosol absorptance, K1 is a table value. 0.1 is recommended unless aerosol data is available
    rs = 0.0685+(1-Ba)*(1.0-Ta/Taa); % Albedo (dimensionless), Ba is found from table 0.84 is recommended but can change demning on situation
    Ias = 0.79*Oext*Taa*Tw*Tum*To*((0.5*(1-Tr) + Ba(Ta/Taa))/(1-mp+mp^1.02)); % scattered solar radiation 
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
    
    Rt = RtA*(Aoc)^RtB;% Surface reflectivity, cloudiness coefficents are found in tables, using 1.18 and -0.77 for clear skies
    out = (directHz + Ias) / (1 - Rt * rs);
end


function out = lwRCalc(Tair,cloudiness) %  net long wave radiation formula.
    sigma = 5.67*10^-8;
    if Tair >= 5 % Swinbank Formula 
        Oac = (5.31 * 10^-13) * (Tair  + 273)^6; % clear sky long wave radiation, Tair in celcius
    else % 
        Oac = sigma*((Tair + 273)^4) * (1 - 0.261 * exp((-7.77 * 10^-4)*Tair^2));
    end
    k = 0.17;
    out = Oac*(1+k*cloudiness^2) * 0.97; % C is for cloudniess which can be from 0 to 1. 
end

function out = bRCalc(Ts) % back radiation 
    epsilon = 0.97; % emissivity of water
    sigma = 5.67*10^-8;
    out = epsilon*sigma*(Ts + 273.15)^4; % Ts is water temp surface in Celcius
end

function out = windSpeedFunctionGenModel(Wz) % model 1 from Edinger et al 1974
    c = 2; 
    b = 0.46;
    a = 9.2;
    out = a + b*Wz ^ c; % evaporative wind speed function at wind height of z, measured at 2m off the ground if this is
end



function out = evapCalcGenModel(Wz,es,ea) % evaporation heat loss  BIG NOTE: ASSUME WIND IS MEASURED FROM 2METERS OFF THE GROUND
    out = windSpeedFunctionGenModel(Wz) * (es - ea);  % es is saturation vapor pressaure at water surface mmHg, and atmospheric vapure pressure at mmHg
end


function out = windSpeedFunctionReservoirModel(Wz)
    out = 10.512 + 2.94 * Wz;
end

function out = evapCalcReservoirModel(Wz,es,ea)
    out = 80 + 10*(Wz) * (es - ea);
end

function out = conductionReservoirModel(Wz,Ta,Ts)
    Cc = 0.47; % Bowen Coefficient , 0.47mm Hg C--1
    out = Cc*windSpeedFunctionReservoirModel(Wz)*(Ts - Ta);
end

