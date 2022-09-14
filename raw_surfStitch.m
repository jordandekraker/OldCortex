% Tries to stitch together hipp and neocortical surfaces by making a 'bidgehead'. Still not fully happy since there are sections with gaps and overlaps, and the face connectivity only goes one way.

clear; close all;

hdr = niftiinfo('sourcedata/full16_100um_optbal_space-hist.nii.gz');
aff = hdr.Transform.T;
hipp = gifti('sourcedata/sub-bbhist_hemi-R_space-hist_den-32k_midthickness.surf.gii');
neo = gifti('sourcedata/layer3_right_327680_space-hist.gii');
neo.vertices = (neo.vertices - aff(4,1:3))/aff(1,1); % same as (vertices(:,1:4)*aff)'
hipp.vertices = (hipp.vertices - aff(4,1:3))/aff(1,1); % same as (vertices(:,1:4)*aff)'

load('/export03/data/micaopen/cortical_confluence/data/bigbrain_labels.mat','bigbrain_labels');

neo.vertices(bigbrain_labels==1,:) = nan;
p = patch('faces',neo.faces,'vertices',neo.vertices);
p.LineStyle = 'none';
p.FaceVertexCData = bigbrain_labels';
p.FaceColor = 'flat'; % default grey
material dull;
axis equal tight off;
light;


% remove "wall" vertices
% conditioned on unknown + superior to the closest hippocampal
% bridgehead
load([micaopen '/data/bigbrain_wall.mat']);
wall_idx = find(bigbrain_labels==1);
rm_idx = zeros(1,length(P.coord));
PD1 = find(PD_hipp==min(PD_hipp));
n1 = length(PD1);
for ii = 1:length(wall_idx) 
    d = sqrt(sum((repmat(P.coord(:,wall_idx(ii)),1,n1) - I.coord(:,PD1)).^2));
    d = abs(diff([repmat(P.coord(2,wall_idx(ii)),1,n1); I.coord(2,PD1)]));
    [~, closest_bridgehead] = min(d);
    if P.coord(3,wall_idx(ii)) - I.coord(3,PD1(closest_bridgehead)) > 0
        rm_idx(wall_idx(ii)) = 1;
    end
end
P_slim = remove_vertices(P, rm_idx);

% find links along the proximal edge of the hippocampus
edg = SurfStatEdg(I);
new_tri = [0 0 0];
n1 = length(P_slim.coord);
for ii = 1:length(PD1)
   potential_edge = [edg(edg(:,1)==PD1(ii),2); edg(edg(:,2)==PD1(ii),1)];
   good_edge = potential_edge(ismember(potential_edge, PD1));  % matching to other edge vertices of the hippocampus
    if length(good_edge)>2  % take the closest in each direction
       clear tmp 
       y_shift = I.coord(2,good_edge) - I.coord(2,PD1(ii));
        y_shift(y_shift<0) = nan;
        [~, tmp(1)] = min(y_shift);
        y_shift = I.coord(2,good_edge) - I.coord(2,PD1(ii));
        y_shift(y_shift>0) = nan;
        [~, tmp(2)] = max(y_shift);
        good_edge = good_edge(tmp);
   end
   cort_vert = zeros(1,2);
   for jj = 1:length(good_edge)
       d1 = sqrt(sum((repmat(I.coord(:,PD1(ii)),1,n1) - P_slim.coord).^2));
       d2 = sqrt(sum((repmat(I.coord(:,good_edge(jj)),1,n1) - P_slim.coord).^2));
       [min_d, idx_d] = min(sum([d1; d2]));                  % find nearest cortical vertex for the hippocampal pair
       cort_vert(1,jj) = idx_d(1)+length(I.coord);
       new_tri = [new_tri; double([PD1(ii) good_edge(jj)  cort_vert(1,jj)])];
   end
   if length(good_edge) == 2
        new_tri = [new_tri; double([PD1(ii) cort_vert(1,:)])];  % make a triangle between the bridgehead and the cortical pair
   end
end   
new_tri(1,:) = [];

% create the confluence surface
C.coord = [I.coord P_slim.coord]';
C.tri   = [I.tri; P_slim.tri+length(I.coord); new_tri];


p = patch('faces',C.tri,'vertices',C.coord');
p.FaceColor = 'b'; % default grey
p.LineStyle = 'none';
material dull;
axis equal tight off;
light;


hdr = niftiinfo('labelmap-postProc.nii.gz');
gii = gifti();
gii.faces = C.tri;
gii.vertices = C.coord';
save(gii,'cortical_confluence.surf.gii','Base64Binary');
