
%yadadadadadadadadadadadadada
% input data
%so mathmatics uhhhh 
% basic 2D node? 
% ASSUMPTIONS 
% no penetration
% uniform channel
% as stated via W2 sediment heat exchange can be neglected 
% lets use the dam upsteam and downstream to find results, then compare it 
% 10 meter node size. 
% 4,660 meters downstream of dam is the downstream monitoring station 
% 1,150 meters upstream of the dam is the downstream monitoring station


% using water speeds and discharge rates the average "diameter" can be
% assumed 
% net heat exchange = mass flow rate * cp (Tend - Tin)  * area
% surface area is a weird one, We can assume an averaged surface area using
% google earth. 
lowerRiverSurfaceArea = 2.97*10^6;
upperRiverSurfaceArea = 0.67*10^6;
% assuming no cloudiness  surfaceOutput(swRadModel,cloudiness,long,lat,z,Jday,HOUR,year,month,TZ, Tair, Ts, condModel, Wz, RH)
heatTransferFlux = surfaceOutput(MBH,0,-121.190,45.608,50,Jday,HOUR,year,month,TZ, Tair, Ts, condModel, Wz, RH,rZ);
upperDischargeRate % get data for this aidan 
lowerDischrageRate % get data for this as well
damDischargeRate
cp = 4184;
waterDensity = 1000;
tUpper % get data for this 
tLower % get data for this 
tBelow = heatTransferFlux*lowerRiverSurfaceArea/(lowerDischargeRate * waterDensity*cp) + tLower;
tAbove = heatTransferFlux*upperRiverSurfaceArea/(upperDischargeRate * waterDensity*cp) + tUpper;
tChange = tBelow - tAbove;
qDam = tChange*DischargeRate*density*cp;



