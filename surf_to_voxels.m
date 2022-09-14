hdr = niftiinfo('full16_100um_optbal_space-hist.nii.gz');
aff = hdr.Transform.T;

edgedist = 0.4; %mm

neo = gifti('layer3_right_327680_space-hist.gii');
[neoV, neoF, edge] = remesher(double(neo.vertices), double(neo.faces), edgedist, 5);
neoV = round((neoV - aff(4,1:3))/aff(1,1));

hipp = gifti('sub-bbhist_hemi-R_space-hist_den-32k_midthickness.surf.gii');
[hippV, hippF, edge] = remesher(double(hipp.vertices), double(hipp.faces), edgedist, 5);
hippV = round((hippV - aff(4,1:3))/aff(1,1));

lbl = zeros(hdr.ImageSize);
for i = 1:length(neoV)
    lbl(neoV(i,1),neoV(i,2),neoV(i,3)) = 1;
end
for i = 1:length(hippV)
    lbl(hippV(i,1),hippV(i,2),hippV(i,3)) = 2;
end
lbl(imdilate(lbl==1,strel('sphere',1))) = 1;
lbl(imdilate(lbl==2,strel('sphere',1))) = 2;


niftiwrite(uint16(lbl),lbls,hdr,'Compressed',true);

