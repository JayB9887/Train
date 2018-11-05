%% Header
%  Group: 2         Time: Tues-Thurs
%  Names: Jay, James, Michael, Noah
%Train software design project


clear;
close all;
delete(instrfindall);
clc;
tic();
%% Connect equipment
a = arduino('COM4');
%a = arduino_sim;

%attach servo motor for the gate
a.servoAttach(1);

%setup gate LEDs
a.pinMode(14, 'output');
a.pinMode(15, 'output');

%% Setup before loop

%LED pin numbers
lLed = 14;
rLed = 15;


%beam break sensor pin mumbers
approach = 3;
departure = 2;

%setup motor
a.motorRun(1,'forward');
a.motorSpeed(1, 170);

%Drop gate for safe start
a.servoWrite(1, 170);
%boolean for if gate is down  
gateDown = 1;

%variables to keep track of time delay
approachDelay = 0;
delay2 = 0;

% used to track only one value from sensors
readApproach = 0;
readDeparture = 0;

%used in delay for flashing gate lights
lightDelay = 0;

%boolean to turn lights on and off
leftLightOn = 0;
rightLightOn = 1;

%boolean for if lights should flash
flash = 1;

%% Infinite Loop

while 1
    %Flash lights
    if(flash)
        
        if(toc() - lightDelay > .35)
            leftLightOn = ~leftLightOn;
            rightLightOn = ~rightLightOn;
            a.digitalWrite(lLed, leftLightOn);
            a.digitalWrite(rLed, rightLightOn);
            lightDelay = toc();
        end
    else
        a.digitalWrite(lLed, 0);
        a.digitalWrite(rLed, 0);
    end
    
    %Timing on gate
    if(approachDelay && toc() - approachDelay > 2 && toc() - approachDelay < 5 && ~gateDown)
        a.servoWrite(1, 170);
        gateDown = 1;
    end
    if(approachDelay && toc() - approachDelay > 5 && gateDown)
        a.servoWrite(1, 70);
        gateDown = 0;
        flash = 0;
    end
    
    %checking approach sensor
    if(a.analogRead(approach) > 250 && ~readApproach)
        readDeparture = 0;
        readApproach = 1;
        
        %train entering urban area
        %start flashing lights
        flash = 1;
        
        %slow down train
        a.motorSpeed(1, 170);
        
        %start delay on gate
        approachDelay = toc();
      
    end
    
    
    %checking departure sensor
    if(a.analogRead(departure) > 250 && ~readDeparture)
        %Entering rural area
        readApproach = 0;
        delay2 = toc();
        readDeparture = 1;
        
        %speed up train
        a.motorSpeed(1, 255);
      
        
        %Opening gate and stopping lights after safe start
        if(gateDown)
            a.servoWrite(1, 70);
            gateDown = 0;
            flash = 0;
        end
    end
    
end
    
    
