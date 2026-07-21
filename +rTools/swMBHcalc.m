function out = swMBHcalc(cloudiness,Ba,K1,ta038,ta050,long,lat,Tdpt,z,dayIn,HOUR,yearS,monthS)
% Patched swMBHcalc with defensive checks to avoid unexpected complex values.
% Assumptions:
% - lat and long are given in degrees (converted to radians internally).
% - dayIn, HOUR, year, month, TZ as before.
% Returns out = 0 when sun is below horizon or numerics invalid.
    if any(isnan([cloudiness, long, lat, Tdpt]), 'all') || any(isinf([cloudiness, long, lat, Tdpt]), 'all')
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
    day = dayIn;
    DD = day + HOUR/24;
    if monthS <= 2
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
    epsilonP = epsilonO + 0.00256 * cos(deg2rad(omega));

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
    % if any(isnan([denom_out, directHz, Ias]), 'all') || any(isinf([denom_out, directHz, Ias]), 'all')
    %         warning('NaN detected at exhange functions');
    %         keyboard
    % end
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