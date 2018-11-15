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

%attach servo motor for the gate
a.servoAttach(1);

%setup gate LEDs
a.pinMode(14, 'output');
a.pinMode(15, 'output');

%arrival gates
a.pinMode(6, 'output');
a.pinMode(7, 'output');

%departure gates
a.pinMode(8, 'output');
a.pinMode(9, 'output');
%% Setup before loop

%LED pin numbers
lLed = 15;
rLed = 14;
approachRed = 6;
approachGreen = 7;
departureRed = 8;
departureGreen = 9;

%beam break sensor pin mumbers
approach = 2;
departure = 3;

%setup motor
a.motorRun(1,'forward');
a.motorSpeed(1, 170);

%Drop gate for safe start
a.servoWrite(1, 170);
%boolean for if gate is down  
gateDown = 1;

%variables to keep track of time delay
approachDelay = 0;
departureDelay = 0;

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
            if (leftLightOn)
                leftLightOn = 0;
            else
                leftLightOn = 1;
            end
            if(rightLightOn)
                rightLightOn = 0;
            else
                rightLightOn = 1;
            end
            a.digitalWrite(lLed, leftLightOn);
            a.digitalWrite(rLed, rightLightOn);
            lightDelay = toc();
        end
    else
        a.digitalWrite(lLed, 0);
        a.digitalWrite(rLed, 0);
    end
    
    %Timing on gate
    %if 1.2 to 2 seconds have passed after crossing the approach gate and the
    %gate is up, drop the gate
    if(readApproach == 1 && toc() - approachDelay > 1.2 && toc() - approachDelay < 2 && ~gateDown)
        a.servoWrite(1, 170);
        gateDown = 1;
    end
    
    
   
    
    
    %checking approach sensor
    aa = a.analogRead(approach);
    %making sure value is a number and not an array of random characters
    while(length(aa) ~= 1)
        aa = a.analogRead(approach);
    end
    if((aa > 250) && (readApproach == 0))
        readDeparture = 0;
        readApproach = 1;
        
        %train entering urban area
        %start flashing lights
        flash = 1;
        
        %slow down train
        a.motorSpeed(1, 170);
        
        %start delay on gate
        approachDelay = toc();
        
        %recording trainspeed
        if(departureDelay)
            speed = 11.25 * pi / approachDelay - departureDelay;
        end
        
        %change lights on approach/departure gates
        a.digitalWrite(approachRed, 1);
        a.digitalWrite(departureGreen, 1);
        a.digitalWrite(approachGreen, 0);
        a.digitalWrite(departureRed, 0);
    end
    
    
    %checking departure sensor
    if(a.analogRead(departure) > 250 && readDeparture == 0)
        %Entering rural area
        readApproach = 0;
        departureDelay = toc();
        readDeparture = 1;
        
        
        
        %speed up train
        a.motorSpeed(1, 255);
        
        %change lights on approach/departure gates
        a.digitalWrite(approachGreen, 1);
        a.digitalWrite(departureRed, 1);
        a.digitalWrite(approachRed, 0);
        a.digitalWrite(departureGreen, 0);
        
        
        %Opening gate and stopping lights
        a.servoWrite(1, 70);
        gateDown = 0;
        flash = 0;
    end
    
end
    
    
