classdef groupProject < matlab.apps.AppBase

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
        v;
        t;
        tempK;
        tempF;
        Plotting = false;
        ClockTimer;
    end

    methods (Access = private)
        
        function updateClockLabel(app, ~)
            % update the clock label
            currentTime = datetime('now');
            dateTime = datestr(currentTime);
            clockString = datestr(currentTime, 'HH:MM:SS');
            app.DigitalClockLabel.Text = clockString;
            titleStr = strcat("Temperature Vs. Time   ",dateTime);
            app.UIAxes.Title.String = titleStr;
        end
       
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            
            app.a = arduino;

            analogPinlight = 'A1';
            % read the intensity level
            lightLevel = readVoltage(app.a, analogPinlight);
            % the light intensity equal to the light level over 3.3V
            intensity = lightLevel / 3.3;
            app.lightintensityGauge.Value = intensity;

            % Set the initial clock label text
            app.DigitalClockLabel.Text = '00:00:00';

            % create a timer
            timer_clock = timer;
            % set start delay
            timer_clock.StartDelay = 1.0;
            % set period
            timer_clock.Period = 1.0;
            % execution mode set to fixedSpacing mode
            timer_clock.ExecutionMode = 'fixedSpacing';
            % set a the timer_handler function to timer function
            timer_clock.TimerFcn = @timer_handler;
            % start the timer
            start(timer_clock);
            
            % create a timer
            timer_temp = timer;
            % set start delay
            timer_temp.StartDelay = 1.0;
            % set period
            timer_temp.Period = 1.0;
            % execution mode set to fixedSpacing mode
            timer_temp.ExecutionMode = 'fixedSpacing';
            % set a the timer_handler function to timer function
            timer_temp.TimerFcn = @timer_handler_temp_gauge;
            % start the timer
            start(timer_temp);
            
            % create a timer
            timer_LEDtime = timer;
            % set start delay
            timer_LEDtime.StartDelay = 1.0;
            % set period
            timer_LEDtime.Period = 1.0;
            % execution mode set to fixedSpacing mode
            timer_LEDtime.ExecutionMode = 'fixedSpacing';
            % set a the timer_handler function to timer function
            timer_LEDtime.TimerFcn = @timer_updateLEDbyTime;
            % start the timer
            start(timer_LEDtime);

                        % create a timer
            timer_light = timer;
            % set start delay
            timer_light.StartDelay = 0.1;
            % set period
            timer_light.Period = 0.1;
            % execution mode set to fixedSpacing mode
            timer_light.ExecutionMode = 'fixedSpacing';
            % set a the timer_handler function to timer function
            timer_light.TimerFcn = @timer_handler_light;
            % start the timer
            start(timer_light);
            

        function timer_updateLEDbyTime(~, ~)
            % this function check current time and update the automatic day/night mode 
            % switch value to day or night mode.

            % assign current time to a string
            currentTime = datetime('now');
            clockString = datestr(currentTime, 'HH:MM:SS');

            % split the string to get a cell array contaning hour, minutes
            % and seconds. 
            timeCellString = split(clockString, ':');
            % get the hour from the string and convert it to double
            hour = str2double(timeCellString{1});
            % check if hour greater than 6 and less than 18
            if hour > 6 && hour < 18
                app.LightModeSwitch.Value = "Day"; % Set LED color to red in the evening
            else
                app.LightModeSwitch.Value = "Night"; % Set LED color to yellow during the day
            end
        end

        function timer_handler(~,~)
            % Timer handler that updates the time for the app
            currentTime = datetime('now');
            clockString = datestr(currentTime, 'HH:MM:SS');
            app.DigitalClockLabel.Text = clockString;
        end

            function timer_handler_temp_gauge(~, ~)
                %  read the voltage
                analogPinlight = 'A0';
                app.v = readVoltage(app.a, analogPinlight);
                %read by Arduino to a temperature in Kelvin
                SeriesResistor = 10000; % the 10K ohm resistor is used in the circuit
                ThermistorResistance = 10000; %The resistance of thermistor
                %With NTC thermistors, resistance decreases as temperature increases
                resistance = SeriesResistor .* app.v ./ (5 - app.v);
                %Constants used in Steinhart equation
                A1 = 3.354016E-03;
                B1 = 2.569850E-04;
                C1 = 2.620131E-06;
                D1 = 6.383091E-08;
                % calculate the resistance
                resRatio = log(resistance ./ ThermistorResistance);
                % calculate the temperature in Kelvin
                app.tempK = 1 ./ (A1 + B1 .* resRatio + C1 .* resRatio .^ 2 + D1 .* resRatio .^ 3);
                % calculate the temperature in C
                tempC = app.tempK - 273.15;
                % calculate the temperature in F
                app.tempF = 9/5 * tempC + 32;
                % update the gauge value
                app.TemperatureGauge.Value = app.tempF;
                
            end
            
            function timer_handler_light(~,~)
                analogPin = 'A1';
                % read the intensity level
                lightLevel = readVoltage(app.a, analogPin);
                % the light intensity equal to the light level over 3.3V
                intensity = lightLevel / 3.3;
                app.lightintensityGauge.Value = intensity;
                threshold = 0.4; % set an intensity threhold
                minIntensity = 0.01;
                maxIntensity = 0.96;
                % intensity range 0.1-0.9 , 0.1 means low light, 0.9 means high light
                % 0.4 intensity low
                % 0.7 high intensity
                dayLightOut = 'D9';
                nightLightOut = 'D11';
                lightLevel = (1 - intensity + minIntensity) / (maxIntensity - minIntensity);

                if intensity < threshold
                    % turn on the light 
                    % if it's day, turn on day light
                    if app.LightModeSwitch.Value == "Day"
                        writePWMDutyCycle(app.a,dayLightOut, lightLevel);
                        % writeDigitalPin(app.a, dayLightOut, 1);
                    % if it's night, turn on night light
                    end
                    if app.LightModeSwitch.Value == "Night"
                        writePWMDutyCycle(app.a,dayLightOut, lightLevel);
                        % writeDigitalPin(app.a, nightLightOut, 1);
                    end
                else
                    % turn off both light
                    writeDigitalPin(app.a, dayLightOut, 0);
                    writeDigitalPin(app.a, nightLightOut, 0);
                end
            end
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

            % a loop testing for graph.
            app.Plotting = true;
            % set the analogPin
            analogPin = 'A0';
            i = 1;
            % create a infinit loop which Plotting variable is true 
            while app.Plotting
                % read the voltage
                app.v = readVoltage(app.a, analogPin);
                %read by Arduino to a temperature in Kelvin
                SeriesResistor = 10000; % the 10K ohm resistor is used in the circuit
                ThermistorResistance = 10000; %The resistance of thermistor
                %With NTC thermistors, resistance decreases as temperature increases
                resistance = SeriesResistor .* app.v ./ (5 - app.v);
                %Constants used in Steinhart equation
                A1 = 3.354016E-03;
                B1 = 2.569850E-04;
                C1 = 2.620131E-06;
                D1 = 6.383091E-08;
                % calculate the resistance
                resRatio = log(resistance ./ ThermistorResistance);
                % calculate the temperature in Kelvin
                app.tempK = 1 ./ (A1 + B1 .* resRatio + C1 .* resRatio .^ 2 + D1 .* resRatio .^ 3);
                % calculate the temperature in C
                tempC = app.tempK - 273.15;
                % calculate the temperature in F
                app.tempF = 9/5 * tempC + 32;
                % update the gauge value
                app.TemperatureGauge.Value = app.tempF;
                plot(app.UIAxes, i, app.tempF,"b--*");
                hold(app.UIAxes, "on");
                updateClockLabel(app);
                i = i + 1;
            end
            hold(app.UIAxes, "off");
        end

        % Button pushed function: StopPlotButton
        function StopPlotButtonPushed(app, event)
            % set plotting variable to false
            app.Plotting = false;
        end

        % Value changed function: LightModeSwitch
        function LightModeSwitchValueChanged(app, event)
            % this function update the little light color on the app,
            % indicate it's day light mode or night light mode

            % get the value from the automatic day/night light switch
            value = app.LightModeSwitch.Value;

            % if value is day, change the light color to daylight color
            if value == "Day"
                app.LampNight.Color = [1,1,1];
                app.LampDay.Color = [1,1,0];
            end

            % if value is night, change the light color to nightlight color
            if value == "Night"
                app.LampDay.Color = [1,1,1];
                app.LampNight.Color = [1,0,0];
            end
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
                imshow(fid,'Parent',app.UIAxes);

            % delete the file object
            delete(fid);
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
            % delete the new file handle
            delete(new_f_handle);
        end

        % Value changed function: ManualDayLightSwitch
        function ManualDayLightSwitchValueChanged(app, event)
            value = app.ManualDayLightSwitch.Value;
            dayLightOut = 'D9';
            if value == "On"
                writeDigitalPin(app.a, dayLightOut, 1);
                % writeDigitalPin(app.a, dayLightOut, 1);
            end
            if value == "Off"
                writeDigitalPin(app.a, dayLightOut, 0);
            end
        end

        % Value changed function: ManualNightLightSwitch
        function ManualNightLightSwitchValueChanged(app, event)
            value = app.ManualNightLightSwitch.Value;
            nightLightOut = 'D11';
            if value == "On"
                writeDigitalPin(app.a, nightLightOut, 1);
            end
            if value == "Off"
                writeDigitalPin(app.a, nightLightOut, 0);
            end
        end

        % Value changed function: automaticlightswitchSwitch
        function automaticlightswitchSwitchValueChanged(app, event)
            value = app.automaticlightswitchSwitch.Value;
           
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
            app.UIAxes.YLim = [50 90];
            app.UIAxes.ButtonDownFcn = createCallbackFcn(app, @UIAxesButtonDown2, true);
            app.UIAxes.Position = [8 12 680 467];

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
            app.lightintensityGaugeLabel.Position = [364 480 76 22];
            app.lightintensityGaugeLabel.Text = 'light intensity';

            % Create lightintensityGauge
            app.lightintensityGauge = uigauge(app.CenterPanel, 'linear');
            app.lightintensityGauge.Limits = [0 1];
            app.lightintensityGauge.Position = [86 501 590 41];

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
        function app = groupProject

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
