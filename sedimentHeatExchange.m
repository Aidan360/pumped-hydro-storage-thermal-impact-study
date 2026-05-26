%Matlab script 2, Condition two. Sediment heat exchange, this is fairly simple 

%Temp of water
%Temp of sediment 
%coefficent of diffusion D 
% L is element size so i might need to come back to that later
% range between 0.16 to 9 
function output = sedimentHeatExchange(Tw,Ts,L)
    % D = 0.035 m^2/D for lake sediment study (Fang and Stefan)
    % p*cps = 2.3*10^6 (Fang and Stefan)
    Ksw = KswCalc(2.3*10^6,0.035,L);
    output = -Ksw*(Tw - Ts);
end

function out = KswCalc(pcp,D,L)
    out = pcp*D/L;
end