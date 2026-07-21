function out = vaporPressureCalc(RH,eS)
    vP = eS * (RH/100);
    if vP == 0
       warning('NaN detected at vaporPressure');
       keyboard
    end
    out = eS * (RH/100);
    
end