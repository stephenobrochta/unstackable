function [udoutput, shadingmat, sarsummarymat, sarshadingmat] = unstackable(proxy,files,nsim,xfactor,bootpc,varargin)
% [udoutput, shadingmat, sarsummarymat, sarshadingmat] = undatable(inputfile,nsim,xfactor,bootpc)
%
% This is a modified version of undatable designed to stack
% data. It is essentially undatable with reversals allowed.
% A high value for bootpc will produce a smooth line with high
% uncertainty. A larger value of xfactor will increase error
% in interals that lack data, which probably won't be the case
% for standard usage. Data should be formatted following the
% PARIS database.
% https://zenodo.org/record/5115993#.Ygs2gS-l2XE
% 
% "Undatable" age-depth modelling software.
% Version 1.2 (2020-07-01). For deailed description, see:
% Lougheed, B. C. and Obrochta, S. P. (2019),
% "A rapid, deterministic age depth modeling routine for
% geological sequences with inherent depth uncertainty."
% Paleoceanography and Paleoclimatology, 34, pp. 122-133.
% https://doi.org/10.1029/2018PA003457
%
% REQUIRED INPUT VARIABLES
% ================================
%
% proxy = string name of data column to stack
% 
% files = cell of filenames or unique strings to identify files
%
% nsim = number of iterations to run (e.g. 10^3, 10^4, 10^5)
%
% xfactor = Gaussian SAR uncertainty factor (e.g. 0.1, 0.2, etc)
% if data are generally continuously and densely sampled, set to 0.
%
% bootpc = Percent of age-depth constraints to bootstrap for
% each age-depth model iteration (e.g. 10, 20, 40, etc.).
%
% OUTPUT VARIABLES
% ================================
%
% udoutput = n by 7 matrix containing age-depth model
% confidence intervals. Col 1 is depth value, Col 2 is median
% age, Col 3 is mean age, Col 4 is 2sigma lower age interval,
% Col 5 1sigma lower age interval, Col 6 is 1sigma upper age
% interval, Col 7 is 2sigma upper age interval.
%
% shadingmat = n by 99 matrix containing the 1st to 99th
% age percentiles of the age-depth model. Each row corresponds
% to the depth value of the corresponding row in the first
% column of udoutput.
%
% Additional output variables sarsummarymat and sarshadingmat
% are empty by default unless activated (see "Optional Commands" below).
%
% OUTPUT TO HARD DRIVE
% ================================
%
% The following will be saved to your working directory:
%
% A tabbed text file (yourinputname_admodel.txt),
% containing the udoutput output variable as well as information
% about sediment accumulation rate (SAR).
%
% An Adobe PDF showing the age-depth plot will be saved,
% under the name yourinputname_admodel.pdf
%
% OPTIONAL COMMANDS
% ================================
% 'combine': Sum age PDFs with identical depth intervals
% interval. 1 = Yes, 0 = No. (e.g.: 'combine',1 ) Default = 1.
%
% 'savemat' : Save a .mat file (yourinputname_output.mat)
% containing all the variables produced. 1 = Yes, 0 = No.
% (e.g.: 'savemat',1 ) default = 0.
% 
% 'savebigmat' : Save a .mat file (yourinputname_bigmat.mat)
% containg the variable 'tempage', which is the age results
% for all model iterations. Its dimensions are depthrange x nsim,
% where depthrange is top depth to bottom depth at a 1-cm interval and
% nsim is the number of monte carlo iterations. This matrix
% is usually discarded after calculating summary statistics because
% its size can cause memory errors if retained. This is not yet
% available in GUI mode. The save operation occurrs in ussummary.mat.
% If savebigmat = 1, savemat is also set to 1;
% 1 = Yes, 0 = No. (e.g.: 'savemat',1 ) default = 0.
% 
%
% 'writedir': Change the directory to which output files
% will by saved. (e.g.: 'writedir','myharddrive/somefolder/')
% Default is your working directory.
%
% 'plotme' = Enable/disable the plot windows. 1 = Yes, 0 = No.
% (e.g.: 'plotme',0) default = 1.
%
% 'printme' : Enable/disable the saving of the Adobe PDF file.
% 1 = Yes, 0 = No. (e.g.: 'printme',0) default = 1. Will revert
% to 0 if the plot window is disabled.
%
% 'vcloud' : plot the probability density cloud using vector objects.
% 1 = Yes, 0 = No, default = 0
% This makes much larger PDF files but with slightly better quality.
% Use this is you are not satisfied with graphics quality or if
% you are experiencing errors with plot2raster, which is untested
% on older versions of matlab.
% 
% 'debug' = Plot all age-depth model points used to make cloud
% 1 = Yes, 0 = No. (e.g.: 'debug',1') default = 0.

%---INPUT PARSER
p = inputParser;
p.KeepUnmatched = true;
p.CaseSensitive = false;
defaultcombine = 1;
defaultplotme = 1;
defaultprintme = 1;
defaultsavemat = 0;
defaultsavebigmat = 0;
defaultdebug = 0;
defaultwritedir = '';
defaultguimode = 0;
defaultrun1nsim = 2000;
defaultsar = 0;
defaultvcloud = 0;
defaultdt = 100;
[defaultminproxy,defaultmaxproxy] = deal([]);
scenario = 'SCEN1';
rangeage = [];
makeanimation = 0;
SaveName = '';
Location = '';
datapath = 'Data-with-age/26-Aug-2021 11.08.41 n10000 x0.1 b30/';
plotraw = 1;

addParameter(p,'combine',defaultcombine,@isnumeric);
addParameter(p,'plotme',defaultplotme,@isnumeric);
addParameter(p,'printme',defaultprintme,@isnumeric);
addParameter(p,'savemat',defaultsavemat,@isnumeric);
addParameter(p,'savebigmat',defaultsavebigmat,@isnumeric);
addParameter(p,'debug',defaultdebug,@isnumeric);
addParameter(p,'writedir',defaultwritedir,@isstr);
addParameter(p,'guimode',defaultguimode,@isnumeric);
addParameter(p,'run1nsim',defaultrun1nsim,@isnumeric);
addParameter(p,'sar',defaultsar,@isnumeric);
addParameter(p,'vcloud',defaultvcloud,@isnumeric);
addParameter(p,'dt',defaultdt,@isnumeric);
addParameter(p,'minproxy',defaultminproxy,@isnumeric);
addParameter(p,'maxproxy',defaultmaxproxy,@isnumeric);
addParameter(p,'scenario',scenario,@isstr);
addParameter(p,'agerange',rangeage,@isnumeric);
addParameter(p,'movie',makeanimation,@isnumeric);
addParameter(p,'savename',SaveName,@isstr);
addParameter(p,'location',Location,@isstr);
addParameter(p,'datapath',datapath,@isstr);

parse(p,varargin{:});
depthcombine=p.Results.combine;
plotme = p.Results.plotme;
printme = p.Results.printme;
savemat = p.Results.savemat;
savebigmat = p.Results.savebigmat;
debugme = p.Results.debug;
writedir = p.Results.writedir;
guimode = p.Results.guimode;
run1nsim = p.Results.run1nsim;
sar = p.Results.sar;
vcloud = p.Results.vcloud;
dt = p.Results.dt;
minproxy = p.Results.minproxy;
maxproxy = p.Results.maxproxy;
scenario = p.Results.scenario;
rangeage = p.Results.agerange;
makeanimation = p.Results.movie;
SaveName = p.Results.savename;
Location = p.Results.location;
datapath = p.Results.datapath;
if isempty(Location)
	% preallocate a string arrary with extra room for ', '. There's gotta be a better way
	loc_length = length([files{:}]) + 2 * (length(files) - 1);
	Location = blanks(loc_length);
	% starting index
	j = 1;
	for i = 1:length(files)
		% end index of current string
		k = length(files{i}) + 2 + j - 1;
		Location(j:k) = [files{i} ', '];
		j = k + 1;
	end
end
if isempty(SaveName)
	Title = [Location proxy '_' scenario];
	SaveName = strrep(Title,', ','_');
end

% append / to writedir in case user forgot
if isempty(writedir) == 0
	if strcmp(writedir(end),'/') == 0 && strcmp(writedir(end),'\') == 0
		writedir = [writedir,'/'];
	end
end

% Check bootpc
if bootpc < 0
	bootpc = 0;
elseif bootpc >= 100
	error('It is not possible to bootstrap 100% or more, please select lower bootpc');
end

%---GET AND SORT INPUT DATA
[datelabel, depth1, depth2, depth, age, ageerr, proxy_str, dateboot] = usgetdata(proxy, files, scenario,datapath);

%---MAKE AGE AND DEPTH PDFs
[medians, p68_2, p95_4, probtoplot, rundepth, rundepthpdf, runprob2sig, runboot, runncaldepth, usrunshuffle] = usmakepdfs(depth, depth1, depth2, age, ageerr, dateboot, depthcombine);

%---RUN THE AGE DEPTH LOOPS
if mean(depth2 - depth1) ~= 0
	% run1nsim = 2000; % default now set in input parser
	%message1 = ['Depth uncertainty detected: Running preliminary Monte Carlo age-depth loops'];
else
	run1nsim = nsim;
	%message1 = 'Running the Monte Carlo age-depth loops';
end

% run age depth loop for the first time (without anchors)
agedepmat = usrun(nsim, bootpc, xfactor, rundepth, rundepthpdf, runprob2sig, runboot, runncaldepth, usrunshuffle);

% summarise the data
depthstart = depth(1);
depthend = depth(end);
[summarymat, shadingmat, depthrange] = ussummary(depthstart, depthend, run1nsim, agedepmat, dt, writedir, bootpc, xfactor, depthcombine, savebigmat, proxy, SaveName);

if mean(depth2 - depth1) ~= 0
	
	% make anchors based on first run
	[rundepth, rundepthpdf, runprob2sig, runboot, runncaldepth] = usanchors(depthrange, summarymat, rundepth, rundepthpdf, runprob2sig, runboot);
	
	% run age depth loop for the second time with anchors
	agedepmat = usrun(nsim, bootpc, xfactor, rundepth, rundepthpdf, runprob2sig, runboot, runncaldepth, usrunshuffle);
	
	% summarise the data
	[summarymat, shadingmat, depthrange] = ussummary(depthstart, depthend, nsim, agedepmat, dt, writedir, bootpc, xfactor, depthcombine, savebigmat, proxy, SaveName);
end

if sum(isnan(agedepmat(:,1,:))) == numel(agedepmat(:,1,:))
	warning('All age-depth runs failed to produce an age-depth relationship. Check run settings (bootpc too high/low?). Also, your data may not be suitable or contain typos.')
end

udoutput = [depthrange summarymat(:,1) summarymat(:,6) summarymat(:,2:5)]; % summarymat is: median, 2siglo, 1siglo, 1sighi, 2sighi, mean

% Save output (if savemat selected)
if savebigmat == 1
	savemat = 1;
end

if savemat == 1 && guimode == 0
	save([writedir,SaveName,'.mat'])
elseif guimode == 1
	save([writedir,'guitemp.mat'])
end

%---PLOT STUFF
if plotme == 1
	usplot
end

end % end function

