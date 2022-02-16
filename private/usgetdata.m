function [datelabel, depth1, depth2, depth, age, ageerr, proxy_str, dateboot] = usgetdata(proxy,files,scenario,datapath)

datafiles = dir([datapath '*.txt']);
datafiles = datafiles(contains({datafiles.name},files));
datafiles = datafiles(contains({datafiles.name},scenario));
[datacell,dataheader] = deal(cell(size(datafiles)));
s = nan(numel(datafiles),2);

% check that the strings produced unique hits
if numel(datafiles) ~= numel(files)
	error([[files{:}] ' were specified but ' [datafiles.name] ' were found'])
end

% read in the data
for i = 1:numel(datacell)
	datacell{i} = fileread([datafiles(i).folder '/' datafiles(i).name]);
	datacell{i} = splitlines(datacell{i});
	
	% check for empty rows at the bottom
	lastrow = datacell{i}(end,:);
	while isempty(lastrow{:})
		datacell{i}(end,:) = [];
		lastrow = datacell{i}(end,:);
	end

	% get the header to lookup against proxy
	dataheader{i} = strsplit(char(datacell{i}(1,:)));

	% convert to a matrix
	datacell{i} = cell2mat(cellfun(@str2num,datacell{i}(2:end,:),'UniformOutput',false));

	% make 1sig lo, median, 1 sig hi
	indexage = contains(dataheader{i},'age') & contains(dataheader{i},'med') | contains(dataheader{i},'mean') | contains(dataheader{i},'ave');
	index1sig = contains(dataheader{i},'age') & contains(dataheader{i},'68') | contains(dataheader{i},'1');
	index = logical(sum([indexage; index1sig]));
	age = datacell{i}(:,index);
	[~,ind] = sort(age(1,:));
	age = age(:,ind);

	% get the proxy data
	indexproxy = contains(dataheader{i},proxy);
	proxydata = datacell{i}(:,indexproxy);
	
	% put back in cell
	datacell{i} = age;
	datacell{i}(:,4) = proxydata;
	s(i) = size(age,1);
end

[depth1,depth2,depth,age,ageerr,dateboot] = deal(ones(sum(s(:,1)),1));
datelabel = cell(sum(s(:,1)),1);
startindex = 1;
s(:,2) = cumsum(s(:,1));

for i = 1:numel(datacell)
	depth1(startindex:s(i,2)) = datacell{i}(:,1);
	depth(startindex:s(i,2)) = datacell{i}(:,2);
	depth2(startindex:s(i,2)) = datacell{i}(:,3);
	age(startindex:s(i,2)) = datacell{i}(:,4);
	[datelabel{startindex:s(i,2)}] = deal(strrep(datafiles(i).name,'.txt',''));
	startindex = startindex + s(i,1);
end


% easiest method for now is use use the 1 sigma as depth1 and depth2 and set ageerr to 0
% can also try my method ofr converting age error to proxy error
% can also create a 1 sigma error from the average difference from mean
% get bryan's opinion
ageerr = ageerr * 0;

% Sort by depth
[~,ind] = sort(depth);
datelabel = datelabel(ind);
depth1 = depth1(ind);
depth2 = depth2(ind);
depth = depth(ind);
age = age(ind);
ageerr = ageerr(ind);
dateboot = logical(dateboot(ind));

% Unlike undatable, it is possibl to have NaNs so remove
index1 = isnan(age); % could be no data value
index2 = isnan(depth); % could be out of range of age model
index = sum([index1 index2],2) > 0;
depth1(index) = [];
depth2(index) = [];
depth(index) = [];
age(index) = [];
ageerr(index) = [];
dateboot(index) = [];
datelabel(index) = [];

legendlookup = fileread('private/Codes legend.txt');
legendlookup = splitlines(legendlookup);
index = contains(legendlookup,proxy);
proxy_str = legendlookup{index}(10:end);
index = strfind(proxy_str,' ');
proxy_str(index:end) = [];

end %  end function