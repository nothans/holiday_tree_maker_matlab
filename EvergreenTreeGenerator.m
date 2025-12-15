classdef EvergreenTreeGenerator < matlab.apps.AppBase
    % EVERGREENTREEGENERATOR - A MATLAB App Designer application that
    % procedurally generates and displays customizable evergreen trees.
    %
    % Features:
    %   - Adjustable tree height and number of layers
    %   - Customizable trunk dimensions
    %   - Multiple color themes (Classic, Winter, Autumn, Festive)
    %   - Optional decorations (ornaments, star, snow)
    %   - Natural randomness for organic appearance
    %
    % Usage:
    %   app = EvergreenTreeGenerator();
    %
    % Author: Hans Scharler
    % Date: December 2025

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                    matlab.ui.Figure
        MainGridLayout              matlab.ui.container.GridLayout
        ControlPanel                matlab.ui.container.Panel
        ControlGridLayout           matlab.ui.container.GridLayout
        TreeAxes                    matlab.ui.control.UIAxes
        
        % Control Labels
        TitleLabel                  matlab.ui.control.Label
        HeightLabel                 matlab.ui.control.Label
        LayersLabel                 matlab.ui.control.Label
        TrunkWidthLabel             matlab.ui.control.Label
        TrunkHeightLabel            matlab.ui.control.Label
        ColorThemeLabel             matlab.ui.control.Label
        RandomnessLabel             matlab.ui.control.Label
        DecorationsLabel            matlab.ui.control.Label
        
        % Control Components
        HeightSlider                matlab.ui.control.Slider
        HeightValueLabel            matlab.ui.control.Label
        LayersSlider                matlab.ui.control.Slider
        LayersValueLabel            matlab.ui.control.Label
        TrunkWidthSlider            matlab.ui.control.Slider
        TrunkWidthValueLabel        matlab.ui.control.Label
        TrunkHeightSlider           matlab.ui.control.Slider
        TrunkHeightValueLabel       matlab.ui.control.Label
        ColorThemeDropDown          matlab.ui.control.DropDown
        RandomnessSlider            matlab.ui.control.Slider
        RandomnessValueLabel        matlab.ui.control.Label
        
        % Decoration Checkboxes
        OrnamentCheckBox            matlab.ui.control.CheckBox
        StarCheckBox                matlab.ui.control.CheckBox
        SnowCheckBox                matlab.ui.control.CheckBox
        
        % Action Buttons
        GenerateButton              matlab.ui.control.Button
        RandomTreeButton            matlab.ui.control.Button
        SaveButton                  matlab.ui.control.Button
        ExportCodeButton            matlab.ui.control.Button
    end

    % Private properties for app state
    properties (Access = private)
        ColorThemes struct          % Store color theme definitions
        CurrentSeed double          % Random seed for reproducibility
    end

    % Callback methods
    methods (Access = private)

        % Generate button callback - creates a new tree
        function GenerateButtonPushed(app, ~)
            app.generateTree();
        end

        % Random tree button callback - randomizes all parameters
        function RandomTreeButtonPushed(app, ~)
            % Randomize all slider values
            app.HeightSlider.Value = randi([5, 15]);
            app.LayersSlider.Value = randi([3, 8]);
            app.TrunkWidthSlider.Value = 0.5 + rand() * 1.5;
            app.TrunkHeightSlider.Value = 1 + rand() * 2;
            app.RandomnessSlider.Value = rand() * 0.5;
            
            % Randomize color theme
            themes = app.ColorThemeDropDown.Items;
            app.ColorThemeDropDown.Value = themes{randi(length(themes))};
            
            % Randomize decorations
            app.OrnamentCheckBox.Value = rand() > 0.5;
            app.StarCheckBox.Value = rand() > 0.3;
            app.SnowCheckBox.Value = rand() > 0.5;
            
            % Update value labels
            updateValueLabels(app);
            
            % Generate the tree
            app.generateTree();
        end

        % Save button callback - saves tree image
        function SaveButtonPushed(app, ~)
            [filename, pathname] = uiputfile(...
                {'*.png', 'PNG Image (*.png)'; ...
                 '*.jpg', 'JPEG Image (*.jpg)'; ...
                 '*.pdf', 'PDF Document (*.pdf)'}, ...
                'Save Tree Image');
            
            if filename ~= 0
                exportgraphics(app.TreeAxes, fullfile(pathname, filename), ...
                    'Resolution', 300);
            end
        end

        % Export M Code button callback - exports standalone MATLAB script
        function ExportCodeButtonPushed(app, ~)
            [filename, pathname] = uiputfile(...
                {'*.m', 'MATLAB Script (*.m)'}, ...
                'Export Tree Generation Code', ...
                'generateEvergreenTree.m');
            
            if filename ~= 0
                app.exportMatlabCode(fullfile(pathname, filename));
                uialert(app.UIFigure, ...
                    sprintf('Code exported successfully to:\n%s', fullfile(pathname, filename)), ...
                    'Export Complete', 'Icon', 'success');
            end
        end

        % Generate standalone MATLAB code for current tree
        function exportMatlabCode(app, filepath)
            % Get current parameter values
            treeHeight = app.HeightSlider.Value;
            numLayers = round(app.LayersSlider.Value);
            trunkWidth = app.TrunkWidthSlider.Value;
            trunkHeight = app.TrunkHeightSlider.Value;
            randomness = app.RandomnessSlider.Value;
            themeName = app.ColorThemeDropDown.Value;
            showOrnaments = app.OrnamentCheckBox.Value;
            showStar = app.StarCheckBox.Value;
            showSnow = app.SnowCheckBox.Value;
            seed = app.CurrentSeed;
            
            % Get theme colors
            theme = app.getColorTheme(themeName);
            
            % Build the MATLAB code as a string
            code = strings(0);
            code(end+1) = "%% Evergreen Tree Generator";
            code(end+1) = "% Auto-generated code from EvergreenTreeGenerator app";
            code(end+1) = "% Generated: " + string(datetime('now'));
            code(end+1) = "";
            code(end+1) = "%% Parameters";
            code(end+1) = sprintf("treeHeight = %.1f;", treeHeight);
            code(end+1) = sprintf("numLayers = %d;", numLayers);
            code(end+1) = sprintf("trunkWidth = %.2f;", trunkWidth);
            code(end+1) = sprintf("trunkHeight = %.2f;", trunkHeight);
            code(end+1) = sprintf("randomness = %.3f;", randomness);
            code(end+1) = sprintf("randomSeed = %d;", seed);
            code(end+1) = "";
            code(end+1) = "% Decoration flags";
            code(end+1) = sprintf("showOrnaments = %s;", mat2str(showOrnaments));
            code(end+1) = sprintf("showStar = %s;", mat2str(showStar));
            code(end+1) = sprintf("showSnow = %s;", mat2str(showSnow));
            code(end+1) = "";
            code(end+1) = "%% Color Theme: " + themeName;
            code(end+1) = sprintf("foliageColors = {[%.3f, %.3f, %.3f], [%.3f, %.3f, %.3f], [%.3f, %.3f, %.3f], [%.3f, %.3f, %.3f]};", ...
                theme.foliage{1}(1), theme.foliage{1}(2), theme.foliage{1}(3), ...
                theme.foliage{2}(1), theme.foliage{2}(2), theme.foliage{2}(3), ...
                theme.foliage{3}(1), theme.foliage{3}(2), theme.foliage{3}(3), ...
                theme.foliage{4}(1), theme.foliage{4}(2), theme.foliage{4}(3));
            code(end+1) = sprintf("trunkColor = [%.3f, %.3f, %.3f];", theme.trunk(1), theme.trunk(2), theme.trunk(3));
            code(end+1) = sprintf("highlightColor = [%.3f, %.3f, %.3f];", theme.highlight(1), theme.highlight(2), theme.highlight(3));
            code(end+1) = sprintf("starColor = [%.3f, %.3f, %.3f];", theme.star(1), theme.star(2), theme.star(3));
            code(end+1) = sprintf("backgroundColor = [%.3f, %.3f, %.3f];", theme.background(1), theme.background(2), theme.background(3));
            code(end+1) = "";
            code(end+1) = "%% Create Figure";
            code(end+1) = "figure('Color', backgroundColor, 'Position', [100, 100, 800, 600]);";
            code(end+1) = "ax = axes('Color', backgroundColor, 'XTick', [], 'YTick', [], 'Box', 'off');";
            code(end+1) = "ax.XColor = 'none';";
            code(end+1) = "ax.YColor = 'none';";
            code(end+1) = "hold(ax, 'on');";
            code(end+1) = "";
            code(end+1) = "% Set random seed for reproducibility";
            code(end+1) = "rng(randomSeed);";
            code(end+1) = "";
            code(end+1) = "%% Draw Trunk";
            code(end+1) = "trunkX = [-trunkWidth/2, trunkWidth/2, trunkWidth/2, -trunkWidth/2];";
            code(end+1) = "trunkY = [0, 0, trunkHeight, trunkHeight];";
            code(end+1) = "fill(ax, trunkX, trunkY, trunkColor, 'EdgeColor', 'none');";
            code(end+1) = "";
            code(end+1) = "% Add bark texture";
            code(end+1) = "numBarkLines = round(trunkWidth * 3);";
            code(end+1) = "for i = 1:numBarkLines";
            code(end+1) = "    lineX = -trunkWidth/2 + (i - 0.5) * trunkWidth / numBarkLines;";
            code(end+1) = "    lineX = lineX + (rand() - 0.5) * trunkWidth * 0.1;";
            code(end+1) = "    line(ax, [lineX, lineX], [0.1, trunkHeight - 0.1], 'Color', [0.3, 0.2, 0.1], 'LineWidth', 0.5);";
            code(end+1) = "end";
            code(end+1) = "";
            code(end+1) = "%% Draw Tree Layers";
            code(end+1) = "baseWidth = treeHeight * 0.8;";
            code(end+1) = "layerHeight = treeHeight / numLayers;";
            code(end+1) = "currentY = trunkHeight;";
            code(end+1) = "";
            code(end+1) = "for layerIdx = 1:numLayers";
            code(end+1) = "    % Calculate layer dimensions";
            code(end+1) = "    layerBottom = currentY - layerHeight * 0.2;";
            code(end+1) = "    layerTop = currentY + layerHeight;";
            code(end+1) = "    widthFactor = 1 - (layerIdx - 1) / numLayers;";
            code(end+1) = "    layerWidth = baseWidth * widthFactor^0.7;";
            code(end+1) = "    ";
            code(end+1) = "    % Add randomness";
            code(end+1) = "    if randomness > 0";
            code(end+1) = "        layerWidth = layerWidth * (1 + (rand() - 0.5) * randomness);";
            code(end+1) = "    end";
            code(end+1) = "    ";
            code(end+1) = "    % Get layer color";
            code(end+1) = "    colorIdx = min(layerIdx, length(foliageColors));";
            code(end+1) = "    layerColor = foliageColors{colorIdx};";
            code(end+1) = "    ";
            code(end+1) = "    % Generate jagged triangle";
            code(end+1) = "    numPoints = 20 + round(layerWidth * 5);";
            code(end+1) = "    leftX = zeros(1, numPoints);";
            code(end+1) = "    leftY = linspace(layerBottom, layerTop, numPoints);";
            code(end+1) = "    for i = 1:numPoints";
            code(end+1) = "        progress = (i - 1) / (numPoints - 1);";
            code(end+1) = "        baseX = -layerWidth/2 * (1 - progress);";
            code(end+1) = "        jag = (rand() - 0.5) * layerWidth * 0.1 * randomness * (1 - progress * 0.5);";
            code(end+1) = "        leftX(i) = baseX + jag;";
            code(end+1) = "    end";
            code(end+1) = "    ";
            code(end+1) = "    rightX = zeros(1, numPoints);";
            code(end+1) = "    rightY = linspace(layerTop, layerBottom, numPoints);";
            code(end+1) = "    for i = 1:numPoints";
            code(end+1) = "        progress = 1 - (i - 1) / (numPoints - 1);";
            code(end+1) = "        baseX = layerWidth/2 * (1 - progress);";
            code(end+1) = "        jag = (rand() - 0.5) * layerWidth * 0.1 * randomness * (1 - progress * 0.5);";
            code(end+1) = "        rightX(i) = baseX + jag;";
            code(end+1) = "    end";
            code(end+1) = "    ";
            code(end+1) = "    polyX = [leftX, rightX];";
            code(end+1) = "    polyY = [leftY, rightY];";
            code(end+1) = "    fill(ax, polyX, polyY, layerColor, 'EdgeColor', 'none');";
            code(end+1) = "    ";
            code(end+1) = "    % Add branch details";
            code(end+1) = "    if randomness >= 0.1";
            code(end+1) = "        numBranches = round(5 + randomness * 10);";
            code(end+1) = "        for b = 1:numBranches";
            code(end+1) = "            branchY = layerBottom + rand() * (layerTop - layerBottom) * 0.8;";
            code(end+1) = "            prog = (branchY - layerBottom) / (layerTop - layerBottom);";
            code(end+1) = "            maxW = layerWidth * (1 - prog) * 0.4;";
            code(end+1) = "            if rand() > 0.5";
            code(end+1) = "                bx1 = -rand() * maxW * 0.3; bx2 = -rand() * maxW;";
            code(end+1) = "            else";
            code(end+1) = "                bx1 = rand() * maxW * 0.3; bx2 = rand() * maxW;";
            code(end+1) = "            end";
            code(end+1) = "            by2 = branchY - (layerTop - layerBottom) * 0.1 * rand();";
            code(end+1) = "            line(ax, [bx1, bx2], [branchY, by2], 'Color', highlightColor, 'LineWidth', 1 + rand());";
            code(end+1) = "        end";
            code(end+1) = "    end";
            code(end+1) = "    ";
            code(end+1) = "    currentY = layerTop - layerHeight * 0.15;";
            code(end+1) = "end";
            code(end+1) = "";
            code(end+1) = "%% Add Decorations";
            code(end+1) = "if showSnow";
            code(end+1) = "    % Snow patches on tree";
            code(end+1) = "    numSnowPatches = 30 + numLayers * 10;";
            code(end+1) = "    for i = 1:numSnowPatches";
            code(end+1) = "        y = trunkHeight + rand() * treeHeight * 0.9;";
            code(end+1) = "        progress = (y - trunkHeight) / treeHeight;";
            code(end+1) = "        maxX = baseWidth/2 * (1 - progress) * 0.8;";
            code(end+1) = "        x = (rand() - 0.5) * 2 * maxX;";
            code(end+1) = "        radius = 0.1 + rand() * 0.2;";
            code(end+1) = "        theta = linspace(0, 2*pi, 20);";
            code(end+1) = "        snowX = x + radius * cos(theta);";
            code(end+1) = "        snowY = y + radius * 0.5 * sin(theta);";
            code(end+1) = "        fill(ax, snowX, snowY, [0.95, 0.97, 1], 'EdgeColor', 'none', 'FaceAlpha', 0.8);";
            code(end+1) = "    end";
            code(end+1) = "    % Ground snow";
            code(end+1) = "    groundX = linspace(-baseWidth, baseWidth, 50);";
            code(end+1) = "    groundY = 0.3 * sin(groundX * 2) .* rand(1, 50) + 0.1;";
            code(end+1) = "    fill(ax, [groundX, baseWidth, -baseWidth], [groundY, -0.5, -0.5], [0.95, 0.97, 1], 'EdgeColor', 'none');";
            code(end+1) = "end";
            code(end+1) = "";
            code(end+1) = "if showOrnaments";
            code(end+1) = "    numOrnaments = 10 + numLayers * 3;";
            code(end+1) = "    ornamentColors = {[1, 0, 0], [1, 0.84, 0], [0, 0, 1], [0.5, 0, 0.5], [1, 0.5, 0], [0, 0.8, 0.8]};";
            code(end+1) = "    for i = 1:numOrnaments";
            code(end+1) = "        y = trunkHeight + rand() * treeHeight * 0.85;";
            code(end+1) = "        progress = (y - trunkHeight) / treeHeight;";
            code(end+1) = "        maxX = baseWidth/2 * (1 - progress) * 0.7;";
            code(end+1) = "        x = (rand() - 0.5) * 2 * maxX;";
            code(end+1) = "        radius = 0.15 + rand() * 0.1;";
            code(end+1) = "        color = ornamentColors{randi(length(ornamentColors))};";
            code(end+1) = "        theta = linspace(0, 2*pi, 30);";
            code(end+1) = "        ornX = x + radius * cos(theta);";
            code(end+1) = "        ornY = y + radius * sin(theta);";
            code(end+1) = "        fill(ax, ornX, ornY, color, 'EdgeColor', [0.2, 0.2, 0.2], 'LineWidth', 0.5);";
            code(end+1) = "        % Shine highlight";
            code(end+1) = "        shineR = radius * 0.25;";
            code(end+1) = "        fill(ax, x - radius*0.3 + shineR*cos(theta), y + radius*0.3 + shineR*sin(theta), [1,1,1], 'EdgeColor', 'none', 'FaceAlpha', 0.6);";
            code(end+1) = "    end";
            code(end+1) = "end";
            code(end+1) = "";
            code(end+1) = "if showStar";
            code(end+1) = "    % Draw five-pointed star at top";
            code(end+1) = "    starCx = 0;";
            code(end+1) = "    starCy = trunkHeight + treeHeight * 0.95;";
            code(end+1) = "    starSize = treeHeight * 0.08;";
            code(end+1) = "    outerR = starSize;";
            code(end+1) = "    innerR = starSize * 0.4;";
            code(end+1) = "    angles = zeros(1, 10);";
            code(end+1) = "    for i = 1:5";
            code(end+1) = "        angles(2*i - 1) = pi/2 - (i - 1) * 2 * pi / 5;";
            code(end+1) = "        angles(2*i) = pi/2 - (i - 1) * 2 * pi / 5 - pi / 5;";
            code(end+1) = "    end";
            code(end+1) = "    radii = repmat([outerR, innerR], 1, 5);";
            code(end+1) = "    starX = starCx + radii .* cos(angles);";
            code(end+1) = "    starY = starCy + radii .* sin(angles);";
            code(end+1) = "    fill(ax, starX, starY, starColor, 'EdgeColor', [0.8, 0.6, 0], 'LineWidth', 1.5);";
            code(end+1) = "    % Glow effect";
            code(end+1) = "    for r = 1:3";
            code(end+1) = "        glowRadii = repmat([outerR * (1 + r*0.2), innerR * (1 + r*0.1)], 1, 5);";
            code(end+1) = "        patch(ax, starCx + glowRadii.*cos(angles), starCy + glowRadii.*sin(angles), starColor, 'EdgeColor', 'none', 'FaceAlpha', 0.1);";
            code(end+1) = "    end";
            code(end+1) = "end";
            code(end+1) = "";
            code(end+1) = "%% Set Axis Limits";
            code(end+1) = "maxX = baseWidth / 2 + 1;";
            code(end+1) = "maxY = trunkHeight + treeHeight + 1;";
            code(end+1) = "axis(ax, 'equal');";
            code(end+1) = "xlim(ax, [-maxX, maxX]);";
            code(end+1) = "ylim(ax, [-0.5, maxY]);";
            code(end+1) = "title(ax, 'Evergreen Tree', 'FontSize', 14);";
            code(end+1) = "hold(ax, 'off');";
            
            % Write to file
            fid = fopen(filepath, 'w');
            if fid == -1
                error('Could not open file for writing: %s', filepath);
            end
            
            for i = 1:length(code)
                fprintf(fid, '%s\n', code(i));
            end
            
            fclose(fid);
        end

        % Slider value changing callbacks
        function SliderValueChanged(app, ~)
            updateValueLabels(app);
        end

        % Update all value display labels
        function updateValueLabels(app)
            app.HeightValueLabel.Text = sprintf('%.0f', app.HeightSlider.Value);
            app.LayersValueLabel.Text = sprintf('%.0f', app.LayersSlider.Value);
            app.TrunkWidthValueLabel.Text = sprintf('%.1f', app.TrunkWidthSlider.Value);
            app.TrunkHeightValueLabel.Text = sprintf('%.1f', app.TrunkHeightSlider.Value);
            app.RandomnessValueLabel.Text = sprintf('%.2f', app.RandomnessSlider.Value);
        end

        % Main tree generation algorithm
        function generateTree(app)
            % Clear previous plot
            cla(app.TreeAxes);
            hold(app.TreeAxes, 'on');
            
            % Get parameters from controls
            treeHeight = app.HeightSlider.Value;
            numLayers = round(app.LayersSlider.Value);
            trunkWidth = app.TrunkWidthSlider.Value;
            trunkHeight = app.TrunkHeightSlider.Value;
            randomness = app.RandomnessSlider.Value;
            
            % Get color theme
            theme = app.getColorTheme(app.ColorThemeDropDown.Value);
            
            % Generate new random seed
            app.CurrentSeed = randi(10000);
            rng(app.CurrentSeed);
            
            % Calculate layer parameters
            baseWidth = treeHeight * 0.8;  % Base width proportional to height
            layerHeight = treeHeight / numLayers;
            
            % Draw trunk first (so it's behind the tree)
            app.drawTrunk(trunkWidth, trunkHeight, theme.trunk);
            
            % Draw tree layers from bottom to top
            currentY = trunkHeight;
            for i = 1:numLayers
                % Calculate layer dimensions with slight overlap
                layerBottom = currentY - layerHeight * 0.2;
                layerTop = currentY + layerHeight;
                
                % Width decreases as we go up (exponential decay for natural look)
                widthFactor = 1 - (i - 1) / numLayers;
                layerWidth = baseWidth * widthFactor^0.7;
                
                % Add randomness to layer width
                if randomness > 0
                    layerWidth = layerWidth * (1 + (rand() - 0.5) * randomness);
                end
                
                % Determine layer color (gradient from dark to light)
                colorIdx = min(i, length(theme.foliage));
                layerColor = theme.foliage{colorIdx};
                
                % Draw the layer
                app.drawTreeLayer(layerBottom, layerTop, layerWidth, ...
                    layerColor, randomness, theme.highlight);
                
                currentY = layerTop - layerHeight * 0.15;  % Overlap layers
            end
            
            % Add decorations if enabled
            if app.SnowCheckBox.Value
                app.addSnow(treeHeight, trunkHeight, baseWidth, numLayers);
            end
            
            if app.OrnamentCheckBox.Value
                app.addOrnaments(treeHeight, trunkHeight, baseWidth, numLayers);
            end
            
            if app.StarCheckBox.Value
                starY = trunkHeight + treeHeight * 0.95;
                app.drawStar(0, starY, treeHeight * 0.08, theme.star);
            end
            
            % Set axis properties
            hold(app.TreeAxes, 'off');
            axis(app.TreeAxes, 'equal');
            
            % Calculate view bounds
            maxX = baseWidth / 2 + 1;
            maxY = trunkHeight + treeHeight + 1;
            xlim(app.TreeAxes, [-maxX, maxX]);
            ylim(app.TreeAxes, [-0.5, maxY]);
            
            % Style the axes
            app.TreeAxes.XTick = [];
            app.TreeAxes.YTick = [];
            app.TreeAxes.Box = 'off';
            app.TreeAxes.Color = theme.background;
            app.TreeAxes.XColor = 'none';
            app.TreeAxes.YColor = 'none';
        end

        % Draw trunk with bark texture effect
        function drawTrunk(app, width, height, color)
            % Main trunk rectangle
            x = [-width/2, width/2, width/2, -width/2];
            y = [0, 0, height, height];
            fill(app.TreeAxes, x, y, color, 'EdgeColor', 'none');
            
            % Add bark texture lines
            numLines = round(width * 3);
            for i = 1:numLines
                lineX = -width/2 + (i - 0.5) * width / numLines;
                lineX = lineX + (rand() - 0.5) * width * 0.1;
                line(app.TreeAxes, [lineX, lineX], [0.1, height - 0.1], ...
                    'Color', [0.3, 0.2, 0.1], 'LineWidth', 0.5);
            end
        end

        % Draw a single tree layer (triangle with jagged edges)
        function drawTreeLayer(app, yBottom, yTop, width, color, randomness, highlightColor)
            % Number of points for jagged edge
            numPoints = 20 + round(width * 5);
            
            % Generate left edge points (bottom to top)
            leftX = zeros(1, numPoints);
            leftY = linspace(yBottom, yTop, numPoints);
            for i = 1:numPoints
                progress = (i - 1) / (numPoints - 1);  % 0 to 1
                baseX = -width/2 * (1 - progress);     % Triangle shape
                
                % Add jagged randomness (more at edges, less near center)
                jag = (rand() - 0.5) * width * 0.1 * randomness * (1 - progress * 0.5);
                leftX(i) = baseX + jag;
            end
            
            % Generate right edge points (top to bottom)
            rightX = zeros(1, numPoints);
            rightY = linspace(yTop, yBottom, numPoints);
            for i = 1:numPoints
                progress = 1 - (i - 1) / (numPoints - 1);  % 1 to 0
                baseX = width/2 * (1 - progress);
                jag = (rand() - 0.5) * width * 0.1 * randomness * (1 - progress * 0.5);
                rightX(i) = baseX + jag;
            end
            
            % Combine into polygon
            polyX = [leftX, rightX];
            polyY = [leftY, rightY];
            
            % Draw filled polygon
            fill(app.TreeAxes, polyX, polyY, color, 'EdgeColor', 'none');
            
            % Add highlight/shadow effect
            app.addBranchDetails(yBottom, yTop, width, highlightColor, randomness);
        end

        % Add branch-like details for depth
        function addBranchDetails(app, yBottom, yTop, width, highlightColor, randomness)
            if randomness < 0.1
                return;  % Skip for low randomness
            end
            
            numBranches = round(5 + randomness * 10);
            layerHeight = yTop - yBottom;
            
            for i = 1:numBranches
                % Random position within layer
                branchY = yBottom + rand() * layerHeight * 0.8;
                progress = (branchY - yBottom) / layerHeight;
                maxWidth = width * (1 - progress) * 0.4;
                
                % Branch on left or right
                if rand() > 0.5
                    branchX1 = -rand() * maxWidth * 0.3;
                    branchX2 = -rand() * maxWidth;
                else
                    branchX1 = rand() * maxWidth * 0.3;
                    branchX2 = rand() * maxWidth;
                end
                
                branchY2 = branchY - layerHeight * 0.1 * rand();
                
                line(app.TreeAxes, [branchX1, branchX2], [branchY, branchY2], ...
                    'Color', highlightColor, 'LineWidth', 1 + rand());
            end
        end

        % Add snow patches to tree
        function addSnow(app, treeHeight, trunkHeight, baseWidth, numLayers)
            numSnowPatches = 30 + numLayers * 10;
            
            for i = 1:numSnowPatches
                % Random position on tree
                y = trunkHeight + rand() * treeHeight * 0.9;
                progress = (y - trunkHeight) / treeHeight;
                maxX = baseWidth/2 * (1 - progress) * 0.8;
                x = (rand() - 0.5) * 2 * maxX;
                
                % Snow patch size
                radius = 0.1 + rand() * 0.2;
                
                % Draw snow ellipse
                theta = linspace(0, 2*pi, 20);
                snowX = x + radius * cos(theta);
                snowY = y + radius * 0.5 * sin(theta);
                fill(app.TreeAxes, snowX, snowY, [0.95, 0.97, 1], ...
                    'EdgeColor', 'none', 'FaceAlpha', 0.8);
            end
            
            % Add ground snow
            groundSnowX = linspace(-baseWidth, baseWidth, 50);
            groundSnowY = 0.3 * sin(groundSnowX * 2) .* rand(1, 50) + 0.1;
            fill(app.TreeAxes, [groundSnowX, baseWidth, -baseWidth], ...
                [groundSnowY, -0.5, -0.5], [0.95, 0.97, 1], 'EdgeColor', 'none');
        end

        % Add ornament decorations
        function addOrnaments(app, treeHeight, trunkHeight, baseWidth, numLayers)
            numOrnaments = 10 + numLayers * 3;
            ornamentColors = {[1, 0, 0], [1, 0.84, 0], [0, 0, 1], ...
                             [0.5, 0, 0.5], [1, 0.5, 0], [0, 0.8, 0.8]};
            
            for i = 1:numOrnaments
                % Random position on tree
                y = trunkHeight + rand() * treeHeight * 0.85;
                progress = (y - trunkHeight) / treeHeight;
                maxX = baseWidth/2 * (1 - progress) * 0.7;
                x = (rand() - 0.5) * 2 * maxX;
                
                % Ornament size and color
                radius = 0.15 + rand() * 0.1;
                color = ornamentColors{randi(length(ornamentColors))};
                
                % Draw ornament (circle with shine)
                theta = linspace(0, 2*pi, 30);
                ornX = x + radius * cos(theta);
                ornY = y + radius * sin(theta);
                fill(app.TreeAxes, ornX, ornY, color, 'EdgeColor', [0.2, 0.2, 0.2], ...
                    'LineWidth', 0.5);
                
                % Add shine highlight
                shineX = x - radius * 0.3;
                shineY = y + radius * 0.3;
                shineR = radius * 0.25;
                shineTheta = linspace(0, 2*pi, 15);
                fill(app.TreeAxes, shineX + shineR*cos(shineTheta), ...
                    shineY + shineR*sin(shineTheta), [1, 1, 1], ...
                    'EdgeColor', 'none', 'FaceAlpha', 0.6);
            end
        end

        % Draw a star at tree top
        function drawStar(app, cx, cy, size, color)
            % Five-pointed star with top point facing up
            numPoints = 5;
            outerRadius = size;
            innerRadius = size * 0.4;
            
            % Create angles for star points, starting at pi/2 (top) and going clockwise
            % Each outer point is followed by an inner point
            angles = zeros(1, numPoints * 2);
            for i = 1:numPoints
                % Outer point angle (tips of star)
                angles(2*i - 1) = pi/2 - (i - 1) * 2 * pi / numPoints;
                % Inner point angle (valleys between tips)
                angles(2*i) = pi/2 - (i - 1) * 2 * pi / numPoints - pi / numPoints;
            end
            
            radii = repmat([outerRadius, innerRadius], 1, numPoints);
            
            starX = cx + radii .* cos(angles);
            starY = cy + radii .* sin(angles);
            
            fill(app.TreeAxes, starX, starY, color, 'EdgeColor', [0.8, 0.6, 0], ...
                'LineWidth', 1.5);
            
            % Add glow effect
            for r = 1:3
                glowRadius = outerRadius * (1 + r * 0.2);
                glowRadii = repmat([glowRadius, innerRadius * (1 + r * 0.1)], 1, numPoints);
                glowX = cx + glowRadii .* cos(angles);
                glowY = cy + glowRadii .* sin(angles);
                patch(app.TreeAxes, glowX, glowY, color, 'EdgeColor', 'none', ...
                    'FaceAlpha', 0.1);
            end
        end

        % Get color theme structure
        function theme = getColorTheme(app, themeName)
            switch themeName
                case 'Classic'
                    theme.foliage = {[0.1, 0.4, 0.1], [0.15, 0.5, 0.15], ...
                                    [0.2, 0.55, 0.2], [0.25, 0.6, 0.25]};
                    theme.trunk = [0.4, 0.25, 0.1];
                    theme.highlight = [0.3, 0.6, 0.3];
                    theme.star = [1, 0.84, 0];
                    theme.background = [0.85, 0.92, 1];
                    
                case 'Winter'
                    theme.foliage = {[0.2, 0.35, 0.3], [0.25, 0.4, 0.35], ...
                                    [0.3, 0.45, 0.4], [0.35, 0.5, 0.45]};
                    theme.trunk = [0.35, 0.25, 0.2];
                    theme.highlight = [0.5, 0.6, 0.55];
                    theme.star = [0.9, 0.95, 1];
                    theme.background = [0.75, 0.82, 0.9];
                    
                case 'Autumn'
                    theme.foliage = {[0.3, 0.35, 0.15], [0.35, 0.4, 0.18], ...
                                    [0.4, 0.45, 0.2], [0.45, 0.5, 0.22]};
                    theme.trunk = [0.45, 0.3, 0.15];
                    theme.highlight = [0.5, 0.55, 0.3];
                    theme.star = [1, 0.6, 0.2];
                    theme.background = [0.95, 0.9, 0.8];
                    
                case 'Festive'
                    theme.foliage = {[0.05, 0.35, 0.1], [0.08, 0.4, 0.12], ...
                                    [0.1, 0.45, 0.15], [0.12, 0.5, 0.18]};
                    theme.trunk = [0.5, 0.3, 0.15];
                    theme.highlight = [0.2, 0.5, 0.25];
                    theme.star = [1, 0.9, 0.3];
                    theme.background = [0.15, 0.1, 0.2];
                    
                otherwise
                    % Default to Classic
                    theme = app.getColorTheme('Classic');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)
            
            % Create UIFigure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100, 100, 1000, 700];
            app.UIFigure.Name = 'Evergreen Tree Generator';
            app.UIFigure.Color = [0.94, 0.94, 0.94];
            app.UIFigure.Resize = 'on';
            
            % Create main grid layout (2 columns: controls | display)
            app.MainGridLayout = uigridlayout(app.UIFigure, [1, 2]);
            app.MainGridLayout.ColumnWidth = {280, '1x'};
            app.MainGridLayout.RowHeight = {'1x'};
            app.MainGridLayout.Padding = [10, 10, 10, 10];
            app.MainGridLayout.ColumnSpacing = 10;
            
            % Create Control Panel
            app.ControlPanel = uipanel(app.MainGridLayout);
            app.ControlPanel.Title = 'Tree Controls';
            app.ControlPanel.FontWeight = 'bold';
            app.ControlPanel.FontSize = 14;
            app.ControlPanel.Layout.Row = 1;
            app.ControlPanel.Layout.Column = 1;
            
            % Create control grid layout
            app.ControlGridLayout = uigridlayout(app.ControlPanel, [17, 3]);
            app.ControlGridLayout.ColumnWidth = {'fit', '1x', 40};
            app.ControlGridLayout.RowHeight = {30, 25, 40, 25, 40, 25, 40, 25, 40, ...
                                               30, 40, 30, 25, 25, 25, '1x', 75};
            app.ControlGridLayout.Padding = [10, 10, 10, 10];
            app.ControlGridLayout.RowSpacing = 5;
            
            % Title Label
            app.TitleLabel = uilabel(app.ControlGridLayout);
            app.TitleLabel.Text = 'Tree Parameters';
            app.TitleLabel.FontSize = 12;
            app.TitleLabel.FontWeight = 'bold';
            app.TitleLabel.Layout.Row = 1;
            app.TitleLabel.Layout.Column = [1, 3];
            
            % --- Height Slider ---
            app.HeightLabel = uilabel(app.ControlGridLayout);
            app.HeightLabel.Text = 'Tree Height:';
            app.HeightLabel.Layout.Row = 2;
            app.HeightLabel.Layout.Column = 1;
            
            app.HeightSlider = uislider(app.ControlGridLayout);
            app.HeightSlider.Limits = [3, 20];
            app.HeightSlider.Value = 10;
            app.HeightSlider.MajorTicks = [3, 7, 11, 15, 20];
            app.HeightSlider.ValueChangedFcn = @(~,~) app.SliderValueChanged();
            app.HeightSlider.Layout.Row = 3;
            app.HeightSlider.Layout.Column = [1, 2];
            
            app.HeightValueLabel = uilabel(app.ControlGridLayout);
            app.HeightValueLabel.Text = '10';
            app.HeightValueLabel.HorizontalAlignment = 'center';
            app.HeightValueLabel.Layout.Row = 3;
            app.HeightValueLabel.Layout.Column = 3;
            
            % --- Layers Slider ---
            app.LayersLabel = uilabel(app.ControlGridLayout);
            app.LayersLabel.Text = 'Number of Layers:';
            app.LayersLabel.Layout.Row = 4;
            app.LayersLabel.Layout.Column = 1;
            
            app.LayersSlider = uislider(app.ControlGridLayout);
            app.LayersSlider.Limits = [2, 10];
            app.LayersSlider.Value = 5;
            app.LayersSlider.MajorTicks = 2:2:10;
            app.LayersSlider.ValueChangedFcn = @(~,~) app.SliderValueChanged();
            app.LayersSlider.Layout.Row = 5;
            app.LayersSlider.Layout.Column = [1, 2];
            
            app.LayersValueLabel = uilabel(app.ControlGridLayout);
            app.LayersValueLabel.Text = '5';
            app.LayersValueLabel.HorizontalAlignment = 'center';
            app.LayersValueLabel.Layout.Row = 5;
            app.LayersValueLabel.Layout.Column = 3;
            
            % --- Trunk Width Slider ---
            app.TrunkWidthLabel = uilabel(app.ControlGridLayout);
            app.TrunkWidthLabel.Text = 'Trunk Width:';
            app.TrunkWidthLabel.Layout.Row = 6;
            app.TrunkWidthLabel.Layout.Column = 1;
            
            app.TrunkWidthSlider = uislider(app.ControlGridLayout);
            app.TrunkWidthSlider.Limits = [0.3, 2.5];
            app.TrunkWidthSlider.Value = 1.0;
            app.TrunkWidthSlider.MajorTicks = [0.3, 1, 1.7, 2.5];
            app.TrunkWidthSlider.ValueChangedFcn = @(~,~) app.SliderValueChanged();
            app.TrunkWidthSlider.Layout.Row = 7;
            app.TrunkWidthSlider.Layout.Column = [1, 2];
            
            app.TrunkWidthValueLabel = uilabel(app.ControlGridLayout);
            app.TrunkWidthValueLabel.Text = '1.0';
            app.TrunkWidthValueLabel.HorizontalAlignment = 'center';
            app.TrunkWidthValueLabel.Layout.Row = 7;
            app.TrunkWidthValueLabel.Layout.Column = 3;
            
            % --- Trunk Height Slider ---
            app.TrunkHeightLabel = uilabel(app.ControlGridLayout);
            app.TrunkHeightLabel.Text = 'Trunk Height:';
            app.TrunkHeightLabel.Layout.Row = 8;
            app.TrunkHeightLabel.Layout.Column = 1;
            
            app.TrunkHeightSlider = uislider(app.ControlGridLayout);
            app.TrunkHeightSlider.Limits = [0.5, 4];
            app.TrunkHeightSlider.Value = 1.5;
            app.TrunkHeightSlider.MajorTicks = [0.5, 1.5, 2.5, 4];
            app.TrunkHeightSlider.ValueChangedFcn = @(~,~) app.SliderValueChanged();
            app.TrunkHeightSlider.Layout.Row = 9;
            app.TrunkHeightSlider.Layout.Column = [1, 2];
            
            app.TrunkHeightValueLabel = uilabel(app.ControlGridLayout);
            app.TrunkHeightValueLabel.Text = '1.5';
            app.TrunkHeightValueLabel.HorizontalAlignment = 'center';
            app.TrunkHeightValueLabel.Layout.Row = 9;
            app.TrunkHeightValueLabel.Layout.Column = 3;
            
            % --- Color Theme Dropdown ---
            app.ColorThemeLabel = uilabel(app.ControlGridLayout);
            app.ColorThemeLabel.Text = 'Color Theme:';
            app.ColorThemeLabel.Layout.Row = 10;
            app.ColorThemeLabel.Layout.Column = 1;
            
            app.ColorThemeDropDown = uidropdown(app.ControlGridLayout);
            app.ColorThemeDropDown.Items = {'Classic', 'Winter', 'Autumn', 'Festive'};
            app.ColorThemeDropDown.Value = 'Classic';
            app.ColorThemeDropDown.Layout.Row = 11;
            app.ColorThemeDropDown.Layout.Column = [1, 3];
            
            % --- Randomness Slider ---
            app.RandomnessLabel = uilabel(app.ControlGridLayout);
            app.RandomnessLabel.Text = 'Randomness (Natural Look):';
            app.RandomnessLabel.Layout.Row = 12;
            app.RandomnessLabel.Layout.Column = [1, 2];
            
            app.RandomnessSlider = uislider(app.ControlGridLayout);
            app.RandomnessSlider.Limits = [0, 0.5];
            app.RandomnessSlider.Value = 0.2;
            app.RandomnessSlider.MajorTicks = [0, 0.25, 0.5];
            app.RandomnessSlider.ValueChangedFcn = @(~,~) app.SliderValueChanged();
            app.RandomnessSlider.Layout.Row = 12;
            app.RandomnessSlider.Layout.Column = 2;
            
            app.RandomnessValueLabel = uilabel(app.ControlGridLayout);
            app.RandomnessValueLabel.Text = '0.20';
            app.RandomnessValueLabel.HorizontalAlignment = 'center';
            app.RandomnessValueLabel.Layout.Row = 12;
            app.RandomnessValueLabel.Layout.Column = 3;
            
            % --- Decorations Section ---
            app.DecorationsLabel = uilabel(app.ControlGridLayout);
            app.DecorationsLabel.Text = 'Decorations:';
            app.DecorationsLabel.FontWeight = 'bold';
            app.DecorationsLabel.Layout.Row = 13;
            app.DecorationsLabel.Layout.Column = [1, 3];
            
            app.OrnamentCheckBox = uicheckbox(app.ControlGridLayout);
            app.OrnamentCheckBox.Text = 'Ornaments';
            app.OrnamentCheckBox.Value = false;
            app.OrnamentCheckBox.Layout.Row = 14;
            app.OrnamentCheckBox.Layout.Column = [1, 3];
            
            app.StarCheckBox = uicheckbox(app.ControlGridLayout);
            app.StarCheckBox.Text = 'Star on Top';
            app.StarCheckBox.Value = true;
            app.StarCheckBox.Layout.Row = 15;
            app.StarCheckBox.Layout.Column = [1, 3];
            
            app.SnowCheckBox = uicheckbox(app.ControlGridLayout);
            app.SnowCheckBox.Text = 'Snow Effect';
            app.SnowCheckBox.Value = false;
            app.SnowCheckBox.Layout.Row = 16;
            app.SnowCheckBox.Layout.Column = [1, 3];
            
            % --- Buttons Panel ---
            buttonGrid = uigridlayout(app.ControlGridLayout, [2, 2]);
            buttonGrid.Layout.Row = 17;
            buttonGrid.Layout.Column = [1, 3];
            buttonGrid.ColumnWidth = {'1x', '1x'};
            buttonGrid.RowHeight = {'1x', '1x'};
            buttonGrid.Padding = [0, 5, 0, 0];
            buttonGrid.ColumnSpacing = 5;
            buttonGrid.RowSpacing = 5;
            
            app.GenerateButton = uibutton(buttonGrid, 'push');
            app.GenerateButton.Text = 'Generate';
            app.GenerateButton.FontWeight = 'bold';
            app.GenerateButton.BackgroundColor = [0.3, 0.7, 0.4];
            app.GenerateButton.FontColor = [1, 1, 1];
            app.GenerateButton.ButtonPushedFcn = @(~,~) app.GenerateButtonPushed();
            app.GenerateButton.Layout.Row = 1;
            app.GenerateButton.Layout.Column = 1;
            
            app.RandomTreeButton = uibutton(buttonGrid, 'push');
            app.RandomTreeButton.Text = 'Random';
            app.RandomTreeButton.BackgroundColor = [0.5, 0.5, 0.8];
            app.RandomTreeButton.FontColor = [1, 1, 1];
            app.RandomTreeButton.ButtonPushedFcn = @(~,~) app.RandomTreeButtonPushed();
            app.RandomTreeButton.Layout.Row = 1;
            app.RandomTreeButton.Layout.Column = 2;
            
            app.SaveButton = uibutton(buttonGrid, 'push');
            app.SaveButton.Text = 'Save Image';
            app.SaveButton.BackgroundColor = [0.6, 0.6, 0.6];
            app.SaveButton.FontColor = [1, 1, 1];
            app.SaveButton.ButtonPushedFcn = @(~,~) app.SaveButtonPushed();
            app.SaveButton.Layout.Row = 2;
            app.SaveButton.Layout.Column = 1;
            
            app.ExportCodeButton = uibutton(buttonGrid, 'push');
            app.ExportCodeButton.Text = 'Export M Code';
            app.ExportCodeButton.BackgroundColor = [0.7, 0.5, 0.3];
            app.ExportCodeButton.FontColor = [1, 1, 1];
            app.ExportCodeButton.ButtonPushedFcn = @(~,~) app.ExportCodeButtonPushed();
            app.ExportCodeButton.Layout.Row = 2;
            app.ExportCodeButton.Layout.Column = 2;
            
            % Create UIAxes for tree display
            app.TreeAxes = uiaxes(app.MainGridLayout);
            app.TreeAxes.Layout.Row = 1;
            app.TreeAxes.Layout.Column = 2;
            app.TreeAxes.Box = 'off';
            app.TreeAxes.XTick = [];
            app.TreeAxes.YTick = [];
            app.TreeAxes.XColor = 'none';
            app.TreeAxes.YColor = 'none';
            title(app.TreeAxes, 'Your Evergreen Tree', 'FontSize', 14);
            
            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = EvergreenTreeGenerator()
            % Create UIFigure and components
            createComponents(app);

            % Register the app with App Designer
            registerApp(app, app.UIFigure);

            % Initialize random seed
            app.CurrentSeed = randi(10000);
            
            % Generate initial tree
            app.generateTree();

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            % Delete UIFigure when app is deleted
            delete(app.UIFigure);
        end
    end
end
