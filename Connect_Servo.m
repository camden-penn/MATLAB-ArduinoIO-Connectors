
%Function Connect_Arduino
%Authors: Camden Penn, Dr. Neil Moore, Dr. Laura Letellier
%Last revision: 3/7/17

%This function will connect an Arduino object without fuss.
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