function out = saturationVaporPressureCalc(Tair)
    eJ = exp((17.625 * Tair)/(Tair + 243.04));
    if eJ == 0
       warning('NaN detected at saturationPressure');
       keyboard
    end
    out = 6.1094*eJ; % From August Roche Magnus formula
end