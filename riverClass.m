classdef riverClass < handle
   properties
      %geometric data and constants 
      Cp = 0;% [J/kg*k]
      density = 0;%[kg/m^3]
      tS = 15*60; % timeStep of everything
      elevation = 0; % elevation of BOTTOM of control volume
      % transient data
      falseVolume = 0; % volume is just a 1m crossectional Area
      depth = 0;
      temp = 0;
      surfaceArea = 0;
      % table data 
      flow = 0; 
      rain = 0;
      rainCheck = true; % checks if rain will be accounted for in flow rate
      gaugeIn = 0;
      velocity = 0;
   end
   methods
       function obj = surfCalc(obj)
            obj.surfaceArea = 2*obj.falseVolume/pi*obj.depth;
      end
      function obj = depthCalc(obj)
            obj.depth = obj.gaugeIn - obj.elevation;
      end
      function obj = volCalc(obj)
            obj.falseVolume = obj.flow / obj.velocity; 
      end
      function obj = updateWaterBalance(obj)
           obj = obj.depthCalc();
           obj = obj.volCalc();
           obj = obj.surfCalc();
      end
      function out = outHeatTransfer(obj,tFinal) % watts output
              qMix = (obj.temp - tFinal)*obj.flow*obj.Cp*obj.density; % flow is made positive so heat transfer is pos
              out = obj.tS*qMix;
      end
      function obj = inHeatTransfer(obj,qIn) % watts and volumetric flow Input at output interval
          % qIn is both surface AND 
            obj.temp = obj.temp + qIn / ((obj.flow)*obj.tS * obj.density * obj.Cp);
      end
      
   end
end