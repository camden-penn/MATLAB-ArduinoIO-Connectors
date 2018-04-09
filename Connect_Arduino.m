%Function Connect_Arduino
%Authors: Camden Penn, Dr. Neil Moore, Dr. Laura Letellier
%Last code revision: 2/28/18
%Last comment revision: 3/26/18

%------------- USAGE -------------
%
% In this section, text in [square brackets]
% is a placeholder for stuff that's up to you.
%
% At top of script, include the following line:
% Connect_Arduino([optional args]);
%
% If you are using a Stepper object:
%   Before the line with Connect_Arduino(), type the following:
%   clear [name of Stepper];
%
% ----------------------------------------------------------------------------
% Optional args, in the order they appear, are as follows:
% name:        A string which is the name you want to give the Arduino.
%              Default: 'a'.
%
% port:        A string listing the COM (or /dev/tty/usbmodem ... on Mac) port
%                       on which the Arduino can be found.
%              Default: attempts to find any connected Arduino, using the first
%                       valid port it can find.
%
% board:       A string describing the type of Arduino that is being connected.
%              Default: 'uno'.
%
% libraryList: A cell array of the libraries you want the Arduino to use.
%                       Used _extremely_ rarely.
%              Default: {'I2C','Servo','SPI'}.
%-------------------------------------------------------------------------------

%This function will connect an Arduino object without fuss.
%Please do not touch.
%Also, please do not use any of the underhanded tricks contained herein.
%For your own sake.

function Connect_Arduino(name, port, board, libraryList)
    %No name? Name is 'a'.
    if(nargin<1)
        name = 'a';
    end
    %Name is invalid? Clean it up.
    tmpName = matlab.lang.makeValidName(name,'ReplacementStyle','delete','Prefix','a');
    if(~strcmp(name, tmpName))
        %The name needed cleaning - tell user about the change.
        fprintf('"%s" is not a valid name. Using "%s" instead.\n',name, tmpName);
        name = tmpName;
    end
    clear('tmpName');
    
    %No port? Find one.
    if(nargin<2)
        isConnected = true;
        fprintf('Searching for available Arduino... ');
        try(evalin('base',[name ' = arduino();']));
        %If it breaks, it's probably already connected.
        %For future reference, extract the port tried from the error
        %message.
        catch e
            
            if(strcmpi(e.identifier,'MATLAB:arduinoio:general:openFailed'))
                i = 28;
                port = e.message(i);
                i = i+1;
                while ~strcmpi(e.message(i),' ')
                    port = strcat(port, e.message(i));
                    i = i+1;
                end
                if(strcmp(port, 'at'))
                    i=43;
                    port = e.message(i);
                    i = i+1;
                    while ~strcmpi(e.message(i),' ')&&~strcmpi(e.message(i),'.')
                        port = strcat(port, e.message(i));
                        i = i+1;
                    end
                end
            elseif(strcmpi(e.identifier,'MATLAB:arduinoio:general:connectionExists'))
                i=37;
                port=e.message(i);
                i=i+1;
                while(~strcmpi(e.message(i),' '))
                    port=strcat(port,e.message(i));
                    i=i+1;
                end
            else
            %It's an error I haven't handled - throw it.
                throwAsCaller(e);
            end
            isConnected = false;
            fprintf('Found');
        end
        if(isConnected)
        %If it doesn't break, get info from constructed object.
            port = evalin('base',[name '.Port;']);
            board = evalin('base',[name '.Board;']);
            fprintf('Connected');
        end
    fprintf(' on port %s.\n',port);
    end
    
    %Deal with little-used argument defaults.
    if(nargin<3)
        board = 'Uno';
    end
    if(nargin<4)
        libraryList = {'I2C','Servo','SPI'};
    end
    
    nameChangeCheck(name, port, board);
    
    if(evalin('base',sprintf('exist(''%s'',''var'')',name))&&isa(evalin('base',name),'arduino'))
        %Make a dummy var to test the connection.
        C = evalin('base','who');
        C{end+1} = 'x';
        C = matlab.lang.makeUniqueStrings(C);
        dummyVar=C{end};
        %Test the connection.
        try(evalin('base',[ C{end} ' =' name '.readVoltage(''A0'');']));
        catch e
            if(strcmpi(e.identifier,'MATLAB:arduinoio:general:connectionIsLost'))
                disp('Bad connection. Clearing and retrying.');
                evalin('base',sprintf('clear(''%s'')',name));
                
                C = evalin('base','who');
                for i=1:length(C)
                    %For all vars in the workspace
                    if (isa(evalin('base',[C{i} ';']),'arduinoio.Servo'))
                        %If the item is an Arduino servo
                        try(evalin('base',[ C{i} '.readPosition();']));
                        catch error
                            if(strcmpi(error.identifier,'MATLAB:arduinoio:general:connectionIsLost'))
                                %Servo has a broken connection - wipe it.
                                %disp(C{i});
                                evalin('base',sprintf('clear(''%s'')',C{i}));
                            else
                                %It's an error I haven't handled - throw
                                %it.
                                throwAsCaller(error);
                            end
                        end
                    end
                end
            end
        end
        %Trash dummy var.
        evalin('base',['clear(''' dummyVar ''')']);
        
    end
    %If the Arduino doesn't exist, make it.
    if(~(evalin('base',sprintf('exist(''%s'',''var'')',name))&&isa(evalin('base',name),'arduino')))
        fprintf('Arduino ''%s'' now connecting... ',name);
        %Assemble string to use in evalin relating to the library list.
        libraryString = '{';
        for i = 1:length(libraryList)
            libraryString = sprintf('%s,''%s''',libraryString,libraryList{i});
        end
        libraryString = sprintf('%s}',libraryString);
        %Try to connect the Arduino.
        try(evalin('base',sprintf('%s= arduino(''%s'',''%s'', ''Libraries'',%s);', name,port,board,libraryString)));
        catch e
            if(strcmpi(e.identifier,'MATLAB:arduinoio:general:openFailed'))
                %This error probably means the Arduino isn't plugged in,
                %but the default message sucks. This throws a more useful
                %error instead.
                fprintf('\n');
                error('MATLAB:arduinoio:connect_arduino:openFailed','Failed to open serial port %s to communicate with board %s. Please make sure the Arduino is plugged into the computer.',port,board);
            else
                %The error isn't handled - throw it.
                throwAsCaller(e);
            end
        end
        disp('Connected.');
    end
    %If Connect_Arduino was called from inside a function, copy the object 
    %from the base workspace to the function workspace. 
    a=evalin('base',sprintf('%s;',name));
    assignin('caller',name,a);
end

%Checks whether the Arduino already exists with a different name - if so,
%just reassign var to the new name.
function nameChangeCheck(name,port,board)
    C = evalin('base','who');
    for i=1:length(C)
        %For all vars in the workspace
        if (isa(evalin('base',[C{i} ';']),'arduino'))
            %If the item is an Arduino object
            if(strcmpi(evalin('base',[C{i} '.Port']),port)&&strcmpi(evalin('base',[C{i} '.Board']),board)&&~strcmpi(C{i},name))
                %If the port and board are identical, but the names are different
                
                %Make new name var reference the Arduino.
                evalin('base',[name '=' C{i} ';']);
                %Delete old var name.
                evalin('base',sprintf('clear(''%s'')',C{i}));
            end
        end
    end
end

%If you are still reading this, you probably know precisely why I said these
%functions are full of 'underhanded tricks'.
%It's nothing more than an elaborate hack. I'm sorry.
%This was the cleanest user interface I could think of, but it needs these tricks to work.
% -Camden