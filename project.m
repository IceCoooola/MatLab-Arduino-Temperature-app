classdef group10_Dee_Shokuh_Behishta < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        LeftPanel                    matlab.ui.container.Panel
        StopPlotButton               matlab.ui.control.Button
        StartPlotButton_2            matlab.ui.control.Button
        TemperatureGauge             matlab.ui.control.Gauge
        TemperatureGaugeLabel        matlab.ui.control.Label
        OpenButton                   matlab.ui.control.Button
        SaveButton                   matlab.ui.control.Button
        CenterPanel                  matlab.ui.container.Panel
        lightintensityGauge          matlab.ui.control.LinearGauge
        lightintensityGaugeLabel     matlab.ui.control.Label
        CurrenttimeLabel             matlab.ui.control.Label
        DigitalClockLabel            matlab.ui.control.Label
        UIAxes                       matlab.ui.control.UIAxes
        RightPanel                   matlab.ui.container.Panel
        automaticlightswitchSwitch   matlab.ui.control.ToggleSwitch
        automaticlightswitchSwitchLabel  matlab.ui.control.Label
        LightButton                  matlab.ui.control.StateButton
        LampNight                    matlab.ui.control.Lamp
        LampDay                      matlab.ui.control.Lamp
        ManualDayLightSwitch         matlab.ui.control.Switch
        ManualDayLightSwitchLabel    matlab.ui.control.Label
        LightModeSwitch              matlab.ui.control.RockerSwitch
        LightModeSwitchLabel         matlab.ui.control.Label
        ManualNightLightSwitch       matlab.ui.control.Switch
        ManualNightLightSwitchLabel  matlab.ui.control.Label
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
    end


    properties (Access = private)
        a; % arduino
        t;
        tempF;
        ClockTimer;
        TempPlottingTimer; % a temperature plotting timer
        DigitalClockTimer; % a digital clock timer
        tempGaugeTimer; % a temperature gauge timer
        automaticLightSwitch; % an automatic light switch timer
        lightIntensityTimer; % a light intensity timer 
        hour;
        i = 1; % counter for temperature plotting
    end

    methods (Access = public)
        function TempPlottingTimerCallback(app, obj, event)  
            % temperature plotting call back function
            % when start the timer, this function run 2 times per seconds.
            % set the Y axis limit to manual
            app.UIAxes.YLimMode = "manual";
            % set the x axis limit to auto
            app.UIAxes.XLimMode = "auto";
            % set the y lower limit to 50 and upper limit to 90
            app.UIAxes.YLim = [50, 90];
            plot(app.UIAxes, app.i,app.tempF,"b*");
            hold(app.UIAxes, "on");
            app.i = app.i + 1;
        end

        function TempPlottingTimerStopFunc(app, obj, event)  
            % change back the UI figure to auto limit mode
          
            % set the x axis limit to auto
           app.UIAxes.XLimMode = "auto";
           % reset i
           app.i = 1;
           % hold off the graph
           hold(app.UIAxes, "off");
        end

        function DigitalClockTimerCallback(app, obj, event)
            % this function update the current time clock and plot title
            % clock

            % get today's current date and time
            currentTime = datetime('now');
            % get the time 
            clockString = datestr(currentTime, 'HH:MM:SS');
            % make today's date and time to a string
            currentDateTime = datestr(currentTime);
            % update the digital clock label
            app.DigitalClockLabel.Text = clockString;
            % split the time string hour, min, sec
            timeCellString = split(clockString, ':');
            % save today's hour into hour variable.
            app.hour = str2double(timeCellString{1});
            % concat the title string
            titleStr = strcat("Temperature Vs. Time   ", currentDateTime);
            % update the plot title string
            app.UIAxes.Title.String = titleStr;
        end

        function tempGaugeTimerCallback(app, obj, event)
                % this function read current temperature when timer is
                % start

                %  read the voltage
                analogPinlight = 'A0';
                v = readVoltage(app.a, analogPinlight);
                %read by Arduino to a temperature in Kelvin
                SeriesResistor = 10000; % the 10K ohm resistor is used in the circuit
                ThermistorResistance = 10000; %The resistance of thermistor
                %With NTC thermistors, resistance decreases as temperature increases
                resistance = SeriesResistor .* v ./ (5 - v);
                %Constants used in Steinhart equation
                A1 = 3.354016E-03;
                B1 = 2.569850E-04;
                C1 = 2.620131E-06;
                D1 = 6.383091E-08;
                % calculate the resistance
                resRatio = log(resistance ./ ThermistorResistance);
                % calculate the temperature in Kelvin
                tempK = 1 ./ (A1 + B1 .* resRatio + C1 .* resRatio .^ 2 + D1 .* resRatio .^ 3);
                % calculate the temperature in C
                tempC = tempK - 273.15;
                % calculate the temperature in F
                app.tempF = 9/5 * tempC + 32;
                % update the gauge value
                app.TemperatureGauge.Value = app.tempF;
        end

        function automaticLightSwitchTimerCallback(app, obj, event)
            % this function check current time and update the automatic day/night mode 
            % switch value to day or night mode, and the app lamp to yellow or red.

            % check if hour greater than 6 and less than 18, if it is day time
             if app.hour > 6 && app.hour < 18
                app.LightModeSwitch.Value = "Day"; % Set LED color to yellow during the day
                % set the lamp to yellow
                app.LampNight.Color = [1,1,1]; 
                app.LampDay.Color = [1,1,0];
            else
                app.LightModeSwitch.Value = "Night"; % Set LED color to red in the evening
                % set the lamp to red
                app.LampDay.Color = [1,1,1]; 
                app.LampNight.Color = [1,0,0];
            end
        end

        function lightIntensityTimerCallback(app, obj, event)
            % this function will read light intensity and decide to turn on
            % or off the light.
            analogPin = 'A1';
            maxVoltage = 3.3;
            % read the intensity level
            lightVoltage = readVoltage(app.a, analogPin);
            % the light intensity equal to the light level over 3.3V
            intensity = lightVoltage / maxVoltage;
            app.lightintensityGauge.Value = intensity;
            threshold = 0.25; % set an intensity threhold
            dayLightOut = 'D9';
            nightLightOut = 'D11';
            lightLevel = (threshold - intensity) * (1 - threshold - intensity);

            if intensity < threshold
                % turn on the light 
                % if it's day, turn on day light
                if app.LightModeSwitch.Value == "Day"
                    writePWMDutyCycle(app.a,dayLightOut, lightLevel);
                    % writeDigitalPin(app.a, dayLightOut, 1);
                % if it's night, turn on night light
                end
                if app.LightModeSwitch.Value == "Night"
                    writePWMDutyCycle(app.a,nightLightOut, lightLevel);
                end
            else
                % turn off both light
                writeDigitalPin(app.a, dayLightOut, 0);
                writeDigitalPin(app.a, nightLightOut, 0);
            end
         end
        function lightIntensityTimerStopFcn(app, obj, event)
            % this timer function check the light intensity each seconds 
            % and turn or off the light

            dayLightOut = 'D9';
            nightLightOut = 'D11';
            % turn off both light
            writeDigitalPin(app.a, dayLightOut, 0);
            writeDigitalPin(app.a, nightLightOut, 0);
        end
    end
    

    methods (Access = private)
        
        
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            % set up the arduino
            app.a = arduino;
            
            
            % create a temperature plotting timer. timer run 2 times per seconds. 
            app.TempPlottingTimer = timer('Period',0.5,'ExecutionMode','fixedSpacing','TasksToExecute', Inf);
            app.TempPlottingTimer.TimerFcn = {@app.TempPlottingTimerCallback};
            app.TempPlottingTimer.stopFcn = {@app.TempPlottingTimerStopFunc};
            
            % create a light intensity read and turn on/off light timer. timer run 10 times per seconds. 
            app.lightIntensityTimer = timer('Period',0.1,'ExecutionMode','fixedSpacing','TasksToExecute', Inf);
            app.lightIntensityTimer.TimerFcn = {@app.lightIntensityTimerCallback};
            app.lightIntensityTimer.stopFcn = {@app.lightIntensityTimerStopFcn};
            
            % create a digital clock timer. timer run 1 times per seconds. 
            app.DigitalClockTimer = timer('Period',1,'ExecutionMode','fixedSpacing','TasksToExecute', Inf);
            app.DigitalClockTimer.TimerFcn = {@app.DigitalClockTimerCallback};
            start(app.DigitalClockTimer);
            
            % create a temperature gauge timer. timer run 10 times per seconds. 
            app.tempGaugeTimer = timer('Period',0.1,'ExecutionMode','fixedSpacing','TasksToExecute', Inf);
            app.tempGaugeTimer.TimerFcn = {@app.tempGaugeTimerCallback};
            start(app.tempGaugeTimer);
            
            % create a automatic light switch timer. timer run 1 time per ten seconds. 
            app.automaticLightSwitch = timer('Period',10,'ExecutionMode','fixedSpacing','TasksToExecute', Inf);
            app.automaticLightSwitch.TimerFcn = {@app.automaticLightSwitchTimerCallback};
            start(app.automaticLightSwitch);
            
            
        end

        % Callback function
        function UIAxesButtonDown(app, event)

        end

        % Button down function: CenterPanel
        function CenterPanelButtonDown(app, event)

        end

        % Button down function: UIAxes
        function UIAxesButtonDown2(app, event)

        end

        % Button pushed function: StartPlotButton_2
        function StartPlotButton_2Pushed(app, event)
           % this function check if start button pushed, start plot the
           % graph

            %reset the graph and start the temperature plotting timer.
            cla(app.UIAxes, "reset");
            start(app.TempPlottingTimer);
        end

        % Button pushed function: StopPlotButton
        function StopPlotButtonPushed(app, event)
            % this function check if stop button is pushed, stop plot the
            % graph.

            % stop the timer
            stop(app.TempPlottingTimer);
            
        end

        % Value changed function: LightModeSwitch
        function LightModeSwitchValueChanged(app, event)

        end

        % Value changed function: LightButton
        function LightButtonValueChanged(app, event)
            % this function enable every function and light mode
            % get the value of light button
            value = app.LightButton.Value;
            % if it's on
            if value == true
                % enable the manual switch
                app.ManualDayLightSwitch.Enable = "on";
                app.ManualNightLightSwitch.Enable = "on";
                app.automaticlightswitchSwitch.Enable = "on";
            else
                % disable the manual switch
                app.ManualDayLightSwitch.Enable = "off";
                app.ManualNightLightSwitch.Enable = "off";
                app.automaticlightswitchSwitch.Enable = "off";
            end

        end

        % Button pushed function: OpenButton
        function OpenButtonPushed(app, event)
            % this function determine the open button pushed event

            % open the file
            fid = uigetfile({'*.jpg';'*.bmp'});

            % if file is open
            if fid ~= 0
                app.UIAxes.YLimMode = "auto";
                imshow(fid,'Parent',app.UIAxes);

            % delete the file object
            end
        
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            % this function determine the save button pushed event

            % create a new file handle
            new_f_handle = figure('visible','off');
            % copy the object and save to new_axes
            new_axes = copyobj(app.UIAxes, new_f_handle); 
            % set the new axies
            set(new_axes,'units','default','position','default');
            % save the file
            [filename,pathname, fileindex]=uiputfile({'*.jpg';'*.bmp'},'save picture as');
            % if no file name input
            if ~filename
                return
            % if filename input
            else
            % make the file name and path together
            file=strcat(pathname,filename);
            
            % save the file to different type by different choice
            switch fileindex
            case 1
                print(new_f_handle,'-djpeg',file);
            case 2
                print(new_f_handle,'-dbmp',file);
            end
            end
        end

        % Value changed function: ManualDayLightSwitch
        function ManualDayLightSwitchValueChanged(app, event)
            % this function check the manual day light switch changed and
            % turn on or off the light 
            value = app.ManualDayLightSwitch.Value;
            dayLightOut = 'D9';
      
            % is switch is on, turn on the light 
            if value == "On"
                app.automaticlightswitchSwitch.Enable = "off";
                writeDigitalPin(app.a, dayLightOut, 1);
            end
            % if switch is off, turn off the light 
            if value == "Off"
                app.automaticlightswitchSwitch.Enable = "on";
                writeDigitalPin(app.a, dayLightOut, 0);
            end
        end

        % Value changed function: ManualNightLightSwitch
        function ManualNightLightSwitchValueChanged(app, event)
            % this function check the manual night light switch changed and
            % turn on or off the light 
            value = app.ManualNightLightSwitch.Value;
            nightLightOut = 'D11';
            % is switch is on, turn on the light 
            if value == "On"
                app.automaticlightswitchSwitch.Enable = "off";
                writeDigitalPin(app.a, nightLightOut, 1);
            end
            % if switch is off, turn off the light 
            if value == "Off"
                app.automaticlightswitchSwitch.Enable = "on";
                writeDigitalPin(app.a, nightLightOut, 0);
            end
        end

        % Value changed function: automaticlightswitchSwitch
        function automaticlightswitchSwitchValueChanged(app, event)
            value = app.automaticlightswitchSwitch.Value;
            
            % if the automatic switch is on, turn off manual switch
            if value == "On"
                app.ManualDayLightSwitch.Enable = "off";
                app.ManualNightLightSwitch.Enable = "off";
                start(app.lightIntensityTimer);
            end
            % if the automatic switch is off, turn on manual switch
            if value == "Off"
                app.ManualDayLightSwitch.Enable = "on";
                app.ManualNightLightSwitch.Enable = "on";
                stop(app.lightIntensityTimer);
            end
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            stop(app.DigitalClockTimer);
            stop(app.tempGaugeTimer);
            stop(app.automaticLightSwitch);
            delete(app);
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 3x1 grid
                app.GridLayout.RowHeight = {559, 559, 559};
                app.GridLayout.ColumnWidth = {'1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 1;
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 3;
                app.RightPanel.Layout.Column = 1;
            elseif (currentFigureWidth > app.onePanelWidth && currentFigureWidth <= app.twoPanelWidth)
                % Change to a 2x2 grid
                app.GridLayout.RowHeight = {559, 559};
                app.GridLayout.ColumnWidth = {'1x', '1x'};
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = [1,2];
                app.LeftPanel.Layout.Row = 2;
                app.LeftPanel.Layout.Column = 1;
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 2;
            else
                % Change to a 1x3 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {158, '1x', 160};
                app.LeftPanel.Layout.Row = 1;
                app.LeftPanel.Layout.Column = 1;
                app.CenterPanel.Layout.Row = 1;
                app.CenterPanel.Layout.Column = 2;
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 3;
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Position = [100 100 1018 559];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {158, '1x', 160};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create SaveButton
            app.SaveButton = uibutton(app.LeftPanel, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.FontSize = 18;
            app.SaveButton.Position = [20 313 117 69];
            app.SaveButton.Text = 'Save';

            % Create OpenButton
            app.OpenButton = uibutton(app.LeftPanel, 'push');
            app.OpenButton.ButtonPushedFcn = createCallbackFcn(app, @OpenButtonPushed, true);
            app.OpenButton.FontSize = 18;
            app.OpenButton.Position = [20 221 117 69];
            app.OpenButton.Text = 'Open';

            % Create TemperatureGaugeLabel
            app.TemperatureGaugeLabel = uilabel(app.LeftPanel);
            app.TemperatureGaugeLabel.HorizontalAlignment = 'center';
            app.TemperatureGaugeLabel.Position = [40 395 72 22];
            app.TemperatureGaugeLabel.Text = 'Temperature';

            % Create TemperatureGauge
            app.TemperatureGauge = uigauge(app.LeftPanel, 'circular');
            app.TemperatureGauge.Limits = [50 95];
            app.TemperatureGauge.Position = [25 432 103 103];

            % Create StartPlotButton_2
            app.StartPlotButton_2 = uibutton(app.LeftPanel, 'push');
            app.StartPlotButton_2.ButtonPushedFcn = createCallbackFcn(app, @StartPlotButton_2Pushed, true);
            app.StartPlotButton_2.FontSize = 18;
            app.StartPlotButton_2.Position = [23 130 114 64];
            app.StartPlotButton_2.Text = 'Start Plot';

            % Create StopPlotButton
            app.StopPlotButton = uibutton(app.LeftPanel, 'push');
            app.StopPlotButton.ButtonPushedFcn = createCallbackFcn(app, @StopPlotButtonPushed, true);
            app.StopPlotButton.FontSize = 18;
            app.StopPlotButton.Position = [25 26 112 70];
            app.StopPlotButton.Text = 'Stop Plot';

            % Create CenterPanel
            app.CenterPanel = uipanel(app.GridLayout);
            app.CenterPanel.ButtonDownFcn = createCallbackFcn(app, @CenterPanelButtonDown, true);
            app.CenterPanel.Layout.Row = 1;
            app.CenterPanel.Layout.Column = 2;

            % Create UIAxes
            app.UIAxes = uiaxes(app.CenterPanel);
            title(app.UIAxes, 'Temperature Vs. Time')
            xlabel(app.UIAxes, 'Time (seconds)')
            ylabel(app.UIAxes, 'Temperature (°F)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @UIAxesButtonDown2, true);
            app.UIAxes.Position = [8 6 668 462];

            % Create DigitalClockLabel
            app.DigitalClockLabel = uilabel(app.CenterPanel);
            app.DigitalClockLabel.Position = [15 497 72 22];
            app.DigitalClockLabel.Text = '00:00:00';

            % Create CurrenttimeLabel
            app.CurrenttimeLabel = uilabel(app.CenterPanel);
            app.CurrenttimeLabel.Position = [12 518 71 22];
            app.CurrenttimeLabel.Text = 'Current time';

            % Create lightintensityGaugeLabel
            app.lightintensityGaugeLabel = uilabel(app.CenterPanel);
            app.lightintensityGaugeLabel.HorizontalAlignment = 'center';
            app.lightintensityGaugeLabel.Position = [276 533 163 22];
            app.lightintensityGaugeLabel.Text = 'light intensity';

            % Create lightintensityGauge
            app.lightintensityGauge = uigauge(app.CenterPanel, 'linear');
            app.lightintensityGauge.Limits = [0 1];
            app.lightintensityGauge.Position = [85 493 590 41];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create ManualNightLightSwitchLabel
            app.ManualNightLightSwitchLabel = uilabel(app.RightPanel);
            app.ManualNightLightSwitchLabel.HorizontalAlignment = 'center';
            app.ManualNightLightSwitchLabel.Enable = 'off';
            app.ManualNightLightSwitchLabel.Position = [8 21 144 22];
            app.ManualNightLightSwitchLabel.Text = 'Manual Night Light Switch';

            % Create ManualNightLightSwitch
            app.ManualNightLightSwitch = uiswitch(app.RightPanel, 'slider');
            app.ManualNightLightSwitch.ValueChangedFcn = createCallbackFcn(app, @ManualNightLightSwitchValueChanged, true);
            app.ManualNightLightSwitch.Enable = 'off';
            app.ManualNightLightSwitch.Position = [46 58 68 30];

            % Create LightModeSwitchLabel
            app.LightModeSwitchLabel = uilabel(app.RightPanel);
            app.LightModeSwitchLabel.HorizontalAlignment = 'center';
            app.LightModeSwitchLabel.Enable = 'off';
            app.LightModeSwitchLabel.Position = [46 184 64 22];
            app.LightModeSwitchLabel.Text = 'Light Mode';

            % Create LightModeSwitch
            app.LightModeSwitch = uiswitch(app.RightPanel, 'rocker');
            app.LightModeSwitch.Items = {'Day', 'Night'};
            app.LightModeSwitch.Orientation = 'horizontal';
            app.LightModeSwitch.ValueChangedFcn = createCallbackFcn(app, @LightModeSwitchValueChanged, true);
            app.LightModeSwitch.Enable = 'off';
            app.LightModeSwitch.Position = [35 224 86 38];
            app.LightModeSwitch.Value = 'Day';

            % Create ManualDayLightSwitchLabel
            app.ManualDayLightSwitchLabel = uilabel(app.RightPanel);
            app.ManualDayLightSwitchLabel.HorizontalAlignment = 'center';
            app.ManualDayLightSwitchLabel.Enable = 'off';
            app.ManualDayLightSwitchLabel.Position = [13 100 137 22];
            app.ManualDayLightSwitchLabel.Text = 'Manual Day Light Switch';

            % Create ManualDayLightSwitch
            app.ManualDayLightSwitch = uiswitch(app.RightPanel, 'slider');
            app.ManualDayLightSwitch.ValueChangedFcn = createCallbackFcn(app, @ManualDayLightSwitchValueChanged, true);
            app.ManualDayLightSwitch.Enable = 'off';
            app.ManualDayLightSwitch.Position = [39 137 83 36];

            % Create LampDay
            app.LampDay = uilamp(app.RightPanel);
            app.LampDay.Position = [21 185 20 20];
            app.LampDay.Color = [1 1 0];

            % Create LampNight
            app.LampNight = uilamp(app.RightPanel);
            app.LampNight.Position = [113 185 20 20];
            app.LampNight.Color = [1 1 1];

            % Create LightButton
            app.LightButton = uibutton(app.RightPanel, 'state');
            app.LightButton.ValueChangedFcn = createCallbackFcn(app, @LightButtonValueChanged, true);
            app.LightButton.Text = 'Light';
            app.LightButton.Position = [30 518 100 23];

            % Create automaticlightswitchSwitchLabel
            app.automaticlightswitchSwitchLabel = uilabel(app.RightPanel);
            app.automaticlightswitchSwitchLabel.HorizontalAlignment = 'center';
            app.automaticlightswitchSwitchLabel.Enable = 'off';
            app.automaticlightswitchSwitchLabel.Position = [19 285 123 22];
            app.automaticlightswitchSwitchLabel.Text = 'automatic light switch';

            % Create automaticlightswitchSwitch
            app.automaticlightswitchSwitch = uiswitch(app.RightPanel, 'toggle');
            app.automaticlightswitchSwitch.ValueChangedFcn = createCallbackFcn(app, @automaticlightswitchSwitchValueChanged, true);
            app.automaticlightswitchSwitch.Enable = 'off';
            app.automaticlightswitchSwitch.Position = [70 343 20 45];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = group10_Dee_Shokuh_Behishta

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
