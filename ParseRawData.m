function ParseRawData(options)

%% Parse raw data
if strcmp(options.ParseData,'Yes')
    
    fileListing=dir('RawDataFiles/Subject*');
    NumberOfSubjects=length(fileListing);
    for i=1:NumberOfSubjects
        filename=['RawDataFiles/' fileListing(i).name];
        MeasuredVoltage=csvread(filename,3,0); %#ok<*NASGU>
        MetaData=textread(filename,'%s',5); %#ok<DTXTRD> % read 5 objects because spaces and new line character make new objects
        SampleRate=str2num(MetaData{1}(11:end)); %#ok<ST2NM>
        DataCollectionTimeStamp=datestr([MetaData{2},' ', MetaData{3}]);
        CantileverName=MetaData{5};
        fileListing(1).name(1:end-4);
        save(['ParsedData/' fileListing(i).name(1:end-5)],'MeasuredVoltage','SampleRate','DataCollectionTimeStamp','CantileverName')
    end
    
    disp('Done parsing data')
end