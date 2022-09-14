clear; close all;

lbl = niftiread('lbls_JD-sparse_space-ICBM2009asym7.nii.gz');
% swap these labels (easier to index later)
lbl(lbl==4) = 11;
lbl(lbl==5) = 4;
lbl(lbl==11) = 5;
hdr = niftiinfo('lbls_JD-sparse_space-ICBM2009asym7.nii.gz');
% clean
l = bwconncomp(lbl>0);
idxgm = l.PixelIdxList{1};
lbl(~idxgm) = 0;
lbl(lbl>5) = 5; %terminus
clear l;

%% get some radial coordinates

% geodesic distance from terminus
dist = bwdistgeodesic(lbl>0,lbl==5);
dist = dist(idxgm);
dist(isnan(dist)) = 0;
dist(isinf(dist)) = 0;
[~,neoend] = max(dist);
dist = dist/max(dist);
% dilate a bit but stay in idxgm
i = zeros(size(lbl));
i(idxgm(neoend)) = 1;
i = imdilate(i,strel('sphere',2));
neoend = find(i==1);
i = ismember(neoend,idxgm);
neoend = neoend(i);
lbl(neoend) = 6; % distal neocortex

% inverted distance
distinv = bwdistgeodesic(lbl>0,double(neoend));
distinv = distinv(idxgm);
distinv(isnan(distinv)) = 0;
distinv(isinf(distinv)) = 0;
distinv = 1- distinv/max(distinv);

% both (averaged)
both = (dist+distinv)/2;

% Laplacian
Laplace_radial = laplace_solver(idxgm,find(lbl==5),neoend,1000,both,size(lbl),2);
LP = zeros(size(lbl));
LP(idxgm) = Laplace_radial;
hdr.Datatype = 'double';
niftiwrite(LP,'Laplace_radial',hdr,'compressed',true);

%% meridian

% custom gradient descent
LP = nan(size(lbl));
LP(idxgm) = Laplace_radial;
check = zeros(size(lbl));
descentpath = zeros(size(lbl));
m=1; pos = neoend;
while m>0
    check(:) = 0;
    check(pos) = 1;
    check = imdilate(check,strel('sphere',2));
    checkind = find(check==1);
    [m,i] = nanmin(LP(checkind));
    pos = checkind(i);
    descentpath(pos) = 1;
    disp(m)
end

% dilate to cover thickness
descentpath = imdilate(descentpath,strel('sphere',2)) & lbl>0;
descentpath = imdilate(descentpath,strel('sphere',2)) & lbl>0;
descentpath = imdilate(descentpath,strel('sphere',2)) & lbl>0;
lbl(descentpath==1 & lbl<5) = 7; % meridian
lbl(neoend) = 6; % distal neocortex (dont let this get overwritten!

% here i manually labelled the other half of the meridian with label==8
% save new labels

hdr.Datatype = 'uint16';
niftiwrite(lbl,'lbls_JD-sparse_space-ICBM2009asym8',hdr,'compressed',true);

clearvars -except lbl hdr idxgm Laplace_radial

%% get tangential coords

lbl = niftiread('lbls_JD-sparse_space-ICBM2009asym9.nii.gz');
Laplace_radial = niftiread('Laplace_radial.nii.gz');

% custom initialization (otherwise solution takes way too long)
pts = 0:0.02:1;
dist = zeros(size(lbl));
for r = 1:(length(pts)-1)
    domain = Laplace_radial>pts(r) & Laplace_radial<=pts(r+1);
    domain(lbl==8) = 0;
    d = bwdistgeodesic(domain,find(lbl==7));
    d = d(domain);
    d(isnan(d) | isinf(d)) = 0;
    d = d/max(d);
    dist(domain) = d;
end
dist = dist(lbl>0);

% clear up as much memory as possible
i = find(lbl>0);
s = find(lbl==7);
e = find(lbl==8);
sz = size(lbl);
clearvars -except dist i s e sz
Laplace_tangential = laplace_solver(i,s,e,2000,dist,sz,4);
Laplace_tangential = laplace_solver(i,s,e,2000,Laplace_tangential,sz,1);

hdr = niftiinfo('lbls_JD-sparse_space-ICBM2009asym7.nii.gz');
LP = zeros(sz);
LP(i) = Laplace_tangential;
hdr.Datatype = 'double';
niftiwrite(LP,'Laplace_tangential',hdr);

%% plot

%hdr = niftiinfo('lbls_JD-sparse_space-ICBM2009asym7.nii.gz');
[x,y,z] = ind2sub(sz,i);
figure;
scatter3(x,y,z,1,Laplace_radial,'.'); axis equal tight;
figure;
scatter3(x,y,z,1,Laplace_tangential,'.'); axis equal tight;
