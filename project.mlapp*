classdef groupProject < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        GridLayout                    matlab.ui.container.GridLayout
        LeftPanel                     matlab.ui.container.Panel
        CurrentTemperatureGauge       matlab.ui.control.Gauge
        CurrentTemperatureGaugeLabel  matlab.ui.control.Label
        SaveButton_2                  matlab.ui.control.Button
        SaveButton                    matlab.ui.control.Button
        CenterPanel                   matlab.ui.container.Panel
        DigitalClockLabel             matlab.ui.control.Label
        StopPlotButton                matlab.ui.control.Button
        StartPlotButton_2             matlab.ui.control.Button
        UIAxes                        matlab.ui.control.UIAxes
        RightPanel                    matlab.ui.container.Panel
        ManualDayLightSwitch          matlab.ui.control.Switch
        ManualDayLightSwitchLabel     matlab.ui.control.Label
        LightModeSwitch               matlab.ui.control.RockerSwitch
        LightModeSwitchLabel          matlab.ui.control.Label
        ManualNightLightSwitch        matlab.ui.control.Switch
        ManualNightLightSwitchLabel   matlab.ui.control.Label
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
        twoPanelWidth = 768;
    end


    properties (Access = private)
        a; % arduino
        v;
        tempK;
        tempF;
        Plotting = false;
        ClockTimer;
    end

    methods (Access = private)

        % Timer callback function
        function updateClockLabel(app, ~)
            currentTime = datetime('now');
            clockString = datestr(currentTime, 'HH:MM:SS');
            app.DigitalClockLabel.Text = clockString;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.a = arduino;
            % Set the initial clock label text
            app.DigitalClockLabel.Text = '00:00:00';
            updateClockLabel(app);
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
            i = 1;
            while app.Plotting
                app.v = readVoltage(app.a, 'A0');
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
                resRatio = log(resistance ./ ThermistorResistance);
                app.tempK = 1 ./ (A1 + B1 .* resRatio + C1 .* resRatio .^ 2 + D1 .* resRatio .^ 3);
                tempC = app.tempK - 273.15;
                app.tempF = 9/5 * tempC + 32;
                app.CurrentTemperatureGauge.Value = app.tempF;
                plot(app.UIAxes, i, app.tempF,"b*");
                hold(app.UIAxes, "on");
                updateClockLabel(app);
                i = i + 1;
                pause(1);
            end

        end

        % Button pushed function: StopPlotButton
        function StopPlotButtonPushed(app, event)
            app.Plotting = false;
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
            app.SaveButton.FontSize = 18;
            app.SaveButton.Position = [20 282 117 69];
            app.SaveButton.Text = 'Save';

            % Create SaveButton_2
            app.SaveButton_2 = uibutton(app.LeftPanel, 'push');
            app.SaveButton_2.FontSize = 18;
            app.SaveButton_2.Position = [20 188 117 69];
            app.SaveButton_2.Text = 'Save';

            % Create CurrentTemperatureGaugeLabel
            app.CurrentTemperatureGaugeLabel = uilabel(app.LeftPanel);
            app.CurrentTemperatureGaugeLabel.HorizontalAlignment = 'center';
            app.CurrentTemperatureGaugeLabel.Position = [13 395 116 22];
            app.CurrentTemperatureGaugeLabel.Text = 'Current Temperature';

            % Create CurrentTemperatureGauge
            app.CurrentTemperatureGauge = uigauge(app.LeftPanel, 'circular');
            app.CurrentTemperatureGauge.Limits = [-90 120];
            app.CurrentTemperatureGauge.Position = [20 432 103 103];

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
            app.UIAxes.Position = [8 12 680 446];

            % Create StartPlotButton_2
            app.StartPlotButton_2 = uibutton(app.CenterPanel, 'push');
            app.StartPlotButton_2.ButtonPushedFcn = createCallbackFcn(app, @StartPlotButton_2Pushed, true);
            app.StartPlotButton_2.FontSize = 18;
            app.StartPlotButton_2.Position = [27 470 96 70];
            app.StartPlotButton_2.Text = 'Start Plot';

            % Create StopPlotButton
            app.StopPlotButton = uibutton(app.CenterPanel, 'push');
            app.StopPlotButton.ButtonPushedFcn = createCallbackFcn(app, @StopPlotButtonPushed, true);
            app.StopPlotButton.FontSize = 18;
            app.StopPlotButton.Position = [145 470 96 70];
            app.StopPlotButton.Text = 'Stop Plot';

            % Create DigitalClockLabel
            app.DigitalClockLabel = uilabel(app.CenterPanel);
            app.DigitalClockLabel.Position = [313 494 353 41];
            app.DigitalClockLabel.Text = '00:00:00';

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 3;

            % Create ManualNightLightSwitchLabel
            app.ManualNightLightSwitchLabel = uilabel(app.RightPanel);
            app.ManualNightLightSwitchLabel.HorizontalAlignment = 'center';
            app.ManualNightLightSwitchLabel.Position = [8 93 144 22];
            app.ManualNightLightSwitchLabel.Text = 'Manual Night Light Switch';

            % Create ManualNightLightSwitch
            app.ManualNightLightSwitch = uiswitch(app.RightPanel, 'slider');
            app.ManualNightLightSwitch.Position = [46 130 68 30];

            % Create LightModeSwitchLabel
            app.LightModeSwitchLabel = uilabel(app.RightPanel);
            app.LightModeSwitchLabel.HorizontalAlignment = 'center';
            app.LightModeSwitchLabel.Position = [45 457 64 22];
            app.LightModeSwitchLabel.Text = 'Light Mode';

            % Create LightModeSwitch
            app.LightModeSwitch = uiswitch(app.RightPanel, 'rocker');
            app.LightModeSwitch.Items = {'Day', 'Night'};
            app.LightModeSwitch.Orientation = 'horizontal';
            app.LightModeSwitch.Position = [34 497 86 38];
            app.LightModeSwitch.Value = 'Day';

            % Create ManualDayLightSwitchLabel
            app.ManualDayLightSwitchLabel = uilabel(app.RightPanel);
            app.ManualDayLightSwitchLabel.HorizontalAlignment = 'center';
            app.ManualDayLightSwitchLabel.Position = [13 184 137 22];
            app.ManualDayLightSwitchLabel.Text = 'Manual Day Light Switch';

            % Create ManualDayLightSwitch
            app.ManualDayLightSwitch = uiswitch(app.RightPanel, 'slider');
            app.ManualDayLightSwitch.Position = [39 221 83 36];

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
