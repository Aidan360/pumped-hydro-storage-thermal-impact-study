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