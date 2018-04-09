
%Function Connect_Arduino
%Authors: Camden Penn, Dr. Neil Moore, Dr. Laura Letellier
%Last revision: 3/26/18

%------------- USAGE -------------
%
% In this section, text in [square brackets]
% is a placeholder for stuff that's up to you.
%
% At top of script, after Connect_Arduino(), include the following line:
% Connect_Servo([servo name],[Arduino name],[seervo pin],[optional args]);
%
% ----------------------------------------------------------------------------
% Required args are as follows:
% name: A string which is the name you want to give the Servo, eg. 's1'.
% 
% targetArduino: A string which names the Arduino that is using the servo.
%                Usually 'a'.
% 
% pin: The digital pin that the servo is connected to on the Arduino, eg.
%      'D9'.
% Optional args, in the order they appear, are as follows:
% minPulseDuration: The minimum time in seconds that a pulse will last, in seconds.
%                   Default: 700e-6.
%
% maxPulseDuration: The maximum duration taht a pulse will last, in
%                   seconds.
%                   Default: 2300e-6.
%
%-------------------------------------------------------------------------------

%This function will connect an Arduino servo object without fuss.
%Please do not touch.
%Also, please do not use any of the underhanded tricks contained herein.
%For your own sake.

function Connect_Servo(name, targetArduino,pin, minPulseDuration, maxPulseDuration)
    tmpName = matlab.lang.makeValidName(name,'ReplacementStyle','delete');
    if(~strcmp(name, tmpName))
        fprintf('"%s" is not a valid name. Using "%s" instead.\n',name, tmpName);
        name = tmpName;
    end
    clear('tmpName');
    if(nargin<5)
        maxPulseDuration = 2300*10^-6;
    end
    if(nargin<4)
        minPulseDuration = 700*10^-6;
    end
    
    nameChangeCheck(name, targetArduino,pin);
    
    if(evalin('base',sprintf('exist(''%s'',''var'')',name))&&isa(evalin('base',name),'arduinoio.Servo'))
        C = evalin('base','who');
        C{end+1} = 'x';
        C = matlab.lang.makeUniqueStrings(C);
        try(evalin('base',[ C{end} ' =' name '.readPosition();']));
        catch e
            if(strcmpi(e.identifier,'MATLAB:arduinoio:general:connectionIsLost'))
                evalin('base',sprintf('clear(''%s'')',name));
            else
                throwAsCaller(e);
            end
        end
        evalin('base',['clear(''' C{end} ''')']);
        
    end
    if(~(evalin('base',sprintf('exist(''%s'',''var'')',name))&&isa(evalin('base',name),'arduinoio.Servo')))
        fprintf('Servo ''%s'' now connecting... ',name);
        evalin('base',sprintf('%s= servo(%s,''%s'', ''MinPulseDuration'',%f, ''MaxPulseDuration'',%f);', name,targetArduino,pin,minPulseDuration, maxPulseDuration));
        disp('Connected.');
    end
    %If Connect_Servo was called from inside a function, copy the object 
    %from the base workspace to the function workspace. 
    s=evalin('base',sprintf('%s;',name));
    assignin('caller',name,s);
end
function nameChangeCheck(name,targetArduino,pin)
    C = evalin('base','who');
    for i=1:length(C)
        if (isa(evalin('base',[C{i} ';']),'arduinoio.Servo'))
            if(strcmpi(evalin('base',[C{i} '.Pins']),pin)&&~strcmpi(C{i},name))
                if(isSameArduino(evalin('base',[C{i} '.Parent']),targetArduino))
                    evalin('base',[name '=' C{i} ';']);
                    evalin('base',sprintf('clear(''%s'')',C{i}));
                end
            end
        end
    end
end
function decision = isSameArduino(a,b)
    if(isa(a,'arduino')&&isa(b,'arduino'))
        if(strcmpi(a.Port,b.Port)&&strcmpi(a.Board,b.Board))
            decision = true;
        else
            decision = false;
        end
    else
        decision = false;
    end
end
%If you are reading this, you probably know precisely why I said these
%functions are full of 'underhanded tricks'. I'm sorry.
%This was the cleanest user interface I could think of, but it needed those tricks to work.