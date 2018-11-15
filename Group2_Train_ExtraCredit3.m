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
a = arduinoXtra('COM4');
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

%variable to record time it takes to cross the urban area
urbanSpeed = 0;

%variable to record time it takes to cross the rural area
ruralSpeed = 0;

%variable for random sensor led delays
delay = 0;
on = 0;

%variable to check if train is stopped
stopped = 0;

%sets random gate leds
a.randomGateLeds(1);

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
    
    %checking if upcoming departure gate is clear
    if(~stopped && readApproach && a.digitalRead(departureRed) && (toc() - approachDelay) * urbanSpeed > 11.25 * pi - 2)
        a.motorRun(1, 'release');
        stopped = 1;
    elseif(readApproach && a.digitalRead(departureRed) == 0)
        a.motorRun(1, 'forward');
        a.motorSpeed(1, 170);
        stopped = 0;
    end
    %checking if upcoming approach gate is clear
    if(~stopped && readDeparture && a.digitalRead(approachRed) && (toc() - departureDelay) * ruralSpeed > 11.25 * pi - 2)
        a.motorRun(1, 'release');
        stopped = 1;
    elseif(readDeparture && a.digitalRead(approachRed) == 0)
        a.motorRun(1, 'forward');
        a.motorSpeed(1, 255);
        stopped = 0;
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
        
        %recording rural speed
        if(departureDelay)
            ruralSpeed = 11.25 * pi / (approachDelay - departureDelay);
        end
        
    end
    
    
    %checking departure sensor
    bb = a.analogRead(departure);
    %making sure value is a number and not an array of random characters
    while(length(bb) ~= 1)
        bb = a.analogRead(departure);
    end
    if(bb > 250 && ~readDeparture)
        %Entering rural area
        readApproach = 0;
        departureDelay = toc();
        readDeparture = 1;
        
        %speed up train
        a.motorSpeed(1, 255);
        
        %recording urban speed
        if(approachDelay)
            urbanSpeed = 11.25 * pi / (departureDelay - approachDelay);
        end
        
        
        
        %Opening gate and stopping lights after safe start
        a.servoWrite(1, 70);
        gateDown = 0;
        flash = 0;
    end
    
end
    
    
