% plot dimensions in pixels
figw = 600;
axesl = 55;
axesw = 525;
figh = 400;
axesb = 50;
axesh = 310;

% set paper size
plotwidth = 18; % centimetres
plotheight = plotwidth * (figh / figw);

% set font size
textsize = 12;

% set axis labels (e.g. change to metres or Ma if you wish)
agelabel =  'Age (ka)';

% convert pixel dimensions to relative units so plot can be resized
axesl = axesl / figw;
axesb = axesb / figh;
axesw = axesw / figw;
axesh = axesh / figh;

% center figure on primary monitor
scrnsze = get(0,'monitorPositions');
if size(scrnsze,1) > 1
	i = find(scrnsze(:,1) == 1);
else
	i = 1;
end
figl = (scrnsze(i,3)/2) - figw / 2;
figb = (scrnsze(i,4)/2) - figh / 2;