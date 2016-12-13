function options = AnalysisOptions
options = struct('ParseData','No','ProcessData','No','SaveData','No','SaveFigures','No','DiagFigs','No','Filename',[]);

bgHeight = 0.13;
bgCount = 1;

% Create figure
fig = figure('units','pixels','position',[2000,1000,300,600],...
    'toolbar','none','menu','none','CloseRequestFcn',@closeFig); %#ok<*NASGU>

%% ui control definitions
% Create the button group.
bg1 = uibuttongroup('visible','off','Position',[0 1-bgHeight*bgCount 1 bgHeight],'Title','Parse Data?','TitlePosition','centertop','SelectionChangeFcn',@parseChange);
% Create three radio buttons in the button group.
parseYes = uicontrol('Style','radiobutton','String','Yes',...
    'Units','normalized','pos',[.25 .35 .2 .6],'parent',bg1,'HandleVisibility','off');
parseNo = uicontrol('Style','radiobutton','String','No',...
    'Units','normalized','pos',[.65 .35 .2 .6],'parent',bg1,'HandleVisibility','off');
% Initialize some button group properties.
set(bg1,'SelectedObject',parseNo);  % default
set(bg1,'Visible','on');

bgCount=bgCount+1;
% Create the button group.
bg2 = uibuttongroup('visible','off','Position',[0 1-bgHeight*bgCount 1 bgHeight],'Title','Process Data?','TitlePosition','centertop','SelectionChangeFcn',@analyzeChange);
% Create three radio buttons in the button group.
analyzeYes = uicontrol('Style','radiobutton','String','Yes','Tag','Yes',...
    'Units','normalized','pos',[.25 .35 .2 .6],'parent',bg2,'HandleVisibility','off');
analyzeNo = uicontrol('Style','radiobutton','String','No',...
    'Units','normalized','pos',[.65 .35 .2 .6],'parent',bg2,'HandleVisibility','off');
% Initialize some button group properties.
set(bg2,'SelectedObject',analyzeNo);  % default
set(bg2,'Visible','on');

bgCount=bgCount+1;
% Create the button group.
bg3 = uibuttongroup('visible','off','Position',[0 1-bgHeight*bgCount 1 bgHeight],'Title','Save Data?','TitlePosition','centertop','SelectionChangeFcn',@saveDataChange);
% Create three radio buttons in the button group.
saveDataYes = uicontrol('Style','radiobutton','String','Yes',...
    'Units','normalized','pos',[.25 .35 .2 .6],'parent',bg3,'HandleVisibility','off');
saveDataNo = uicontrol('Style','radiobutton','String','No',...
    'Units','normalized','pos',[.65 .35 .2 .6],'parent',bg3,'HandleVisibility','off');
% Initialize some button group properties.
set(bg3,'SelectedObject',saveDataNo);  % default
set(bg3,'Visible','on');

bgCount=bgCount+1;
% Create the button group.
bg4 = uibuttongroup('visible','off','Position',[0 1-bgHeight*bgCount 1 bgHeight],'Title','Save Figures?','TitlePosition','centertop','SelectionChangeFcn',@saveFigsChange);
% Create three radio buttons in the button group.
saveFigsYes = uicontrol('Style','radiobutton','String','Yes',...
    'Units','normalized','pos',[.25 .35 .2 .6],'parent',bg4,'HandleVisibility','off');
saveFigsNo = uicontrol('Style','radiobutton','String','No',...
    'Units','normalized','pos',[.65 .35 .2 .6],'parent',bg4,'HandleVisibility','off');
% Initialize some button group properties.
set(bg4,'SelectedObject',saveFigsNo);  % default
set(bg4,'Visible','on');

bgCount=bgCount+1;
% Create the button group.
bg4 = uibuttongroup('visible','off','Position',[0 1-bgHeight*bgCount 1 bgHeight],'Title','Diagnostic Figures?','TitlePosition','centertop','SelectionChangeFcn',@diagFigsChange);
% Create three radio buttons in the button group.
diagFigsYes = uicontrol('Style','radiobutton','String','Yes',...
    'Units','normalized','pos',[.25 .35 .2 .6],'parent',bg4,'HandleVisibility','off');
diagFigsNo = uicontrol('Style','radiobutton','String','No',...
    'Units','normalized','pos',[.65 .35 .2 .6],'parent',bg4,'HandleVisibility','off');
% Initialize some button group properties.
set(bg4,'SelectedObject',diagFigsNo);  % default
set(bg4,'Visible','on');

bgCount=bgCount+1;
% Create the button group.
bg5 = uibuttongroup('visible','off','Position',[0 1-bgHeight*bgCount 1 bgHeight],'Title','Which data set to analyze?','TitlePosition','centertop');
% Create button for choosing files
chooseFile = uicontrol('style','pushbutton','units','normalized',...
    'position',[.2 .18 .2 .6],'string','Choose File',...
    'parent',bg5,'callback',@chooseFile_call);
fileIndicator=annotation('textbox',[.5 1-bgHeight*bgCount+bgHeight/4 .4 .05],'String','No File Selected');

set(bg5,'Visible','on');


% Create OK pushbutton
p = uicontrol('style','pushbutton','units','normalized',...
    'position',[.4,.1 ,.2,.1],'string','OK',...
    'callback',@p_call);


%% Callbacks
    function parseChange(~,event)
        selection=get(event.NewValue);
        options.ParseData=selection.String;
    end

    function analyzeChange(~,event)
        selection=get(event.NewValue);
        options.ProcessData=selection.String;
    end

    function saveDataChange(~,event)
        selection=get(event.NewValue);
        options.SaveData=selection.String;
    end

    function saveFigsChange(~,event)
        selection=get(event.NewValue);
        options.SaveFigures=selection.String;
    end

    function diagFigsChange(~,event)
        selection=get(event.NewValue);
        options.DiagFigs=selection.String;
    end

    % Choose file pushbutton callback
    function chooseFile_call(varargin)
        options.Filename=uigetfile('/Users/adam/Documents/MATLAB/HairTouch2016/ParsedData');
        set(fileIndicator,'String',options.Filename)
    end

    % OK Pushbutton callback
    function p_call(varargin)
        if ~strcmp(get(fileIndicator,'String'),'No File Selected') || strcmp(options.ProcessData,'No')
            uiresume(fig)
            close(gcf)
        else
            WarningDialog=warndlg('Please choose a file.','No file selected');
            oldPos=get(WarningDialog,'Position');
            set(WarningDialog,'Position',[2000,1000,oldPos(3),oldPos(4)]);
        end
    end

    function closeFig(src,event)
        delete(gcf)
    end
uiwait(fig)
end

