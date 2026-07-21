function out = dewPointTempCalc(vapPressure) % from Magnus formula 
    alpha = 6.112; % in hPa
    beta =  17.63; % constant
    Lambda = 243.12; % in Celcius
    denom = (beta - log(vapPressure/alpha));
    test = (Lambda) * log(vapPressure/alpha) / denom;
    if any(isnan([vapPressure,denom,test]), 'all') || any(isinf([vapPressure,denom,test]), 'all')
       warning('NaN detected at dew point');
       keyboard
    end
    out = test;
end