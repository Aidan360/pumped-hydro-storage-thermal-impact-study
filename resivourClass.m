classdef resivourClass < handle
   properties
      %geometric data and constants 
      resMaxRadius = 0;% [M]
      resMaxDepth = 0;% [M]
      length = 0; % [M]
      Cp = 0;% [J/kg*k]
      density = 0;%[kg/m^3]
      inEff = 0;%[J/m^3]
      outEff = 0;%[J/m^3]
      tS = 15*60; % timeStep of everything
      elevation = 0;
      head = 0;
      % transient data
      depth = 0;
      temp = 0;
      volume = 0;
      surfaceArea = 0;
      inCoff = 0;
      outCoff = 0;
      riverHeight = 0;
      evap = 0;
      % table data 
      inflow = 0; % flow in is POSITIVE
      outflow = 0; % flow out is NEGATIVE 
      spill = 0;
      rain = 0;
      rainCheck = true; % checks if rain will be accounted for in flow rate
   end
   methods
       function obj = troughDepthCalc(obj)
            r = obj.resMaxRadius;
            L = obj.length;
            h = obj.depth;
            vDer = L * 2 * sqrt(2*r*h-h^2);
            obj.depth = obj.depth - (obj.inflow + obj.outflow)/vDer;
       end
       function obj = troughSurfCalc(obj)
           obj.surfaceArea = obj.length * 2 * sqrt(2*obj.resMaxRadius*obj.depth - obj.depth^2);
       end
       function obj = surfCalc(obj)
            h = obj.depth;
            r = obj.resMaxRadius;
            L = obj.resMaxDepth; 
            obj.surfaceArea = L*2*sqrt(h*(2*r-h));
      end
      function obj = depthCalc(obj)
            obj.depth; 
            Vder = pi * (obj.resMaxRadius^2)/(obj.resMaxDepth^2) * obj.depth * (2*obj.resMaxDepth - obj.depth); 
            if Vder == 0
                obj.depth = obj.depth;
            else 
                obj.depth = obj.depth + (obj.inflow + obj.outflow)*obj.tS/Vder;
            end
      end


      function obj = cubicDepthCalc(obj)
            % p1 = -1.86691*10^-16;
            % p2 = 1.49139*10^-7;
            % p3 = 18.225;
            obj.depth = -1.86691*10^-16*obj.volume + 1.49139*10^-7*obj.volume + 18.225;
      end
      function obj = cubicSurfaceCalc(obj)
            obj.surfaceArea = obj.volume / obj.depth;
      end
      function obj = volCalc(obj)
         if obj.rainCheck == true
            obj.volume = obj.volume + obj.tS*(obj.rain*obj.surfaceArea + obj.inflow + obj.outflow - obj.evap);
         else
            obj.volume = obj.volume + obj.tS*(obj.inflow + obj.outflow - obj.evap);
         end
      end
      function out = volFromDepthCalc(obj)
            out = pi * obj.resMaxRadius^2/obj.resMaxDepth^2 * obj.resMaxDepth * (obj.resMaxDepth*obj.depth^2 - obj.depth^3/3); 
      end
      function obj = turbPumpCalc(obj)
            obj.inCoff =  (1 - obj.inEff) * obj.density * 9.806 * (obj.depth + obj.head - obj.riverHeight);
            obj.outCoff = (1 - obj.outEff) * obj.density * 9.806 * (obj.depth + obj.head - obj.riverHeight); % [J/m^3] 
      end
      
      function obj = updateWaterBalance(obj)
           obj = obj.troughDepthCalc();
           obj = obj.troughSurfCalc();
           %obj = obj.depthCalc();
           %obj = obj.surfCalc();
           obj = obj.volCalc();
           %obj = obj.cubicDepthCalc();
           %obj = obj.cubicSurfaceCalc();
           %obj = obj.surfCalc();
           obj = obj.turbPumpCalc();
      end
      function out = outHeatTransfer(obj,tFinal,turb) % watts output
              if turb == true 
                qTurb = obj.outCoff * (obj.outflow + obj.spill); % flow out is neg, so positive spillway does stuff idk man
              else
                qTurb = 0;
              end
              qMix = (obj.temp - tFinal)*-1*obj.outflow*obj.Cp*obj.density; % flow is made positive so heat transfer is pos
              out = obj.tS*(qTurb + qMix);
      end
      function obj = inHeatTransfer(obj,qIn) % watts and volumetric flow Input at output interval
          % qIn is both surface AND 
            qPump = obj.tS*obj.inflow * obj.inCoff;
            obj.temp = obj.temp + (qIn + qPump) / (obj.volume * obj.density * obj.Cp);
      end
      function out = evaporation()
            out = N * u * (es - ea) % coeff * wind in km/day * mb * m, out = cm/day
            % https://www.nrcs.usda.gov/sites/default/files/2023-06/8a_MT_estimation_evaporation_ponds-impound.pdf
            % 
     end
   end
end