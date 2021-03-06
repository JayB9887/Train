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

%variable to count how many times it has looped the track
loopCounter = 0;

%% Infinite Loop
%ask user if train is in a rural or urban setting
location = input('Is the train in an urban or rural setting: ', 's');
%verify that the user gave a correct input
while(~strcmp(location, 'urban') && ~strcmp(location, 'rural'))
    location = input('\nInvalid input try again\nIs the train in an urban or rural setting: ', 's');
end
%set gate delay based on user input
if(strcmp(location, 'urban'))
    gateDelay = .9;
elseif(strcmp(location, 'rural'))
    gateDelay = 1.4;
end



%setup motor
a.motorRun(1,'forward');
a.motorSpeed(1, 170);



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
    if(readApproach == 1 && toc() - approachDelay > gateDelay && toc() - approachDelay < 2 && ~gateDown)
        a.servoWrite(1, 170);
        gateDown = 1;
    end
    if(loopCounter >=3)
        %checking if upcoming departure gate is clear
        if(~stopped && readApproach && (toc() - approachDelay) * urbanSpeed > (11.25 * pi) - 4 && a.digitalRead(departureRed))
            a.motorSpeed(1, 0);
            stopped = 1;
        elseif(stopped && readApproach && a.digitalRead(departureRed) == 0)
            a.motorSpeed(1, 170);
            a.motorRun(1, 'forward');
            stopped = 0;
        end
        %checking if upcoming approach gate is clear
        if(~stopped && readDeparture && (toc() - departureDelay) * ruralSpeed > (11.25 * pi) - 4 && a.digitalRead(approachRed))
            a.motorRun(1, 0);
            stopped = 1;
        elseif(readDeparture && stopped && a.digitalRead(approachRed) == 0)
            a.motorSpeed(1, 255);
            a.motorRun(1, 'forward');
            stopped = 0;
        end
    end
    
    %checking approach sensor
    aa = a.analogRead(approach);
    %making sure value is a number and not an array of random characters
    while(length(aa) ~= 1)
        aa = a.analogRead(approach);
    end
    if((aa > 250) && (readApproach == 0))
        %variables to declare which side of the track the train is on
        readDeparture = 0;
        readApproach = 1;
        
        %increment loop counter by one
        loopCounter = loopCounter + 1;
        
        %train entering urban area
        %start flashing lights
        flash = 1;
        
        %slow down train
        a.motorSpeed(1, 170);
        
        %start delay on gate
        approachDelay = toc();
        
         %recording rural speed
        if(departureDelay && (approachDelay - departureDelay) - (1/(ruralSpeed / (11.25 * pi))) < .75)
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
        if(approachDelay && (departureDelay - approachDelay) - (1/(urbanSpeed / (11.25 * pi))) < .75) 
            urbanSpeed = 11.25 * pi / (departureDelay - approachDelay);
        end
        
        
        
        %Opening gate and stopping lights after safe start
        a.servoWrite(1, 70);
        gateDown = 0;
        flash = 0;
    end
    
end
    
    
